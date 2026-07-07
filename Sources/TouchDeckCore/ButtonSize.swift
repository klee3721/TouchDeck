public enum ButtonSize: Int, Codable, CaseIterable, Sendable, Identifiable {
    case small = 1
    case medium = 2
    case large = 3

    public var id: Int { rawValue }

    public var displayName: String {
        switch self {
        case .small:
            "1 cell"
        case .medium:
            "2 cells"
        case .large:
            "3 cells"
        }
    }
}
