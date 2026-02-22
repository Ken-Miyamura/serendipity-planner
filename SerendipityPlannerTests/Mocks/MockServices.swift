import Foundation
import CoreLocation
@testable import SerendipityPlanner

// MARK: - MockCalendarService

class MockCalendarService: CalendarServiceProtocol {
    var hasAccess: Bool = true
    var requestAccessResult: Bool = true
    var requestAccessError: Error?
    var addEventError: Error?
    var freeTimeSlots: [FreeTimeSlot] = []
    var fetchFreeSlotsError: Error?

    var requestAccessCallCount = 0
    var addEventCallCount = 0
    var addEventTitles: [String] = []
    var fetchFreeSlotsCallCount = 0

    func requestAccess() async throws -> Bool {
        requestAccessCallCount += 1
        if let error = requestAccessError { throw error }
        return requestAccessResult
    }

    func addEvent(title: String, startDate: Date, endDate: Date, notes: String?) throws {
        addEventCallCount += 1
        addEventTitles.append(title)
        if let error = addEventError { throw error }
    }

    func fetchFreeTimeSlots(
        from startDate: Date,
        to endDate: Date,
        minimumMinutes: Int,
        activeHours: ActiveHoursPreference
    ) async throws -> [FreeTimeSlot] {
        fetchFreeSlotsCallCount += 1
        if let error = fetchFreeSlotsError { throw error }
        return freeTimeSlots
    }

    func fetchUpcomingFreeSlots(
        days: Int,
        minimumMinutes: Int,
        activeHours: ActiveHoursPreference
    ) async throws -> [FreeTimeSlot] {
        fetchFreeSlotsCallCount += 1
        if let error = fetchFreeSlotsError { throw error }
        return freeTimeSlots
    }
}

// MARK: - MockWeatherService

class MockWeatherService: WeatherServiceProtocol {
    var weatherResult: WeatherData?
    var weatherError: Error?
    var fetchWeatherCallCount = 0

    func fetchWeather(for city: String) async throws -> WeatherData {
        fetchWeatherCallCount += 1
        if let error = weatherError { throw error }
        return weatherResult ?? WeatherData(
            temperature: 20.0, condition: .clear, description: "晴れ",
            humidity: 50, windSpeed: 3.0, fetchedAt: Date()
        )
    }

    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherData {
        fetchWeatherCallCount += 1
        if let error = weatherError { throw error }
        return weatherResult ?? WeatherData(
            temperature: 20.0, condition: .clear, description: "晴れ",
            humidity: 50, windSpeed: 3.0, fetchedAt: Date()
        )
    }
}

// MARK: - MockLocationService

class MockLocationService: LocationServiceProtocol {
    var currentLocationName: String = "東京 渋谷"
    var currentLocation: CLLocation?
    var locationAuthorized: Bool = true

    var requestPermissionCallCount = 0
    var requestCurrentLocationCallCount = 0

    func requestPermission() {
        requestPermissionCallCount += 1
    }

    func requestCurrentLocation() async -> CLLocation? {
        requestCurrentLocationCallCount += 1
        return currentLocation
    }
}

// MARK: - MockNotificationService

class MockNotificationService: NotificationServiceProtocol {
    var requestPermissionResult: Bool = true
    var requestPermissionError: Error?
    var isAuthorizedResult: Bool = true

    var requestPermissionCallCount = 0
    var scheduleSuggestionCallCount = 0
    var scheduleMorningCallCount = 0
    var cancelMorningCallCount = 0
    var cancelNotificationCallCount = 0
    var cancelAllCallCount = 0

    func requestPermission() async throws -> Bool {
        requestPermissionCallCount += 1
        if let error = requestPermissionError { throw error }
        return requestPermissionResult
    }

    func isAuthorized() async -> Bool {
        return isAuthorizedResult
    }

    func scheduleSuggestionNotification(for suggestion: Suggestion, leadTimeMinutes: Int) {
        scheduleSuggestionCallCount += 1
    }

    func scheduleMorningNotification(hour: Int, freeSlotCount: Int) {
        scheduleMorningCallCount += 1
    }

    func cancelMorningNotification() {
        cancelMorningCallCount += 1
    }

    func cancelNotification(for suggestionId: UUID) {
        cancelNotificationCallCount += 1
    }

    func cancelAllNotifications() {
        cancelAllCallCount += 1
    }
}

// MARK: - MockPlaceSearchService

class MockPlaceSearchService: PlaceSearchServiceProtocol {
    var nearbyPlaces: [NearbyPlace] = []
    var findResult: NearbyPlace?
    var searchCallCount = 0
    var findCallCount = 0

    func searchNearbyPlaces(for category: SuggestionCategory, near location: CLLocation) async -> [NearbyPlace] {
        searchCallCount += 1
        return nearbyPlaces
    }

    func findNearbyPlace(for category: SuggestionCategory, near location: CLLocation) async -> NearbyPlace? {
        findCallCount += 1
        return findResult
    }
}

// MARK: - MockSuggestionEngine

class MockSuggestionEngine: SuggestionEngineProtocol {
    var generateResult: Suggestion?
    var alternativesResult: [Suggestion] = []
    var generateCallCount = 0
    var alternativesCallCount = 0

    func generateSuggestion(for slot: FreeTimeSlot, weather: WeatherData?, preference: UserPreference) -> Suggestion {
        generateCallCount += 1
        return generateResult ?? Suggestion(
            category: .cafe,
            title: "テスト提案",
            description: "テスト用の説明",
            duration: slot.durationMinutes,
            freeTimeSlot: slot,
            weatherContext: "テスト天気"
        )
    }

    func generateAlternatives(
        for slot: FreeTimeSlot,
        weather: WeatherData?,
        preference: UserPreference,
        excluding: SuggestionCategory?
    ) -> [Suggestion] {
        alternativesCallCount += 1
        return alternativesResult
    }
}

// MARK: - MockPreferenceService

class MockPreferenceService: PreferenceServiceProtocol {
    var settings: UserSettings = .default
    var preference: UserPreference = .default

    var saveSettingsCallCount = 0
    var savePreferenceCallCount = 0
    var completeOnboardingCallCount = 0
    var recordSelectionCategories: [SuggestionCategory] = []
    var resetLearningDataCallCount = 0
    var resetAllCallCount = 0

    func saveSettings() { saveSettingsCallCount += 1 }
    func savePreference() { savePreferenceCallCount += 1 }

    func completeOnboarding() {
        completeOnboardingCallCount += 1
        settings.hasCompletedOnboarding = true
    }

    func updateNotificationEnabled(_ enabled: Bool) {
        settings.notificationsEnabled = enabled
        saveSettingsCallCount += 1
    }

    func updateNotificationLeadTime(_ minutes: Int) {
        settings.notificationLeadTimeMinutes = minutes
        saveSettingsCallCount += 1
    }

    func updateMorningNotificationEnabled(_ enabled: Bool) {
        settings.morningNotificationEnabled = enabled
        saveSettingsCallCount += 1
    }

    func updateMorningNotificationHour(_ hour: Int) {
        settings.morningNotificationHour = hour
        saveSettingsCallCount += 1
    }

    func updateBeforeFreeTimeNotificationEnabled(_ enabled: Bool) {
        settings.beforeFreeTimeNotificationEnabled = enabled
        saveSettingsCallCount += 1
    }

    func updatePreferredCategories(_ categories: [SuggestionCategory]) {
        preference.preferredCategories = categories
        savePreferenceCallCount += 1
    }

    func updateMinimumFreeTime(_ minutes: Int) {
        preference.minimumFreeTimeMinutes = minutes
        savePreferenceCallCount += 1
    }

    func updateActiveHours(_ activeHours: ActiveHoursPreference) {
        preference.activeHours = activeHours
        savePreferenceCallCount += 1
    }

    func recordSelection(for category: SuggestionCategory) {
        recordSelectionCategories.append(category)
        preference.recordSelection(for: category)
        savePreferenceCallCount += 1
    }

    func resetLearningData() {
        resetLearningDataCallCount += 1
        preference.resetLearningData()
        savePreferenceCallCount += 1
    }

    func resetAll() {
        resetAllCallCount += 1
        settings = .default
        preference = .default
    }
}

// MARK: - Test Helpers

extension FreeTimeSlot {
    static func mock(
        startHour: Int = 10,
        endHour: Int = 12,
        date: Date = Date()
    ) -> FreeTimeSlot {
        let calendar = Calendar.current
        let start = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: date)!
        let end = calendar.date(bySettingHour: endHour, minute: 0, second: 0, of: date)!
        return FreeTimeSlot(startDate: start, endDate: end)
    }
}

extension Suggestion {
    static func mock(
        category: SuggestionCategory = .cafe,
        title: String = "テストカフェ",
        slot: FreeTimeSlot? = nil,
        isAccepted: Bool = false
    ) -> Suggestion {
        let freeSlot = slot ?? .mock()
        return Suggestion(
            category: category,
            title: title,
            description: "テスト用の説明",
            duration: freeSlot.durationMinutes,
            freeTimeSlot: freeSlot,
            weatherContext: "テスト天気",
            isAccepted: isAccepted
        )
    }
}

extension WeatherData {
    static func mock(
        temperature: Double = 20.0,
        condition: WeatherCondition = .clear
    ) -> WeatherData {
        WeatherData(
            temperature: temperature,
            condition: condition,
            description: condition.displayName,
            humidity: 50,
            windSpeed: 3.0,
            fetchedAt: Date()
        )
    }
}
