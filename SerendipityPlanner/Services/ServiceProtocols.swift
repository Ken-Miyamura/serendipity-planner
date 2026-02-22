import CoreLocation
import Foundation

// MARK: - CalendarServiceProtocol

protocol CalendarServiceProtocol {
    var hasAccess: Bool { get }
    func requestAccess() async throws -> Bool
    func addEvent(title: String, startDate: Date, endDate: Date, notes: String?) throws
    func fetchFreeTimeSlots(
        from startDate: Date,
        to endDate: Date,
        minimumMinutes: Int,
        activeHours: ActiveHoursPreference
    ) async throws -> [FreeTimeSlot]
    func fetchUpcomingFreeSlots(
        days: Int,
        minimumMinutes: Int,
        activeHours: ActiveHoursPreference
    ) async throws -> [FreeTimeSlot]
}

// MARK: - WeatherServiceProtocol

protocol WeatherServiceProtocol {
    func fetchWeather(for city: String) async throws -> WeatherData
    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherData
}

// MARK: - LocationServiceProtocol

protocol LocationServiceProtocol: AnyObject {
    var currentLocationName: String { get }
    var currentLocation: CLLocation? { get }
    var locationAuthorized: Bool { get }
    func requestPermission()
    func requestCurrentLocation() async -> CLLocation?
}

// MARK: - NotificationServiceProtocol

protocol NotificationServiceProtocol {
    func requestPermission() async throws -> Bool
    func isAuthorized() async -> Bool
    func scheduleSuggestionNotification(for suggestion: Suggestion, leadTimeMinutes: Int)
    func scheduleMorningNotification(hour: Int, freeSlotCount: Int)
    func cancelMorningNotification()
    func cancelNotification(for suggestionId: UUID)
    func cancelAllNotifications()
}

// MARK: - PlaceSearchServiceProtocol

protocol PlaceSearchServiceProtocol {
    func searchNearbyPlaces(for category: SuggestionCategory, near location: CLLocation) async -> [NearbyPlace]
    func findNearbyPlace(for category: SuggestionCategory, near location: CLLocation) async -> NearbyPlace?
}

// MARK: - SuggestionEngineProtocol

protocol SuggestionEngineProtocol {
    func generateSuggestion(for slot: FreeTimeSlot, weather: WeatherData?, preference: UserPreference) -> Suggestion
    func generateAlternatives(
        for slot: FreeTimeSlot,
        weather: WeatherData?,
        preference: UserPreference,
        excluding: SuggestionCategory?
    ) -> [Suggestion]
}

// MARK: - FavoriteServiceProtocol

protocol FavoriteServiceProtocol: AnyObject {
    /// すべてのお気に入りを取得する
    func getFavorites() -> [FavoriteSuggestion]
    /// お気に入りを追加する
    func addFavorite(_ suggestion: Suggestion) -> FavoriteSuggestion
    /// お気に入りを削除する
    func removeFavorite(id: UUID)
    /// 指定した提案がお気に入りに登録されているかを判定する（タイトルとカテゴリで照合）
    func isFavorite(title: String, category: SuggestionCategory) -> Bool
    /// カテゴリでフィルタリングしたお気に入りを取得する
    func getFavorites(for category: SuggestionCategory) -> [FavoriteSuggestion]
    /// お気に入りに登録されているカテゴリ一覧を取得する
    func favoritedCategories() -> Set<SuggestionCategory>
    /// すべてのお気に入りを削除する
    func removeAll()
}

// MARK: - PreferenceServiceProtocol

protocol PreferenceServiceProtocol: AnyObject {
    var settings: UserSettings { get set }
    var preference: UserPreference { get set }
    func saveSettings()
    func savePreference()
    func completeOnboarding()
    func updateNotificationEnabled(_ enabled: Bool)
    func updateNotificationLeadTime(_ minutes: Int)
    func updateMorningNotificationEnabled(_ enabled: Bool)
    func updateMorningNotificationHour(_ hour: Int)
    func updateBeforeFreeTimeNotificationEnabled(_ enabled: Bool)
    func updatePreferredCategories(_ categories: [SuggestionCategory])
    func updateMinimumFreeTime(_ minutes: Int)
    func updateActiveHours(_ activeHours: ActiveHoursPreference)
    func recordSelection(for category: SuggestionCategory)
    func resetLearningData()
    func resetAll()
}
