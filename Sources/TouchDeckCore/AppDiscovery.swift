import Foundation

public struct InstalledApp: Codable, Equatable, Identifiable, Sendable {
    public var id: String { bundleIdentifier }
    public var name: String
    public var bundleIdentifier: String
    public var path: String

    public init(name: String, bundleIdentifier: String, path: String) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.path = path
    }
}

public struct AppDiscovery: Sendable {
    public init() {}

    public func discoverInstalledApps() -> [InstalledApp] {
        discoverApps(in: Self.defaultSearchDirectories())
    }

    public func discoverApps(in directories: [URL]) -> [InstalledApp] {
        let discoveredAppURLs = directories.flatMap { directory in
            appURLs(in: directory)
        }

        let apps = discoveredAppURLs.compactMap(makeInstalledApp)
        return deduplicateAndSort(apps)
    }

    public static func defaultSearchDirectories() -> [URL] {
        let fileManager = FileManager.default
        var directories = fileManager.urls(for: .applicationDirectory, in: .localDomainMask)
        directories.append(contentsOf: fileManager.urls(for: .applicationDirectory, in: .userDomainMask))

        let systemApplicationURLs = [
            URL(fileURLWithPath: "/System/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications/Utilities", isDirectory: true),
            URL(fileURLWithPath: "/Applications/Utilities", isDirectory: true)
        ]
        directories.append(contentsOf: systemApplicationURLs)

        var seenPaths: Set<String> = []
        return directories.filter { url in
            let path = url.resolvingSymlinksInPath().path
            return seenPaths.insert(path).inserted
        }
    }

    private func appURLs(in directory: URL) -> [URL] {
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        return enumerator.compactMap { element in
            guard let url = element as? URL, url.pathExtension == "app" else {
                return nil
            }

            return url
        }
    }

    private func makeInstalledApp(from appURL: URL) -> InstalledApp? {
        guard
            let bundle = Bundle(url: appURL),
            let bundleIdentifier = bundle.bundleIdentifier
        else {
            return nil
        }

        let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        let bundleName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
        let name = displayName ?? bundleName ?? appURL.deletingPathExtension().lastPathComponent

        return InstalledApp(
            name: name,
            bundleIdentifier: bundleIdentifier,
            path: appURL.resolvingSymlinksInPath().path
        )
    }

    private func deduplicateAndSort(_ apps: [InstalledApp]) -> [InstalledApp] {
        var appByBundleID: [String: InstalledApp] = [:]

        for app in apps {
            let existing = appByBundleID[app.bundleIdentifier]

            if existing == nil || app.path.count < (existing?.path.count ?? Int.max) {
                appByBundleID[app.bundleIdentifier] = app
            }
        }

        return appByBundleID.values.sorted {
            let nameComparison = $0.name.localizedCaseInsensitiveCompare($1.name)

            if nameComparison == .orderedSame {
                return $0.bundleIdentifier < $1.bundleIdentifier
            }

            return nameComparison == .orderedAscending
        }
    }
}
