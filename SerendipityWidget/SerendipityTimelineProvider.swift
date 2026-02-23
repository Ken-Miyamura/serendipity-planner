import WidgetKit

struct SerendipityEntry: TimelineEntry {
    let date: Date
    let nextFreeTimeSlot: FreeTimeSlot?
    let suggestion: Suggestion?
    let weather: WeatherData?
    let timePeriod: TimePeriod
}

struct SerendipityTimelineProvider: TimelineProvider {
    func placeholder(in _: Context) -> SerendipityEntry {
        SerendipityEntry(
            date: Date(),
            nextFreeTimeSlot: FreeTimeSlot(
                startDate: Date().addingTimeInterval(3600),
                endDate: Date().addingTimeInterval(7200)
            ),
            suggestion: nil,
            weather: nil,
            timePeriod: TimePeriod.current()
        )
    }

    func getSnapshot(in _: Context, completion: @escaping (SerendipityEntry) -> Void) {
        let entry = createEntry(for: Date())
        completion(entry)
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<SerendipityEntry>) -> Void) {
        let now = Date()
        let entry = createEntry(for: now)

        // 15分後に更新
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    // MARK: - Private

    private func createEntry(for date: Date) -> SerendipityEntry {
        let slots = SharedDataManager.loadFreeTimeSlots()
        let suggestions = SharedDataManager.loadSuggestions()
        let weather = SharedDataManager.loadWeather()

        // 現在時刻以降の次の空き時間を探す
        let nextSlot = slots.first { $0.endDate > date }
        let matchingSuggestion = nextSlot.flatMap { slot in
            suggestions.first { $0.freeTimeSlot.id == slot.id }
        }

        return SerendipityEntry(
            date: date,
            nextFreeTimeSlot: nextSlot,
            suggestion: matchingSuggestion,
            weather: weather,
            timePeriod: TimePeriod.current()
        )
    }
}
