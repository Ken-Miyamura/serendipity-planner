import Foundation

struct WeatherData: Codable {
    let temperature: Double
    let condition: WeatherCondition
    let description: String
    let humidity: Int
    let windSpeed: Double
    let fetchedAt: Date

    var isExpired: Bool {
        Date().timeIntervalSince(fetchedAt) > 3600 // 1 hour cache
    }

    /// 気温表示。API からは常に摂氏で受け取り、表示時にロケールの単位系へ換算する。
    var temperatureText: String {
        LocalizedUnits.temperature(celsius: temperature)
    }

    var summary: String {
        "\(condition.displayName) \(temperatureText)"
    }
}

enum WeatherCondition: String, Codable {
    case clear = "Clear"
    case clouds = "Clouds"
    case rain = "Rain"
    case drizzle = "Drizzle"
    case thunderstorm = "Thunderstorm"
    case snow = "Snow"
    case mist = "Mist"
    case unknown = "Unknown"

    var displayName: String {
        switch self {
        case .clear: String(localized: "晴れ")
        case .clouds: String(localized: "曇り")
        case .rain: String(localized: "雨")
        case .drizzle: String(localized: "小雨")
        case .thunderstorm: String(localized: "雷雨")
        case .snow: String(localized: "雪")
        case .mist: String(localized: "霧")
        case .unknown: String(localized: "不明")
        }
    }

    var iconName: String {
        switch self {
        case .clear: "sun.max.fill"
        case .clouds: "cloud.fill"
        case .rain: "cloud.rain.fill"
        case .drizzle: "cloud.drizzle.fill"
        case .thunderstorm: "cloud.bolt.rain.fill"
        case .snow: "cloud.snow.fill"
        case .mist: "cloud.fog.fill"
        case .unknown: "questionmark.circle"
        }
    }

    var isOutdoorFriendly: Bool {
        switch self {
        case .clear, .clouds: true
        case .rain, .drizzle, .thunderstorm, .snow, .mist, .unknown: false
        }
    }
}

// MARK: - OpenWeatherMap API Response

struct OpenWeatherResponse: Codable {
    let weather: [WeatherInfo]
    let main: MainInfo
    let wind: WindInfo

    struct WeatherInfo: Codable {
        let main: String
        let description: String
    }

    struct MainInfo: Codable {
        let temp: Double
        let humidity: Int
    }

    struct WindInfo: Codable {
        let speed: Double
    }

    func toWeatherData() -> WeatherData {
        let condition = WeatherCondition(rawValue: weather.first?.main ?? "") ?? .unknown
        return WeatherData(
            temperature: main.temp,
            condition: condition,
            description: weather.first?.description ?? "",
            humidity: main.humidity,
            windSpeed: wind.speed,
            fetchedAt: Date()
        )
    }
}
