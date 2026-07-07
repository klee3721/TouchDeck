public enum LayoutEditingError: Error, Equatable, Sendable {
    case itemNotFound(itemId: TouchBarItemConfig.ID)
    case pageCapacityExceeded(maxCells: Int)
}

public struct LayoutEditingEngine: Sendable {
    public let maxCellsPerPage: Int

    public init(maxCellsPerPage: Int = TouchBarLayoutMetrics.maxCellsPerPage) {
        self.maxCellsPerPage = maxCellsPerPage
    }

    public func insert(
        _ item: TouchBarItemConfig,
        into page: TouchBarPage,
        at index: Int? = nil
    ) throws -> TouchBarPage {
        var items = sortedItems(in: page)
        let insertionIndex = min(max(index ?? items.endIndex, items.startIndex), items.endIndex)
        items.insert(item, at: insertionIndex)

        return try pageWithNormalizedPositions(page, items: items)
    }

    public func move(
        itemId: TouchBarItemConfig.ID,
        before targetId: TouchBarItemConfig.ID?,
        in page: TouchBarPage
    ) throws -> TouchBarPage {
        var items = sortedItems(in: page)

        guard let sourceIndex = items.firstIndex(where: { $0.id == itemId }) else {
            throw LayoutEditingError.itemNotFound(itemId: itemId)
        }

        let item = items.remove(at: sourceIndex)
        let targetIndex = targetId.flatMap { id in
            items.firstIndex { $0.id == id }
        } ?? items.endIndex

        items.insert(item, at: targetIndex)
        return try pageWithNormalizedPositions(page, items: items)
    }

    public func resize(
        itemId: TouchBarItemConfig.ID,
        to size: ButtonSize,
        in page: TouchBarPage
    ) throws -> TouchBarPage {
        var items = sortedItems(in: page)

        guard let index = items.firstIndex(where: { $0.id == itemId }) else {
            throw LayoutEditingError.itemNotFound(itemId: itemId)
        }

        items[index].size = size
        return try pageWithNormalizedPositions(page, items: items)
    }

    public func remove(
        itemId: TouchBarItemConfig.ID,
        from page: TouchBarPage
    ) throws -> TouchBarPage {
        var items = sortedItems(in: page)

        guard let index = items.firstIndex(where: { $0.id == itemId }) else {
            throw LayoutEditingError.itemNotFound(itemId: itemId)
        }

        items.remove(at: index)
        return try pageWithNormalizedPositions(page, items: items)
    }

    public func normalized(_ page: TouchBarPage) throws -> TouchBarPage {
        try pageWithNormalizedPositions(page, items: sortedItems(in: page))
    }

    private func sortedItems(in page: TouchBarPage) -> [TouchBarItemConfig] {
        page.items.sorted {
            if $0.position == $1.position {
                return $0.id.uuidString < $1.id.uuidString
            }
            return $0.position < $1.position
        }
    }

    private func pageWithNormalizedPositions(
        _ page: TouchBarPage,
        items: [TouchBarItemConfig]
    ) throws -> TouchBarPage {
        let totalCells = items.reduce(0) { $0 + $1.size.rawValue }

        guard totalCells <= maxCellsPerPage else {
            throw LayoutEditingError.pageCapacityExceeded(maxCells: maxCellsPerPage)
        }

        var cursor = 0
        let normalizedItems = items.map { item in
            var normalizedItem = item
            normalizedItem.position = cursor
            cursor += normalizedItem.size.rawValue
            return normalizedItem
        }

        return TouchBarPage(id: page.id, items: normalizedItems)
    }
}
