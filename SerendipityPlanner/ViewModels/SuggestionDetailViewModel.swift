import Foundation

@MainActor
class SuggestionDetailViewModel: ObservableObject {
    @Published var suggestion: Suggestion
    @Published var alternatives: [Suggestion] = []
    @Published var isAccepted = false
    @Published var calendarAlertMessage: String?

    private let suggestionEngine: SuggestionEngineProtocol
    private let placeSearchService: PlaceSearchServiceProtocol
    private var weather: WeatherData?
    private var preference: UserPreference?
    private var preferenceService: PreferenceServiceProtocol?
    private var locationService: LocationServiceProtocol?
    private var calendarService: CalendarServiceProtocol?

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

    func configure(weather: WeatherData?, preference: UserPreference, preferenceService: PreferenceServiceProtocol? = nil, locationService: LocationServiceProtocol? = nil, calendarService: CalendarServiceProtocol? = nil) {
        self.weather = weather
        self.preference = preference
        self.preferenceService = preferenceService
        self.locationService = locationService
        self.calendarService = calendarService
        loadAlternatives()
    }

    func accept() {
        isAccepted = true
        suggestion.isAccepted = true
        // Record selection for learning system
        preferenceService?.recordSelection(for: suggestion.category)

        // カレンダーに登録
        guard let calendarService = calendarService else {
            calendarAlertMessage = "提案を受け入れました"
            return
        }
        do {
            try calendarService.addEvent(
                title: suggestion.title,
                startDate: suggestion.freeTimeSlot.startDate,
                endDate: suggestion.freeTimeSlot.endDate,
                notes: suggestion.description
            )
            calendarAlertMessage = "カレンダーに追加しました"
        } catch {
            calendarAlertMessage = "カレンダーへの追加に失敗しました"
        }
    }

    func enrichIfNeeded() async {
        await enrichWithPlace()
    }

    func regenerate() {
        guard let preference = preference else { return }

        let newSuggestion = suggestionEngine.generateSuggestion(
            for: suggestion.freeTimeSlot,
            weather: weather,
            preference: preference
        )
        suggestion = newSuggestion
        isAccepted = false
        loadAlternatives()
        Task { await enrichWithPlace() }
    }

    private func enrichWithPlace() async {
        guard suggestion.nearbyPlace == nil,
              let location = await locationService?.requestCurrentLocation() else { return }
        if let place = await placeSearchService.findNearbyPlace(
            for: suggestion.category, near: location
        ) {
            suggestion.nearbyPlace = place
        }
    }

    private func loadAlternatives() {
        guard let preference = preference else { return }

        alternatives = suggestionEngine.generateAlternatives(
            for: suggestion.freeTimeSlot,
            weather: weather,
            preference: preference,
            excluding: suggestion.category
        )
    }
}
