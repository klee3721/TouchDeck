import Foundation

public struct ProfileStore: Sendable {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public static func defaultStore(appName: String = "TouchDeck") -> ProfileStore {
        ProfileStore(fileURL: defaultFileURL(appName: appName))
    }

    public static func defaultFileURL(appName: String = "TouchDeck") -> URL {
        let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]

        return applicationSupportURL
            .appendingPathComponent(appName, isDirectory: true)
            .appendingPathComponent("profiles.json")
    }

    public func load() throws -> [TouchBarProfile] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return [SampleData.defaultProfile]
        }

        let data = try Data(contentsOf: fileURL)
        return try ProfileDocumentCodec.decode(data).map(\.normalizedForCurrentRules)
    }

    public func save(_ profiles: [TouchBarProfile]) throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let data = try ProfileDocumentCodec.encode(profiles.map(\.normalizedForCurrentRules))
        try data.write(to: fileURL, options: [.atomic])
    }
}
