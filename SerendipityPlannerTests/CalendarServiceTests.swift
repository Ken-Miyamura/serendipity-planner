import EventKit
@testable import SerendipityPlanner
import XCTest

final class CalendarServiceTests: XCTestCase {
    var service: CalendarService!

    /// Active hours config matching the old hardcoded 5:00-23:00 range
    let fullDayHours = ActiveHoursPreference(
        weekday: ActiveHoursConfig(startHour: 5, endHour: 23),
        weekend: ActiveHoursConfig(startHour: 5, endHour: 23)
    )

    override func setUp() {
        super.setUp()
        service = CalendarService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - Free Slot Detection Tests

    func testFindFreeSlots_noEvents_returnsFullDay() {
        let today = Date().startOfDay
        let dayStart = today.setting(hour: 5)
        let dayEnd = today.setting(hour: 23)

        let slots = service.findFreeSlots(
            between: dayStart,
            and: dayEnd,
            events: [],
            minimumMinutes: 60,
            activeHours: fullDayHours
        )

        XCTAssertEqual(slots.count, 1, "Should find one large free slot")
        XCTAssertEqual(slots.first?.durationMinutes, 1080, "Free slot should be 18 hours (1080 min)")
    }

    func testFindFreeSlots_oneEventInMiddle_findsTwoSlots() {
        let today = Date().startOfDay
        let dayStart = today.setting(hour: 5)
        let dayEnd = today.setting(hour: 23)

        let store = EKEventStore()
        let event = EKEvent(eventStore: store)
        event.startDate = today.setting(hour: 12)
        event.endDate = today.setting(hour: 13)

        let slots = service.findFreeSlots(
            between: dayStart,
            and: dayEnd,
            events: [event],
            minimumMinutes: 60,
            activeHours: fullDayHours
        )

        XCTAssertEqual(slots.count, 2, "Should find two free slots around the event")

        // Before event: 5:00-12:00 = 420 min
        XCTAssertEqual(slots[0].durationMinutes, 420)

        // After event: 13:00-23:00 = 600 min
        XCTAssertEqual(slots[1].durationMinutes, 600)
    }

    func testFindFreeSlots_consecutiveEvents_noGap() {
        let today = Date().startOfDay
        let dayStart = today.setting(hour: 8)
        let dayEnd = today.setting(hour: 12)

        let store = EKEventStore()

        let event1 = EKEvent(eventStore: store)
        event1.startDate = today.setting(hour: 8)
        event1.endDate = today.setting(hour: 10)

        let event2 = EKEvent(eventStore: store)
        event2.startDate = today.setting(hour: 10)
        event2.endDate = today.setting(hour: 12)

        let slots = service.findFreeSlots(
            between: dayStart,
            and: dayEnd,
            events: [event1, event2],
            minimumMinutes: 60,
            activeHours: fullDayHours
        )

        XCTAssertEqual(slots.count, 0, "Should find no free slots when events fill the entire range")
    }

    func testFindFreeSlots_shortGap_filteredByMinimum() {
        let today = Date().startOfDay
        let dayStart = today.setting(hour: 8)
        let dayEnd = today.setting(hour: 12)

        let store = EKEventStore()

        let event1 = EKEvent(eventStore: store)
        event1.startDate = today.setting(hour: 8)
        event1.endDate = today.setting(hour: 9, minute: 30)

        let event2 = EKEvent(eventStore: store)
        event2.startDate = today.setting(hour: 10)
        event2.endDate = today.setting(hour: 12)

        let slots = service.findFreeSlots(
            between: dayStart,
            and: dayEnd,
            events: [event1, event2],
            minimumMinutes: 60,
            activeHours: fullDayHours
        )

        // Gap is 9:30-10:00 = 30 min, which is less than minimum 60 min
        XCTAssertEqual(slots.count, 0, "Should filter out gaps shorter than 60 minutes")
    }

    func testFindFreeSlots_respectsMinimumDuration() {
        let today = Date().startOfDay
        let dayStart = today.setting(hour: 8)
        let dayEnd = today.setting(hour: 14)

        let store = EKEventStore()

        let event1 = EKEvent(eventStore: store)
        event1.startDate = today.setting(hour: 8)
        event1.endDate = today.setting(hour: 9)

        let event2 = EKEvent(eventStore: store)
        event2.startDate = today.setting(hour: 10)
        event2.endDate = today.setting(hour: 14)

        // Gap: 9:00-10:00 = 60 min
        let slots60 = service.findFreeSlots(
            between: dayStart,
            and: dayEnd,
            events: [event1, event2],
            minimumMinutes: 60,
            activeHours: fullDayHours
        )

        let slots90 = service.findFreeSlots(
            between: dayStart,
            and: dayEnd,
            events: [event1, event2],
            minimumMinutes: 90,
            activeHours: fullDayHours
        )

        XCTAssertEqual(slots60.count, 1, "Should find 60-minute gap with 60-min minimum")
        XCTAssertEqual(slots90.count, 0, "Should not find 60-minute gap with 90-min minimum")
    }

    func testFindFreeSlots_multipleEvents_findsAllGaps() {
        let today = Date().startOfDay
        let dayStart = today.setting(hour: 5)
        let dayEnd = today.setting(hour: 23)

        let store = EKEventStore()

        let event1 = EKEvent(eventStore: store)
        event1.startDate = today.setting(hour: 9)
        event1.endDate = today.setting(hour: 10)

        let event2 = EKEvent(eventStore: store)
        event2.startDate = today.setting(hour: 12)
        event2.endDate = today.setting(hour: 13)

        let event3 = EKEvent(eventStore: store)
        event3.startDate = today.setting(hour: 15)
        event3.endDate = today.setting(hour: 16)

        let slots = service.findFreeSlots(
            between: dayStart,
            and: dayEnd,
            events: [event1, event2, event3],
            minimumMinutes: 60,
            activeHours: fullDayHours
        )

        // 5:00-9:00(240min), 10:00-12:00(120min), 13:00-15:00(120min), 16:00-23:00(420min)
        XCTAssertEqual(slots.count, 4, "Should find 4 free slots between events")
        XCTAssertEqual(slots[0].durationMinutes, 240)
        XCTAssertEqual(slots[1].durationMinutes, 120)
        XCTAssertEqual(slots[2].durationMinutes, 120)
        XCTAssertEqual(slots[3].durationMinutes, 420)
    }

    // MARK: - Weekday / Weekend Active Hours Tests

    func testFindFreeSlots_weekdayUsesWeekdayConfig() {
        // Find a known weekday (Monday)
        let calendar = Calendar.current
        let today = Date().startOfDay
        var weekday = today
        while calendar.isDateInWeekend(weekday) {
            weekday = weekday.adding(days: 1)
        }

        let activeHours = ActiveHoursPreference(
            weekday: ActiveHoursConfig(startHour: 9, endHour: 18),
            weekend: ActiveHoursConfig(startHour: 10, endHour: 22)
        )

        let slots = service.findFreeSlots(
            between: weekday.setting(hour: 0),
            and: weekday.setting(hour: 23),
            events: [],
            minimumMinutes: 30,
            activeHours: activeHours
        )

        XCTAssertEqual(slots.count, 1, "Should find one free slot for the weekday")
        // Weekday: 9:00-18:00 = 540 min
        XCTAssertEqual(slots[0].durationMinutes, 540, "Weekday slot should be 9 hours (540 min)")
        XCTAssertEqual(slots[0].startDate, weekday.setting(hour: 9))
        XCTAssertEqual(slots[0].endDate, weekday.setting(hour: 18))
    }

    func testFindFreeSlots_weekendUsesWeekendConfig() {
        // Find a known weekend day (Saturday)
        let calendar = Calendar.current
        let today = Date().startOfDay
        var weekend = today
        while !calendar.isDateInWeekend(weekend) {
            weekend = weekend.adding(days: 1)
        }

        let activeHours = ActiveHoursPreference(
            weekday: ActiveHoursConfig(startHour: 9, endHour: 18),
            weekend: ActiveHoursConfig(startHour: 10, endHour: 22)
        )

        let slots = service.findFreeSlots(
            between: weekend.setting(hour: 0),
            and: weekend.setting(hour: 23),
            events: [],
            minimumMinutes: 30,
            activeHours: activeHours
        )

        XCTAssertEqual(slots.count, 1, "Should find one free slot for the weekend")
        // Weekend: 10:00-22:00 = 720 min
        XCTAssertEqual(slots[0].durationMinutes, 720, "Weekend slot should be 12 hours (720 min)")
        XCTAssertEqual(slots[0].startDate, weekend.setting(hour: 10))
        XCTAssertEqual(slots[0].endDate, weekend.setting(hour: 22))
    }

    func testFindFreeSlots_mixedWeekdayWeekend_appliesDifferentConfig() {
        // Find a Friday
        let calendar = Calendar.current
        let today = Date().startOfDay
        var friday = today
        while calendar.component(.weekday, from: friday) != 6 { // 6 = Friday
            friday = friday.adding(days: 1)
        }
        let saturday = friday.adding(days: 1)

        let activeHours = ActiveHoursPreference(
            weekday: ActiveHoursConfig(startHour: 8, endHour: 20),
            weekend: ActiveHoursConfig(startHour: 10, endHour: 22)
        )

        let slots = service.findFreeSlots(
            between: friday.setting(hour: 0),
            and: saturday.setting(hour: 23),
            events: [],
            minimumMinutes: 30,
            activeHours: activeHours
        )

        XCTAssertEqual(slots.count, 2, "Should find two free slots (one per day)")

        // Friday (weekday): 8:00-20:00 = 720 min
        XCTAssertEqual(slots[0].durationMinutes, 720, "Friday slot should be 12 hours (720 min)")
        XCTAssertEqual(slots[0].startDate, friday.setting(hour: 8))
        XCTAssertEqual(slots[0].endDate, friday.setting(hour: 20))

        // Saturday (weekend): 10:00-22:00 = 720 min
        XCTAssertEqual(slots[1].durationMinutes, 720, "Saturday slot should be 12 hours (720 min)")
        XCTAssertEqual(slots[1].startDate, saturday.setting(hour: 10))
        XCTAssertEqual(slots[1].endDate, saturday.setting(hour: 22))
    }
}
