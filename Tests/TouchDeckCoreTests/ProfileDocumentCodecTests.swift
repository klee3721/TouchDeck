import Testing
import TouchDeckCore

@Test func profileDocumentCodecRoundTripsProfiles() throws {
    let profiles = [
        SampleData.defaultProfile,
        TouchBarProfile(
            name: "Finder",
            bundleIdentifier: "com.apple.finder",
            layout: TouchBarLayout()
        )
    ]

    let data = try ProfileDocumentCodec.encode(profiles)
    let decodedProfiles = try ProfileDocumentCodec.decode(data)

    #expect(decodedProfiles == profiles)
}
