public struct OnboardingStep: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var detail: String
    public var symbolName: String

    public init(id: String, title: String, detail: String, symbolName: String) {
        self.id = id
        self.title = title
        self.detail = detail
        self.symbolName = symbolName
    }
}

public enum OnboardingChecklist {
    public static let steps: [OnboardingStep] = [
        OnboardingStep(
            id: "arrange",
            title: "Arrange your Touch Bar",
            detail: "Drag buttons from the library into the virtual Touch Bar.",
            symbolName: "rectangle.and.hand.point.up.left"
        ),
        OnboardingStep(
            id: "configure",
            title: "Configure actions",
            detail: "Select a button and adjust its app, function, widget, or size in Inspector.",
            symbolName: "slider.horizontal.3"
        ),
        OnboardingStep(
            id: "permissions",
            title: "Grant permissions",
            detail: "Enable Accessibility for keyboard shortcuts and system actions.",
            symbolName: "lock.shield"
        ),
        OnboardingStep(
            id: "save",
            title: "Save and test",
            detail: "Save your profile, then test it globally on the Touch Bar.",
            symbolName: "rectangle.on.rectangle"
        )
    ]
}
