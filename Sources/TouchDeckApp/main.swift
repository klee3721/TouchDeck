import AppKit
import Combine
import SwiftUI
import TouchDeckCore
import TouchDeckRuntime
import TouchDeckStudio

let app = NSApplication.shared
let delegate = TouchDeckAppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()

@MainActor
final class TouchDeckAppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: TouchDeckWindowController?
    private var statusItem: NSStatusItem?
    private let profileStore = ProfileStore.defaultStore()
    private let profileSyncBridge = StudioProfileSyncBridge()
    private var runtimeCoordinator: TouchBarRuntimeCoordinator?
    private var runtimeStatusCancellable: AnyCancellable?
    private var runtimeStatusMenuItem: NSMenuItem?
    private var startRuntimeMenuItem: NSMenuItem?
    private var stopRuntimeMenuItem: NSMenuItem?
    private var representRuntimeMenuItem: NSMenuItem?
    private var profiles = [SampleData.defaultProfile]
    private var profile = SampleData.defaultProfile
    private var appActivationObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        loadInitialProfiles()
        startRuntime()
        configureMenuBar()
        observeAppActivation()
        showStudio()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @objc private func showStudio() {
        if windowController == nil {
            windowController = TouchDeckWindowController(
                profile: profile,
                profiles: profiles,
                profileStore: profileStore,
                profileSyncBridge: profileSyncBridge,
                runtimeCoordinator: runtimeCoordinator
            ) { [weak self] updatedProfiles, selectedProfile in
                self?.profiles = updatedProfiles
                self?.profile = selectedProfile
                self?.runtimeCoordinator?.update(profile: selectedProfile)
            }
        }

        windowController?.showStudioWindow()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    @objc private func startRuntimeFromMenu() {
        runtimeCoordinator?.startGlobalRuntime()
        updateRuntimeMenuItems()
    }

    @objc private func stopRuntimeFromMenu() {
        runtimeCoordinator?.stopGlobalRuntime()
        updateRuntimeMenuItems()
    }

    @objc private func representRuntimeFromMenu() {
        runtimeCoordinator?.representGlobalRuntime()
        updateRuntimeMenuItems()
    }

    private func configureMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "rectangle.on.rectangle", accessibilityDescription: "TouchDeck")
        item.button?.imagePosition = .imageOnly

        let menu = NSMenu()

        let runtimeStatusMenuItem = NSMenuItem(title: "Runtime: Starting", action: nil, keyEquivalent: "")
        runtimeStatusMenuItem.isEnabled = false
        menu.addItem(runtimeStatusMenuItem)
        self.runtimeStatusMenuItem = runtimeStatusMenuItem

        let startRuntimeMenuItem = NSMenuItem(title: "Start Global Runtime", action: #selector(startRuntimeFromMenu), keyEquivalent: "r")
        startRuntimeMenuItem.target = self
        menu.addItem(startRuntimeMenuItem)
        self.startRuntimeMenuItem = startRuntimeMenuItem

        let stopRuntimeMenuItem = NSMenuItem(title: "Stop Runtime", action: #selector(stopRuntimeFromMenu), keyEquivalent: "")
        stopRuntimeMenuItem.target = self
        menu.addItem(stopRuntimeMenuItem)
        self.stopRuntimeMenuItem = stopRuntimeMenuItem

        let representRuntimeMenuItem = NSMenuItem(title: "Re-present Touch Bar", action: #selector(representRuntimeFromMenu), keyEquivalent: "")
        representRuntimeMenuItem.target = self
        menu.addItem(representRuntimeMenuItem)
        self.representRuntimeMenuItem = representRuntimeMenuItem

        menu.addItem(.separator())

        let openStudioItem = NSMenuItem(title: "Open TouchDeck Studio", action: #selector(showStudio), keyEquivalent: "o")
        openStudioItem.target = self
        menu.addItem(openStudioItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit TouchDeck", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        item.menu = menu

        statusItem = item
        updateRuntimeMenuItems()
    }

    private func loadInitialProfiles() {
        do {
            profiles = try profileStore.load()
        } catch {
            profiles = [SampleData.defaultProfile]
        }

        if profiles.isEmpty {
            profiles = [SampleData.defaultProfile]
        }

        profile = ProfileSelection.effectiveProfile(
            from: profiles,
            frontmostBundleIdentifier: NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        )
    }

    private func startRuntime() {
        let runtimeCoordinator = TouchBarRuntimeCoordinator(profile: profile)
        self.runtimeCoordinator = runtimeCoordinator
        runtimeStatusCancellable = runtimeCoordinator.statusStore.$state.sink { [weak self] _ in
            self?.updateRuntimeMenuItems()
        }
        runtimeCoordinator.startGlobalRuntime()
    }

    private func updateRuntimeMenuItems() {
        guard let state = runtimeCoordinator?.statusStore.state else {
            runtimeStatusMenuItem?.title = "Runtime: Unavailable"
            startRuntimeMenuItem?.isEnabled = false
            stopRuntimeMenuItem?.isEnabled = false
            representRuntimeMenuItem?.isEnabled = false
            return
        }

        runtimeStatusMenuItem?.title = "Runtime: \(state.title)"
        startRuntimeMenuItem?.isEnabled = state != .globalActive && state != .starting
        stopRuntimeMenuItem?.isEnabled = state != .stopped
        representRuntimeMenuItem?.isEnabled = state == .globalActive
        statusItem?.button?.toolTip = "TouchDeck Runtime: \(state.title)"
    }

    private func observeAppActivation() {
        appActivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let runningApplication = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                return
            }

            Task { @MainActor in
                self?.activateProfile(for: runningApplication.bundleIdentifier)
            }
        }
    }

    private func activateProfile(for bundleIdentifier: String?) {
        let nextProfile = ProfileSelection.effectiveProfile(
            from: profiles,
            frontmostBundleIdentifier: bundleIdentifier
        )

        guard nextProfile.id != profile.id else {
            return
        }

        profile = nextProfile
        runtimeCoordinator?.update(profile: nextProfile)
        profileSyncBridge.select(profiles: profiles, profile: nextProfile)
        windowController?.updateTouchBar()
    }
}

@MainActor
final class TouchDeckWindowController: NSWindowController {
    private let runtimeCoordinator: TouchBarRuntimeCoordinator?

    init(
        profile: TouchBarProfile,
        profiles: [TouchBarProfile],
        profileStore: ProfileStore,
        profileSyncBridge: StudioProfileSyncBridge,
        runtimeCoordinator: TouchBarRuntimeCoordinator?,
        onProfilesChange: @escaping ([TouchBarProfile], TouchBarProfile) -> Void
    ) {
        self.runtimeCoordinator = runtimeCoordinator

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1320, height: 820),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "TouchDeck"
        window.minSize = NSSize(width: 1280, height: 740)
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .unified
        window.center()

        super.init(window: window)

        window.contentViewController = NSHostingController(
            rootView: StudioRootView(
                profile: profile,
                profiles: profiles,
                profileStore: profileStore,
                profileSyncBridge: profileSyncBridge,
                runtimeStatusStore: runtimeCoordinator?.statusStore,
                onStartRuntime: {
                    runtimeCoordinator?.startGlobalRuntime()
                },
                onStopRuntime: {
                    runtimeCoordinator?.stopGlobalRuntime()
                },
                onProfilesChange: { [weak self] updatedProfiles, updatedProfile in
                    onProfilesChange(updatedProfiles, updatedProfile)
                    self?.updateTouchBar()
                }
            )
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func makeTouchBar() -> NSTouchBar? {
        runtimeCoordinator?.makeAppActiveTouchBar()
    }

    func updateTouchBar() {
        touchBar = runtimeCoordinator?.makeAppActiveTouchBar()
    }

    func showStudioWindow() {
        showWindow(nil)
        if let window, window.frame.width < 1280 || window.frame.height < 740 {
            window.setContentSize(NSSize(width: 1320, height: 820))
            window.center()
        }
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()

        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
