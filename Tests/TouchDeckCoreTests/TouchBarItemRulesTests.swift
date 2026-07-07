import Testing
import TouchDeckCore

@Test func appButtonsAreLogoOnlyOneCellControls() {
    let item = TouchBarItemConfig(
        position: 0,
        size: .medium,
        type: .app(
            AppButtonConfig(
                appName: "Finder",
                bundleIdentifier: "com.apple.finder"
            )
        )
    )

    #expect(item.allowedSizes == [.small])
    #expect(item.normalizedSize == .small)
}
