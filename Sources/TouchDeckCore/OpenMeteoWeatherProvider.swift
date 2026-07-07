import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct WeatherSnapshotRequest: Codable, Equatable, Sendable {
    public var location: String

    public init(location: String) {
        self.location = location
    }
}

public struct OpenMeteoWeatherProvider: Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func snapshot(for request: WeatherSnapshotRequest) async -> WidgetSnapshot? {
        let location = request.location.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            !location.isEmpty,
            let geocodingURL = Self.geocodingURL(location: location)
        else {
            return nil
        }

        do {
            let (geocodingData, _) = try await session.data(from: geocodingURL)
            let geocodingResponse = try JSONDecoder().decode(OpenMeteoGeocodingResponse.self, from: geocodingData)

            guard
                let result = geocodingResponse.results?.first,
                let forecastURL = Self.forecastURL(latitude: result.latitude, longitude: result.longitude)
            else {
                return nil
            }

            let (forecastData, _) = try await session.data(from: forecastURL)
            let forecastResponse = try JSONDecoder().decode(OpenMeteoForecastResponse.self, from: forecastData)

            return WidgetSnapshot(
                title: "\(Int(forecastResponse.current.temperature2m.rounded()))°",
                subtitle: result.name,
                symbolName: Self.symbolName(for: forecastResponse.current.weatherCode, isDay: forecastResponse.current.isDay == 1),
                progress: nil,
                colorHex: "#64D2FF"
            )
        } catch {
            return nil
        }
    }

    public static func geocodingURL(location: String) -> URL? {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")
        components?.queryItems = [
            URLQueryItem(name: "name", value: location),
            URLQueryItem(name: "count", value: "1"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]
        return components?.url
    }

    public static func forecastURL(latitude: Double, longitude: Double) -> URL? {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code,is_day"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        return components?.url
    }

    public static func symbolName(for weatherCode: Int, isDay: Bool) -> String {
        switch weatherCode {
        case 0:
            return isDay ? "sun.max" : "moon.stars"
        case 1, 2:
            return isDay ? "cloud.sun" : "cloud.moon"
        case 3:
            return "cloud"
        case 45, 48:
            return "cloud.fog"
        case 51...67, 80...82:
            return "cloud.rain"
        case 71...77, 85...86:
            return "cloud.snow"
        case 95...99:
            return "cloud.bolt.rain"
        default:
            return "cloud.sun"
        }
    }
}

private struct OpenMeteoGeocodingResponse: Decodable {
    var results: [OpenMeteoLocation]?
}

private struct OpenMeteoLocation: Decodable {
    var name: String
    var latitude: Double
    var longitude: Double
}

private struct OpenMeteoForecastResponse: Decodable {
    var current: OpenMeteoCurrentWeather
}

private struct OpenMeteoCurrentWeather: Decodable {
    var temperature2m: Double
    var weatherCode: Int
    var isDay: Int

    enum CodingKeys: String, CodingKey {
        case temperature2m = "temperature_2m"
        case weatherCode = "weather_code"
        case isDay = "is_day"
    }
}
