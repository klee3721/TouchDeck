import Foundation
import TouchDeckCore

struct LibraryButtonTemplate: Identifiable {
    var id: String
    var title: String
    var subtitle: String
    var symbolName: String
    var size: ButtonSize
    var itemType: TouchBarItemType

    func makeItem() -> TouchBarItemConfig {
        let item = TouchBarItemConfig(
            position: 0,
            size: size,
            type: itemType
        )
        return TouchBarItemConfig(
            id: item.id,
            position: item.position,
            size: item.normalizedSize,
            type: item.type
        )
    }

    static let all: [LibraryButtonTemplate] = [
        LibraryButtonTemplate(
            id: "system.layout-switch",
            title: BuiltInSystemActionCatalog.definition(id: "layoutSwitch")?.name ?? "Switch Layout",
            subtitle: "System",
            symbolName: BuiltInSystemActionCatalog.definition(id: "layoutSwitch")?.symbolName ?? "rectangle.2.swap",
            size: .small,
            itemType: .system(SystemButtonConfig(actionId: "layoutSwitch"))
        ),
        LibraryButtonTemplate(
            id: "system.volume-up",
            title: BuiltInSystemActionCatalog.definition(id: "volumeUp")?.name ?? "Volume Up",
            subtitle: "System",
            symbolName: BuiltInSystemActionCatalog.definition(id: "volumeUp")?.symbolName ?? "speaker.wave.3",
            size: .small,
            itemType: .system(SystemButtonConfig(actionId: "volumeUp"))
        ),
        LibraryButtonTemplate(
            id: "system.mute",
            title: BuiltInSystemActionCatalog.definition(id: "mute")?.name ?? "Mute",
            subtitle: "System",
            symbolName: BuiltInSystemActionCatalog.definition(id: "mute")?.symbolName ?? "speaker.slash",
            size: .small,
            itemType: .system(SystemButtonConfig(actionId: "mute"))
        ),
        LibraryButtonTemplate(
            id: "system.mission-control",
            title: BuiltInSystemActionCatalog.definition(id: "missionControl")?.name ?? "Mission Control",
            subtitle: "System",
            symbolName: BuiltInSystemActionCatalog.definition(id: "missionControl")?.symbolName ?? "rectangle.3.group",
            size: .small,
            itemType: .system(SystemButtonConfig(actionId: "missionControl"))
        ),
        LibraryButtonTemplate(
            id: "system.volume-slider",
            title: BuiltInSystemActionCatalog.definition(id: "volumeSlider")?.name ?? "Volume Slider",
            subtitle: "System Slider",
            symbolName: BuiltInSystemActionCatalog.definition(id: "volumeSlider")?.symbolName ?? "speaker.wave.2",
            size: .medium,
            itemType: .system(SystemButtonConfig(actionId: "volumeSlider"))
        ),
        LibraryButtonTemplate(
            id: "system.brightness-slider",
            title: BuiltInSystemActionCatalog.definition(id: "brightnessSlider")?.name ?? "Brightness Slider",
            subtitle: "System Slider",
            symbolName: BuiltInSystemActionCatalog.definition(id: "brightnessSlider")?.symbolName ?? "sun.max",
            size: .medium,
            itemType: .system(SystemButtonConfig(actionId: "brightnessSlider"))
        ),
        LibraryButtonTemplate(
            id: "system.screenshot-full",
            title: BuiltInSystemActionCatalog.definition(id: "screenshotFull")?.name ?? "Screenshot Full Screen",
            subtitle: "System",
            symbolName: BuiltInSystemActionCatalog.definition(id: "screenshotFull")?.symbolName ?? "camera.viewfinder",
            size: .small,
            itemType: .system(SystemButtonConfig(actionId: "screenshotFull"))
        ),
        LibraryButtonTemplate(
            id: "system.screenshot-selection",
            title: BuiltInSystemActionCatalog.definition(id: "screenshotSelection")?.name ?? "Screenshot Selection",
            subtitle: "System",
            symbolName: BuiltInSystemActionCatalog.definition(id: "screenshotSelection")?.symbolName ?? "camera.viewfinder",
            size: .small,
            itemType: .system(SystemButtonConfig(actionId: "screenshotSelection"))
        ),
        LibraryButtonTemplate(
            id: "system.emoji",
            title: BuiltInSystemActionCatalog.definition(id: "emoji")?.name ?? "Emoji Picker",
            subtitle: "System",
            symbolName: BuiltInSystemActionCatalog.definition(id: "emoji")?.symbolName ?? "face.smiling",
            size: .small,
            itemType: .system(SystemButtonConfig(actionId: "emoji"))
        ),
        LibraryButtonTemplate(
            id: "system.lock-screen",
            title: BuiltInSystemActionCatalog.definition(id: "lockScreen")?.name ?? "Lock Screen",
            subtitle: "System",
            symbolName: BuiltInSystemActionCatalog.definition(id: "lockScreen")?.symbolName ?? "lock",
            size: .small,
            itemType: .system(SystemButtonConfig(actionId: "lockScreen"))
        ),
        LibraryButtonTemplate(
            id: "system.sleep",
            title: BuiltInSystemActionCatalog.definition(id: "sleep")?.name ?? "Sleep",
            subtitle: "System",
            symbolName: BuiltInSystemActionCatalog.definition(id: "sleep")?.symbolName ?? "powersleep",
            size: .small,
            itemType: .system(SystemButtonConfig(actionId: "sleep"))
        ),
        LibraryButtonTemplate(
            id: "app.finder",
            title: "Finder",
            subtitle: "App Button",
            symbolName: "app",
            size: .small,
            itemType: .app(
                AppButtonConfig(
                    appName: "Finder",
                    bundleIdentifier: "com.apple.finder"
                )
            )
        ),
        LibraryButtonTemplate(
            id: "function.copy",
            title: BuiltInFunctionCatalog.definition(id: "clipboard.copy")?.name ?? "Copy",
            subtitle: "Function",
            symbolName: BuiltInFunctionCatalog.definition(id: "clipboard.copy")?.symbolName ?? "doc.on.doc",
            size: .small,
            itemType: .function(FunctionButtonConfig(functionId: "clipboard.copy"))
        ),
        LibraryButtonTemplate(
            id: "function.paste",
            title: BuiltInFunctionCatalog.definition(id: "clipboard.paste")?.name ?? "Paste",
            subtitle: "Function",
            symbolName: BuiltInFunctionCatalog.definition(id: "clipboard.paste")?.symbolName ?? "clipboard",
            size: .small,
            itemType: .function(FunctionButtonConfig(functionId: "clipboard.paste"))
        ),
        LibraryButtonTemplate(
            id: "function.control-paste",
            title: BuiltInFunctionCatalog.definition(id: "clipboard.controlPaste")?.name ?? "Control Paste",
            subtitle: "Function",
            symbolName: BuiltInFunctionCatalog.definition(id: "clipboard.controlPaste")?.symbolName ?? "clipboard",
            size: .small,
            itemType: .function(FunctionButtonConfig(functionId: "clipboard.controlPaste"))
        ),
        LibraryButtonTemplate(
            id: "function.open-url",
            title: BuiltInFunctionCatalog.definition(id: "open.url")?.name ?? "Open URL",
            subtitle: "Function",
            symbolName: BuiltInFunctionCatalog.definition(id: "open.url")?.symbolName ?? "safari",
            size: .small,
            itemType: .function(
                FunctionButtonConfig(
                    functionId: "open.url",
                    parameters: ["url": "https://www.apple.com"]
                )
            )
        ),
        LibraryButtonTemplate(
            id: "function.select-all",
            title: BuiltInFunctionCatalog.definition(id: "edit.selectAll")?.name ?? "Select All",
            subtitle: "Function",
            symbolName: BuiltInFunctionCatalog.definition(id: "edit.selectAll")?.symbolName ?? "selection.pin.in.out",
            size: .small,
            itemType: .function(FunctionButtonConfig(functionId: "edit.selectAll"))
        ),
        LibraryButtonTemplate(
            id: "function.kill-app",
            title: BuiltInFunctionCatalog.definition(id: "currentApp.kill")?.name ?? "Kill App",
            subtitle: "Function",
            symbolName: BuiltInFunctionCatalog.definition(id: "currentApp.kill")?.symbolName ?? "bolt.trianglebadge.exclamationmark",
            size: .small,
            itemType: .function(FunctionButtonConfig(functionId: "currentApp.kill"))
        ),
        LibraryButtonTemplate(
            id: "function.keyboard-shortcut",
            title: BuiltInFunctionCatalog.definition(id: "keyboard.shortcut")?.name ?? "Keyboard Shortcut",
            subtitle: "Function",
            symbolName: BuiltInFunctionCatalog.definition(id: "keyboard.shortcut")?.symbolName ?? "keyboard",
            size: .small,
            itemType: .function(
                FunctionButtonConfig(
                    functionId: "keyboard.shortcut",
                    parameters: ["shortcut": "cmd+shift+p"]
                )
            )
        ),
        LibraryButtonTemplate(
            id: "function.shell-run",
            title: BuiltInFunctionCatalog.definition(id: "shell.run")?.name ?? "Run Shell",
            subtitle: "Function",
            symbolName: BuiltInFunctionCatalog.definition(id: "shell.run")?.symbolName ?? "terminal",
            size: .small,
            itemType: .function(
                FunctionButtonConfig(
                    functionId: "shell.run",
                    parameters: ["command": "say Hello from TouchDeck"]
                )
            )
        ),
        LibraryButtonTemplate(
            id: "function.applescript-run",
            title: BuiltInFunctionCatalog.definition(id: "applescript.run")?.name ?? "Run AppleScript",
            subtitle: "Function",
            symbolName: BuiltInFunctionCatalog.definition(id: "applescript.run")?.symbolName ?? "applescript",
            size: .small,
            itemType: .function(
                FunctionButtonConfig(
                    functionId: "applescript.run",
                    parameters: ["source": "display notification \"Hello from TouchDeck\""]
                )
            )
        ),
        LibraryButtonTemplate(
            id: "widget.ram",
            title: BuiltInWidgetCatalog.definition(id: "system.ram")?.name ?? "RAM",
            subtitle: "Widget",
            symbolName: BuiltInWidgetCatalog.definition(id: "system.ram")?.symbolName ?? "memorychip",
            size: .small,
            itemType: .widget(WidgetButtonConfig(widgetId: "system.ram"))
        ),
        LibraryButtonTemplate(
            id: "widget.ssd",
            title: BuiltInWidgetCatalog.definition(id: "system.ssd")?.name ?? "SSD",
            subtitle: "Widget",
            symbolName: BuiltInWidgetCatalog.definition(id: "system.ssd")?.symbolName ?? "internaldrive",
            size: .small,
            itemType: .widget(WidgetButtonConfig(widgetId: "system.ssd"))
        ),
        LibraryButtonTemplate(
            id: "widget.battery",
            title: BuiltInWidgetCatalog.definition(id: "system.battery")?.name ?? "Battery",
            subtitle: "Widget",
            symbolName: BuiltInWidgetCatalog.definition(id: "system.battery")?.symbolName ?? "battery.100",
            size: .small,
            itemType: .widget(WidgetButtonConfig(widgetId: "system.battery"))
        ),
        LibraryButtonTemplate(
            id: "widget.cpu",
            title: BuiltInWidgetCatalog.definition(id: "system.cpu")?.name ?? "CPU Load",
            subtitle: "Widget",
            symbolName: BuiltInWidgetCatalog.definition(id: "system.cpu")?.symbolName ?? "cpu",
            size: .small,
            itemType: .widget(WidgetButtonConfig(widgetId: "system.cpu"))
        ),
        LibraryButtonTemplate(
            id: "widget.clock",
            title: BuiltInWidgetCatalog.definition(id: "system.clock")?.name ?? "Clock",
            subtitle: "Widget",
            symbolName: BuiltInWidgetCatalog.definition(id: "system.clock")?.symbolName ?? "clock",
            size: .small,
            itemType: .widget(WidgetButtonConfig(widgetId: "system.clock"))
        ),
        LibraryButtonTemplate(
            id: "widget.active-app",
            title: BuiltInWidgetCatalog.definition(id: "system.activeApp")?.name ?? "Active App",
            subtitle: "Widget",
            symbolName: BuiltInWidgetCatalog.definition(id: "system.activeApp")?.symbolName ?? "app.badge",
            size: .small,
            itemType: .widget(WidgetButtonConfig(widgetId: "system.activeApp"))
        ),
        LibraryButtonTemplate(
            id: "widget.weather",
            title: BuiltInWidgetCatalog.definition(id: "weather.current")?.name ?? "Weather",
            subtitle: "Widget",
            symbolName: BuiltInWidgetCatalog.definition(id: "weather.current")?.symbolName ?? "cloud.sun",
            size: .small,
            itemType: .widget(
                WidgetButtonConfig(
                    widgetId: "weather.current",
                    parameters: ["location": "San Francisco"]
                )
            )
        )
    ]

    static func template(id: String) -> LibraryButtonTemplate? {
        all.first { $0.id == id }
    }
}
