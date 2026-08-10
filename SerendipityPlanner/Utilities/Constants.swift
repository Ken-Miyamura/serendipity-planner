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
        /// API へのリクエストは常に摂氏で行う。表示単位の切り替えは
        /// `LocalizedUnits` が担う（キャッシュをまたいで単位が混ざらないようにするため）。
        static let units = "metric"

        /// OpenWeatherMap が対応していない言語では英語にフォールバックする。
        /// 対応コード: https://openweathermap.org/current#multi
        static let supportedLanguages: Set<String> = [
            "af", "al", "ar", "az", "bg", "ca", "cz", "da", "de", "el", "en", "eu", "fa", "fi",
            "fr", "gl", "he", "hi", "hr", "hu", "id", "it", "ja", "kr", "la", "lt", "mk", "no",
            "nl", "pl", "pt", "pt_br", "ro", "ru", "sv", "sk", "sl", "sp", "sr", "th", "tr",
            "ua", "vi", "zh_cn", "zh_tw", "zu",
        ]

        /// 端末の言語に対応する API リクエスト用の言語コード。
        static var requestLanguage: String {
            requestLanguage(for: Locale.currentLanguageCode)
        }

        /// OpenWeatherMap は韓国語を "kr"、スペイン語を "sp" という独自コードで扱う。
        /// 未対応の言語は英語にフォールバックする（日本語のまま返すと英語圏に日本語が出る）。
        static func requestLanguage(for languageCode: String) -> String {
            let mapped = ["ko": "kr", "es": "sp"][languageCode] ?? languageCode
            return supportedLanguages.contains(mapped) ? mapped : "en"
        }
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
        static let todayDestinationKey = "todayDestination"
        static let recentDestinationsKey = "recentDestinations"
    }
}
