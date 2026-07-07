public enum LayoutValidationError: Error, Equatable, Sendable {
    case negativePosition(itemId: TouchBarItemConfig.ID)
    case itemExceedsPage(itemId: TouchBarItemConfig.ID, maxCells: Int)
    case overlappingItems(firstId: TouchBarItemConfig.ID, secondId: TouchBarItemConfig.ID)
}

public struct LayoutValidator: Sendable {
    public let maxCellsPerPage: Int

    public init(maxCellsPerPage: Int = TouchBarLayoutMetrics.maxCellsPerPage) {
        self.maxCellsPerPage = maxCellsPerPage
    }

    public func validate(page: TouchBarPage) -> [LayoutValidationError] {
        var errors: [LayoutValidationError] = []
        let items = page.items.sorted { $0.position < $1.position }

        for item in items {
            if item.position < 0 {
                errors.append(.negativePosition(itemId: item.id))
            }

            if item.position + item.size.rawValue > maxCellsPerPage {
                errors.append(.itemExceedsPage(itemId: item.id, maxCells: maxCellsPerPage))
            }
        }

        for index in items.indices.dropLast() {
            let current = items[index]
            let next = items[items.index(after: index)]
            let currentEnd = current.position + current.size.rawValue

            if currentEnd > next.position {
                errors.append(.overlappingItems(firstId: current.id, secondId: next.id))
            }
        }

        return errors
    }
}
