import CoreLocation
import Foundation

@MainActor
class SuggestionDetailViewModel: ObservableObject {
    @Published var suggestion: Suggestion
    @Published var alternatives: [Suggestion] = []
    @Published var isAccepted = false
    @Published var isFavorite = false
    @Published var calendarAlertMessage: String?
    /// 解決済みの現在地。ブラウザ経路で出発点を明示するために使う（#40）。
    /// 目的地が設定されている場合や現在地が取れない場合は nil のまま。
    @Published private(set) var currentLocationPoint: MapPoint?

    private let suggestionEngine: SuggestionEngineProtocol
    private let placeSearchService: PlaceSearchServiceProtocol
    private var weather: WeatherData?
    private var preference: UserPreference?
    private var preferenceService: PreferenceServiceProtocol?
    private var locationService: LocationServiceProtocol?
    private var calendarService: CalendarServiceProtocol?
    private var favoriteService: FavoriteServiceProtocol?

    /// 設定中の今日の目的地（あれば周辺スポット検索の基点になる）
    private(set) var destination: TodayDestination?

    init(
        suggestion: Suggestion,
        suggestionEngine: SuggestionEngineProtocol = SuggestionEngine(),
        placeSearchService: PlaceSearchServiceProtocol = PlaceSearchService()
    ) {
        self.suggestion = suggestion
        self.suggestionEngine = suggestionEngine
        self.placeSearchService = placeSearchService
        self.isAccepted = suggestion.isAccepted
    }

    func configure(
        weather: WeatherData?,
        preference: UserPreference,
        preferenceService: PreferenceServiceProtocol? = nil,
        locationService: LocationServiceProtocol? = nil,
        calendarService: CalendarServiceProtocol? = nil,
        favoriteService: FavoriteServiceProtocol? = nil,
        destination: TodayDestination? = nil
    ) {
        self.weather = weather
        self.preference = preference
        self.preferenceService = preferenceService
        self.locationService = locationService
        self.calendarService = calendarService
        self.favoriteService = favoriteService
        self.destination = destination
        updateFavoriteState()
        loadAlternatives()
    }

    /// 周辺スポット検索の基点。目的地が設定されていればそれを優先し、なければ現在地（GPS）。
    private func effectiveLocation() async -> CLLocation? {
        if let destination {
            return destination.location
        }
        return await locationService?.requestCurrentLocation()
    }

    func accept() {
        isAccepted = true
        suggestion.isAccepted = true
        // Record selection for learning system
        preferenceService?.recordSelection(for: suggestion.category)

        // カレンダーに登録
        guard let calendarService else {
            calendarAlertMessage = String(localized: "提案を受け入れました")
            return
        }
        do {
            try calendarService.addEvent(
                title: suggestion.title,
                startDate: suggestion.freeTimeSlot.startDate,
                endDate: suggestion.freeTimeSlot.endDate,
                notes: suggestion.description
            )
            calendarAlertMessage = String(localized: "カレンダーに追加しました")
        } catch {
            calendarAlertMessage = String(localized: "カレンダーへの追加に失敗しました")
        }
    }

    /// お気に入りの追加・解除を切り替える
    func toggleFavorite() {
        guard let favoriteService else { return }

        if isFavorite {
            // タイトルとカテゴリが一致するお気に入りを探して削除
            let favorites = favoriteService.getFavorites()
            if let existing = favorites.first(where: {
                $0.title == suggestion.title && $0.category == suggestion.category
            }) {
                favoriteService.removeFavorite(id: existing.id)
            }
        } else {
            favoriteService.addFavorite(suggestion)
        }
        isFavorite.toggle()
    }

    /// 現在の提案がお気に入りかどうかを更新する
    private func updateFavoriteState() {
        guard let favoriteService else { return }
        isFavorite = favoriteService.isFavorite(
            title: suggestion.title,
            category: suggestion.category
        )
    }

    func enrichIfNeeded() async {
        // スポット補完とは独立して走らせる。enrichWithPlace() は nearbyPlace が
        // 既にあると早期 return するため、そこに相乗りさせるとホーム画面で
        // スポットが埋まっている通常の経路で現在地が解決されない。
        await resolveCurrentLocationIfNeeded()
        await enrichWithPlace()
    }

    /// ブラウザ経路の出発点に使う現在地を解決する（#40）。
    /// 目的地が設定されているときは目的地が出発点になるので不要。
    private func resolveCurrentLocationIfNeeded() async {
        guard destination == nil, currentLocationPoint == nil else { return }
        guard let location = await locationService?.requestCurrentLocation() else { return }
        // 名前は付けない（現在地は固有名を持たないため）
        currentLocationPoint = MapPoint(
            name: nil,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }

    private func enrichWithPlace() async {
        guard suggestion.nearbyPlace == nil,
              let location = await effectiveLocation() else { return }
        if let place = await placeSearchService.findNearbyPlace(
            for: suggestion.category, near: location
        ) {
            suggestion.nearbyPlace = place
        }
    }

    private func loadAlternatives() {
        guard let preference else { return }

        alternatives = suggestionEngine.generateAlternatives(
            for: suggestion.freeTimeSlot,
            weather: weather,
            preference: preference,
            excluding: suggestion.category
        )
    }
}
