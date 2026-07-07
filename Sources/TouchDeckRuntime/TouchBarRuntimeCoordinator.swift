import AppKit
import TouchDeckCore

@MainActor
public final class TouchBarRuntimeCoordinator {
    public let statusStore: RuntimeStatusStore

    private let renderer: TouchBarRenderer
    private let globalPresenter: GlobalTouchBarPresenter
    private let fallbackPresenter: AppActiveTouchBarPresenter
    private var observers: [NSObjectProtocol] = []
    private var isGlobalRuntimeEnabled = true

    public init(
        profile: TouchBarProfile,
        statusStore: RuntimeStatusStore = RuntimeStatusStore(),
        globalPresenter: GlobalTouchBarPresenter = GlobalTouchBarPresenter(),
        fallbackPresenter: AppActiveTouchBarPresenter = AppActiveTouchBarPresenter()
    ) {
        self.statusStore = statusStore
        self.renderer = TouchBarRenderer(profile: profile)
        self.globalPresenter = globalPresenter
        self.fallbackPresenter = fallbackPresenter
        self.renderer.onTouchBarNeedsRefresh = { [weak self] in
            self?.refreshPresentedTouchBars()
        }
    }

    public func startGlobalRuntime() {
        isGlobalRuntimeEnabled = true
        statusStore.update(.starting)
        installRecoveryObservers()
        startOrFallback()
    }

    public func stopGlobalRuntime() {
        isGlobalRuntimeEnabled = false
        globalPresenter.stop()
        fallbackPresenter.stop()
        statusStore.update(.stopped)
    }

    public func update(profile: TouchBarProfile) {
        renderer.update(profile: profile)

        if isGlobalRuntimeEnabled {
            do {
                try globalPresenter.update(touchBar: renderer.makeTouchBar())
                fallbackPresenter.update(touchBar: renderer.makeTouchBar())
                statusStore.update(.globalActive)
            } catch {
                fallbackPresenter.update(touchBar: renderer.makeTouchBar())
                statusStore.update(.fallbackAppActive("Global presenter failed: \(error.localizedDescription). TouchDeck is using App-Active fallback mode."))
            }
        } else {
            fallbackPresenter.update(touchBar: renderer.makeTouchBar())
        }
    }

    public func makeAppActiveTouchBar() -> NSTouchBar {
        let touchBar = renderer.makeTouchBar()
        fallbackPresenter.update(touchBar: touchBar)
        return touchBar
    }

    public func representGlobalRuntime() {
        guard isGlobalRuntimeEnabled else {
            return
        }

        globalPresenter.represent()
    }

    private func refreshPresentedTouchBars() {
        let touchBar = renderer.makeTouchBar()
        fallbackPresenter.update(touchBar: touchBar)

        guard isGlobalRuntimeEnabled else {
            return
        }

        do {
            try globalPresenter.update(touchBar: renderer.makeTouchBar())
            statusStore.update(.globalActive)
        } catch {
            statusStore.update(.fallbackAppActive("Global presenter failed: \(error.localizedDescription). TouchDeck is using App-Active fallback mode."))
        }
    }

    private func startOrFallback() {
        do {
            try globalPresenter.start(touchBar: renderer.makeTouchBar())
            fallbackPresenter.update(touchBar: renderer.makeTouchBar())
            statusStore.update(.globalActive)
        } catch {
            fallbackPresenter.update(touchBar: renderer.makeTouchBar())
            statusStore.update(.fallbackAppActive("Global presenter failed: \(error.localizedDescription). TouchDeck is using App-Active fallback mode."))
        }
    }

    private func installRecoveryObservers() {
        guard observers.isEmpty else {
            return
        }

        let workspaceNotifications = NSWorkspace.shared.notificationCenter
        observers.append(
            workspaceNotifications.addObserver(
                forName: NSWorkspace.didActivateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.recoverGlobalPresentation()
                }
            }
        )

        observers.append(
            workspaceNotifications.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.recoverGlobalPresentation()
                }
            }
        )

        observers.append(
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.screensDidWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.recoverGlobalPresentation()
                }
            }
        )
    }

    private func recoverGlobalPresentation() {
        guard isGlobalRuntimeEnabled else {
            return
        }

        if globalPresenter.isPresenting {
            globalPresenter.represent()
        } else {
            startOrFallback()
        }
    }
}
