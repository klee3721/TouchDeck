import Testing
import TouchDeckCore

@Test func insertingItemNormalizesPositions() throws {
    let engine = LayoutEditingEngine(maxCellsPerPage: 12)
    let existing = TouchBarItemConfig(position: 4, size: .medium, type: .spacer)
    let inserted = TouchBarItemConfig(position: 99, size: .small, type: .spacer)
    let page = TouchBarPage(items: [existing])

    let editedPage = try engine.insert(inserted, into: page, at: 0)

    #expect(editedPage.items.map(\.id) == [inserted.id, existing.id])
    #expect(editedPage.items.map(\.position) == [0, 1])
}

@Test func defaultEditingCapacityMatchesFullTouchBarCells() {
    #expect(LayoutEditingEngine().maxCellsPerPage == TouchBarLayoutMetrics.maxCellsPerPage)
}

@Test func movingItemBeforeTargetKeepsLayoutCompact() throws {
    let engine = LayoutEditingEngine(maxCellsPerPage: 12)
    let first = TouchBarItemConfig(position: 0, size: .small, type: .spacer)
    let second = TouchBarItemConfig(position: 1, size: .medium, type: .spacer)
    let third = TouchBarItemConfig(position: 3, size: .small, type: .spacer)
    let page = TouchBarPage(items: [first, second, third])

    let editedPage = try engine.move(itemId: third.id, before: first.id, in: page)

    #expect(editedPage.items.map(\.id) == [third.id, first.id, second.id])
    #expect(editedPage.items.map(\.position) == [0, 1, 2])
}

@Test func resizingItemRejectsLayoutsOverCapacity() {
    let engine = LayoutEditingEngine(maxCellsPerPage: 3)
    let first = TouchBarItemConfig(position: 0, size: .medium, type: .spacer)
    let second = TouchBarItemConfig(position: 2, size: .small, type: .spacer)
    let page = TouchBarPage(items: [first, second])

    #expect(throws: LayoutEditingError.pageCapacityExceeded(maxCells: 3)) {
        try engine.resize(itemId: second.id, to: .medium, in: page)
    }
}

@Test func removingItemNormalizesRemainingItems() throws {
    let engine = LayoutEditingEngine(maxCellsPerPage: 12)
    let first = TouchBarItemConfig(position: 0, size: .small, type: .spacer)
    let second = TouchBarItemConfig(position: 1, size: .medium, type: .spacer)
    let third = TouchBarItemConfig(position: 3, size: .small, type: .spacer)
    let page = TouchBarPage(items: [first, second, third])

    let editedPage = try engine.remove(itemId: second.id, from: page)

    #expect(editedPage.items.map(\.id) == [first.id, third.id])
    #expect(editedPage.items.map(\.position) == [0, 1])
}
