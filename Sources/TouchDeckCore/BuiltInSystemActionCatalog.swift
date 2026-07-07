public enum PermissionKind: String, Codable, Equatable, Sendable, CaseIterable {
    case accessibility
    case automation
    case location
    case network
}

public enum ActionSupportStatus: String, Codable, Equatable, Sendable {
    case supported
    case requiresPermission
    case limited
}

public struct BuiltInSystemActionDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var symbolName: String
    public var supportedSizes: [ButtonSize]
    public var requiredPermissions: [PermissionKind]
    public var supportStatus: ActionSupportStatus

    public init(
        id: String,
        name: String,
        symbolName: String,
        supportedSizes: [ButtonSize] = [.small],
        requiredPermissions: [PermissionKind] = [],
        supportStatus: ActionSupportStatus = .supported
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.supportedSizes = supportedSizes
        self.requiredPermissions = requiredPermissions
        self.supportStatus = supportStatus
    }
}

public enum BuiltInSystemActionCatalog {
    public static let all: [BuiltInSystemActionDefinition] = [
        BuiltInSystemActionDefinition(id: "layoutSwitch", name: "Switch Layout", symbolName: "rectangle.2.swap"),
        BuiltInSystemActionDefinition(id: "escape", name: "Escape", symbolName: "escape"),
        BuiltInSystemActionDefinition(id: "volumeUp", name: "Volume Up", symbolName: "speaker.wave.3"),
        BuiltInSystemActionDefinition(id: "volumeDown", name: "Volume Down", symbolName: "speaker.wave.1"),
        BuiltInSystemActionDefinition(
            id: "volumeSlider",
            name: "Volume Slider",
            symbolName: "speaker.wave.2",
            supportedSizes: [.medium],
            requiredPermissions: [.automation],
            supportStatus: .requiresPermission
        ),
        BuiltInSystemActionDefinition(id: "mute", name: "Mute", symbolName: "speaker.slash"),
        BuiltInSystemActionDefinition(id: "brightnessUp", name: "Brightness Up", symbolName: "sun.max"),
        BuiltInSystemActionDefinition(id: "brightnessDown", name: "Brightness Down", symbolName: "sun.min"),
        BuiltInSystemActionDefinition(
            id: "brightnessSlider",
            name: "Brightness Slider",
            symbolName: "sun.max",
            supportedSizes: [.medium],
            requiredPermissions: [.accessibility],
            supportStatus: .requiresPermission
        ),
        BuiltInSystemActionDefinition(
            id: "keyboardBrightnessUp",
            name: "Keyboard Brightness Up",
            symbolName: "keyboard.badge.ellipsis",
            supportStatus: .limited
        ),
        BuiltInSystemActionDefinition(
            id: "keyboardBrightnessDown",
            name: "Keyboard Brightness Down",
            symbolName: "keyboard",
            supportStatus: .limited
        ),
        BuiltInSystemActionDefinition(id: "playPause", name: "Play/Pause", symbolName: "playpause"),
        BuiltInSystemActionDefinition(id: "nextTrack", name: "Next Track", symbolName: "forward.end"),
        BuiltInSystemActionDefinition(id: "previousTrack", name: "Previous Track", symbolName: "backward.end"),
        BuiltInSystemActionDefinition(
            id: "missionControl",
            name: "Mission Control",
            symbolName: "rectangle.3.group",
            requiredPermissions: [.accessibility],
            supportStatus: .requiresPermission
        ),
        BuiltInSystemActionDefinition(
            id: "launchpad",
            name: "Launchpad",
            symbolName: "square.grid.3x3",
            requiredPermissions: [.accessibility],
            supportStatus: .requiresPermission
        ),
        BuiltInSystemActionDefinition(
            id: "screenshotFull",
            name: "Screenshot Full Screen",
            symbolName: "camera.viewfinder",
            requiredPermissions: [.accessibility],
            supportStatus: .requiresPermission
        ),
        BuiltInSystemActionDefinition(
            id: "screenshotSelection",
            name: "Screenshot Selection",
            symbolName: "camera.viewfinder",
            requiredPermissions: [.accessibility],
            supportStatus: .requiresPermission
        ),
        BuiltInSystemActionDefinition(
            id: "emoji",
            name: "Emoji Picker",
            symbolName: "face.smiling",
            requiredPermissions: [.accessibility],
            supportStatus: .requiresPermission
        ),
        BuiltInSystemActionDefinition(
            id: "dictation",
            name: "Dictation",
            symbolName: "mic",
            requiredPermissions: [.accessibility],
            supportStatus: .limited
        ),
        BuiltInSystemActionDefinition(
            id: "siri",
            name: "Siri",
            symbolName: "sparkle.magnifyingglass",
            supportStatus: .limited
        ),
        BuiltInSystemActionDefinition(id: "lockScreen", name: "Lock Screen", symbolName: "lock"),
        BuiltInSystemActionDefinition(
            id: "sleep",
            name: "Sleep",
            symbolName: "powersleep",
            requiredPermissions: [.automation],
            supportStatus: .requiresPermission
        ),
        BuiltInSystemActionDefinition(
            id: "focus",
            name: "Focus",
            symbolName: "moon",
            requiredPermissions: [.automation],
            supportStatus: .limited
        )
    ]

    public static func definition(id: String) -> BuiltInSystemActionDefinition? {
        all.first { $0.id == id }
    }
}
