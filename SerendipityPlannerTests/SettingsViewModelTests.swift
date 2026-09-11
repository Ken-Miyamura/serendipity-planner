@testable import SerendipityPlanner
import XCTest

@MainActor
final class SettingsViewModelTests: XCTestCase {
    private var sut: SettingsViewModel!
    private var mockPreference: MockPreferenceService!
    private var mockHistory: MockHistoryService!

    override func setUp() {
        super.setUp()
        mockPreference = MockPreferenceService()
        mockHistory = MockHistoryService()
        sut = SettingsViewModel(historyService: mockHistory)
        sut.configure(with: mockPreference)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Load Settings

    func testConfigureLoadsSettings() {
        mockPreference.settings.notificationsEnabled = false
        mockPreference.settings.morningNotificationHour = 8
        mockPreference.preference.minimumFreeTimeMinutes = 45

        sut.configure(with: mockPreference)

        XCTAssertFalse(sut.notificationsEnabled)
        XCTAssertEqual(sut.morningNotificationHour, 8)
        XCTAssertEqual(sut.minimumFreeTime, 45)
    }

    func testConfigureLoadsActiveHours() {
        mockPreference.preference.activeHours = ActiveHoursPreference(
            weekday: ActiveHoursConfig(startHour: 9, endHour: 18),
            weekend: ActiveHoursConfig(startHour: 11, endHour: 21)
        )

        sut.configure(with: mockPreference)

        XCTAssertEqual(sut.weekdayStartHour, 9)
        XCTAssertEqual(sut.weekdayEndHour, 18)
        XCTAssertEqual(sut.weekendStartHour, 11)
        XCTAssertEqual(sut.weekendEndHour, 21)
    }

    // MARK: - Save Settings

    func testSaveNotificationSettings() {
        sut.notificationsEnabled = false
        sut.notificationLeadTime = 30

        sut.saveNotificationSettings()

        XCTAssertFalse(mockPreference.settings.notificationsEnabled)
        XCTAssertEqual(mockPreference.settings.notificationLeadTimeMinutes, 30)
    }

    func testSaveMorningNotificationSettings() {
        sut.morningNotificationEnabled = false
        sut.morningNotificationHour = 9

        sut.saveMorningNotificationSettings()

        XCTAssertFalse(mockPreference.settings.morningNotificationEnabled)
        XCTAssertEqual(mockPreference.settings.morningNotificationHour, 9)
    }

    func testSaveMinimumFreeTime() {
        sut.minimumFreeTime = 90

        sut.saveMinimumFreeTime()

        XCTAssertEqual(mockPreference.preference.minimumFreeTimeMinutes, 90)
    }

    func testSaveActiveHours() {
        sut.weekdayStartHour = 9
        sut.weekdayEndHour = 18
        sut.weekendStartHour = 11
        sut.weekendEndHour = 21

        sut.saveActiveHours()

        XCTAssertEqual(mockPreference.preference.activeHours.weekday.startHour, 9)
        XCTAssertEqual(mockPreference.preference.activeHours.weekday.endHour, 18)
        XCTAssertEqual(mockPreference.preference.activeHours.weekend.startHour, 11)
        XCTAssertEqual(mockPreference.preference.activeHours.weekend.endHour, 21)
    }

    // MARK: - Category Toggle

    func testToggleCategoryRemove() {
        sut.toggleCategory(.cafe)

        XCTAssertFalse(sut.preferredCategories.contains(.cafe))
    }

    func testToggleCategoryAdd() {
        sut.toggleCategory(.cafe) // Remove
        sut.toggleCategory(.cafe) // Add back

        XCTAssertTrue(sut.preferredCategories.contains(.cafe))
    }

    func testToggleCategoryCannotRemoveLast() throws {
        // Remove all but one
        let allCategories = SuggestionCategory.allCases
        for category in allCategories.dropLast() {
            sut.toggleCategory(category)
        }

        let remaining = try XCTUnwrap(sut.preferredCategories.first)
        sut.toggleCategory(remaining) // Try to remove last

        XCTAssertEqual(sut.preferredCategories.count, 1)
    }

    // MARK: - Learning Data

    func testResetLearningData() {
        mockPreference.preference.selectionCounts = ["cafe": 5, "walk": 3]
        sut.configure(with: mockPreference)

        sut.resetLearningData()

        XCTAssertTrue(sut.selectionCounts.isEmpty)
        XCTAssertEqual(mockPreference.resetLearningDataCallCount, 1)
    }

    func testSelectionCount() {
        mockPreference.preference.selectionCounts = ["cafe": 5, "walk": 3]
        sut.configure(with: mockPreference)

        XCTAssertEqual(sut.selectionCount(for: .cafe), 5)
        XCTAssertEqual(sut.selectionCount(for: .walk), 3)
        XCTAssertEqual(sut.selectionCount(for: .music), 0)
    }

    func testTotalSelectionCount() {
        mockPreference.preference.selectionCounts = ["cafe": 5, "walk": 3]
        sut.configure(with: mockPreference)

        XCTAssertEqual(sut.totalSelectionCount, 8)
    }

    // MARK: - Display Text

    /// 端末のロケールに依存しないよう、数値が入ることと空でないことで検証する。
    /// 期待値を日本語で直書きすると en 環境（CI）で落ちる。
    func testLeadTimeDisplayText() {
        XCTAssertTrue(sut.leadTimeDisplayText(15).contains("15"), sut.leadTimeDisplayText(15))
        XCTAssertTrue(sut.leadTimeDisplayText(60).contains("1"), sut.leadTimeDisplayText(60))
        XCTAssertFalse(sut.leadTimeDisplayText(15).isEmpty)
    }

    func testFreeTimeDisplayText() {
        XCTAssertTrue(sut.freeTimeDisplayText(30).contains("30"), sut.freeTimeDisplayText(30))
        XCTAssertTrue(sut.freeTimeDisplayText(60).contains("1"), sut.freeTimeDisplayText(60))
        // 1時間30分 → 両方の数値が現れること（時と分の組み立てが壊れていないこと）
        let ninety = sut.freeTimeDisplayText(90)
        XCTAssertTrue(ninety.contains("1"), ninety)
        XCTAssertTrue(ninety.contains("30"), ninety)
    }

    /// 日本語では従来どおりの表記になること（ja のデグレ防止）
    func testDisplayTextInJapanese() throws {
        try XCTSkipUnless(Locale.currentLanguageCode == "ja", "ja 環境でのみ検証する")

        XCTAssertEqual(sut.leadTimeDisplayText(15), "15分前")
        XCTAssertEqual(sut.freeTimeDisplayText(90), "1時間30分")
    }

    // MARK: - History Data

    func testDeleteAllHistories() {
        // まず履歴を追加
        mockHistory.histories = [
            SuggestionHistory(
                suggestion: Suggestion.mock(category: .cafe, title: "テスト"),
                acceptedDate: Date()
            )
        ]

        sut.deleteAllHistories()

        XCTAssertEqual(mockHistory.deleteAllCallCount, 1)
        XCTAssertTrue(mockHistory.histories.isEmpty)
    }
}
