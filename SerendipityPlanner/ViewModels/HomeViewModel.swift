import Combine
import CoreLocation
import Foundation
import WidgetKit

@MainActor
class HomeViewModel: ObservableObject {
    @Published var freeTimeSlots: [FreeTimeSlot] = []
    @Published var suggestions: [Suggestion] = []
    @Published var acceptedSuggestions: [Suggestion] = []
    @Published var weather: WeatherData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var warningMessage: String?

    let calendarService: CalendarServiceProtocol
    private let weatherService: WeatherServiceProtocol
    private let suggestionEngine: SuggestionEngineProtocol
    private let notificationService: NotificationServiceProtocol
    private let placeSearchService: PlaceSearchServiceProtocol

    private var preferenceService: PreferenceServiceProtocol?
    private var locationService: LocationServiceProtocol?
    private var destinationService: DestinationServiceProtocol?
    private let historyService: HistoryServiceProtocol

    init(
        calendarService: CalendarServiceProtocol = CalendarService(),
        weatherService: WeatherServiceProtocol = WeatherService(),
        suggestionEngine: SuggestionEngineProtocol = SuggestionEngine(),
        notificationService: NotificationServiceProtocol = NotificationService(),
        placeSearchService: PlaceSearchServiceProtocol = PlaceSearchService(),
        historyService: HistoryServiceProtocol = HistoryService()
    ) {
        self.calendarService = calendarService
        self.weatherService = weatherService
        self.suggestionEngine = suggestionEngine
        self.notificationService = notificationService
        self.placeSearchService = placeSearchService
        self.historyService = historyService
    }

    func configure(
        with preferenceService: PreferenceServiceProtocol,
        locationService: LocationServiceProtocol,
        destinationService: DestinationServiceProtocol? = nil
    ) {
        self.preferenceService = preferenceService
        self.locationService = locationService
        self.destinationService = destinationService
    }

    /// 現在設定中の今日の目的地（未設定なら nil）
    var destination: TodayDestination? {
        destinationService?.currentDestination
    }

    /// 目的地周辺で実際にスポットが見つかった提案の件数（バナー表示用）
    var resolvedSpotCount: Int {
        suggestions.filter { $0.nearbyPlace != nil }.count
    }

    /// 提案の検索基点となる位置。目的地が設定されていればそれを優先し、なければ現在地（GPS）。
    private func effectiveLocation() async -> CLLocation? {
        if let destination = destinationService?.currentDestination {
            return destination.location
        }
        return await locationService?.requestCurrentLocation()
    }

    /// 目的地を設定し、その周辺で提案を再生成する
    func setDestination(_ destination: TodayDestination) async {
        destinationService?.setDestination(destination)
        await refresh()
    }

    /// 目的地を解除し、現在地ベースで提案を再生成する
    func clearDestination() async {
        destinationService?.clearDestination()
        await refresh()
    }

    func loadData() async {
        isLoading = true
        errorMessage = nil
        warningMessage = nil

        // Restore persisted accepted suggestions for today
        loadAcceptedSuggestions()

        // 検索基点を決定（目的地が設定されていればその座標、なければ現在地）。
        // 天気・周辺スポット検索の両方でこの位置を使う。
        let location = await effectiveLocation()

        async let weatherTask: () = fetchWeather(location: location)
        async let slotsTask: () = fetchFreeTimeSlots()

        _ = await (weatherTask, slotsTask)

        generateSuggestions()

        // Enrich suggestions with nearby places
        if let location {
            await enrichSuggestionsWithPlaces(near: location)
        }

        // Widgetにデータを共有
        updateWidgetData()

        isLoading = false
    }

    func refresh() async {
        let preserved = acceptedSuggestions
        await loadData()
        // Merge: keep previously accepted suggestions that aren't already restored
        let restoredIDs = Set(acceptedSuggestions.map(\.id))
        for item in preserved where !restoredIDs.contains(item.id) {
            acceptedSuggestions.append(item)
        }
    }

    // MARK: - Weather

    private func fetchWeather(location: CLLocation?) async {
        do {
            if let location {
                weather = try await weatherService.fetchWeather(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            } else {
                weather = WeatherService.mockWeather()
                warningMessage = "位置情報が取得できないため、天気情報は概算です"
            }
        } catch {
            weather = WeatherService.mockWeather()
            warningMessage = "天気情報の取得に失敗しました。概算の天気を表示しています"
        }
    }

    // MARK: - Calendar

    private func fetchFreeTimeSlots() async {
        if !calendarService.hasAccess {
            do {
                let granted = try await calendarService.requestAccess()
                guard granted else {
                    errorMessage = "カレンダーへのアクセスが許可されていません。"
                    return
                }
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }

        do {
            let preference = preferenceService?.preference ?? .default
            let now = Date()
            freeTimeSlots = try await calendarService.fetchFreeTimeSlots(
                from: now,
                to: now.endOfDay,
                minimumMinutes: preference.minimumFreeTimeMinutes,
                activeHours: preference.activeHours
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Suggestions

    private func generateSuggestions() {
        guard let preference = preferenceService?.preference else { return }

        suggestions = freeTimeSlots.flatMap { slot in
            suggestionEngine.generateSuggestions(
                for: slot,
                weather: weather,
                preference: preference
            )
        }

        scheduleNotifications()
    }

    // MARK: - Notifications

    private func scheduleNotifications() {
        guard let settings = preferenceService?.settings,
              settings.notificationsEnabled
        else {
            notificationService.cancelAllNotifications()
            return
        }

        // Morning summary notification
        if settings.morningNotificationEnabled {
            notificationService.scheduleMorningNotification(
                hour: settings.morningNotificationHour,
                freeSlotCount: suggestions.count
            )
        } else {
            notificationService.cancelMorningNotification()
        }

        // Before free time notifications
        if settings.beforeFreeTimeNotificationEnabled {
            for suggestion in suggestions {
                notificationService.scheduleSuggestionNotification(
                    for: suggestion,
                    leadTimeMinutes: settings.notificationLeadTimeMinutes
                )
            }
        }
    }

    // MARK: - Place Search

    private func enrichSuggestionsWithPlaces(near location: CLLocation) async {
        for i in suggestions.indices {
            let category = suggestions[i].category
            if let place = await placeSearchService.findNearbyPlace(for: category, near: location) {
                suggestions[i].nearbyPlace = place
            }
        }
    }

    func regenerateSuggestion(for slot: FreeTimeSlot, excluding category: SuggestionCategory) {
        guard let preference = preferenceService?.preference else { return }

        let alternatives = suggestionEngine.generateAlternatives(
            for: slot,
            weather: weather,
            preference: preference,
            excluding: category
        )

        if let newSuggestion = alternatives.first,
           let index = suggestions.firstIndex(where: { $0.freeTimeSlot == slot }) {
            suggestions[index] = newSuggestion

            // Search for nearby place for the new suggestion
            Task {
                guard let location = await effectiveLocation() else { return }
                if let place = await placeSearchService.findNearbyPlace(
                    for: newSuggestion.category, near: location
                ) {
                    suggestions[index].nearbyPlace = place
                }
            }
        }
    }

    func acceptSuggestion(_ suggestion: Suggestion) {
        if let index = suggestions.firstIndex(where: { $0.id == suggestion.id }) {
            var accepted = suggestions[index]
            accepted.isAccepted = true
            acceptedSuggestions.append(accepted)
            suggestions.remove(at: index)
            saveAcceptedSuggestions()

            // 履歴に保存
            let history = SuggestionHistory(
                suggestion: accepted,
                acceptedDate: Date(),
                placeName: accepted.nearbyPlace?.name,
                placeAddress: nil
            )
            historyService.saveHistory(history)
        }
    }

    // MARK: - Widget Data Sharing

    private func updateWidgetData() {
        // 提案の freeTimeSlot（分割後サブスロット含む）を保存することで
        // ウィジェット側の id マッチングが正しく機能する
        let effectiveSlots = suggestions
            .map(\.freeTimeSlot)
            .sorted { $0.startDate < $1.startDate }
        SharedDataManager.saveAll(
            slots: effectiveSlots.isEmpty ? freeTimeSlots : effectiveSlots,
            suggestions: suggestions,
            weather: weather
        )
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Accepted Suggestions Persistence

    private func saveAcceptedSuggestions() {
        guard let data = try? JSONEncoder().encode(acceptedSuggestions) else { return }
        UserDefaults.standard.set(data, forKey: Constants.Storage.acceptedSuggestionsKey)
    }

    private func loadAcceptedSuggestions() {
        guard let data = UserDefaults.standard.data(forKey: Constants.Storage.acceptedSuggestionsKey),
              let saved = try? JSONDecoder().decode([Suggestion].self, from: data) else { return }

        // Only restore suggestions from today
        let calendar = Calendar.current
        let todaySuggestions = saved.filter { calendar.isDateInToday($0.freeTimeSlot.startDate) }

        // Clean up stale data if needed
        if todaySuggestions.count != saved.count {
            if todaySuggestions.isEmpty {
                UserDefaults.standard.removeObject(forKey: Constants.Storage.acceptedSuggestionsKey)
            } else if let data = try? JSONEncoder().encode(todaySuggestions) {
                UserDefaults.standard.set(data, forKey: Constants.Storage.acceptedSuggestionsKey)
            }
        }

        acceptedSuggestions = todaySuggestions
    }
}
