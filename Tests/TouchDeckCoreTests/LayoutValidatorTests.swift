import Testing
import TouchDeckCore

@Test func validSampleLayoutHasNoValidationErrors() {
    let validator = LayoutValidator(maxCellsPerPage: 12)
    let page = SampleData.defaultProfile.layout.pages[0]

    #expect(validator.validate(page: page).isEmpty)
}

@Test func defaultLayoutCapacityMatchesFullTouchBarCells() {
    #expect(TouchBarLayoutMetrics.maxCellsPerPage == 17)
    #expect(LayoutValidator().maxCellsPerPage == TouchBarLayoutMetrics.maxCellsPerPage)
}

@Test func validatorReportsOverlappingItems() {
    let first = TouchBarItemConfig(
        position: 0,
        size: .medium,
        type: .spacer
    )
    let second = TouchBarItemConfig(
        position: 1,
        size: .small,
        type: .spacer
    )
    let page = TouchBarPage(items: [first, second])
    let validator = LayoutValidator(maxCellsPerPage: 12)

    #expect(validator.validate(page: page) == [
        .overlappingItems(firstId: first.id, secondId: second.id)
    ])
}

@Test func validatorReportsItemsOutsidePage() {
    let item = TouchBarItemConfig(
        position: 11,
        size: .medium,
        type: .spacer
    )
    let page = TouchBarPage(items: [item])
    let validator = LayoutValidator(maxCellsPerPage: 12)

    #expect(validator.validate(page: page) == [
        .itemExceedsPage(itemId: item.id, maxCells: 12)
    ])
}
