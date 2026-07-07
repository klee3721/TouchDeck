public enum FunctionParameterKind: String, Codable, Equatable, Sendable {
    case text
    case url
    case filePath
    case bundleIdentifier
    case keyboardShortcut
}

public struct BuiltInFunctionParameter: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var placeholder: String
    public var kind: FunctionParameterKind

    public init(
        id: String,
        name: String,
        placeholder: String,
        kind: FunctionParameterKind
    ) {
        self.id = id
        self.name = name
        self.placeholder = placeholder
        self.kind = kind
    }
}

public struct BuiltInFunctionDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var symbolName: String
    public var supportedSizes: [ButtonSize]
    public var parameters: [BuiltInFunctionParameter]

    public init(
        id: String,
        name: String,
        symbolName: String,
        supportedSizes: [ButtonSize],
        parameters: [BuiltInFunctionParameter] = []
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.supportedSizes = supportedSizes
        self.parameters = parameters
    }
}

public enum BuiltInFunctionCatalog {
    public static let all: [BuiltInFunctionDefinition] = [
        BuiltInFunctionDefinition(
            id: "clipboard.copy",
            name: "Copy",
            symbolName: "doc.on.doc",
            supportedSizes: [.small]
        ),
        BuiltInFunctionDefinition(
            id: "clipboard.paste",
            name: "Paste",
            symbolName: "clipboard",
            supportedSizes: [.small]
        ),
        BuiltInFunctionDefinition(
            id: "clipboard.controlPaste",
            name: "Control Paste",
            symbolName: "clipboard",
            supportedSizes: [.small]
        ),
        BuiltInFunctionDefinition(
            id: "clipboard.cut",
            name: "Cut",
            symbolName: "scissors",
            supportedSizes: [.small]
        ),
        BuiltInFunctionDefinition(
            id: "edit.undo",
            name: "Undo",
            symbolName: "arrow.uturn.backward",
            supportedSizes: [.small]
        ),
        BuiltInFunctionDefinition(
            id: "edit.redo",
            name: "Redo",
            symbolName: "arrow.uturn.forward",
            supportedSizes: [.small]
        ),
        BuiltInFunctionDefinition(
            id: "edit.selectAll",
            name: "Select All",
            symbolName: "selection.pin.in.out",
            supportedSizes: [.small]
        ),
        BuiltInFunctionDefinition(
            id: "open.url",
            name: "Open URL",
            symbolName: "safari",
            supportedSizes: [.small],
            parameters: [
                BuiltInFunctionParameter(
                    id: "url",
                    name: "URL",
                    placeholder: "https://www.apple.com",
                    kind: .url
                )
            ]
        ),
        BuiltInFunctionDefinition(
            id: "open.app",
            name: "Open App",
            symbolName: "app",
            supportedSizes: [.small],
            parameters: [
                BuiltInFunctionParameter(
                    id: "bundleIdentifier",
                    name: "Bundle ID or Path",
                    placeholder: "com.apple.Safari",
                    kind: .bundleIdentifier
                )
            ]
        ),
        BuiltInFunctionDefinition(
            id: "open.file",
            name: "Open File",
            symbolName: "doc",
            supportedSizes: [.small],
            parameters: [
                BuiltInFunctionParameter(
                    id: "path",
                    name: "File Path",
                    placeholder: "/Users/me/Documents/file.pdf",
                    kind: .filePath
                )
            ]
        ),
        BuiltInFunctionDefinition(
            id: "open.folder",
            name: "Open Folder",
            symbolName: "folder",
            supportedSizes: [.small],
            parameters: [
                BuiltInFunctionParameter(
                    id: "path",
                    name: "Folder Path",
                    placeholder: "/Users/me/Downloads",
                    kind: .filePath
                )
            ]
        ),
        BuiltInFunctionDefinition(
            id: "keyboard.shortcut",
            name: "Keyboard Shortcut",
            symbolName: "keyboard",
            supportedSizes: [.small],
            parameters: [
                BuiltInFunctionParameter(
                    id: "shortcut",
                    name: "Shortcut",
                    placeholder: "cmd+shift+p",
                    kind: .keyboardShortcut
                )
            ]
        ),
        BuiltInFunctionDefinition(
            id: "shell.run",
            name: "Run Shell",
            symbolName: "terminal",
            supportedSizes: [.small],
            parameters: [
                BuiltInFunctionParameter(
                    id: "command",
                    name: "Command",
                    placeholder: "say Hello from TouchDeck",
                    kind: .text
                )
            ]
        ),
        BuiltInFunctionDefinition(
            id: "applescript.run",
            name: "Run AppleScript",
            symbolName: "applescript",
            supportedSizes: [.small],
            parameters: [
                BuiltInFunctionParameter(
                    id: "source",
                    name: "Script",
                    placeholder: "display notification \"Hello from TouchDeck\"",
                    kind: .text
                )
            ]
        ),
        BuiltInFunctionDefinition(
            id: "shortcut.run",
            name: "Run Shortcut",
            symbolName: "sparkles",
            supportedSizes: [.small],
            parameters: [
                BuiltInFunctionParameter(
                    id: "name",
                    name: "Shortcut Name",
                    placeholder: "Morning Setup",
                    kind: .text
                )
            ]
        ),
        BuiltInFunctionDefinition(
            id: "currentApp.hide",
            name: "Hide Current App",
            symbolName: "eye.slash",
            supportedSizes: [.small]
        ),
        BuiltInFunctionDefinition(
            id: "currentApp.quit",
            name: "Quit Current App",
            symbolName: "xmark.circle",
            supportedSizes: [.small]
        ),
        BuiltInFunctionDefinition(
            id: "currentApp.kill",
            name: "Kill Current App",
            symbolName: "bolt.trianglebadge.exclamationmark",
            supportedSizes: [.small]
        )
    ]

    public static func definition(id: String) -> BuiltInFunctionDefinition? {
        all.first { $0.id == id }
    }
}
