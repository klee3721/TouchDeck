import Foundation

public enum TouchDeckCellMetrics {
    public static let runtimeCellWidthKey = "TouchDeck.runtimeCellWidth"

    public static let defaultRuntimeCellWidth = 38.0
    public static let minimumRuntimeCellWidth = 30.0
    public static let maximumRuntimeCellWidth = 56.0
    public static let studioPreviewWidthOffset = 8.0

    public static var runtimeCellWidth: Double {
        get {
            let storedValue = UserDefaults.standard.object(forKey: runtimeCellWidthKey) as? Double
            return clampedRuntimeCellWidth(storedValue ?? defaultRuntimeCellWidth)
        }
        set {
            UserDefaults.standard.set(clampedRuntimeCellWidth(newValue), forKey: runtimeCellWidthKey)
        }
    }

    public static var studioCellWidth: Double {
        runtimeCellWidth + studioPreviewWidthOffset
    }

    public static func clampedRuntimeCellWidth(_ value: Double) -> Double {
        min(max(value, minimumRuntimeCellWidth), maximumRuntimeCellWidth)
    }
}

