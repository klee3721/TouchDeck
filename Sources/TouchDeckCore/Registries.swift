import Foundation

public struct ActionContext: Sendable {
    public init() {}
}

public struct FunctionParameter: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var placeholder: String?

    public init(id: String, name: String, placeholder: String? = nil) {
        self.id = id
        self.name = name
        self.placeholder = placeholder
    }
}

public protocol TouchDeckFunction: Sendable {
    var id: String { get }
    var name: String { get }
    var symbolName: String { get }
    var supportedSizes: [ButtonSize] { get }
    var parameters: [FunctionParameter] { get }

    func run(context: ActionContext, parameters: [String: String]) async throws
}

public struct FunctionDescriptor: Sendable, Identifiable {
    public var id: String
    public var name: String
    public var symbolName: String
    public var supportedSizes: [ButtonSize]
    public var parameters: [FunctionParameter]

    public init(function: any TouchDeckFunction) {
        self.id = function.id
        self.name = function.name
        self.symbolName = function.symbolName
        self.supportedSizes = function.supportedSizes
        self.parameters = function.parameters
    }
}

public final class FunctionRegistry: @unchecked Sendable {
    private var functions: [String: any TouchDeckFunction] = [:]

    public init(functions: [any TouchDeckFunction] = []) {
        functions.forEach(register)
    }

    public func register(_ function: any TouchDeckFunction) {
        functions[function.id] = function
    }

    public func function(id: String) -> (any TouchDeckFunction)? {
        functions[id]
    }

    public func descriptors() -> [FunctionDescriptor] {
        functions.values
            .map(FunctionDescriptor.init(function:))
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

public struct WidgetSnapshot: Codable, Equatable, Sendable {
    public var title: String
    public var subtitle: String?
    public var symbolName: String?
    public var progress: Double?
    public var colorHex: String?

    public init(
        title: String,
        subtitle: String? = nil,
        symbolName: String? = nil,
        progress: Double? = nil,
        colorHex: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.symbolName = symbolName
        self.progress = progress
        self.colorHex = colorHex
    }
}

public protocol TouchDeckWidget: Sendable {
    var id: String { get }
    var name: String { get }
    var symbolName: String { get }
    var refreshInterval: TimeInterval { get }

    func snapshot(parameters: [String: String]) async throws -> WidgetSnapshot
}

public struct WidgetDescriptor: Sendable, Identifiable {
    public var id: String
    public var name: String
    public var symbolName: String
    public var refreshInterval: TimeInterval

    public init(widget: any TouchDeckWidget) {
        self.id = widget.id
        self.name = widget.name
        self.symbolName = widget.symbolName
        self.refreshInterval = widget.refreshInterval
    }
}

public final class WidgetRegistry: @unchecked Sendable {
    private var widgets: [String: any TouchDeckWidget] = [:]

    public init(widgets: [any TouchDeckWidget] = []) {
        widgets.forEach(register)
    }

    public func register(_ widget: any TouchDeckWidget) {
        widgets[widget.id] = widget
    }

    public func widget(id: String) -> (any TouchDeckWidget)? {
        widgets[id]
    }

    public func descriptors() -> [WidgetDescriptor] {
        widgets.values
            .map(WidgetDescriptor.init(widget:))
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
