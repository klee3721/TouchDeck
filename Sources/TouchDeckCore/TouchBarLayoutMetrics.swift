import Foundation

public enum TouchBarLayoutMetrics {
    public static let maxCellsPerPageKey = "TouchDeck.maxCellsPerPage"

    public static let defaultMaxCellsPerPage = 17
    public static let minimumMaxCellsPerPage = 8
    public static let maximumMaxCellsPerPage = 40

    public static var maxCellsPerPage: Int {
        get {
            let storedValue = UserDefaults.standard.object(forKey: maxCellsPerPageKey) as? Int
            return clampedMaxCellsPerPage(storedValue ?? defaultMaxCellsPerPage)
        }
        set {
            UserDefaults.standard.set(clampedMaxCellsPerPage(newValue), forKey: maxCellsPerPageKey)
        }
    }

    public static func clampedMaxCellsPerPage(_ value: Int) -> Int {
        min(max(value, minimumMaxCellsPerPage), maximumMaxCellsPerPage)
    }
}
