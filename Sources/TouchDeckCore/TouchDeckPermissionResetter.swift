import Foundation

public enum TouchDeckPermissionResetter {
    private static let lastPermissionResetVersionKey = "TouchDeck.lastPermissionResetVersion"

    @discardableResult
    public static func resetCurrentAppPermissions() -> Bool {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.touchdeck.app"
        return reset(service: "All", bundleIdentifier: bundleIdentifier)
    }

    @discardableResult
    public static func resetOnNewAppVersionIfNeeded() -> Bool {
        let versionIdentifier = currentVersionIdentifier()
        let previousVersionIdentifier = UserDefaults.standard.string(forKey: lastPermissionResetVersionKey)

        defer {
            UserDefaults.standard.set(versionIdentifier, forKey: lastPermissionResetVersionKey)
        }

        guard
            let previousVersionIdentifier,
            previousVersionIdentifier != versionIdentifier
        else {
            return false
        }

        return resetCurrentAppPermissions()
    }

    private static func currentVersionIdentifier() -> String {
        let infoDictionary = Bundle.main.infoDictionary ?? [:]
        let shortVersion = infoDictionary["CFBundleShortVersionString"] as? String ?? "0"
        let buildVersion = infoDictionary["CFBundleVersion"] as? String ?? "0"
        return "\(shortVersion)-\(buildVersion)"
    }

    private static func reset(service: String, bundleIdentifier: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        process.arguments = ["reset", service, bundleIdentifier]

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
