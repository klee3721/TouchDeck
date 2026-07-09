import AppKit
import ApplicationServices
import CoreAudio
import Foundation
import IOKit
import IOKit.graphics
import OSLog
import TouchDeckCore

@MainActor
public final class ActionDispatcher {
    private let logger = Logger(subsystem: "com.touchdeck.app", category: "ActionDispatcher")
    private var didRequestAccessibilityPermission = false
    private var lastBrightnessFallbackStep: Int?
    private var lastBrightnessFallbackDate = Date.distantPast
    private var pendingBrightnessFallbackStep: Int?
    private var brightnessFallbackTask: Task<Void, Never>?
    private let brightnessFallbackInterval: TimeInterval = 0.06

    public init() {}

    public func dispatch(item: TouchBarItemConfig) {
        switch item.type {
        case .app(let config):
            logger.info("Dispatch app button: \(config.bundleIdentifier, privacy: .public)")
            activateOrLaunchApp(config)
        case .function(let config):
            logger.info("Dispatch function button: \(config.functionId, privacy: .public)")
            runFunction(config)
        case .system(let config):
            logger.info("Dispatch system button: \(config.actionId, privacy: .public)")
            runSystemAction(config)
        case .widget(let config):
            logger.info("Dispatch widget button: \(config.widgetId, privacy: .public)")
            runWidgetAction(config)
        case .spacer:
            break
        }
    }

    public func dispatchSystemSlider(actionId: String, value: Double) {
        let clampedValue = min(max(value, 0), 1)

        switch actionId {
        case "volumeSlider":
            logger.debug("Dispatch volume slider: \(clampedValue, privacy: .public)")
            setOutputVolume(clampedValue)
        case "brightnessSlider":
            logger.debug("Dispatch brightness slider: \(clampedValue, privacy: .public)")
            setDisplayBrightness(clampedValue)
        default:
            break
        }
    }

    public func currentSystemSliderValue(actionId: String) -> Double? {
        switch actionId {
        case "volumeSlider":
            return currentOutputVolume()
        case "brightnessSlider":
            return currentDisplayBrightness()
        default:
            return nil
        }
    }

    private func activateOrLaunchApp(_ config: AppButtonConfig) {
        let appURL = applicationURL(
            bundleIdentifier: config.bundleIdentifier,
            path: config.appPath
        )

        if activateRunningApplication(bundleIdentifier: config.bundleIdentifier) {
            if let appURL {
                openOrReopenApplication(at: appURL)
            }
            return
        }

        guard let appURL else {
            logger.error("Unable to find app for bundle id: \(config.bundleIdentifier, privacy: .public)")
            return
        }

        openOrReopenApplication(at: appURL)
    }

    @discardableResult
    private func activateRunningApplication(
        bundleIdentifier: String? = nil,
        appURL: URL? = nil
    ) -> Bool {
        let runningApp: NSRunningApplication?

        if let bundleIdentifier {
            runningApp = NSRunningApplication
                .runningApplications(withBundleIdentifier: bundleIdentifier)
                .first
        } else if let appURL {
            let standardizedAppURL = appURL.standardizedFileURL
            runningApp = NSWorkspace.shared.runningApplications.first {
                $0.bundleURL?.standardizedFileURL == standardizedAppURL
            }
        } else {
            runningApp = nil
        }

        guard let runningApp else {
            return false
        }

        runningApp.unhide()
        let didActivate = runningApp.activate(options: [.activateAllWindows])

        if !didActivate {
            logger.warning("Unable to activate running app: \(runningApp.bundleIdentifier ?? "unknown", privacy: .public)")
        }

        return didActivate
    }

    private func runFunction(_ config: FunctionButtonConfig) {
        switch config.functionId {
        case "clipboard.copy":
            sendCommandShortcut(keyCode: KeyboardKey.c)
        case "clipboard.paste":
            sendCommandShortcut(keyCode: KeyboardKey.v)
        case "clipboard.controlPaste":
            sendKeyPress(keyCode: KeyboardKey.v, flags: .maskControl)
        case "clipboard.cut":
            sendCommandShortcut(keyCode: KeyboardKey.x)
        case "edit.undo":
            sendCommandShortcut(keyCode: KeyboardKey.z)
        case "edit.redo":
            sendCommandShortcut(keyCode: KeyboardKey.z, flags: [.maskCommand, .maskShift])
        case "edit.selectAll":
            sendCommandShortcut(keyCode: KeyboardKey.a)
        case "open.url":
            openURL(config.parameters["url"])
        case "open.app":
            openApp(identifierOrPath: config.parameters["bundleIdentifier"])
        case "open.file", "open.folder":
            openFilePath(config.parameters["path"])
        case "keyboard.shortcut":
            sendKeyboardShortcut(config.parameters["shortcut"])
        case "shell.run":
            runShellCommand(config.parameters["command"])
        case "applescript.run":
            runAppleScript(config.parameters["source"])
        case "shortcut.run":
            runMacOSShortcut(config.parameters["name"])
        case "currentApp.hide":
            hideCurrentApp()
        case "currentApp.quit":
            quitCurrentApp(force: false)
        case "currentApp.kill":
            sendCommandShortcut(keyCode: KeyboardKey.q)
        default:
            break
        }
    }

    private func runSystemAction(_ config: SystemButtonConfig) {
        switch config.actionId {
        case "escape":
            sendKeyPress(keyCode: KeyboardKey.escape)
        case "volumeUp":
            sendMediaKey(.volumeUp)
        case "volumeDown":
            sendMediaKey(.volumeDown)
        case "mute":
            sendMediaKey(.mute)
        case "brightnessUp":
            sendMediaKey(.brightnessUp)
        case "brightnessDown":
            sendMediaKey(.brightnessDown)
        case "keyboardBrightnessUp":
            sendMediaKey(.keyboardBrightnessUp)
        case "keyboardBrightnessDown":
            sendMediaKey(.keyboardBrightnessDown)
        case "playPause":
            sendMediaKey(.playPause)
        case "nextTrack":
            sendMediaKey(.nextTrack)
        case "previousTrack":
            sendMediaKey(.previousTrack)
        case "missionControl":
            openSystemApp(path: "/System/Applications/Mission Control.app")
        case "launchpad":
            sendKeyPress(keyCode: KeyboardKey.launchpad)
        case "screenshotFull":
            sendKeyPress(keyCode: KeyboardKey.three, flags: [.maskCommand, .maskShift])
        case "screenshotSelection":
            sendKeyPress(keyCode: KeyboardKey.four, flags: [.maskCommand, .maskShift])
        case "screenshot":
            sendKeyPress(keyCode: KeyboardKey.five, flags: [.maskCommand, .maskShift])
        case "emoji":
            sendKeyPress(keyCode: KeyboardKey.space, flags: [.maskCommand, .maskControl])
        case "dictation":
            sendKeyPress(keyCode: KeyboardKey.fn)
        case "siri":
            openApp(identifierOrPath: "com.apple.Siri")
        case "lockScreen":
            lockScreen()
        case "sleep":
            runAppleScript("tell application \"System Events\" to sleep")
        default:
            break
        }
    }

    private func openURL(_ rawURL: String?) {
        guard
            let rawURL,
            let url = URL(string: rawURL)
        else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    private func runWidgetAction(_ config: WidgetButtonConfig) {
        switch config.widgetId {
        case "system.ram":
            openApp(identifierOrPath: "com.apple.ActivityMonitor")
        default:
            break
        }
    }

    private func openSystemApp(path: String) {
        let url = URL(fileURLWithPath: path)

        if activateRunningApplication(appURL: url) {
            openOrReopenApplication(at: url)
            return
        }

        openOrReopenApplication(at: url)
    }

    private func openApp(identifierOrPath: String?) {
        guard let identifierOrPath = trimmed(identifierOrPath) else {
            return
        }

        let appURL: URL?
        if identifierOrPath.hasPrefix("/") {
            let pathAppURL = URL(fileURLWithPath: identifierOrPath)
            appURL = pathAppURL
            if activateRunningApplication(appURL: pathAppURL) {
                openOrReopenApplication(at: pathAppURL)
                return
            }
        } else {
            appURL = applicationURL(bundleIdentifier: identifierOrPath)

            if activateRunningApplication(bundleIdentifier: identifierOrPath) {
                if let appURL {
                    openOrReopenApplication(at: appURL)
                }
                return
            }
        }

        guard let appURL else {
            logger.error("Unable to find app for identifier or path: \(identifierOrPath, privacy: .public)")
            return
        }

        openOrReopenApplication(at: appURL)
    }

    private func applicationURL(bundleIdentifier: String, path: String? = nil) -> URL? {
        if let path = trimmed(path) {
            let url = URL(fileURLWithPath: NSString(string: path).expandingTildeInPath)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        if let workspaceURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            return workspaceURL
        }

        if let discoveredApp = AppDiscovery()
            .discoverInstalledApps()
            .first(where: { $0.bundleIdentifier == bundleIdentifier }) {
            return URL(fileURLWithPath: discoveredApp.path)
        }

        return nil
    }

    private func openOrReopenApplication(at appURL: URL) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { [weak self] _, error in
            if let error {
                self?.logger.error("Unable to open app at \(appURL.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func openFilePath(_ path: String?) {
        guard let path = trimmed(path) else {
            return
        }

        NSWorkspace.shared.open(URL(fileURLWithPath: NSString(string: path).expandingTildeInPath))
    }

    private func runShellCommand(_ command: String?) {
        guard
            let command,
            !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", command]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        try? process.run()
    }

    private func runAppleScript(_ source: String?) {
        guard
            let source,
            !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return
        }

        var errorInfo: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&errorInfo)

        if let errorInfo {
            logger.error("AppleScript failed: \(String(describing: errorInfo), privacy: .public)")
        }
    }

    private func setOutputVolume(_ ratio: Double) {
        if setCoreAudioOutputVolume(ratio) {
            return
        }

        let volume = Int((ratio * 100).rounded())
        runAppleScript("set volume output volume \(volume)")
    }

    private func setDisplayBrightness(_ ratio: Double) {
        let clampedRatio = min(max(ratio, 0), 1)

        if setIODisplayBrightness(clampedRatio) {
            lastBrightnessFallbackStep = nil
            pendingBrightnessFallbackStep = nil
            brightnessFallbackTask?.cancel()
            brightnessFallbackTask = nil
            return
        }

        scheduleMediaKeyBrightnessFallback(clampedRatio)
    }

    private func scheduleMediaKeyBrightnessFallback(_ ratio: Double) {
        pendingBrightnessFallbackStep = Int((ratio * 16).rounded())

        guard brightnessFallbackTask == nil else {
            return
        }

        applyPendingMediaKeyBrightnessStep()
    }

    private func applyPendingMediaKeyBrightnessStep() {
        let elapsed = Date().timeIntervalSince(lastBrightnessFallbackDate)

        if elapsed < brightnessFallbackInterval {
            let delay = brightnessFallbackInterval - elapsed
            brightnessFallbackTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                self?.brightnessFallbackTask = nil
                self?.applyPendingMediaKeyBrightnessStep()
            }
            return
        }

        guard let targetStep = pendingBrightnessFallbackStep else {
            brightnessFallbackTask = nil
            return
        }

        pendingBrightnessFallbackStep = nil
        applyMediaKeyBrightnessStep(targetStep)

        if pendingBrightnessFallbackStep != nil {
            applyPendingMediaKeyBrightnessStep()
        }
    }

    private func applyMediaKeyBrightnessStep(_ targetStep: Int) {
        let clampedTargetStep = min(max(targetStep, 0), 16)

        let previousStep = lastBrightnessFallbackStep ?? currentBacklightBrightnessStep()

        guard let previousStep else {
            for _ in 0..<16 {
                sendMediaKey(.brightnessDown)
            }

            for _ in 0..<clampedTargetStep {
                sendMediaKey(.brightnessUp)
            }

            lastBrightnessFallbackStep = clampedTargetStep
            lastBrightnessFallbackDate = Date()
            return
        }

        let delta = clampedTargetStep - previousStep

        if delta > 0 {
            for _ in 0..<delta {
                sendMediaKey(.brightnessUp)
            }
        } else if delta < 0 {
            for _ in 0..<abs(delta) {
                sendMediaKey(.brightnessDown)
            }
        }

        lastBrightnessFallbackStep = clampedTargetStep
        lastBrightnessFallbackDate = Date()
    }

    private func currentDisplayBrightness() -> Double? {
        currentIODisplayBrightness() ?? currentBacklightBrightnessRatio()
    }

    private func currentBacklightBrightnessStep() -> Int? {
        guard let ratio = currentBacklightBrightnessRatio() else {
            return nil
        }

        return Int((ratio * 16).rounded())
    }

    private func currentBacklightBrightnessRatio() -> Double? {
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("AppleARMBacklight"),
            &iterator
        )

        guard result == kIOReturnSuccess else {
            return nil
        }

        defer {
            IOObjectRelease(iterator)
        }

        var bestRatio: Double?

        while true {
            let service = IOIteratorNext(iterator)
            guard service != IO_OBJECT_NULL else {
                break
            }

            defer {
                IOObjectRelease(service)
            }

            guard
                let displayParameters = IORegistryEntryCreateCFProperty(
                    service,
                    "IODisplayParameters" as CFString,
                    kCFAllocatorDefault,
                    0
                )?.takeRetainedValue() as? [String: Any],
                let brightness = displayParameters["brightness"] as? [String: Any],
                let value = brightness["value"] as? NSNumber,
                let maxValue = brightness["max"] as? NSNumber,
                maxValue.doubleValue > 0
            else {
                continue
            }

            let ratio = min(max(value.doubleValue / maxValue.doubleValue, 0), 1)
            bestRatio = max(bestRatio ?? ratio, ratio)
        }

        guard let bestRatio else {
            return nil
        }

        return bestRatio
    }

    private func currentIODisplayBrightness() -> Double? {
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IODisplayConnect"),
            &iterator
        )

        guard result == kIOReturnSuccess else {
            return nil
        }

        defer {
            IOObjectRelease(iterator)
        }

        var bestRatio: Double?

        while true {
            let service = IOIteratorNext(iterator)
            guard service != IO_OBJECT_NULL else {
                break
            }

            defer {
                IOObjectRelease(service)
            }

            var brightness = Float(0)
            let status = IODisplayGetFloatParameter(
                service,
                0,
                kIODisplayBrightnessKey as CFString,
                &brightness
            )

            guard status == kIOReturnSuccess else {
                continue
            }

            let ratio = min(max(Double(brightness), 0), 1)
            bestRatio = max(bestRatio ?? ratio, ratio)
        }

        return bestRatio
    }

    private func setIODisplayBrightness(_ ratio: Double) -> Bool {
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IODisplayConnect"),
            &iterator
        )

        guard result == kIOReturnSuccess else {
            return false
        }

        defer {
            IOObjectRelease(iterator)
        }

        let brightness = Float(min(max(ratio, 0), 1))
        var didSetBrightness = false

        while true {
            let service = IOIteratorNext(iterator)
            guard service != IO_OBJECT_NULL else {
                break
            }

            defer {
                IOObjectRelease(service)
            }

            let status = IODisplaySetFloatParameter(
                service,
                0,
                kIODisplayBrightnessKey as CFString,
                brightness
            )

            didSetBrightness = didSetBrightness || status == kIOReturnSuccess
        }

        return didSetBrightness
    }

    private func setCoreAudioOutputVolume(_ ratio: Double) -> Bool {
        guard let defaultDevice = defaultOutputDevice() else {
            return false
        }

        var volume = Float32(min(max(ratio, 0), 1))
        let volumeSize = UInt32(MemoryLayout<Float32>.size)
        var didSetAnyChannel = false
        var volumeAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        if AudioObjectHasProperty(defaultDevice, &volumeAddress) {
            let status = AudioObjectSetPropertyData(defaultDevice, &volumeAddress, 0, nil, volumeSize, &volume)
            if status == noErr {
                return true
            }
        }

        for channel in 1...2 {
            volumeAddress.mElement = AudioObjectPropertyElement(channel)
            guard AudioObjectHasProperty(defaultDevice, &volumeAddress) else {
                continue
            }

            let status = AudioObjectSetPropertyData(defaultDevice, &volumeAddress, 0, nil, volumeSize, &volume)
            didSetAnyChannel = didSetAnyChannel || status == noErr
        }

        return didSetAnyChannel
    }

    private func currentOutputVolume() -> Double? {
        guard let defaultDevice = defaultOutputDevice() else {
            return nil
        }

        var volumeAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        if let volume = outputVolume(device: defaultDevice, address: &volumeAddress) {
            return volume
        }

        var channelVolumes: [Double] = []
        for channel in 1...2 {
            volumeAddress.mElement = AudioObjectPropertyElement(channel)
            if let volume = outputVolume(device: defaultDevice, address: &volumeAddress) {
                channelVolumes.append(volume)
            }
        }

        guard !channelVolumes.isEmpty else {
            return nil
        }

        return channelVolumes.reduce(0, +) / Double(channelVolumes.count)
    }

    private func outputVolume(
        device: AudioObjectID,
        address: inout AudioObjectPropertyAddress
    ) -> Double? {
        guard AudioObjectHasProperty(device, &address) else {
            return nil
        }

        var volume = Float32(0)
        var volumeSize = UInt32(MemoryLayout<Float32>.size)
        let status = AudioObjectGetPropertyData(device, &address, 0, nil, &volumeSize, &volume)

        guard status == noErr else {
            return nil
        }

        return min(max(Double(volume), 0), 1)
    }

    private func defaultOutputDevice() -> AudioObjectID? {
        var defaultDevice = AudioObjectID(0)
        var propertySize = UInt32(MemoryLayout<AudioObjectID>.size)
        var deviceAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let deviceStatus = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &deviceAddress,
            0,
            nil,
            &propertySize,
            &defaultDevice
        )

        guard deviceStatus == noErr, defaultDevice != kAudioObjectUnknown else {
            return nil
        }

        return defaultDevice
    }

    private func runMacOSShortcut(_ name: String?) {
        guard let name = trimmed(name) else {
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["run", name]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try? process.run()
    }

    private func hideCurrentApp() {
        guard let app = currentControllableApp() else {
            return
        }

        app.hide()
    }

    private func quitCurrentApp(force: Bool) {
        guard let app = currentControllableApp() else {
            return
        }

        if force {
            app.forceTerminate()
        } else {
            app.terminate()
        }
    }

    private func currentControllableApp() -> NSRunningApplication? {
        guard
            let app = NSWorkspace.shared.frontmostApplication,
            app.bundleIdentifier != Bundle.main.bundleIdentifier
        else {
            return nil
        }

        return app
    }

    private func sendKeyboardShortcut(_ shortcut: String?) {
        guard let parsedShortcut = KeyboardShortcutParser.parse(shortcut) else {
            return
        }

        sendKeyPress(keyCode: parsedShortcut.keyCode, flags: parsedShortcut.flags)
    }

    private func sendCommandShortcut(
        keyCode: CGKeyCode,
        flags: CGEventFlags = .maskCommand
    ) {
        sendKeyPress(keyCode: keyCode, flags: flags)
    }

    private func sendKeyPress(keyCode: CGKeyCode, flags: CGEventFlags = []) {
        requestAccessibilityPermissionIfNeeded()

        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)

        keyDown?.flags = flags
        keyUp?.flags = flags
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    private func sendMediaKey(_ key: MediaKey) {
        postMediaKey(key, isKeyDown: true)
        postMediaKey(key, isKeyDown: false)
    }

    private func postMediaKey(_ key: MediaKey, isKeyDown: Bool) {
        let keyState = isKeyDown ? 0xA00 : 0xB00
        let data1 = (key.rawValue << 16) | keyState
        let event = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: UInt(keyState)),
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: data1,
            data2: -1
        )

        event?.cgEvent?.post(tap: .cghidEventTap)
    }

    private func lockScreen() {
        let process = Process()
        process.executableURL = URL(
            fileURLWithPath: "/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"
        )
        process.arguments = ["-suspend"]

        do {
            try process.run()
        } catch {
            logger.error("Lock screen failed: \(error.localizedDescription, privacy: .public)")
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/CoreServices/ScreenSaverEngine.app"))
        }
    }

    private func requestAccessibilityPermissionIfNeeded() {
        guard !AXIsProcessTrusted(), !didRequestAccessibilityPermission else {
            return
        }

        didRequestAccessibilityPermission = true
        logger.warning("Accessibility permission is missing; keyboard shortcuts may be blocked.")

        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }

    private func trimmed(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}

private enum KeyboardKey {
    static let escape: CGKeyCode = 53
    static let a: CGKeyCode = 0
    static let c: CGKeyCode = 8
    static let q: CGKeyCode = 12
    static let v: CGKeyCode = 9
    static let x: CGKeyCode = 7
    static let z: CGKeyCode = 6
    static let three: CGKeyCode = 20
    static let four: CGKeyCode = 21
    static let five: CGKeyCode = 23
    static let space: CGKeyCode = 49
    static let fn: CGKeyCode = 63
    static let missionControl: CGKeyCode = 160
    static let launchpad: CGKeyCode = 131
}

private enum MediaKey: Int {
    case brightnessUp = 2
    case brightnessDown = 3
    case keyboardBrightnessUp = 22
    case keyboardBrightnessDown = 21
    case playPause = 16
    case nextTrack = 17
    case previousTrack = 18
    case volumeUp = 0
    case volumeDown = 1
    case mute = 7
}

private struct ParsedKeyboardShortcut {
    var keyCode: CGKeyCode
    var flags: CGEventFlags
}

private enum KeyboardShortcutParser {
    static func parse(_ rawShortcut: String?) -> ParsedKeyboardShortcut? {
        guard let rawShortcut else {
            return nil
        }

        let parts = rawShortcut
            .lowercased()
            .split(separator: "+")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard let keyToken = parts.last, let keyCode = keyCodes[keyToken] else {
            return nil
        }

        var flags: CGEventFlags = []

        for part in parts.dropLast() {
            switch part {
            case "cmd", "command", "⌘":
                flags.insert(.maskCommand)
            case "shift", "⇧":
                flags.insert(.maskShift)
            case "ctrl", "control", "⌃":
                flags.insert(.maskControl)
            case "opt", "option", "alt", "⌥":
                flags.insert(.maskAlternate)
            default:
                continue
            }
        }

        return ParsedKeyboardShortcut(keyCode: keyCode, flags: flags)
    }

    private static let keyCodes: [String: CGKeyCode] = [
        "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7,
        "c": 8, "v": 9, "b": 11, "q": 12, "w": 13, "e": 14, "r": 15,
        "y": 16, "t": 17, "1": 18, "2": 19, "3": 20, "4": 21, "6": 22,
        "5": 23, "=": 24, "9": 25, "7": 26, "-": 27, "8": 28, "0": 29,
        "]": 30, "o": 31, "u": 32, "[": 33, "i": 34, "p": 35, "l": 37,
        "j": 38, "'": 39, "k": 40, ";": 41, "\\": 42, ",": 43, "/": 44,
        "n": 45, "m": 46, ".": 47, "`": 50, "space": 49, "tab": 48,
        "return": 36, "enter": 36, "escape": 53, "esc": 53, "delete": 51
    ]
}
