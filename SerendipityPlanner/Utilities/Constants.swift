import Foundation

enum Constants {
    enum Calendar {
        static let defaultLookAheadDays = 3
        static let minimumFreeTimeMinutes = 60
        static let maximumFreeTimeMinutes = 480
        static let activeHoursStart = 5
        static let activeHoursEnd = 23
    }

    enum Weather {
        static let cacheExpirationSeconds: TimeInterval = 3600
        static let baseURL = "https://api.openweathermap.org/data/2.5"
        static let units = "metric"
        static let language = "ja"
    }

    enum Notification {
        static let defaultLeadTimeMinutes = 15
        static let categoryIdentifier = "SUGGESTION"
        static let morningNotificationIdentifier = "MORNING_SUMMARY"
        static let defaultMorningHour = 7
        static let morningHourRange = 6 ... 10
    }

    enum Storage {
        static let userSettingsKey = "userSettings"
        static let userPreferenceKey = "userPreference"
        static let weatherCacheKey = "weatherCache"
        static let acceptedSuggestionsKey = "acceptedSuggestions"
        static let suggestionHistoryKey = "suggestionHistory"
    }
}
