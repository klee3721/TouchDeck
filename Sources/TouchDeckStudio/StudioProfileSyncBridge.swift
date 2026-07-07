import Combine
import TouchDeckCore

@MainActor
public final class StudioProfileSyncBridge: ObservableObject {
    @Published var request: StudioProfileSyncRequest?

    public init() {}

    public func select(profiles: [TouchBarProfile], profile: TouchBarProfile) {
        request = StudioProfileSyncRequest(profiles: profiles, profile: profile)
    }
}

struct StudioProfileSyncRequest: Equatable {
    var profiles: [TouchBarProfile]
    var profile: TouchBarProfile
}
