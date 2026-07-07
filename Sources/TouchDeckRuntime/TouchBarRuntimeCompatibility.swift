import AppKit
import ApplicationServices
import Darwin
import Foundation

public struct RuntimeCompatibilitySnapshot: Equatable {
    public let macOSVersion: String
    public let modelIdentifier: String
    public let isLikelyTouchBarMac: Bool
    public let isAppKitTouchBarAvailable: Bool
    public let isDFRFoundationAvailable: Bool
    public let isSystemTrayAPIAvailable: Bool
    public let isSystemModalAPIAvailable: Bool
    public let isAccessibilityTrusted: Bool
    public let runtimeState: TouchBarRuntimeState

    public var globalModeCanStart: Bool {
        isLikelyTouchBarMac
            && isAppKitTouchBarAvailable
            && isDFRFoundationAvailable
            && isSystemTrayAPIAvailable
            && isSystemModalAPIAvailable
    }

    public var touchBarHardwareSummary: String {
        if isLikelyTouchBarMac {
            return "Likely present on \(modelIdentifier)"
        }

        if modelIdentifier.isEmpty {
            return "Unknown Mac model"
        }

        return "Not recognized as a Touch Bar Mac"
    }

    public static func current(runtimeState: TouchBarRuntimeState) -> RuntimeCompatibilitySnapshot {
        let modelIdentifier = Self.modelIdentifier()

        return RuntimeCompatibilitySnapshot(
            macOSVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            modelIdentifier: modelIdentifier,
            isLikelyTouchBarMac: Self.isLikelyTouchBarMac(modelIdentifier: modelIdentifier),
            isAppKitTouchBarAvailable: NSClassFromString("NSTouchBar") != nil,
            isDFRFoundationAvailable: FileManager.default.fileExists(atPath: Self.dfrFoundationPath),
            isSystemTrayAPIAvailable: NSTouchBarItem.responds(to: Self.addSystemTrayItemSelector),
            isSystemModalAPIAvailable: NSTouchBar.responds(to: Self.presentTouchBarSelector)
                || NSTouchBar.responds(to: Self.presentFunctionBarSelector),
            isAccessibilityTrusted: AXIsProcessTrusted(),
            runtimeState: runtimeState
        )
    }

    private static let dfrFoundationPath = "/System/Library/PrivateFrameworks/DFRFoundation.framework/DFRFoundation"
    private static let addSystemTrayItemSelector = NSSelectorFromString("addSystemTrayItem:")
    private static let presentTouchBarSelector = NSSelectorFromString("presentSystemModalTouchBar:systemTrayItemIdentifier:")
    private static let presentFunctionBarSelector = NSSelectorFromString("presentSystemModalFunctionBar:systemTrayItemIdentifier:")

    private static func modelIdentifier() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)

        guard size > 0 else {
            return ""
        }

        var buffer = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &buffer, &size, nil, 0)
        let bytes = buffer
            .prefix { $0 != 0 }
            .map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    private static func isLikelyTouchBarMac(modelIdentifier: String) -> Bool {
        let touchBarModels: Set<String> = [
            "MacBookPro13,2",
            "MacBookPro13,3",
            "MacBookPro14,2",
            "MacBookPro14,3",
            "MacBookPro15,1",
            "MacBookPro15,2",
            "MacBookPro15,3",
            "MacBookPro15,4",
            "MacBookPro16,1",
            "MacBookPro16,2",
            "MacBookPro16,3",
            "MacBookPro16,4",
            "MacBookPro17,1"
        ]

        return touchBarModels.contains(modelIdentifier)
    }
}
