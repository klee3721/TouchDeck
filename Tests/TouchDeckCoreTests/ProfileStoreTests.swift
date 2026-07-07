import Foundation
import Testing
import TouchDeckCore

@Test func profileStoreReturnsSampleProfileWhenFileDoesNotExist() throws {
    let fileURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
        .appendingPathComponent("profiles.json")
    let store = ProfileStore(fileURL: fileURL)

    let profiles = try store.load()

    #expect(profiles == [SampleData.defaultProfile])
}

@Test func profileStoreSavesAndLoadsProfiles() throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directoryURL.appendingPathComponent("profiles.json")
    let store = ProfileStore(fileURL: fileURL)
    let profile = TouchBarProfile(
        name: "Design",
        bundleIdentifier: "com.apple.dt.Xcode",
        layout: TouchBarLayout(
            pages: [
                TouchBarPage(
                    items: [
                        TouchBarItemConfig(
                            position: 0,
                            size: .large,
                            type: .function(FunctionButtonConfig(functionId: "xcode.build"))
                        )
                    ]
                )
            ]
        )
    )

    try store.save([profile])
    let loadedProfiles = try store.load()

    #expect(loadedProfiles == [profile.normalizedForCurrentRules])

    try? FileManager.default.removeItem(at: directoryURL)
}

@Test func defaultProfileURLLivesUnderApplicationSupport() {
    let fileURL = ProfileStore.defaultFileURL(appName: "TouchDeckTests")

    #expect(fileURL.lastPathComponent == "profiles.json")
    #expect(fileURL.deletingLastPathComponent().lastPathComponent == "TouchDeckTests")
}
