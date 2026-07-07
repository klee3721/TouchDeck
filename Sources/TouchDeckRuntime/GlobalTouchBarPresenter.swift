import AppKit
import Darwin

@MainActor
public protocol TouchBarPresenting: AnyObject {
    var isPresenting: Bool { get }

    func start(touchBar: NSTouchBar) throws
    func update(touchBar: NSTouchBar) throws
    func stop()
    func represent()
}

public struct TouchBarPresenterError: LocalizedError, Equatable {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var errorDescription: String? {
        message
    }
}

@MainActor
public final class GlobalTouchBarPresenter: NSObject, TouchBarPresenting {
    private static let controlStripIdentifier = NSTouchBarItem.Identifier("com.touchdeck.controlStrip")

    private var touchBar: NSTouchBar?
    private var trayItem: NSCustomTouchBarItem?
    private var privateAPI = PrivateTouchBarAPI()

    public private(set) var isPresenting = false

    public override init() {
        super.init()
    }

    public func start(touchBar: NSTouchBar) throws {
        try privateAPI.validate()
        self.touchBar = touchBar
        try installTrayItemIfNeeded()
        try present(touchBar)
        isPresenting = true
    }

    public func update(touchBar: NSTouchBar) throws {
        self.touchBar = touchBar
        guard isPresenting else {
            try start(touchBar: touchBar)
            return
        }

        try present(touchBar)
    }

    public func stop() {
        if let touchBar {
            privateAPI.dismissSystemModal(touchBar)
        }

        if let trayItem {
            privateAPI.removeSystemTrayItem(trayItem)
        }

        privateAPI.setControlStripPresence(Self.controlStripIdentifier, false)
        trayItem = nil
        touchBar = nil
        isPresenting = false
    }

    public func represent() {
        guard let touchBar, isPresenting else {
            return
        }

        try? present(touchBar)
    }

    @objc private func presentFromControlStrip() {
        represent()
    }

    private func installTrayItemIfNeeded() throws {
        guard trayItem == nil else {
            privateAPI.setControlStripPresence(Self.controlStripIdentifier, true)
            return
        }

        let item = NSCustomTouchBarItem(identifier: Self.controlStripIdentifier)
        let image = NSImage(systemSymbolName: "rectangle.on.rectangle", accessibilityDescription: "TouchDeck")
        let button = NSButton(image: image ?? NSImage(), target: self, action: #selector(presentFromControlStrip))
        button.isBordered = false
        button.imageScaling = .scaleProportionallyDown
        button.wantsLayer = true
        button.layer?.cornerRadius = 8
        button.layer?.cornerCurve = .continuous
        button.layer?.borderWidth = 1
        button.layer?.borderColor = NSColor.white.withAlphaComponent(0.22).cgColor
        button.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.18).cgColor
        item.view = button

        try privateAPI.addSystemTrayItem(item)
        privateAPI.setSystemModalShowsCloseBoxWhenFrontMost(false)
        privateAPI.setControlStripPresence(Self.controlStripIdentifier, true)
        trayItem = item
    }

    private func present(_ touchBar: NSTouchBar) throws {
        try privateAPI.presentSystemModal(touchBar, systemTrayItemIdentifier: Self.controlStripIdentifier)
        privateAPI.setControlStripPresence(Self.controlStripIdentifier, true)
    }
}

@MainActor
public final class AppActiveTouchBarPresenter: TouchBarPresenting {
    public private(set) var isPresenting = false
    private var touchBar: NSTouchBar?

    public init() {}

    public func start(touchBar: NSTouchBar) {
        self.touchBar = touchBar
        isPresenting = true
    }

    public func update(touchBar: NSTouchBar) {
        self.touchBar = touchBar
        isPresenting = true
    }

    public func stop() {
        touchBar = nil
        isPresenting = false
    }

    public func represent() {}
}

private struct PrivateTouchBarAPI {
    private typealias DFRControlStripPresence = @convention(c) (NSString, Bool) -> Void
    private typealias DFRSystemCloseBox = @convention(c) (Bool) -> Void
    private typealias ObjCMessageSendWithPlacement = @convention(c) (
        AnyClass,
        Selector,
        NSTouchBar,
        Int64,
        NSString
    ) -> Void

    private let dfrHandle: UnsafeMutableRawPointer?
    private let systemModalPlacement: Int64 = 1
    private let addSystemTrayItemSelector = NSSelectorFromString("addSystemTrayItem:")
    private let removeSystemTrayItemSelector = NSSelectorFromString("removeSystemTrayItem:")
    private let presentTouchBarWithPlacementSelector = NSSelectorFromString("presentSystemModalTouchBar:placement:systemTrayItemIdentifier:")
    private let presentTouchBarSelector = NSSelectorFromString("presentSystemModalTouchBar:systemTrayItemIdentifier:")
    private let presentFunctionBarWithPlacementSelector = NSSelectorFromString("presentSystemModalFunctionBar:placement:systemTrayItemIdentifier:")
    private let presentFunctionBarSelector = NSSelectorFromString("presentSystemModalFunctionBar:systemTrayItemIdentifier:")
    private let dismissTouchBarSelector = NSSelectorFromString("dismissSystemModalTouchBar:")
    private let dismissFunctionBarSelector = NSSelectorFromString("dismissSystemModalFunctionBar:")

    init() {
        dfrHandle = dlopen("/System/Library/PrivateFrameworks/DFRFoundation.framework/DFRFoundation", RTLD_LAZY)
    }

    func validate() throws {
        guard dfrHandle != nil else {
            throw TouchBarPresenterError("DFRFoundation private framework is not available on this Mac.")
        }

        guard NSTouchBarItem.responds(to: addSystemTrayItemSelector) else {
            throw TouchBarPresenterError("NSTouchBarItem.addSystemTrayItem is not available on this macOS version.")
        }

        guard NSTouchBar.responds(to: presentTouchBarWithPlacementSelector)
            || NSTouchBar.responds(to: presentTouchBarSelector)
            || NSTouchBar.responds(to: presentFunctionBarWithPlacementSelector)
            || NSTouchBar.responds(to: presentFunctionBarSelector) else {
            throw TouchBarPresenterError("System modal Touch Bar presentation API is not available.")
        }
    }

    func addSystemTrayItem(_ item: NSTouchBarItem) throws {
        guard NSTouchBarItem.responds(to: addSystemTrayItemSelector) else {
            throw TouchBarPresenterError("Cannot add TouchDeck to the Control Strip on this macOS version.")
        }

        NSTouchBarItem.perform(addSystemTrayItemSelector, with: item)
    }

    func removeSystemTrayItem(_ item: NSTouchBarItem) {
        guard NSTouchBarItem.responds(to: removeSystemTrayItemSelector) else {
            return
        }

        NSTouchBarItem.perform(removeSystemTrayItemSelector, with: item)
    }

    func presentSystemModal(_ touchBar: NSTouchBar, systemTrayItemIdentifier identifier: NSTouchBarItem.Identifier) throws {
        if NSTouchBar.responds(to: presentTouchBarWithPlacementSelector) {
            try performPresentWithPlacement(
                presentTouchBarWithPlacementSelector,
                touchBar: touchBar,
                placement: systemModalPlacement,
                identifier: identifier.rawValue as NSString
            )
            return
        }

        if NSTouchBar.responds(to: presentFunctionBarWithPlacementSelector) {
            try performPresentWithPlacement(
                presentFunctionBarWithPlacementSelector,
                touchBar: touchBar,
                placement: systemModalPlacement,
                identifier: identifier.rawValue as NSString
            )
            return
        }

        if NSTouchBar.responds(to: presentTouchBarSelector) {
            NSTouchBar.perform(presentTouchBarSelector, with: touchBar, with: identifier.rawValue as NSString)
            return
        }

        if NSTouchBar.responds(to: presentFunctionBarSelector) {
            NSTouchBar.perform(presentFunctionBarSelector, with: touchBar, with: identifier.rawValue as NSString)
            return
        }

        throw TouchBarPresenterError("System modal Touch Bar presentation API is not available.")
    }

    private func performPresentWithPlacement(
        _ selector: Selector,
        touchBar: NSTouchBar,
        placement: Int64,
        identifier: NSString
    ) throws {
        guard
            let objcHandle = dlopen(nil, RTLD_LAZY),
            let symbol = dlsym(objcHandle, "objc_msgSend")
        else {
            throw TouchBarPresenterError("Cannot resolve objc_msgSend for Touch Bar placement presentation.")
        }

        let message = unsafeBitCast(symbol, to: ObjCMessageSendWithPlacement.self)
        message(NSTouchBar.self, selector, touchBar, placement, identifier)
    }

    func dismissSystemModal(_ touchBar: NSTouchBar) {
        if NSTouchBar.responds(to: dismissTouchBarSelector) {
            NSTouchBar.perform(dismissTouchBarSelector, with: touchBar)
            return
        }

        if NSTouchBar.responds(to: dismissFunctionBarSelector) {
            NSTouchBar.perform(dismissFunctionBarSelector, with: touchBar)
        }
    }

    func setControlStripPresence(_ identifier: NSTouchBarItem.Identifier, _ isVisible: Bool) {
        guard let symbol = dlsym(dfrHandle, "DFRElementSetControlStripPresenceForIdentifier") else {
            return
        }

        let function = unsafeBitCast(symbol, to: DFRControlStripPresence.self)
        function(identifier.rawValue as NSString, isVisible)
    }

    func setSystemModalShowsCloseBoxWhenFrontMost(_ isVisible: Bool) {
        guard let symbol = dlsym(dfrHandle, "DFRSystemModalShowsCloseBoxWhenFrontMost") else {
            return
        }

        let function = unsafeBitCast(symbol, to: DFRSystemCloseBox.self)
        function(isVisible)
    }
}
