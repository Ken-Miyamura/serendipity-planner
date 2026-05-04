@testable import SerendipityPlanner
import XCTest

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    private var sut: OnboardingViewModel!
    private var mockCalendar: MockCalendarService!
    private var mockNotification: MockNotificationService!

    override func setUp() {
        super.setUp()
        mockCalendar = MockCalendarService()
        mockNotification = MockNotificationService()
        sut = OnboardingViewModel(
            calendarService: mockCalendar,
            notificationService: mockNotification
        )
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Page Navigation

    func testInitialPage() {
        XCTAssertEqual(sut.currentPage, 0)
        XCTAssertFalse(sut.isLastPage)
    }

    func testNextPage() {
        sut.nextPage()
        XCTAssertEqual(sut.currentPage, 1)
    }

    func testNextPageDoesNotExceedMax() {
        for _ in 0 ..< 10 {
            sut.nextPage()
        }
        XCTAssertEqual(sut.currentPage, sut.totalPages - 1)
    }

    func testPreviousPage() {
        sut.nextPage()
        sut.nextPage()
        sut.previousPage()
        XCTAssertEqual(sut.currentPage, 1)
    }

    func testPreviousPageDoesNotGoBelowZero() {
        sut.previousPage()
        XCTAssertEqual(sut.currentPage, 0)
    }

    func testIsLastPage() {
        for _ in 0 ..< (sut.totalPages - 1) {
            sut.nextPage()
        }
        XCTAssertTrue(sut.isLastPage)
    }

    // MARK: - Interest Selection

    func testDefaultInterests() {
        XCTAssertEqual(sut.selectedInterests.count, SuggestionCategory.allCases.count)
        for category in SuggestionCategory.allCases {
            XCTAssertTrue(sut.selectedInterests.contains(category))
        }
    }

    func testToggleInterestAdd() {
        sut.toggleInterest(.music) // 全選択済みなので一度外す
        XCTAssertFalse(sut.selectedInterests.contains(.music))
        sut.toggleInterest(.music) // 再度追加
        XCTAssertTrue(sut.selectedInterests.contains(.music))
    }

    func testToggleInterestRemove() {
        sut.toggleInterest(.cafe)
        XCTAssertFalse(sut.selectedInterests.contains(.cafe))
    }

    func testCanProceedOnInterestPage() {
        sut.nextPage() // Go to interest selection (page 1)
        XCTAssertTrue(sut.canProceed) // 全カテゴリ選択済み

        // 8個外して2個だけ残す（最低3個未満にする）
        for category in Array(SuggestionCategory.allCases.prefix(8)) {
            sut.toggleInterest(category)
        }
        XCTAssertFalse(sut.canProceed) // 2個のみ選択
    }

    func testCanProceedOnOtherPages() {
        XCTAssertTrue(sut.canProceed) // page 0
        sut.nextPage()
        sut.nextPage() // page 2
        XCTAssertTrue(sut.canProceed)
    }

    // MARK: - Save Interests

    func testSaveInterests() {
        let mockPref = MockPreferenceService()
        sut.toggleInterest(.fitness)

        sut.saveInterests(to: mockPref)

        XCTAssertEqual(mockPref.preference.preferredCategories.count, sut.selectedInterests.count)
    }

    // MARK: - Permission Requests

    func testRequestCalendarPermissionSuccess() async {
        mockCalendar.requestAccessResult = true

        await sut.requestCalendarPermission()

        XCTAssertTrue(sut.calendarPermissionGranted)
        XCTAssertEqual(mockCalendar.requestAccessCallCount, 1)
    }

    func testRequestCalendarPermissionFailure() async {
        mockCalendar.requestAccessResult = false

        await sut.requestCalendarPermission()

        XCTAssertFalse(sut.calendarPermissionGranted)
    }

    func testRequestCalendarPermissionError() async {
        mockCalendar.requestAccessError = NSError(domain: "test", code: 1)

        await sut.requestCalendarPermission()

        XCTAssertFalse(sut.calendarPermissionGranted)
    }

    func testRequestNotificationPermissionSuccess() async {
        mockNotification.requestPermissionResult = true

        await sut.requestNotificationPermission()

        XCTAssertTrue(sut.notificationPermissionGranted)
        XCTAssertEqual(mockNotification.requestPermissionCallCount, 1)
    }

    func testRequestNotificationPermissionFailure() async {
        mockNotification.requestPermissionResult = false

        await sut.requestNotificationPermission()

        XCTAssertFalse(sut.notificationPermissionGranted)
    }

    func testRequestNotificationPermissionError() async {
        mockNotification.requestPermissionError = NSError(domain: "test", code: 1)

        await sut.requestNotificationPermission()

        XCTAssertFalse(sut.notificationPermissionGranted)
    }

    // MARK: - Permission Error Tests (Error Handling)

    func testCalendarPermissionDeniedSetsError() async throws {
        mockCalendar.requestAccessResult = false

        await sut.requestCalendarPermission()

        XCTAssertNotNil(sut.permissionError)
        XCTAssertTrue(try XCTUnwrap(sut.permissionError?.contains("カレンダー")))
    }

    func testCalendarPermissionErrorSetsError() async {
        mockCalendar.requestAccessError = NSError(domain: "test", code: 1)

        await sut.requestCalendarPermission()

        XCTAssertNotNil(sut.permissionError)
    }

    func testNotificationPermissionDeniedSetsError() async throws {
        mockNotification.requestPermissionResult = false

        await sut.requestNotificationPermission()

        XCTAssertNotNil(sut.permissionError)
        XCTAssertTrue(try XCTUnwrap(sut.permissionError?.contains("通知")))
    }

    func testPermissionErrorClearedOnRetry() async {
        mockCalendar.requestAccessResult = false
        await sut.requestCalendarPermission()
        XCTAssertNotNil(sut.permissionError)

        mockCalendar.requestAccessResult = true
        await sut.requestCalendarPermission()
        XCTAssertNil(sut.permissionError)
    }
}
