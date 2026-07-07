public enum WidgetParameterKind: String, Codable, Equatable, Sendable {
    case text
    case location
}

public struct BuiltInWidgetParameter: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var placeholder: String
    public var kind: WidgetParameterKind

    public init(
        id: String,
        name: String,
        placeholder: String,
        kind: WidgetParameterKind
    ) {
        self.id = id
        self.name = name
        self.placeholder = placeholder
        self.kind = kind
    }
}

public struct BuiltInWidgetDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var symbolName: String
    public var refreshIntervalSeconds: Double
    public var supportedSizes: [ButtonSize]
    public var parameters: [BuiltInWidgetParameter]

    public init(
        id: String,
        name: String,
        symbolName: String,
        refreshIntervalSeconds: Double,
        supportedSizes: [ButtonSize],
        parameters: [BuiltInWidgetParameter] = []
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.refreshIntervalSeconds = refreshIntervalSeconds
        self.supportedSizes = supportedSizes
        self.parameters = parameters
    }
}

public enum BuiltInWidgetCatalog {
    public static let all: [BuiltInWidgetDefinition] = [
        BuiltInWidgetDefinition(
            id: "system.ram",
            name: "RAM",
            symbolName: "memorychip",
            refreshIntervalSeconds: 5,
            supportedSizes: [.small]
        ),
        BuiltInWidgetDefinition(
            id: "system.ssd",
            name: "SSD",
            symbolName: "internaldrive",
            refreshIntervalSeconds: 30,
            supportedSizes: [.small]
        ),
        BuiltInWidgetDefinition(
            id: "system.cpu",
            name: "CPU Load",
            symbolName: "cpu",
            refreshIntervalSeconds: 5,
            supportedSizes: [.small]
        ),
        BuiltInWidgetDefinition(
            id: "system.battery",
            name: "Battery",
            symbolName: "battery.100",
            refreshIntervalSeconds: 30,
            supportedSizes: [.small]
        ),
        BuiltInWidgetDefinition(
            id: "system.clock",
            name: "Clock",
            symbolName: "clock",
            refreshIntervalSeconds: 30,
            supportedSizes: [.small]
        ),
        BuiltInWidgetDefinition(
            id: "system.activeApp",
            name: "Active App",
            symbolName: "app.badge",
            refreshIntervalSeconds: 2,
            supportedSizes: [.small]
        ),
        BuiltInWidgetDefinition(
            id: "weather.current",
            name: "Weather",
            symbolName: "cloud.sun",
            refreshIntervalSeconds: 900,
            supportedSizes: [.small],
            parameters: [
                BuiltInWidgetParameter(
                    id: "location",
                    name: "Location",
                    placeholder: "San Francisco",
                    kind: .location
                )
            ]
        )
    ]

    public static func definition(id: String) -> BuiltInWidgetDefinition? {
        all.first { $0.id == id }
    }
}
