import CoreLocation
@testable import SerendipityPlanner
import XCTest

@MainActor
final class HomeViewModelTests: XCTestCase {
    private var sut: HomeViewModel!
    private var mockCalendar: MockCalendarService!
    private var mockWeather: MockWeatherService!
    private var mockEngine: MockSuggestionEngine!
    private var mockNotification: MockNotificationService!
    private var mockPlaceSearch: MockPlaceSearchService!
    private var mockHistory: MockHistoryService!
    private var mockPreference: MockPreferenceService!
    private var mockLocation: MockLocationService!

    override func setUp() {
        super.setUp()
        // Clear stale accepted suggestions from UserDefaults
        UserDefaults.standard.removeObject(forKey: Constants.Storage.acceptedSuggestionsKey)

        mockCalendar = MockCalendarService()
        mockWeather = MockWeatherService()
        mockEngine = MockSuggestionEngine()
        mockNotification = MockNotificationService()
        mockPlaceSearch = MockPlaceSearchService()
        mockHistory = MockHistoryService()
        mockPreference = MockPreferenceService()
        mockLocation = MockLocationService()

        sut = HomeViewModel(
            calendarService: mockCalendar,
            weatherService: mockWeather,
            suggestionEngine: mockEngine,
            notificationService: mockNotification,
            placeSearchService: mockPlaceSearch,
            historyService: mockHistory
        )
        sut.configure(with: mockPreference, locationService: mockLocation)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - loadData Tests

    func testLoadDataSuccess() async {
        let slot = FreeTimeSlot.mock()
        mockCalendar.freeTimeSlots = [slot]
        mockLocation.currentLocation = CLLocation(latitude: 35.68, longitude: 139.76)

        await sut.loadData()

        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.suggestions.count, 1)
        XCTAssertEqual(mockEngine.generateCallCount, 1)
    }

    func testLoadDataFetchesWeatherWithLocation() async {
        mockLocation.currentLocation = CLLocation(latitude: 35.68, longitude: 139.76)
        mockCalendar.freeTimeSlots = []

        await sut.loadData()

        XCTAssertEqual(mockWeather.fetchWeatherCallCount, 1)
        XCTAssertNotNil(sut.weather)
    }

    func testLoadDataUsesMockWeatherWhenNoLocation() async {
        mockLocation.currentLocation = nil
        mockCalendar.freeTimeSlots = []

        await sut.loadData()

        // Weather fetch should not be called, mock fallback used
        XCTAssertEqual(mockWeather.fetchWeatherCallCount, 0)
        XCTAssertNotNil(sut.weather)
    }

    func testLoadDataWeatherFetchFailureFallsBack() async {
        mockLocation.currentLocation = CLLocation(latitude: 35.68, longitude: 139.76)
        mockWeather.weatherError = NSError(domain: "test", code: 1)
        mockCalendar.freeTimeSlots = []

        await sut.loadData()

        // Should still have weather (fallback mock)
        XCTAssertNotNil(sut.weather)
        XCTAssertNil(sut.errorMessage)
    }

    func testLoadDataCalendarAccessDenied() async {
        mockCalendar.hasAccess = false
        mockCalendar.requestAccessResult = false

        await sut.loadData()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.suggestions.isEmpty)
    }

    func testLoadDataCalendarFetchError() async {
        mockCalendar.fetchFreeSlotsError = NSError(domain: "test", code: 2, userInfo: [NSLocalizedDescriptionKey: "テストエラー"])

        await sut.loadData()

        XCTAssertEqual(sut.errorMessage, "テストエラー")
    }

    func testLoadDataEnrichesWithPlaces() async {
        let slot = FreeTimeSlot.mock()
        mockCalendar.freeTimeSlots = [slot]
        mockLocation.currentLocation = CLLocation(latitude: 35.68, longitude: 139.76)
        mockPlaceSearch.findResult = NearbyPlace(
            name: "テストカフェ", category: .cafe,
            latitude: 35.68, longitude: 139.76, distance: 200
        )

        await sut.loadData()

        XCTAssertEqual(mockPlaceSearch.findCallCount, 1)
    }

    // MARK: - acceptSuggestion Tests

    func testAcceptSuggestion() async throws {
        let slot = FreeTimeSlot.mock()
        mockCalendar.freeTimeSlots = [slot]

        await sut.loadData()

        let suggestion = try XCTUnwrap(sut.suggestions.first)
        sut.acceptSuggestion(suggestion)

        XCTAssertTrue(sut.suggestions.isEmpty)
        XCTAssertEqual(sut.acceptedSuggestions.count, 1)
        XCTAssertTrue(try XCTUnwrap(sut.acceptedSuggestions.first?.isAccepted))

        // 履歴にも保存されたことを確認
        XCTAssertEqual(mockHistory.saveCallCount, 1)
        XCTAssertEqual(mockHistory.histories.first?.suggestion.title, suggestion.title)
    }

    // MARK: - regenerateSuggestion Tests

    func testRegenerateSuggestion() async throws {
        let slot = FreeTimeSlot.mock()
        mockCalendar.freeTimeSlots = [slot]
        let altSuggestion = Suggestion.mock(category: .walk, title: "散歩提案", slot: slot)
        mockEngine.alternativesResult = [altSuggestion]

        await sut.loadData()

        let originalCategory = try XCTUnwrap(sut.suggestions.first?.category)
        sut.regenerateSuggestion(for: slot, excluding: originalCategory)

        XCTAssertEqual(mockEngine.alternativesCallCount, 1)
        XCTAssertEqual(sut.suggestions.first?.title, "散歩提案")
    }

    // MARK: - Notification Tests

    func testNotificationsScheduledOnLoad() async {
        let slot = FreeTimeSlot.mock()
        mockCalendar.freeTimeSlots = [slot]
        mockPreference.settings.notificationsEnabled = true
        mockPreference.settings.morningNotificationEnabled = true
        mockPreference.settings.beforeFreeTimeNotificationEnabled = true

        await sut.loadData()

        XCTAssertEqual(mockNotification.scheduleMorningCallCount, 1)
        XCTAssertEqual(mockNotification.scheduleSuggestionCallCount, 1)
    }

    func testNotificationsCancelledWhenDisabled() async {
        mockCalendar.freeTimeSlots = []
        mockPreference.settings.notificationsEnabled = false

        await sut.loadData()

        XCTAssertEqual(mockNotification.cancelAllCallCount, 1)
    }

    // MARK: - Warning Message Tests (Error Handling)

    func testWarningMessageSetWhenNoLocation() async throws {
        mockLocation.currentLocation = nil
        mockCalendar.freeTimeSlots = []

        await sut.loadData()

        XCTAssertNotNil(sut.warningMessage)
        XCTAssertTrue(try XCTUnwrap(sut.warningMessage?.contains("位置情報")))
    }

    func testWarningMessageSetWhenWeatherFails() async throws {
        mockLocation.currentLocation = CLLocation(latitude: 35.68, longitude: 139.76)
        mockWeather.weatherError = NSError(domain: "test", code: 1)
        mockCalendar.freeTimeSlots = []

        await sut.loadData()

        XCTAssertNotNil(sut.warningMessage)
        XCTAssertTrue(try XCTUnwrap(sut.warningMessage?.contains("天気")))
    }

    func testWarningMessageClearedOnNewLoad() async {
        mockLocation.currentLocation = nil
        mockCalendar.freeTimeSlots = []
        await sut.loadData()
        XCTAssertNotNil(sut.warningMessage)

        // Now load with location
        mockLocation.currentLocation = CLLocation(latitude: 35.68, longitude: 139.76)
        await sut.loadData()
        XCTAssertNil(sut.warningMessage)
    }
}
