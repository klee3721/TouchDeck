import Foundation

public enum ProfileSelection {
    public static func defaultProfile(from profiles: [TouchBarProfile]) -> TouchBarProfile {
        profiles.first { $0.bundleIdentifier == nil } ?? profiles.first ?? SampleData.defaultProfile
    }

    public static func effectiveProfile(
        from profiles: [TouchBarProfile],
        frontmostBundleIdentifier: String?
    ) -> TouchBarProfile {
        if let frontmostBundleIdentifier,
           let appProfile = profiles.first(where: { $0.bundleIdentifier == frontmostBundleIdentifier }) {
            return appProfile
        }

        return defaultProfile(from: profiles)
    }

    public static func replacing(
        _ profile: TouchBarProfile,
        in profiles: [TouchBarProfile]
    ) -> [TouchBarProfile] {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else {
            return profiles + [profile]
        }

        var updatedProfiles = profiles
        updatedProfiles[index] = profile
        return updatedProfiles
    }
}
