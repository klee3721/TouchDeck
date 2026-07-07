import Foundation

public struct TouchBarProfile: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var bundleIdentifier: String?
    public var layout: TouchBarLayout

    public init(
        id: UUID = UUID(),
        name: String,
        bundleIdentifier: String? = nil,
        layout: TouchBarLayout
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.layout = layout
    }
}

public struct TouchBarLayout: Codable, Equatable, Sendable {
    public var pages: [TouchBarPage]

    public init(pages: [TouchBarPage] = [TouchBarPage()]) {
        self.pages = pages
    }
}

public struct TouchBarPage: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var items: [TouchBarItemConfig]

    public init(id: UUID = UUID(), items: [TouchBarItemConfig] = []) {
        self.id = id
        self.items = items
    }
}

public struct TouchBarItemConfig: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var position: Int
    public var size: ButtonSize
    public var type: TouchBarItemType

    public init(
        id: UUID = UUID(),
        position: Int,
        size: ButtonSize,
        type: TouchBarItemType
    ) {
        self.id = id
        self.position = position
        self.size = size
        self.type = type
    }
}

public enum TouchBarItemType: Codable, Equatable, Sendable {
    case system(SystemButtonConfig)
    case app(AppButtonConfig)
    case function(FunctionButtonConfig)
    case widget(WidgetButtonConfig)
    case spacer
}

public struct SystemButtonConfig: Codable, Equatable, Sendable {
    public var actionId: String

    public init(actionId: String) {
        self.actionId = actionId
    }
}

public struct AppButtonConfig: Codable, Equatable, Sendable {
    public var appName: String
    public var bundleIdentifier: String
    public var appPath: String?
    public var showRunningIndicator: Bool
    public var showActiveIndicator: Bool

    public init(
        appName: String,
        bundleIdentifier: String,
        appPath: String? = nil,
        showRunningIndicator: Bool = true,
        showActiveIndicator: Bool = true
    ) {
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.appPath = appPath
        self.showRunningIndicator = showRunningIndicator
        self.showActiveIndicator = showActiveIndicator
    }
}

public struct FunctionButtonConfig: Codable, Equatable, Sendable {
    public var functionId: String
    public var parameters: [String: String]

    public init(functionId: String, parameters: [String: String] = [:]) {
        self.functionId = functionId
        self.parameters = parameters
    }
}

public struct WidgetButtonConfig: Codable, Equatable, Sendable {
    public var widgetId: String
    public var parameters: [String: String]

    public init(widgetId: String, parameters: [String: String] = [:]) {
        self.widgetId = widgetId
        self.parameters = parameters
    }
}
