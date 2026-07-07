import Testing
import TouchDeckCore

@Test func profileSelectionReturnsAppSpecificProfileWhenBundleMatches() {
    let defaultProfile = TouchBarProfile(name: "Default", layout: TouchBarLayout())
    let appProfile = TouchBarProfile(
        name: "Xcode",
        bundleIdentifier: "com.apple.dt.Xcode",
        layout: TouchBarLayout()
    )

    let selectedProfile = ProfileSelection.effectiveProfile(
        from: [defaultProfile, appProfile],
        frontmostBundleIdentifier: "com.apple.dt.Xcode"
    )

    #expect(selectedProfile == appProfile)
}

@Test func profileSelectionFallsBackToDefaultProfile() {
    let defaultProfile = TouchBarProfile(name: "Default", layout: TouchBarLayout())
    let appProfile = TouchBarProfile(
        name: "Xcode",
        bundleIdentifier: "com.apple.dt.Xcode",
        layout: TouchBarLayout()
    )

    let selectedProfile = ProfileSelection.effectiveProfile(
        from: [appProfile, defaultProfile],
        frontmostBundleIdentifier: "com.apple.finder"
    )

    #expect(selectedProfile == defaultProfile)
}

@Test func profileSelectionReplacesExistingProfileByID() {
    let profile = TouchBarProfile(name: "Default", layout: TouchBarLayout())
    var editedProfile = profile
    editedProfile.name = "Edited"

    let profiles = ProfileSelection.replacing(editedProfile, in: [profile])

    #expect(profiles == [editedProfile])
}
