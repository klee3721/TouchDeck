import Foundation
import Testing
import TouchDeckCore

@Test func appDiscoveryFindsAppsFromBundleMetadata() throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let appURL = directoryURL.appendingPathComponent("Example.app", isDirectory: true)
    let contentsURL = appURL.appendingPathComponent("Contents", isDirectory: true)
    let plistURL = contentsURL.appendingPathComponent("Info.plist")

    try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)
    try writeInfoPlist(
        [
            "CFBundleIdentifier": "com.example.TouchDeckTest",
            "CFBundleName": "Example",
            "CFBundleDisplayName": "Example App"
        ],
        to: plistURL
    )

    let apps = AppDiscovery().discoverApps(in: [directoryURL])

    #expect(apps == [
        InstalledApp(
            name: "Example App",
            bundleIdentifier: "com.example.TouchDeckTest",
            path: appURL.resolvingSymlinksInPath().path
        )
    ])

    try? FileManager.default.removeItem(at: directoryURL)
}

@Test func appDiscoveryDeduplicatesAppsByBundleIdentifier() throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let firstAppURL = directoryURL.appendingPathComponent("A.app", isDirectory: true)
    let secondAppURL = directoryURL
        .appendingPathComponent("Nested", isDirectory: true)
        .appendingPathComponent("LongerName.app", isDirectory: true)

    try createFakeApp(at: firstAppURL, name: "A", bundleIdentifier: "com.example.Duplicate")
    try createFakeApp(at: secondAppURL, name: "Longer", bundleIdentifier: "com.example.Duplicate")

    let apps = AppDiscovery().discoverApps(in: [directoryURL])

    #expect(apps.count == 1)
    #expect(apps[0].path == firstAppURL.resolvingSymlinksInPath().path)

    try? FileManager.default.removeItem(at: directoryURL)
}

@Test func defaultAppDiscoveryDirectoriesIncludeSystemApplications() {
    let paths = Set(AppDiscovery.defaultSearchDirectories().map(\.path))

    #expect(paths.contains("/Applications"))
    #expect(paths.contains("/System/Applications"))
    #expect(paths.contains("/System/Applications/Utilities"))
    #expect(paths.contains("/Applications/Utilities"))
}

private func createFakeApp(
    at appURL: URL,
    name: String,
    bundleIdentifier: String
) throws {
    let contentsURL = appURL.appendingPathComponent("Contents", isDirectory: true)
    try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)

    try writeInfoPlist(
        [
            "CFBundleIdentifier": bundleIdentifier,
            "CFBundleName": name
        ],
        to: contentsURL.appendingPathComponent("Info.plist")
    )
}

private func writeInfoPlist(_ plist: [String: String], to url: URL) throws {
    let data = try PropertyListSerialization.data(
        fromPropertyList: plist,
        format: .xml,
        options: 0
    )
    try data.write(to: url)
}
