import Testing
import TouchDeckCore

@Test func builtInFunctionCatalogIDsAreUnique() {
    let ids = BuiltInFunctionCatalog.all.map(\.id)

    #expect(Set(ids).count == ids.count)
}

@Test func builtInFunctionCatalogFindsKnownFunctions() throws {
    let copy = try #require(BuiltInFunctionCatalog.definition(id: "clipboard.copy"))
    let controlPaste = try #require(BuiltInFunctionCatalog.definition(id: "clipboard.controlPaste"))
    let openURL = try #require(BuiltInFunctionCatalog.definition(id: "open.url"))
    let openApp = try #require(BuiltInFunctionCatalog.definition(id: "open.app"))
    let openFile = try #require(BuiltInFunctionCatalog.definition(id: "open.file"))
    let keyboardShortcut = try #require(BuiltInFunctionCatalog.definition(id: "keyboard.shortcut"))
    let shellRun = try #require(BuiltInFunctionCatalog.definition(id: "shell.run"))
    let appleScriptRun = try #require(BuiltInFunctionCatalog.definition(id: "applescript.run"))
    let runShortcut = try #require(BuiltInFunctionCatalog.definition(id: "shortcut.run"))
    let killCurrentApp = try #require(BuiltInFunctionCatalog.definition(id: "currentApp.kill"))

    #expect(copy.name == "Copy")
    #expect(copy.supportedSizes == [.small])
    #expect(controlPaste.name == "Control Paste")
    #expect(controlPaste.symbolName == "clipboard")
    #expect(controlPaste.supportedSizes == [.small])
    #expect(openURL.parameters.map(\.id) == ["url"])
    #expect(openURL.parameters[0].kind == .url)
    #expect(openApp.parameters.map(\.id) == ["bundleIdentifier"])
    #expect(openApp.parameters[0].kind == .bundleIdentifier)
    #expect(openFile.parameters.map(\.id) == ["path"])
    #expect(openFile.parameters[0].kind == .filePath)
    #expect(keyboardShortcut.parameters.map(\.id) == ["shortcut"])
    #expect(keyboardShortcut.parameters[0].kind == .keyboardShortcut)
    #expect(shellRun.parameters.map(\.id) == ["command"])
    #expect(appleScriptRun.parameters.map(\.id) == ["source"])
    #expect(runShortcut.parameters.map(\.id) == ["name"])
    #expect(killCurrentApp.supportedSizes == [.small])
    #expect(openURL.supportedSizes == [.small])
    #expect(openApp.supportedSizes == [.small])
    #expect(openFile.supportedSizes == [.small])
    #expect(keyboardShortcut.supportedSizes == [.small])
    #expect(shellRun.supportedSizes == [.small])
    #expect(appleScriptRun.supportedSizes == [.small])
    #expect(runShortcut.supportedSizes == [.small])
}
