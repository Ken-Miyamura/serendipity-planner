import EventKit
import Foundation

class CalendarService: CalendarServiceProtocol {
    private let eventStore = EKEventStore()

    enum CalendarError: LocalizedError {
        case accessDenied
        case fetchFailed

        var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "カレンダーへのアクセスが許可されていません。設定から許可してください。"
            case .fetchFailed:
                return "カレンダーイベントの取得に失敗しました。"
            }
        }
    }

    func requestAccess() async throws -> Bool {
        if #available(iOS 17, *) {
            return try await eventStore.requestFullAccessToEvents()
        } else {
            return try await eventStore.requestAccess(to: .event)
        }
    }

    var hasAccess: Bool {
        if #available(iOS 17, *) {
            return EKEventStore.authorizationStatus(for: .event) == .fullAccess
        } else {
            return EKEventStore.authorizationStatus(for: .event) == .authorized
        }
    }

    func addEvent(title: String, startDate: Date, endDate: Date, notes: String? = nil) throws {
        guard hasAccess else { throw CalendarError.accessDenied }
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents
        try eventStore.save(event, span: .thisEvent)
    }

    func fetchFreeTimeSlots(
        from startDate: Date,
        to endDate: Date,
        minimumMinutes: Int = Constants.Calendar.minimumFreeTimeMinutes,
        activeHours: ActiveHoursPreference = .default
    ) async throws -> [FreeTimeSlot] {
        guard hasAccess else {
            throw CalendarError.accessDenied
        }

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )

        let events = eventStore.events(matching: predicate)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }

        let holidays = fetchHolidayDates(from: startDate, to: endDate)

        return findFreeSlots(
            between: startDate,
            and: endDate,
            events: events,
            minimumMinutes: minimumMinutes,
            activeHours: activeHours,
            holidays: holidays
        )
    }

    // MARK: - Holiday Detection

    /// Fetch holiday dates from the system's subscription calendars (e.g. 日本の祝日)
    func fetchHolidayDates(from startDate: Date, to endDate: Date) -> Set<Date> {
        let holidayCalendars = eventStore.calendars(for: .event).filter { calendar in
            calendar.type == .subscription
        }

        guard !holidayCalendars.isEmpty else { return [] }

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: holidayCalendars
        )

        let holidayEvents = eventStore.events(matching: predicate)
            .filter { $0.isAllDay }

        var dates = Set<Date>()
        for event in holidayEvents {
            dates.insert(event.startDate.startOfDay)
        }
        return dates
    }

    func fetchUpcomingFreeSlots(
        days: Int = Constants.Calendar.defaultLookAheadDays,
        minimumMinutes: Int = Constants.Calendar.minimumFreeTimeMinutes,
        activeHours: ActiveHoursPreference = .default
    ) async throws -> [FreeTimeSlot] {
        let now = Date()
        let endDate = now.adding(days: days)
        return try await fetchFreeTimeSlots(
            from: now,
            to: endDate,
            minimumMinutes: minimumMinutes,
            activeHours: activeHours
        )
    }

    // MARK: - Free Time Detection Algorithm

    func findFreeSlots(
        between rangeStart: Date,
        and rangeEnd: Date,
        events: [EKEvent],
        minimumMinutes: Int,
        activeHours: ActiveHoursPreference = .default,
        holidays: Set<Date> = []
    ) -> [FreeTimeSlot] {
        var freeSlots: [FreeTimeSlot] = []

        // Process day by day
        var currentDay = rangeStart.startOfDay
        let finalDay = rangeEnd.startOfDay

        while currentDay <= finalDay {
            let config = activeHours.config(for: currentDay, holidays: holidays)

            let dayStart = max(
                currentDay.setting(hour: config.startHour),
                rangeStart
            )
            let dayEnd = min(
                currentDay.setting(hour: config.endHour),
                rangeEnd
            )

            guard dayStart < dayEnd else {
                currentDay = currentDay.adding(days: 1)
                continue
            }

            // Get events for this day
            let dayEvents = events.filter { event in
                event.startDate < dayEnd && event.endDate > dayStart
            }.sorted { $0.startDate < $1.startDate }

            // Find gaps between events
            var slotStart = dayStart

            for event in dayEvents {
                let eventStart = max(event.startDate, dayStart)
                let eventEnd = min(event.endDate, dayEnd)

                if eventStart > slotStart {
                    let gapMinutes = Int(eventStart.timeIntervalSince(slotStart) / 60)
                    if gapMinutes >= minimumMinutes {
                        freeSlots.append(FreeTimeSlot(
                            startDate: slotStart,
                            endDate: eventStart
                        ))
                    }
                }

                slotStart = max(slotStart, eventEnd)
            }

            // Check remaining time after last event
            if dayEnd > slotStart {
                let gapMinutes = Int(dayEnd.timeIntervalSince(slotStart) / 60)
                if gapMinutes >= minimumMinutes {
                    freeSlots.append(FreeTimeSlot(
                        startDate: slotStart,
                        endDate: dayEnd
                    ))
                }
            }

            currentDay = currentDay.adding(days: 1)
        }

        return freeSlots
    }
}
