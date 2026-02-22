import XCTest
@testable import SerendipityPlanner

@MainActor
final class SettingsViewModelTests: XCTestCase {

    private var sut: SettingsViewModel!
    private var mockPreference: MockPreferenceService!

    override func setUp() {
        super.setUp()
        mockPreference = MockPreferenceService()
        sut = SettingsViewModel()
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
        sut.toggleCategory(.cafe)  // Remove
        sut.toggleCategory(.cafe)  // Add back

        XCTAssertTrue(sut.preferredCategories.contains(.cafe))
    }

    func testToggleCategoryCannotRemoveLast() {
        // Remove all but one
        let allCategories = SuggestionCategory.allCases
        for category in allCategories.dropLast() {
            sut.toggleCategory(category)
        }

        let remaining = sut.preferredCategories.first!
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

    func testLeadTimeDisplayText() {
        XCTAssertEqual(sut.leadTimeDisplayText(15), "15分前")
        XCTAssertEqual(sut.leadTimeDisplayText(60), "1時間前")
    }

    func testFreeTimeDisplayText() {
        XCTAssertEqual(sut.freeTimeDisplayText(30), "30分")
        XCTAssertEqual(sut.freeTimeDisplayText(60), "1時間")
        XCTAssertEqual(sut.freeTimeDisplayText(90), "1時間30分")
    }
}
