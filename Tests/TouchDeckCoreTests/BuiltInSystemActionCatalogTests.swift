import Testing
import TouchDeckCore

@Test func builtInSystemActionCatalogIDsAreUnique() {
    let ids = BuiltInSystemActionCatalog.all.map(\.id)

    #expect(Set(ids).count == ids.count)
}

@Test func builtInSystemActionCatalogMarksPermissionBoundActions() throws {
    let missionControl = try #require(BuiltInSystemActionCatalog.definition(id: "missionControl"))
    let layoutSwitch = try #require(BuiltInSystemActionCatalog.definition(id: "layoutSwitch"))
    let emoji = try #require(BuiltInSystemActionCatalog.definition(id: "emoji"))
    let sleep = try #require(BuiltInSystemActionCatalog.definition(id: "sleep"))
    let keyboardBrightness = try #require(BuiltInSystemActionCatalog.definition(id: "keyboardBrightnessUp"))
    let focus = try #require(BuiltInSystemActionCatalog.definition(id: "focus"))
    let volumeUp = try #require(BuiltInSystemActionCatalog.definition(id: "volumeUp"))
    let volumeSlider = try #require(BuiltInSystemActionCatalog.definition(id: "volumeSlider"))
    let brightnessSlider = try #require(BuiltInSystemActionCatalog.definition(id: "brightnessSlider"))
    let screenshotFull = try #require(BuiltInSystemActionCatalog.definition(id: "screenshotFull"))
    let screenshotSelection = try #require(BuiltInSystemActionCatalog.definition(id: "screenshotSelection"))

    #expect(layoutSwitch.supportedSizes == [.small])
    #expect(layoutSwitch.symbolName == "rectangle.2.swap")
    #expect(missionControl.requiredPermissions == [.accessibility])
    #expect(missionControl.supportStatus == .requiresPermission)
    #expect(emoji.requiredPermissions == [.accessibility])
    #expect(emoji.supportStatus == .requiresPermission)
    #expect(sleep.requiredPermissions == [.automation])
    #expect(sleep.supportStatus == .requiresPermission)
    #expect(keyboardBrightness.supportStatus == .limited)
    #expect(focus.requiredPermissions == [.automation])
    #expect(focus.supportStatus == .limited)
    #expect(volumeUp.requiredPermissions.isEmpty)
    #expect(volumeUp.supportedSizes == [.small])
    #expect(volumeSlider.supportedSizes == [.medium])
    #expect(volumeSlider.requiredPermissions == [.automation])
    #expect(brightnessSlider.supportedSizes == [.medium])
    #expect(brightnessSlider.requiredPermissions == [.accessibility])
    #expect(screenshotFull.supportedSizes == [.small])
    #expect(screenshotSelection.supportedSizes == [.small])
}
