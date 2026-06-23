import Foundation

enum Constants {
    enum Calendar {
        static let defaultLookAheadDays = 3
        static let minimumFreeTimeMinutes = 60
        static let maximumFreeTimeMinutes = 480
        static let activeHoursStart = 5
        static let activeHoursEnd = 23
    }

    enum Suggestion {
        /// この分数を超える空き時間は複数の提案に分割する
        static let splitThresholdMinutes = 120
        /// 分割時の1提案あたりの目安分数（この単位で分割数を決める）
        static let splitBlockMinutes = 120
        /// 1つの空き時間から生成する提案の最大数
        static let maxSplitCount = 3
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
        static let favoriteSuggestionsKey = "favoriteSuggestions"
        static let suggestionHistoryKey = "suggestionHistory"
    }
}
