import Foundation

class WeatherService {
    private let session: URLSession
    private let apiKey: String
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    enum WeatherError: LocalizedError {
        case invalidAPIKey
        case networkError(Error)
        case decodingError
        case invalidURL
        case cityNotFound(String)

        var errorDescription: String? {
            switch self {
            case .invalidAPIKey:
                return "天気APIキーが設定されていません。"
            case .networkError(let error):
                return "ネットワークエラー: \(error.localizedDescription)"
            case .decodingError:
                return "天気データの解析に失敗しました。"
            case .invalidURL:
                return "無効なURLです。"
            case .cityNotFound(let city):
                return "「\(city)」の天気情報が見つかりません。都市名を確認してください。"
            }
        }
    }

    init(session: URLSession = .shared) {
        self.session = session
        self.apiKey = Bundle.main.object(forInfoDictionaryKey: "OpenWeatherMapAPIKey") as? String ?? ""
    }

    func fetchWeather(for city: String) async throws -> WeatherData {
        // Check cache first
        if let cached = loadCachedWeather(for: city), !cached.isExpired {
            return cached
        }

        guard !apiKey.isEmpty, apiKey != "YOUR_API_KEY_HERE" else {
            throw WeatherError.invalidAPIKey
        }

        var components = URLComponents(string: "\(Constants.Weather.baseURL)/weather")
        components?.queryItems = [
            URLQueryItem(name: "q", value: "\(city),JP"),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: Constants.Weather.units),
            URLQueryItem(name: "lang", value: Constants.Weather.language),
        ]

        guard let url = components?.url else {
            throw WeatherError.invalidURL
        }

        do {
            let (data, response) = try await session.data(from: url)

            // Check HTTP status code for city not found
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
                throw WeatherError.cityNotFound(city)
            }

            let weatherResponse = try decoder.decode(OpenWeatherResponse.self, from: data)
            let weatherData = weatherResponse.toWeatherData()

            // Cache the result
            cacheWeather(weatherData, for: city)

            return weatherData
        } catch let error as WeatherError {
            throw error
        } catch is DecodingError {
            throw WeatherError.decodingError
        } catch {
            throw WeatherError.networkError(error)
        }
    }

    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherData {
        let cacheKey = "coord_\(String(format: "%.2f", latitude))_\(String(format: "%.2f", longitude))"

        if let cached = loadCachedWeather(for: cacheKey), !cached.isExpired {
            return cached
        }

        guard !apiKey.isEmpty, apiKey != "YOUR_API_KEY_HERE" else {
            throw WeatherError.invalidAPIKey
        }

        var components = URLComponents(string: "\(Constants.Weather.baseURL)/weather")
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: Constants.Weather.units),
            URLQueryItem(name: "lang", value: Constants.Weather.language),
        ]

        guard let url = components?.url else {
            throw WeatherError.invalidURL
        }

        do {
            let (data, response) = try await session.data(from: url)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
                throw WeatherError.cityNotFound("(\(latitude), \(longitude))")
            }

            let weatherResponse = try decoder.decode(OpenWeatherResponse.self, from: data)
            let weatherData = weatherResponse.toWeatherData()

            cacheWeather(weatherData, for: cacheKey)

            return weatherData
        } catch let error as WeatherError {
            throw error
        } catch is DecodingError {
            throw WeatherError.decodingError
        } catch {
            throw WeatherError.networkError(error)
        }
    }

    // MARK: - Caching

    private func cacheKey(for city: String) -> String {
        "\(Constants.Storage.weatherCacheKey)_\(city)"
    }

    private func cacheWeather(_ weather: WeatherData, for city: String) {
        if let data = try? encoder.encode(weather) {
            defaults.set(data, forKey: cacheKey(for: city))
        }
    }

    private func loadCachedWeather(for city: String) -> WeatherData? {
        guard let data = defaults.data(forKey: cacheKey(for: city)),
              let weather = try? decoder.decode(WeatherData.self, from: data) else {
            return nil
        }
        return weather
    }

    /// Returns mock weather data for preview/testing when API key is not configured
    static func mockWeather() -> WeatherData {
        WeatherData(
            temperature: 18.5,
            condition: .clear,
            description: "晴れ",
            humidity: 45,
            windSpeed: 3.2,
            fetchedAt: Date()
        )
    }
}
