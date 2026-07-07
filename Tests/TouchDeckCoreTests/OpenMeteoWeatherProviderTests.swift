import Foundation
import Testing
import TouchDeckCore

@Test func openMeteoProviderBuildsExpectedURLs() throws {
    let geocodingURL = try #require(OpenMeteoWeatherProvider.geocodingURL(location: "San Francisco"))
    let forecastURL = try #require(OpenMeteoWeatherProvider.forecastURL(latitude: 37.77, longitude: -122.42))

    #expect(geocodingURL.absoluteString.contains("geocoding-api.open-meteo.com/v1/search"))
    #expect(geocodingURL.absoluteString.contains("name=San%20Francisco"))
    #expect(forecastURL.absoluteString.contains("api.open-meteo.com/v1/forecast"))
    #expect(forecastURL.absoluteString.contains("current=temperature_2m,weather_code,is_day"))
}

@Test func openMeteoProviderReturnsWeatherSnapshotFromResponses() async throws {
    MockResponseStore.shared.setResponses([
        "geocoding-api.open-meteo.com": """
        {
          "results": [
            { "name": "San Francisco", "latitude": 37.7749, "longitude": -122.4194 }
          ]
        }
        """,
        "api.open-meteo.com": """
        {
          "current": {
            "temperature_2m": 18.6,
            "weather_code": 2,
            "is_day": 1
          }
        }
        """
    ])

    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: configuration)
    let provider = OpenMeteoWeatherProvider(session: session)

    let snapshot = try #require(await provider.snapshot(for: WeatherSnapshotRequest(location: "San Francisco")))

    #expect(snapshot.title == "19°")
    #expect(snapshot.subtitle == "San Francisco")
    #expect(snapshot.symbolName == "cloud.sun")
}

@Test func openMeteoWeatherCodeMappingUsesReasonableSymbols() {
    #expect(OpenMeteoWeatherProvider.symbolName(for: 0, isDay: true) == "sun.max")
    #expect(OpenMeteoWeatherProvider.symbolName(for: 0, isDay: false) == "moon.stars")
    #expect(OpenMeteoWeatherProvider.symbolName(for: 61, isDay: true) == "cloud.rain")
    #expect(OpenMeteoWeatherProvider.symbolName(for: 95, isDay: true) == "cloud.bolt.rain")
}

private final class MockResponseStore: @unchecked Sendable {
    static let shared = MockResponseStore()
    private let lock = NSLock()
    private var responses: [String: String] = [:]

    func setResponses(_ responses: [String: String]) {
        lock.lock()
        defer { lock.unlock() }
        self.responses = responses
    }

    func response(for host: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return responses[host]
    }
}

private final class MockURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard
            let host = request.url?.host,
            let response = MockResponseStore.shared.response(for: host),
            let data = response.data(using: .utf8)
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        let urlResponse = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: urlResponse, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
