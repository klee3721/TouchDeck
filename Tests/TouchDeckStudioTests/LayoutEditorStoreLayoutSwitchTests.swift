import Testing
@testable import TouchDeckStudio
import TouchDeckCore

@MainActor
@Test func addLayoutAddsRequiredSwitchButtons() {
    let profile = TouchBarProfile(
        name: "Default",
        layout: TouchBarLayout(
            pages: [
                TouchBarPage(
                    items: [
                        TouchBarItemConfig(position: 0, size: .small, type: .spacer)
                    ]
                )
            ]
        )
    )
    let store = LayoutEditorStore(profile: profile, installedApps: [])

    store.addLayout()

    #expect(store.profile.layout.pages.count == 2)
    #expect(store.profile.layout.pages[0].containsLayoutSwitch)
    #expect(store.profile.layout.pages[1].containsLayoutSwitch)
    #expect(store.selectedLayoutIndex == 1)
}

@MainActor
@Test func addLayoutReportsWhenCurrentLayoutCannotFitRequiredSwitch() {
    let fullItems = (0..<TouchBarLayoutMetrics.maxCellsPerPage).map { index in
        TouchBarItemConfig(position: index, size: .small, type: .spacer)
    }
    let profile = TouchBarProfile(
        name: "Default",
        layout: TouchBarLayout(pages: [TouchBarPage(items: fullItems)])
    )
    let store = LayoutEditorStore(profile: profile, installedApps: [])

    store.addLayout()

    #expect(store.profile.layout.pages.count == 1)
    #expect(store.errorMessage == "Current layout is full. Remove a button before adding a layout so TouchDeck can add Switch Layout.")
}

@MainActor
@Test func requiredSwitchButtonCannotBeRemovedInMultiLayoutProfile() throws {
    let firstSwitch = TouchBarItemConfig(
        position: 0,
        size: .small,
        type: .system(SystemButtonConfig(actionId: "layoutSwitch"))
    )
    let secondSwitch = TouchBarItemConfig(
        position: 0,
        size: .small,
        type: .system(SystemButtonConfig(actionId: "layoutSwitch"))
    )
    let profile = TouchBarProfile(
        name: "Default",
        layout: TouchBarLayout(
            pages: [
                TouchBarPage(items: [firstSwitch]),
                TouchBarPage(items: [secondSwitch])
            ]
        )
    )
    let store = LayoutEditorStore(profile: profile, installedApps: [])

    store.remove(itemID: firstSwitch.id)

    #expect(store.profile.layout.pages[0].items.map(\.id).contains(firstSwitch.id))
    #expect(store.errorMessage == "Switch Layout is required in this layout and cannot be deleted.")
}

@MainActor
@Test func selectedItemMovesLeftAndRightWithKeyboardReorderCommands() {
    let first = TouchBarItemConfig(position: 0, size: .small, type: .spacer)
    let second = TouchBarItemConfig(position: 1, size: .small, type: .spacer)
    let third = TouchBarItemConfig(position: 2, size: .small, type: .spacer)
    let profile = TouchBarProfile(
        name: "Default",
        layout: TouchBarLayout(pages: [TouchBarPage(items: [first, second, third])])
    )
    let store = LayoutEditorStore(profile: profile, installedApps: [])
    store.selectedItemID = second.id

    store.moveSelectedItemLeft()

    #expect(store.profile.layout.pages[0].items.map(\.id) == [second.id, first.id, third.id])
    #expect(store.selectedItemID == second.id)

    store.moveSelectedItemRight()

    #expect(store.profile.layout.pages[0].items.map(\.id) == [first.id, second.id, third.id])
    #expect(store.selectedItemID == second.id)
}

@MainActor
@Test func selectedItemKeyboardReorderStopsAtLayoutEdges() {
    let first = TouchBarItemConfig(position: 0, size: .small, type: .spacer)
    let second = TouchBarItemConfig(position: 1, size: .small, type: .spacer)
    let profile = TouchBarProfile(
        name: "Default",
        layout: TouchBarLayout(pages: [TouchBarPage(items: [first, second])])
    )
    let store = LayoutEditorStore(profile: profile, installedApps: [])
    store.selectedItemID = first.id

    store.moveSelectedItemLeft()

    #expect(store.profile.layout.pages[0].items.map(\.id) == [first.id, second.id])
    #expect(store.selectedItemID == first.id)
}

private extension TouchBarPage {
    var containsLayoutSwitch: Bool {
        items.contains { item in
            if case .system(let config) = item.type {
                return config.actionId == "layoutSwitch"
            }

            return false
        }
    }
}
