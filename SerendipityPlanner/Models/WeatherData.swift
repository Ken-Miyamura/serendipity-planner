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

    var temperatureText: String {
        String(format: "%.0f°C", temperature)
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
        case .clear: return "晴れ"
        case .clouds: return "曇り"
        case .rain: return "雨"
        case .drizzle: return "小雨"
        case .thunderstorm: return "雷雨"
        case .snow: return "雪"
        case .mist: return "霧"
        case .unknown: return "不明"
        }
    }

    var iconName: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .clouds: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .drizzle: return "cloud.drizzle.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .mist: return "cloud.fog.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    var isOutdoorFriendly: Bool {
        switch self {
        case .clear, .clouds: return true
        case .rain, .drizzle, .thunderstorm, .snow, .mist, .unknown: return false
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
