public enum SampleData {
    public static let defaultProfile = TouchBarProfile(
        name: "Default",
        layout: TouchBarLayout(
            pages: [
                TouchBarPage(
                    items: [
                        TouchBarItemConfig(
                            position: 0,
                            size: .small,
                            type: .app(
                                AppButtonConfig(
                                    appName: "Finder",
                                    bundleIdentifier: "com.apple.finder"
                                )
                            )
                        ),
                        TouchBarItemConfig(
                            position: 1,
                            size: .small,
                            type: .function(
                                FunctionButtonConfig(functionId: "clipboard.copy")
                            )
                        ),
                        TouchBarItemConfig(
                            position: 2,
                            size: .small,
                            type: .function(
                                FunctionButtonConfig(functionId: "clipboard.paste")
                            )
                        ),
                        TouchBarItemConfig(
                            position: 3,
                            size: .small,
                            type: .widget(
                                WidgetButtonConfig(widgetId: "system.ram")
                            )
                        ),
                        TouchBarItemConfig(
                            position: 4,
                            size: .small,
                            type: .widget(
                                WidgetButtonConfig(widgetId: "system.ssd")
                            )
                        )
                    ]
                )
            ]
        )
    )
}
