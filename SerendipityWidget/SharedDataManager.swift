import Foundation

/// メインアプリとWidget間のデータ共有を管理する
enum SharedDataManager {
    static let appGroupID = "group.com.serendipity.planner"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Keys

    private enum Keys {
        static let widgetFreeTimeSlots = "widget_freeTimeSlots"
        static let widgetSuggestions = "widget_suggestions"
        static let widgetWeather = "widget_weather"
        static let widgetLastUpdated = "widget_lastUpdated"
    }

    // MARK: - Write (メインアプリ側)

    static func saveFreeTimeSlots(_ slots: [FreeTimeSlot]) {
        guard let data = try? JSONEncoder().encode(slots) else { return }
        sharedDefaults?.set(data, forKey: Keys.widgetFreeTimeSlots)
    }

    static func saveSuggestions(_ suggestions: [Suggestion]) {
        guard let data = try? JSONEncoder().encode(suggestions) else { return }
        sharedDefaults?.set(data, forKey: Keys.widgetSuggestions)
    }

    static func saveWeather(_ weather: WeatherData?) {
        guard let weather, let data = try? JSONEncoder().encode(weather) else {
            sharedDefaults?.removeObject(forKey: Keys.widgetWeather)
            return
        }
        sharedDefaults?.set(data, forKey: Keys.widgetWeather)
    }

    static func updateTimestamp() {
        sharedDefaults?.set(Date(), forKey: Keys.widgetLastUpdated)
    }

    /// メインアプリからまとめて書き込み
    static func saveAll(slots: [FreeTimeSlot], suggestions: [Suggestion], weather: WeatherData?) {
        saveFreeTimeSlots(slots)
        saveSuggestions(suggestions)
        saveWeather(weather)
        updateTimestamp()
    }

    // MARK: - Read (Widget側)

    static func loadFreeTimeSlots() -> [FreeTimeSlot] {
        guard let data = sharedDefaults?.data(forKey: Keys.widgetFreeTimeSlots),
              let slots = try? JSONDecoder().decode([FreeTimeSlot].self, from: data)
        else { return [] }
        return slots
    }

    static func loadSuggestions() -> [Suggestion] {
        guard let data = sharedDefaults?.data(forKey: Keys.widgetSuggestions),
              let suggestions = try? JSONDecoder().decode([Suggestion].self, from: data)
        else { return [] }
        return suggestions
    }

    static func loadWeather() -> WeatherData? {
        guard let data = sharedDefaults?.data(forKey: Keys.widgetWeather),
              let weather = try? JSONDecoder().decode(WeatherData.self, from: data)
        else { return nil }
        return weather
    }

    static func lastUpdated() -> Date? {
        sharedDefaults?.object(forKey: Keys.widgetLastUpdated) as? Date
    }
}
