import Combine
import Foundation

public enum TouchBarRuntimeState: Equatable {
    case stopped
    case starting
    case globalActive
    case fallbackAppActive(String)
    case unsupported(String)
    case permissionMissing(String)
    case error(String)

    public var title: String {
        switch self {
        case .stopped:
            "Stopped"
        case .starting:
            "Starting"
        case .globalActive:
            "Global Active"
        case .fallbackAppActive:
            "Fallback App-Active"
        case .unsupported:
            "Unsupported"
        case .permissionMissing:
            "Permission Missing"
        case .error:
            "Runtime Error"
        }
    }

    public var detail: String {
        switch self {
        case .stopped:
            "TouchDeck runtime is not presenting a Touch Bar."
        case .starting:
            "TouchDeck is preparing the global Touch Bar runtime."
        case .globalActive:
            "TouchDeck should remain visible while other apps are active."
        case .fallbackAppActive(let reason):
            reason
        case .unsupported(let reason), .permissionMissing(let reason), .error(let reason):
            reason
        }
    }

    public var symbolName: String {
        switch self {
        case .globalActive:
            "checkmark.circle.fill"
        case .starting:
            "arrow.triangle.2.circlepath"
        case .fallbackAppActive:
            "rectangle.on.rectangle"
        case .permissionMissing:
            "lock.trianglebadge.exclamationmark"
        case .unsupported:
            "exclamationmark.triangle"
        case .error:
            "xmark.octagon"
        case .stopped:
            "pause.circle"
        }
    }

    public var isHealthy: Bool {
        self == .globalActive
    }
}

@MainActor
public final class RuntimeStatusStore: ObservableObject {
    @Published public private(set) var state: TouchBarRuntimeState = .stopped

    public init() {}

    public var compatibilitySnapshot: RuntimeCompatibilitySnapshot {
        RuntimeCompatibilitySnapshot.current(runtimeState: state)
    }

    public func update(_ state: TouchBarRuntimeState) {
        self.state = state
    }
}
