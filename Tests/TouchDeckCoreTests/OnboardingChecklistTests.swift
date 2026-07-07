import Testing
import TouchDeckCore

@Test func onboardingChecklistHasStableUniqueSteps() {
    let ids = OnboardingChecklist.steps.map(\.id)

    #expect(OnboardingChecklist.steps.count >= 4)
    #expect(Set(ids).count == ids.count)
    #expect(OnboardingChecklist.steps.allSatisfy { !$0.title.isEmpty && !$0.detail.isEmpty })
}
