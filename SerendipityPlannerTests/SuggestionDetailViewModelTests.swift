import XCTest
@testable import SerendipityPlanner

@MainActor
final class SuggestionDetailViewModelTests: XCTestCase {

    private var sut: SuggestionDetailViewModel!
    private var mockEngine: MockSuggestionEngine!
    private var mockPlaceSearch: MockPlaceSearchService!
    private var mockPreference: MockPreferenceService!
    private var mockLocation: MockLocationService!
    private var mockCalendar: MockCalendarService!

    override func setUp() {
        super.setUp()
        mockEngine = MockSuggestionEngine()
        mockPlaceSearch = MockPlaceSearchService()
        mockPreference = MockPreferenceService()
        mockLocation = MockLocationService()
        mockCalendar = MockCalendarService()

        let suggestion = Suggestion.mock()
        sut = SuggestionDetailViewModel(
            suggestion: suggestion,
            suggestionEngine: mockEngine,
            placeSearchService: mockPlaceSearch
        )
        sut.configure(
            weather: .mock(),
            preference: .default,
            preferenceService: mockPreference,
            locationService: mockLocation,
            calendarService: mockCalendar
        )
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Accept Tests

    func testAcceptRecordsSelection() {
        sut.accept()

        XCTAssertTrue(sut.isAccepted)
        XCTAssertTrue(sut.suggestion.isAccepted)
        XCTAssertEqual(mockPreference.recordSelectionCategories.count, 1)
        XCTAssertEqual(mockPreference.recordSelectionCategories.first, .cafe)
    }

    func testAcceptAddsToCalendar() {
        sut.accept()

        XCTAssertEqual(mockCalendar.addEventCallCount, 1)
        XCTAssertEqual(mockCalendar.addEventTitles.first, "テストカフェ")
        XCTAssertEqual(sut.calendarAlertMessage, "カレンダーに追加しました")
    }

    func testAcceptCalendarFailure() {
        mockCalendar.addEventError = NSError(domain: "test", code: 1)

        sut.accept()

        XCTAssertEqual(sut.calendarAlertMessage, "カレンダーへの追加に失敗しました")
    }

    func testAcceptWithoutCalendarService() {
        let suggestion = Suggestion.mock()
        let vm = SuggestionDetailViewModel(
            suggestion: suggestion,
            suggestionEngine: mockEngine,
            placeSearchService: mockPlaceSearch
        )
        vm.configure(
            weather: .mock(),
            preference: .default,
            preferenceService: mockPreference
        )

        vm.accept()

        XCTAssertTrue(vm.isAccepted)
        XCTAssertEqual(vm.calendarAlertMessage, "提案を受け入れました")
    }

    // MARK: - Regenerate Tests

    func testRegenerate() {
        let newSuggestion = Suggestion.mock(category: .walk, title: "新しい散歩")
        mockEngine.generateResult = newSuggestion

        sut.regenerate()

        XCTAssertEqual(mockEngine.generateCallCount, 1)
        XCTAssertEqual(sut.suggestion.title, "新しい散歩")
        XCTAssertFalse(sut.isAccepted)
    }

    func testRegenerateLoadsAlternatives() {
        let alt = Suggestion.mock(category: .reading, title: "読書の時間")
        mockEngine.alternativesResult = [alt]

        let countBefore = mockEngine.alternativesCallCount
        sut.regenerate()

        XCTAssertEqual(mockEngine.alternativesCallCount, countBefore + 1)
        XCTAssertEqual(sut.alternatives.count, 1)
    }
}
