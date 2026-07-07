public extension TouchBarItemConfig {
    var allowedSizes: [ButtonSize] {
        switch type {
        case .system(let config):
            BuiltInSystemActionCatalog.definition(id: config.actionId)?.supportedSizes ?? [.small]
        case .function(let config):
            BuiltInFunctionCatalog.definition(id: config.functionId)?.supportedSizes ?? [.small]
        case .widget(let config):
            BuiltInWidgetCatalog.definition(id: config.widgetId)?.supportedSizes ?? [.medium]
        case .app:
            [.small]
        case .spacer:
            ButtonSize.allCases
        }
    }

    var normalizedSize: ButtonSize {
        allowedSizes.contains(size) ? size : (allowedSizes.first ?? .small)
    }

    var isSystemSlider: Bool {
        guard case .system(let config) = type else {
            return false
        }

        return ["volumeSlider", "brightnessSlider"].contains(config.actionId)
    }

    var isPercentWidget: Bool {
        guard case .widget(let config) = type else {
            return false
        }

        return ["system.ram", "system.ssd", "system.cpu", "system.battery"].contains(config.widgetId)
    }

    var isSimpleIconOnlyAction: Bool {
        switch type {
        case .system:
            return size == .small
        case .function(let config):
            return size == .small && BuiltInFunctionCatalog.definition(id: config.functionId)?.parameters.isEmpty == true
        case .app, .widget, .spacer:
            return false
        }
    }
}

public extension TouchBarProfile {
    var normalizedForCurrentRules: TouchBarProfile {
        TouchBarProfile(
            id: id,
            name: name,
            bundleIdentifier: bundleIdentifier,
            layout: layout.normalizedForCurrentRules
        )
    }
}

public extension TouchBarLayout {
    var normalizedForCurrentRules: TouchBarLayout {
        TouchBarLayout(pages: pages.map(\.normalizedForCurrentRules))
    }
}

public extension TouchBarPage {
    var normalizedForCurrentRules: TouchBarPage {
        var nextPosition = 0
        let normalizedItems = items
            .sorted { $0.position < $1.position }
            .map { item in
                let normalizedItem = TouchBarItemConfig(
                    id: item.id,
                    position: nextPosition,
                    size: item.normalizedSize,
                    type: item.type
                )
                nextPosition += normalizedItem.size.rawValue
                return normalizedItem
            }

        return TouchBarPage(id: id, items: normalizedItems)
    }
}
