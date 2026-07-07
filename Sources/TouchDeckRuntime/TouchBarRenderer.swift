import AppKit
import TouchDeckCore

@MainActor
public final class TouchBarRenderer: NSObject, NSTouchBarDelegate {
    private static let itemIdentifierPrefix = "com.touchdeck.item."

    private var profile: TouchBarProfile
    private let actionDispatcher: ActionDispatcher
    private let statsProvider: SystemStatsProvider
    private let weatherProvider: OpenMeteoWeatherProvider
    private var widgetUpdateHandlers: [TouchBarItemConfig.ID: (TouchBarItemConfig, WidgetSnapshot?) -> Void] = [:]
    private var widgetSnapshots: [TouchBarItemConfig.ID: WidgetSnapshot] = [:]
    private var lastWeatherRefresh: [TouchBarItemConfig.ID: Date] = [:]
    private var dynamicRefreshTimer: Timer?
    private var currentLayoutIndex = 0
    var onTouchBarNeedsRefresh: (() -> Void)?

    public init(
        profile: TouchBarProfile,
        actionDispatcher: ActionDispatcher = ActionDispatcher(),
        statsProvider: SystemStatsProvider = SystemStatsProvider(),
        weatherProvider: OpenMeteoWeatherProvider = OpenMeteoWeatherProvider()
    ) {
        self.profile = profile.normalizedForCurrentRules
        self.actionDispatcher = actionDispatcher
        self.statsProvider = statsProvider
        self.weatherProvider = weatherProvider
        super.init()
    }

    public func update(profile: TouchBarProfile) {
        self.profile = profile.normalizedForCurrentRules
        currentLayoutIndex = clampedLayoutIndex(currentLayoutIndex)
        refreshWidgetViews()
    }

    public func makeTouchBar() -> NSTouchBar {
        widgetUpdateHandlers.removeAll()
        configureDynamicRefreshTimer()

        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.defaultItemIdentifiers = currentItems().map { Self.itemIdentifier(for: $0) }

        return touchBar
    }

    public func touchBar(
        _ touchBar: NSTouchBar,
        makeItemForIdentifier identifier: NSTouchBarItem.Identifier
    ) -> NSTouchBarItem? {
        if identifier == .characterPicker {
            return nil
        }

        guard let itemConfig = itemConfig(for: identifier) else {
            return nil
        }

        let customItem = NSCustomTouchBarItem(identifier: identifier)

        if case .spacer = itemConfig.type {
            customItem.view = TouchDeckSpacerView(size: itemConfig.size)
            return customItem
        }

        if let sliderActionId = itemConfig.sliderSystemActionId {
            customItem.view = TouchDeckSliderView(
                config: itemConfig,
                actionId: sliderActionId,
                onChange: { [weak self] value in
                    self?.actionDispatcher.dispatchSystemSlider(actionId: sliderActionId, value: value)
                }
            )
            return customItem
        }

        if itemConfig.isPercentWidget {
            let percentView = TouchDeckPercentWidgetView(
                config: itemConfig,
                snapshot: widgetSnapshots[itemConfig.id],
                onClick: { [weak self] in
                    self?.actionDispatcher.dispatch(item: itemConfig)
                }
            )
            customItem.view = percentView
            widgetUpdateHandlers[itemConfig.id] = { [weak percentView] config, snapshot in
                percentView?.update(config: config, snapshot: snapshot)
            }
            return customItem
        }

        let buttonView = TouchDeckButtonView(
            config: itemConfig,
            snapshot: widgetSnapshots[itemConfig.id],
            onClick: { [weak self] in
                if itemConfig.isLayoutSwitchButton {
                    self?.switchToNextLayout()
                    return
                }

                self?.actionDispatcher.dispatch(item: itemConfig)
            }
        )
        customItem.view = buttonView
        let title = itemConfig.touchBarTitle(snapshot: widgetSnapshots[itemConfig.id])
        customItem.customizationLabel = title.isEmpty
            ? itemConfig.accessibilityLabel(snapshot: widgetSnapshots[itemConfig.id])
            : title

        if case .widget = itemConfig.type {
            widgetUpdateHandlers[itemConfig.id] = { [weak buttonView, weak customItem] config, snapshot in
                let title = config.touchBarTitle(snapshot: snapshot)
                buttonView?.update(config: config, snapshot: snapshot)
                customItem?.customizationLabel = title.isEmpty ? config.accessibilityLabel(snapshot: snapshot) : title
            }
        }

        return customItem
    }

    private func currentItems() -> [TouchBarItemConfig] {
        currentPage()?.items.sorted { $0.position < $1.position } ?? []
    }

    private func currentPage() -> TouchBarPage? {
        let pages = profile.layout.pages.isEmpty ? [TouchBarPage()] : profile.layout.pages
        guard pages.indices.contains(currentLayoutIndex) else {
            return pages.first
        }

        return pages[currentLayoutIndex]
    }

    private func clampedLayoutIndex(_ index: Int) -> Int {
        let pageCount = max(profile.layout.pages.count, 1)
        return min(max(index, 0), pageCount - 1)
    }

    private func switchToNextLayout() {
        let pageCount = max(profile.layout.pages.count, 1)
        guard pageCount > 1 else {
            return
        }

        currentLayoutIndex = (currentLayoutIndex + 1) % pageCount
        refreshWidgetViews()
        onTouchBarNeedsRefresh?()
    }

    private static func itemIdentifier(for id: TouchBarItemConfig.ID) -> NSTouchBarItem.Identifier {
        NSTouchBarItem.Identifier(itemIdentifierPrefix + id.uuidString)
    }

    private static func itemIdentifier(for item: TouchBarItemConfig) -> NSTouchBarItem.Identifier {
        item.isNativeEmojiPicker ? .characterPicker : itemIdentifier(for: item.id)
    }

    private func itemConfig(for identifier: NSTouchBarItem.Identifier) -> TouchBarItemConfig? {
        let rawValue = identifier.rawValue
        guard rawValue.hasPrefix(Self.itemIdentifierPrefix) else {
            return nil
        }

        let uuidString = String(rawValue.dropFirst(Self.itemIdentifierPrefix.count))
        guard let id = UUID(uuidString: uuidString) else {
            return nil
        }

        return currentItems().first { $0.id == id }
    }

    private func configureDynamicRefreshTimer() {
        dynamicRefreshTimer?.invalidate()

        let hasDynamicItems = currentPage()?.items.contains { item in
            switch item.type {
            case .widget:
                true
            case .app, .system, .function, .spacer:
                false
            }
        } ?? false

        guard hasDynamicItems else {
            dynamicRefreshTimer = nil
            return
        }

        dynamicRefreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshWidgetViews()
            }
        }
    }

    private func refreshWidgetViews() {
        guard let page = currentPage() else {
            return
        }

        refreshLocalWidgetSnapshots(in: page)

        for item in page.items {
            switch item.type {
            case .widget:
                widgetUpdateHandlers[item.id]?(item, widgetSnapshots[item.id])
            case .app, .system, .function, .spacer:
                continue
            }
        }

        refreshWeatherSnapshotsIfNeeded(in: page)
    }

    private func refreshLocalWidgetSnapshots(in page: TouchBarPage) {
        for item in page.items {
            guard case .widget(let config) = item.type else {
                continue
            }

            if config.widgetId == "weather.current" {
                if widgetSnapshots[item.id] == nil {
                    widgetSnapshots[item.id] = statsProvider.snapshot(for: config.widgetId)
                }
                continue
            }

            if let snapshot = statsProvider.snapshot(for: config.widgetId) {
                widgetSnapshots[item.id] = snapshot
            }
        }
    }

    private func refreshWeatherSnapshotsIfNeeded(in page: TouchBarPage) {
        let now = Date()
        let weatherItems = page.items.filter { item in
            guard case .widget(let config) = item.type, config.widgetId == "weather.current" else {
                return false
            }

            if widgetSnapshots[item.id] == nil {
                return true
            }

            guard let lastRefresh = lastWeatherRefresh[item.id] else {
                return true
            }

            return now.timeIntervalSince(lastRefresh) >= 900
        }

        guard !weatherItems.isEmpty else {
            return
        }

        for item in weatherItems {
            lastWeatherRefresh[item.id] = now
        }

        let weatherProvider = weatherProvider
        Task {
            for item in weatherItems {
                guard case .widget(let config) = item.type else {
                    continue
                }

                let location = config.parameters["location"] ?? "San Francisco"
                guard let snapshot = await weatherProvider.snapshot(for: WeatherSnapshotRequest(location: location)) else {
                    continue
                }

                await MainActor.run { [weak self] in
                    self?.widgetSnapshots[item.id] = snapshot
                    self?.widgetUpdateHandlers[item.id]?(item, snapshot)
                }
            }
        }
    }
}

private final class TouchDeckSpacerView: NSView {
    init(size: ButtonSize) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: TouchDeckKeyMetrics.width(for: size)),
            heightAnchor.constraint(equalToConstant: TouchDeckKeyMetrics.height)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class TouchDeckButtonView: NSControl {
    private let imageView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let onClick: () -> Void
    private var widthConstraint: NSLayoutConstraint?

    init(config: TouchBarItemConfig, snapshot: WidgetSnapshot?, onClick: @escaping () -> Void) {
        self.onClick = onClick
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        applyTouchDeckKeyBackground()

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.lineBreakMode = .byClipping
        titleLabel.maximumNumberOfLines = 1

        addSubview(imageView)
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: TouchDeckKeyMetrics.height)
        ])

        update(config: config, snapshot: snapshot)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(config: TouchBarItemConfig, snapshot: WidgetSnapshot?) {
        let title = config.touchBarTitle(snapshot: snapshot)
        let isIconOnly = title.isEmpty
        let iconSize = Self.iconSize(for: config)

        imageView.image = config.touchBarImage(snapshot: snapshot, accessibilityDescription: config.accessibilityLabel(snapshot: snapshot))
        imageView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: iconSize, weight: .semibold)
        imageView.contentTintColor = config.usesAppIcon ? nil : .labelColor
        titleLabel.stringValue = title
        titleLabel.isHidden = isIconOnly

        widthConstraint?.isActive = false
        let nextWidthConstraint = widthAnchor.constraint(equalToConstant: TouchDeckKeyMetrics.width(for: config.normalizedSize))
        nextWidthConstraint.isActive = true
        widthConstraint = nextWidthConstraint

        NSLayoutConstraint.deactivate(constraints.filter { $0.identifier == "touchDeckButtonLayout" })
        let nextConstraints: [NSLayoutConstraint]

        if isIconOnly {
            nextConstraints = [
                imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: iconSize),
                imageView.heightAnchor.constraint(equalToConstant: iconSize)
            ]
        } else {
            nextConstraints = [
                imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: TouchDeckKeyMetrics.horizontalPadding),
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: iconSize),
                imageView.heightAnchor.constraint(equalToConstant: iconSize),
                titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: TouchDeckKeyMetrics.contentSpacing),
                titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -TouchDeckKeyMetrics.horizontalPadding),
                titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
            ]
        }

        nextConstraints.forEach { $0.identifier = "touchDeckButtonLayout" }
        NSLayoutConstraint.activate(nextConstraints)
        needsLayout = true
    }

    override func mouseDown(with event: NSEvent) {
        setTouchDeckKeyPressed(true)
        onClick()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.setTouchDeckKeyPressed(false)
        }
    }

    private static func iconSize(for config: TouchBarItemConfig) -> CGFloat {
        config.usesAppIcon ? 21 : 16
    }
}

private final class TouchDeckSliderCell: NSSliderCell {
    private let knobDiameter: CGFloat = 18
    private let knobIconSize: CGFloat = 11
    private let trackHeight: CGFloat = 4
    private let knobSymbolName: String

    init(knobSymbolName: String) {
        self.knobSymbolName = knobSymbolName
        super.init()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var knobThickness: CGFloat {
        knobDiameter
    }

    override func knobRect(flipped: Bool) -> NSRect {
        let rect = super.knobRect(flipped: flipped)
        let origin = CGPoint(
            x: rect.midX - knobDiameter / 2,
            y: rect.midY - knobDiameter / 2
        )

        return NSRect(origin: origin, size: CGSize(width: knobDiameter, height: knobDiameter))
    }

    override func drawBar(inside rect: NSRect, flipped: Bool) {
        let trackRect = NSRect(
            x: rect.minX,
            y: rect.midY - trackHeight / 2,
            width: rect.width,
            height: trackHeight
        )
        let progress = CGFloat((doubleValue - minValue) / max(maxValue - minValue, 0.0001))
        let fillRect = NSRect(
            x: trackRect.minX,
            y: trackRect.minY,
            width: trackRect.width * min(max(progress, 0), 1),
            height: trackRect.height
        )

        NSColor.white.withAlphaComponent(0.18).setFill()
        NSBezierPath(roundedRect: trackRect, xRadius: trackHeight / 2, yRadius: trackHeight / 2).fill()

        NSColor.white.withAlphaComponent(0.84).setFill()
        NSBezierPath(roundedRect: fillRect, xRadius: trackHeight / 2, yRadius: trackHeight / 2).fill()
    }

    override func drawKnob(_ knobRect: NSRect) {
        NSColor.white.withAlphaComponent(0.96).setFill()
        NSBezierPath(ovalIn: knobRect).fill()

        NSColor.black.withAlphaComponent(0.18).setStroke()
        let strokePath = NSBezierPath(ovalIn: knobRect.insetBy(dx: 0.5, dy: 0.5))
        strokePath.lineWidth = 1
        strokePath.stroke()

        guard let symbolImage = NSImage(systemSymbolName: knobSymbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: knobIconSize, weight: .semibold)) else {
            return
        }

        symbolImage.isTemplate = true
        NSColor.black.withAlphaComponent(0.72).set()
        let iconRect = NSRect(
            x: knobRect.midX - knobIconSize / 2,
            y: knobRect.midY - knobIconSize / 2,
            width: knobIconSize,
            height: knobIconSize
        )
        symbolImage.draw(
            in: iconRect,
            from: .zero,
            operation: .sourceOver,
            fraction: 1,
            respectFlipped: true,
            hints: nil
        )
    }
}

private final class TouchDeckSliderView: NSView {
    private let actionId: String
    private let onChange: (Double) -> Void

    init(config: TouchBarItemConfig, actionId: String, onChange: @escaping (Double) -> Void) {
        self.actionId = actionId
        self.onChange = onChange
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        applyTouchDeckKeyBackground()

        let slider = NSSlider(frame: .zero)
        slider.cell = TouchDeckSliderCell(knobSymbolName: Self.knobSymbolName(for: actionId))
        slider.minValue = 0
        slider.maxValue = 1
        slider.doubleValue = 0.5
        slider.target = self
        slider.action = #selector(handleSliderChange(_:))
        slider.isContinuous = true
        slider.controlSize = .small
        slider.translatesAutoresizingMaskIntoConstraints = false

        let stackView = NSStackView(views: [slider])
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.spacing = 0
        stackView.edgeInsets = NSEdgeInsets(
            top: 0,
            left: TouchDeckKeyMetrics.horizontalPadding,
            bottom: 0,
            right: TouchDeckKeyMetrics.horizontalPadding
        )
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: TouchDeckKeyMetrics.width(for: config.normalizedSize)),
            heightAnchor.constraint(equalToConstant: TouchDeckKeyMetrics.height),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleSliderChange(_ sender: NSSlider) {
        onChange(sender.doubleValue)
    }

    private static func knobSymbolName(for actionId: String) -> String {
        switch actionId {
        case "brightnessSlider":
            return "sun.max.fill"
        case "volumeSlider":
            return "speaker.wave.2.fill"
        default:
            return "circle.fill"
        }
    }
}

private final class TouchDeckPercentWidgetView: NSControl {
    private let valueLabel = NSTextField(labelWithString: "")
    private let onClick: () -> Void
    private var widthConstraint: NSLayoutConstraint?

    init(config: TouchBarItemConfig, snapshot: WidgetSnapshot?, onClick: @escaping () -> Void) {
        self.onClick = onClick
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        applyTouchDeckKeyBackground()

        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.alignment = .center
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 11.5, weight: .bold)
        valueLabel.textColor = .labelColor
        valueLabel.lineBreakMode = .byClipping
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(valueLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: TouchDeckKeyMetrics.height)
        ])

        update(config: config, snapshot: snapshot)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(config: TouchBarItemConfig, snapshot: WidgetSnapshot?) {
        valueLabel.stringValue = config.touchBarTitle(snapshot: snapshot)
        valueLabel.textColor = Self.percentColor(for: snapshot?.progress)

        widthConstraint?.isActive = false
        let nextConstraint = widthAnchor.constraint(equalToConstant: TouchDeckKeyMetrics.width(for: config.normalizedSize))
        nextConstraint.isActive = true
        widthConstraint = nextConstraint

        NSLayoutConstraint.deactivate(constraints.filter { $0.identifier == "percentWidgetLayout" })
        let nextConstraints: [NSLayoutConstraint]

        nextConstraints = [
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]

        nextConstraints.forEach { $0.identifier = "percentWidgetLayout" }
        NSLayoutConstraint.activate(nextConstraints)
    }

    override func mouseDown(with event: NSEvent) {
        setTouchDeckKeyPressed(true)
        onClick()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.setTouchDeckKeyPressed(false)
        }
    }

    private static func percentColor(for progress: Double?) -> NSColor {
        guard let progress else {
            return .labelColor
        }

        switch min(max(progress, 0), 1) {
        case ..<0.2:
            return NSColor.systemGreen
        case ..<0.4:
            return NSColor.systemMint
        case ..<0.6:
            return NSColor.systemYellow
        case ..<0.8:
            return NSColor.systemOrange
        default:
            return NSColor.systemRed
        }
    }
}

private enum TouchDeckKeyMetrics {
    static var cellWidth: CGFloat {
        CGFloat(TouchDeckCellMetrics.runtimeCellWidth)
    }

    static let interCellGap: CGFloat = 4
    static let height: CGFloat = 30
    static let cornerRadius: CGFloat = 7
    static let horizontalPadding: CGFloat = 5
    static let contentSpacing: CGFloat = 5

    static func width(for size: ButtonSize) -> CGFloat {
        CGFloat(size.rawValue) * cellWidth
    }
}

private extension NSView {
    func applyTouchDeckKeyBackground() {
        wantsLayer = true
        layer?.cornerRadius = TouchDeckKeyMetrics.cornerRadius
        layer?.cornerCurve = .continuous
        layer?.masksToBounds = false
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(0.22).cgColor
        layer?.backgroundColor = NSColor.white.withAlphaComponent(0.18).cgColor
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.18
        layer?.shadowRadius = 2
        layer?.shadowOffset = CGSize(width: 0, height: -0.5)
    }

    func setTouchDeckKeyHighlighted(_ isHighlighted: Bool) {
        layer?.backgroundColor = isHighlighted
            ? NSColor.white.withAlphaComponent(0.30).cgColor
            : NSColor.white.withAlphaComponent(0.18).cgColor
        layer?.borderColor = NSColor.white.withAlphaComponent(isHighlighted ? 0.30 : 0.22).cgColor
    }

    func setTouchDeckKeyPressed(_ isPressed: Bool) {
        layer?.backgroundColor = isPressed
            ? NSColor.white.withAlphaComponent(0.34).cgColor
            : NSColor.white.withAlphaComponent(0.18).cgColor
        layer?.borderColor = NSColor.white.withAlphaComponent(isPressed ? 0.34 : 0.22).cgColor
    }
}

private extension TouchBarItemConfig {
    var sliderSystemActionId: String? {
        guard case .system(let config) = type else {
            return nil
        }

        return ["volumeSlider", "brightnessSlider"].contains(config.actionId) ? config.actionId : nil
    }

    func touchBarTitle(snapshot: WidgetSnapshot?) -> String {
        switch type {
        case .system(let config):
            if isIconOnlyButton {
                return ""
            }

            return BuiltInSystemActionCatalog.definition(id: config.actionId)?.name ?? config.actionId
        case .app:
            return ""
        case .function(let config):
            if isIconOnlyButton {
                return ""
            }

            return BuiltInFunctionCatalog.definition(id: config.functionId)?.name ?? config.functionId
        case .widget(let config):
            if isIconOnlyButton {
                return ""
            }

            if isPercentWidget, let progress = snapshot?.progress {
                return SystemStatsProvider.percentString(progress)
            }

            return snapshot?.title
                    ?? BuiltInWidgetCatalog.definition(id: config.widgetId)?.name
                    ?? config.widgetId
        case .spacer:
            return ""
        }
    }

    func touchBarImage(snapshot: WidgetSnapshot?, accessibilityDescription: String) -> NSImage? {
        if case .app(let config) = type {
            if let appPath = config.appPath, !appPath.isEmpty {
                return NSWorkspace.shared.icon(forFile: appPath)
            }

            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: config.bundleIdentifier) {
                return NSWorkspace.shared.icon(forFile: appURL.path)
            }
        }

        return NSImage(systemSymbolName: symbolName(snapshot: snapshot), accessibilityDescription: accessibilityDescription)
    }

    func accessibilityLabel(snapshot: WidgetSnapshot?) -> String {
        switch type {
        case .system(let config):
            BuiltInSystemActionCatalog.definition(id: config.actionId)?.name ?? config.actionId
        case .app(let config):
            config.appName
        case .function(let config):
            BuiltInFunctionCatalog.definition(id: config.functionId)?.name ?? config.functionId
        case .widget(let config):
            BuiltInWidgetCatalog.definition(id: config.widgetId)?.name ?? snapshot?.title ?? config.widgetId
        case .spacer:
            "Spacer"
        }
    }

    func symbolName(snapshot: WidgetSnapshot?) -> String {
        switch type {
        case .system(let config):
            return BuiltInSystemActionCatalog.definition(id: config.actionId)?.symbolName ?? "gearshape"
        case .app:
            return "app"
        case .function(let config):
            return BuiltInFunctionCatalog.definition(id: config.functionId)?.symbolName ?? "bolt"
        case .widget(let config):
            return snapshot?.symbolName
                ?? BuiltInWidgetCatalog.definition(id: config.widgetId)?.symbolName
                ?? "chart.bar"
        case .spacer:
            return "rectangle.dashed"
        }
    }

    var usesAppIcon: Bool {
        if case .app = type {
            return true
        }

        return false
    }

    var isActiveKey: Bool {
        switch type {
        case .app, .function, .system, .widget, .spacer:
            return false
        }
    }

    private var isIconOnlyButton: Bool {
        switch type {
        case .system:
            return normalizedSize == .small
        case .function:
            return normalizedSize == .small
        case .widget:
            return normalizedSize == .small && !isPercentWidget
        case .app, .spacer:
            return false
        }
    }

    private var isPercentWidget: Bool {
        guard case .widget(let config) = type else {
            return false
        }

        return ["system.ram", "system.ssd", "system.cpu", "system.battery"].contains(config.widgetId)
    }

    var isNativeEmojiPicker: Bool {
        guard case .system(let config) = type else {
            return false
        }

        return config.actionId == "emoji"
    }

    var isLayoutSwitchButton: Bool {
        guard case .system(let config) = type else {
            return false
        }

        return config.actionId == "layoutSwitch"
    }

}
