import AppKit
import ApplicationServices
import Combine
import ServiceManagement
import SwiftUI
import TouchDeckCore
import TouchDeckRuntime

public struct StudioRootView: View {
    @StateObject private var store: LayoutEditorStore
    @ObservedObject private var profileSyncBridge: StudioProfileSyncBridge
    private let runtimeStatusStore: RuntimeStatusStore?
    private let onStartRuntime: () -> Void
    private let onStopRuntime: () -> Void

    public init(
        profile: TouchBarProfile = SampleData.defaultProfile,
        profiles: [TouchBarProfile]? = nil,
        profileStore: ProfileStore? = nil,
        profileSyncBridge: StudioProfileSyncBridge = StudioProfileSyncBridge(),
        runtimeStatusStore: RuntimeStatusStore? = nil,
        onStartRuntime: @escaping () -> Void = {},
        onStopRuntime: @escaping () -> Void = {},
        onProfilesChange: @escaping ([TouchBarProfile], TouchBarProfile) -> Void = { _, _ in }
    ) {
        _profileSyncBridge = ObservedObject(wrappedValue: profileSyncBridge)
        self.runtimeStatusStore = runtimeStatusStore
        self.onStartRuntime = onStartRuntime
        self.onStopRuntime = onStopRuntime
        _store = StateObject(
            wrappedValue: LayoutEditorStore(
                profile: profile,
                profiles: profiles,
                profileStore: profileStore,
                onProfilesChange: onProfilesChange
            )
        )
    }

    public var body: some View {
        HStack(spacing: 0) {
            SidebarView(store: store)
                .frame(width: 220)

            Divider()

            EditorView(
                store: store,
                runtimeStatusStore: runtimeStatusStore,
                onStartRuntime: onStartRuntime,
                onStopRuntime: onStopRuntime
            )
                .frame(minWidth: 620)

            Divider()

            InspectorView(store: store)
                .frame(width: 320)
        }
        .frame(minWidth: 1280, minHeight: 740)
        .buttonStyle(TouchDeckRoundedButtonStyle())
        .onReceive(profileSyncBridge.$request.compactMap { $0 }) { request in
            store.applyExternalProfileSelection(
                profiles: request.profiles,
                selectedProfile: request.profile
            )
        }
    }
}

private struct TouchDeckRoundedButtonStyle: ButtonStyle {
    enum Prominence {
        case standard
        case primary
    }

    var prominence: Prominence = .standard

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.medium))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(backgroundFill(isPressed: configuration.isPressed))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            }
            .shadow(color: shadowColor, radius: 5, y: 2)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.snappy(duration: 0.12), value: configuration.isPressed)
    }

    private var foregroundColor: Color {
        switch prominence {
        case .standard:
            .primary
        case .primary:
            .white
        }
    }

    private var borderColor: Color {
        switch prominence {
        case .standard:
            .black.opacity(0.10)
        case .primary:
            .white.opacity(0.24)
        }
    }

    private var shadowColor: Color {
        switch prominence {
        case .standard:
            .black.opacity(0.04)
        case .primary:
            .accentColor.opacity(0.20)
        }
    }

    private func backgroundFill(isPressed: Bool) -> Color {
        switch prominence {
        case .standard:
            Color.white.opacity(isPressed ? 0.72 : 0.88)
        case .primary:
            Color.accentColor.opacity(isPressed ? 0.82 : 0.95)
        }
    }
}

private struct TouchDeckIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(width: 30, height: 30)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.70 : 0.88))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.black.opacity(0.10), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy(duration: 0.12), value: configuration.isPressed)
    }
}

private struct SidebarView: View {
    @ObservedObject var store: LayoutEditorStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SidebarSection(title: "Profiles") {
                    ForEach(store.sortedProfiles) { profile in
                        Button {
                            store.selectProfile(id: profile.id)
                        } label: {
                            ProfileSidebarRow(
                                profile: profile,
                                isSelected: store.profile.id == profile.id
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    SidebarActionButton(title: "New Profile", symbolName: "plus") {
                        store.createDefaultProfile()
                    }

                    SidebarActionButton(title: "New App Profile", symbolName: "app.badge") {
                        store.createProfileForActiveApp()
                    }
                }

                SidebarSection(title: "Library") {
                    SidebarLibraryRow(title: "System", symbolName: "switch.2")
                    SidebarLibraryRow(title: "Apps", symbolName: "app.dashed")
                    SidebarLibraryRow(title: "Functions", symbolName: "bolt")
                    SidebarLibraryRow(title: "Widgets", symbolName: "chart.bar")
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 72)
            .padding(.bottom, 20)
        }
        .background(Color(red: 0.94, green: 0.965, blue: 0.985))
    }
}

private struct SidebarSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)

            content
        }
    }
}

private struct ProfileSidebarRow: View {
    let profile: TouchBarProfile
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: profile.bundleIdentifier == nil ? "rectangle.stack" : "app.badge")
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                if let bundleIdentifier = profile.bundleIdentifier {
                    Text(bundleIdentifier)
                        .font(.caption2)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .foregroundStyle(isSelected ? .white : .primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor : Color.white.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(isSelected ? Color.white.opacity(0.28) : Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct SidebarActionButton: View {
    let title: String
    let symbolName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbolName)
                    .frame(width: 18)
                Text(title)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(.black.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SidebarLibraryRow: View {
    let title: String
    let symbolName: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbolName)
                .frame(width: 18)
            Text(title)
            Spacer()
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
    }
}

private struct EditorView: View {
    @ObservedObject var store: LayoutEditorStore
    let runtimeStatusStore: RuntimeStatusStore?
    let onStartRuntime: () -> Void
    let onStopRuntime: () -> Void

    @AppStorage("TouchDeck.didDismissOnboarding") private var didDismissOnboarding = false
    @State private var isShowingDeleteProfileConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Profile Name", text: profileNameBinding)
                                .font(.largeTitle.weight(.semibold))
                                .textFieldStyle(.plain)
                            Text("Design the Touch Bar layout your hands will actually want to use.")
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if store.isDirty {
                            Text("Unsaved")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.white)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(.black.opacity(0.08), lineWidth: 1)
                                )
                        }

                        Button {
                            store.undo()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                        }
                        .help("Undo")
                        .disabled(!store.canUndo)

                        Button {
                            store.redo()
                        } label: {
                            Image(systemName: "arrow.uturn.forward")
                        }
                        .help("Redo")
                        .disabled(!store.canRedo)

                        Button("Reload") {
                            store.reload()
                        }

                        Button("Import") {
                            store.importProfiles()
                        }

                        Button("Export") {
                            store.exportProfiles()
                        }

                        Button("Delete", role: .destructive) {
                            isShowingDeleteProfileConfirmation = true
                        }
                        .disabled(store.profiles.count <= 1)

                        Button("Save") {
                            store.save()
                        }
                        .buttonStyle(TouchDeckRoundedButtonStyle(prominence: .primary))
                        .disabled(!store.isDirty)
                    }
                }

                if !didDismissOnboarding {
                    OnboardingCard {
                        didDismissOnboarding = true
                    }
                }

                if let errorMessage = store.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .padding(12)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(.orange.opacity(0.28), lineWidth: 1)
                        )
                }

                if let persistenceMessage = store.persistenceMessage {
                    Label(persistenceMessage, systemImage: "checkmark.circle")
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(.black.opacity(0.08), lineWidth: 1)
                        )
                }

                LayoutsEditorView(store: store)
                LibraryPreviewGrid(store: store)
                RemoveDropZone(store: store)
                if let runtimeStatusStore {
                    RuntimeStatusPanel(
                        statusStore: runtimeStatusStore,
                        onStartRuntime: onStartRuntime,
                        onStopRuntime: onStopRuntime
                    )
                }
                PermissionCenterView()
                LaunchAtLoginSettingsView()
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(red: 0.965, green: 0.965, blue: 0.973))
        .task {
            await store.startWidgetRefreshLoop()
        }
        .confirmationDialog(
            "Delete \(store.profile.name)?",
            isPresented: $isShowingDeleteProfileConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Profile", role: .destructive) {
                store.deleteCurrentProfile()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the profile from TouchDeck. Save afterward to make the deletion permanent.")
        }
    }

    private var profileNameBinding: Binding<String> {
        Binding {
            store.profile.name
        } set: { name in
            store.renameCurrentProfile(to: name)
        }
    }
}

private struct OnboardingCard: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Welcome to TouchDeck")
                        .font(.title2.weight(.semibold))
                    Text("Set up your first Stream Deck-style Touch Bar profile in a few focused steps.")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(TouchDeckIconButtonStyle())
                .help("Dismiss")
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 12)], spacing: 12) {
                ForEach(OnboardingChecklist.steps) { step in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: step.symbolName)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 30, height: 30)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.title)
                                .font(.callout.weight(.medium))
                            Text(step.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(red: 0.985, green: 0.985, blue: 0.99))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .padding(18)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 16, y: 8)
    }
}

private struct LayoutsEditorView: View {
    @ObservedObject var store: LayoutEditorStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Virtual Touch Bars")
                        .font(.headline)
                    Text("Each layout can run on the real Touch Bar. Add a Switch Layout button to cycle them.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(store.layouts.count)/5 layouts")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(.black.opacity(0.08), lineWidth: 1)
                    )
            }

            VStack(spacing: 14) {
                ForEach(Array(store.layouts.enumerated()), id: \.element.id) { index, page in
                    VirtualTouchBarView(store: store, layoutIndex: index, page: page)
                }
            }

            Button {
                store.addLayout()
            } label: {
                Label("Add Layout", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .disabled(!store.canAddLayout)
        }
        .padding(18)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 16, y: 8)
    }
}

private struct VirtualTouchBarView: View {
    @ObservedObject var store: LayoutEditorStore
    let layoutIndex: Int
    let page: TouchBarPage
    @State private var isDropTargeted = false
    @FocusState private var isKeyboardReorderFocused: Bool

    private var isSelected: Bool {
        store.selectedLayoutIndex == layoutIndex
    }

    private var sortedItems: [TouchBarItemConfig] {
        page.items.sorted { $0.position < $1.position }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Layout \(layoutIndex + 1)")
                        .font(.callout.weight(.semibold))
                    Text("\(usedCells)/\(TouchBarLayoutMetrics.maxCellsPerPage) cells")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if isSelected {
                        Text("Selected")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }

                virtualBar
            }

            VStack(spacing: 7) {
                layoutControlButton("chevron.up") {
                    store.selectLayout(index: layoutIndex)
                    store.moveSelectedLayoutUp()
                }
                .disabled(layoutIndex == 0)

                layoutControlButton("chevron.down") {
                    store.selectLayout(index: layoutIndex)
                    store.moveSelectedLayoutDown()
                }
                .disabled(layoutIndex >= store.layouts.count - 1)

                Divider()
                    .frame(width: 28)

                layoutControlButton("eraser") {
                    store.selectLayout(index: layoutIndex)
                    store.clearSelectedLayout()
                }
                .help("Clear layout")

                layoutControlButton("trash") {
                    store.selectLayout(index: layoutIndex)
                    store.deleteSelectedLayout()
                }
                .foregroundStyle(.red)
                .disabled(store.layouts.count <= 1)
                .help("Delete layout")
            }
        }
        .padding(14)
        .background(isSelected ? Color.accentColor.opacity(0.07) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? Color.accentColor.opacity(0.46) : Color.black.opacity(0.08), lineWidth: 1)
        )
        .onTapGesture {
            store.selectLayout(index: layoutIndex)
            isKeyboardReorderFocused = true
        }
        .focusable()
        .focused($isKeyboardReorderFocused)
        .onMoveCommand { direction in
            switch direction {
            case .left:
                store.moveSelectedItemLeft()
            case .right:
                store.moveSelectedItemRight()
            default:
                break
            }
        }
    }

    private var virtualBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(sortedItems.enumerated()), id: \.element.id) { _, item in
                    TouchBarDropSlot(
                        isLeading: true,
                        onDrop: { payload in
                            store.handleDrop(payload, on: layoutIndex, before: item.id)
                        }
                    )

                    TouchBarItemPreview(
                        item: item,
                        title: store.displayTitle(for: item),
                        widgetSnapshot: store.widgetSnapshot(for: item),
                        isSelected: store.selectedItemID == item.id,
                        isRunning: store.isRunning(item),
                        isActive: store.isActive(item)
                    )
                    .onTapGesture {
                        store.selectLayout(index: layoutIndex)
                        store.selectedItemID = item.id
                        isKeyboardReorderFocused = true
                    }
                    .draggable(TouchDeckDragPayload.touchBarItem(id: item.id))
                    .animation(.snappy(duration: 0.18), value: sortedItems.map(\.id))
                }

                TouchBarDropSlot(
                    isLeading: false,
                    onDrop: { payload in
                        store.handleDrop(payload, on: layoutIndex)
                    }
                )

                Spacer(minLength: 0)
            }
            .frame(minWidth: StudioTouchBarKeyMetrics.fullWidth)
            .animation(.snappy(duration: 0.18), value: sortedItems.map(\.id))
        }
        .overlay {
            if sortedItems.isEmpty {
                Text("Drag buttons here")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white.opacity(0.52))
            }
        }
        .padding(10)
        .frame(height: 76)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.055, green: 0.055, blue: 0.065))
                .shadow(color: .black.opacity(0.16), radius: 24, y: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(isDropTargeted ? Color.accentColor : .clear, lineWidth: 2)
        )
        .dropDestination(for: TouchDeckDragPayload.self) { payloads, _ in
            guard let payload = payloads.first else {
                return false
            }

            store.handleDrop(payload, on: layoutIndex)
            return true
        } isTargeted: { targeted in
            isDropTargeted = targeted
        }
    }

    private func layoutControlButton(_ symbolName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(TouchDeckIconButtonStyle())
    }

    private var usedCells: Int {
        sortedItems.reduce(0) { $0 + $1.size.rawValue }
    }
}

private struct TouchBarDropSlot: View {
    let isLeading: Bool
    let onDrop: (TouchDeckDragPayload) -> Void
    @State private var isTargeted = false

    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(isTargeted ? Color.accentColor.opacity(0.86) : Color.clear)
            .frame(width: isTargeted ? 18 : (isLeading ? StudioTouchBarKeyMetrics.interCellGap : 12), height: 36)
            .padding(.horizontal, isTargeted ? 3 : 0)
            .animation(.snappy(duration: 0.16), value: isTargeted)
            .dropDestination(for: TouchDeckDragPayload.self) { payloads, _ in
                guard let payload = payloads.first else {
                    return false
                }

                onDrop(payload)
                return true
            } isTargeted: { targeted in
                isTargeted = targeted
            }
    }
}

private struct TouchBarItemPreview: View {
    let item: TouchBarItemConfig
    let title: String
    let widgetSnapshot: WidgetSnapshot?
    let isSelected: Bool
    let isRunning: Bool
    let isActive: Bool

    var body: some View {
        content
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(.white.opacity(0.96))
        .frame(width: StudioTouchBarKeyMetrics.width(for: item.normalizedSize), height: StudioTouchBarKeyMetrics.height)
        .background {
            RoundedRectangle(cornerRadius: StudioTouchBarKeyMetrics.cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: StudioTouchBarKeyMetrics.cornerRadius, style: .continuous)
                        .fill(.white.opacity(isSelected ? 0.22 : 0.12))
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: StudioTouchBarKeyMetrics.cornerRadius, style: .continuous)
                .stroke(isSelected ? Color.accentColor : .white.opacity(0.14), lineWidth: isSelected ? 2 : 1)
        )
        .overlay(alignment: .bottomLeading) {
            if let progress = widgetSnapshot?.progress, !item.isPercentWidget {
                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.accentColor.opacity(0.82))
                        .frame(width: proxy.size.width * min(max(progress, 0), 1), height: 3)
                        .frame(maxHeight: .infinity, alignment: .bottomLeading)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if item.isAppButton {
            ItemIconView(item: item)
        } else if item.isSystemSlider {
            sliderPreviewContent
        } else if item.isPercentWidget {
            percentWidgetContent
        } else {
            HStack(spacing: 6) {
                ItemIconView(item: item)
                if item.normalizedSize != .small {
                    Text(title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(.horizontal, item.normalizedSize == .small ? 0 : 8)
        }
    }

    private var sliderPreviewContent: some View {
        GeometryReader { proxy in
            let horizontalPadding: CGFloat = 12
            let knobSize: CGFloat = 22
            let trackWidth = max(proxy.size.width - horizontalPadding * 2, 0)
            let progress: CGFloat = 0.42
            let knobCenterX = horizontalPadding + trackWidth * progress

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.26))
                    .frame(width: trackWidth, height: 4)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.88))
                            .frame(width: trackWidth * progress, height: 4)
                    }
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)

                Circle()
                    .fill(.white.opacity(0.96))
                    .overlay {
                        Image(systemName: sliderThumbSymbolName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.black.opacity(0.72))
                    }
                    .shadow(color: .black.opacity(0.22), radius: 1.5, y: 0.5)
                    .frame(width: knobSize, height: knobSize)
                    .position(x: knobCenterX, y: proxy.size.height / 2)
            }
        }
        .padding(.horizontal, 0)
    }

    private var sliderThumbSymbolName: String {
        guard case .system(let config) = item.type else {
            return "circle.fill"
        }

        switch config.actionId {
        case "brightnessSlider":
            return "sun.max.fill"
        case "volumeSlider":
            return "speaker.wave.2.fill"
        default:
            return "circle.fill"
        }
    }

    @ViewBuilder
    private var percentWidgetContent: some View {
        let value = widgetSnapshot?.progress.map(SystemStatsProvider.percentString) ?? title

        Text(value)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(percentColor(for: widgetSnapshot?.progress))
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 4)
    }

    private func percentColor(for progress: Double?) -> Color {
        guard let progress else {
            return .white.opacity(0.96)
        }

        switch min(max(progress, 0), 1) {
        case ..<0.2:
            return .green
        case ..<0.4:
            return .mint
        case ..<0.6:
            return .yellow
        case ..<0.8:
            return .orange
        default:
            return .red
        }
    }
}

private enum StudioTouchBarKeyMetrics {
    static let cellWidth: CGFloat = 64
    static let interCellGap: CGFloat = 8
    static let height: CGFloat = 44
    static let cornerRadius: CGFloat = 10

    static func width(for size: ButtonSize) -> CGFloat {
        let cells = CGFloat(size.rawValue)
        return (cells * cellWidth) + (max(0, cells - 1) * interCellGap)
    }

    static var fullWidth: CGFloat {
        let cells = CGFloat(TouchBarLayoutMetrics.maxCellsPerPage)
        return (cells * cellWidth) + (max(0, cells - 1) * interCellGap)
    }

    static func sliderFillWidth(for size: ButtonSize) -> CGFloat {
        width(for: size) * 0.36
    }
}

private struct ItemIconView: View {
    let item: TouchBarItemConfig

    var body: some View {
        if let appIcon = item.appIcon {
            Image(nsImage: appIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
        } else {
            Image(systemName: item.symbolName)
        }
    }
}

private struct LibraryPreviewGrid: View {
    @ObservedObject var store: LayoutEditorStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Button Library")
                    .font(.headline)

                Spacer()

                Text("Drag into the virtual Touch Bar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 14)], spacing: 14) {
                ForEach(LibraryButtonTemplate.all) { template in
                    LibraryTemplateCard(template: template)
                        .onTapGesture {
                            store.add(template: template)
                        }
                        .draggable(TouchDeckDragPayload.library(templateID: template.id))
                }
            }
        }
    }
}

private struct LibraryTemplateCard: View {
    let template: LibraryButtonTemplate

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: template.symbolName)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 32, height: 32)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(template.title)
                    .font(.callout.weight(.medium))
                Text(template.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(template.size.displayName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 10, y: 4)
    }
}

private struct RemoveDropZone: View {
    @ObservedObject var store: LayoutEditorStore
    @State private var isTargeted = false

    var body: some View {
        Label("Drop a Touch Bar button here to remove it", systemImage: "trash")
            .font(.callout.weight(.medium))
            .foregroundStyle(isTargeted ? .red : .secondary)
            .frame(maxWidth: .infinity)
            .padding(18)
            .background(isTargeted ? Color.red.opacity(0.08) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isTargeted ? Color.red.opacity(0.42) : .black.opacity(0.08), lineWidth: 1)
            )
            .dropDestination(for: TouchDeckDragPayload.self) { payloads, _ in
                guard let payload = payloads.first else {
                    return false
                }

                store.handleRemoveDrop(payload)
                return true
            } isTargeted: { targeted in
                isTargeted = targeted
            }
    }
}

private struct RuntimeStatusPanel: View {
    @ObservedObject var statusStore: RuntimeStatusStore
    let onStartRuntime: () -> Void
    let onStopRuntime: () -> Void

    @State private var isShowingCompatibilityDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Image(systemName: statusStore.state.symbolName)
                    .foregroundStyle(tint)
                    .frame(width: 32, height: 32)
                    .background(tint.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Runtime: \(statusStore.state.title)")
                        .font(.headline)
                    Text(statusStore.state.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Button(isShowingCompatibilityDetails ? "Hide Details" : "Compatibility Details") {
                    isShowingCompatibilityDetails.toggle()
                }

                Button("Start") {
                    onStartRuntime()
                }
                .disabled(statusStore.state == .globalActive || statusStore.state == .starting)

                Button("Stop") {
                    onStopRuntime()
                }
                .disabled(statusStore.state == .stopped)
            }

            if isShowingCompatibilityDetails {
                RuntimeCompatibilityDetailsView(snapshot: statusStore.compatibilitySnapshot)
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 10, y: 4)
    }

    private var tint: Color {
        switch statusStore.state {
        case .globalActive:
            .green
        case .starting:
            .blue
        case .fallbackAppActive, .permissionMissing, .unsupported:
            .orange
        case .error:
            .red
        case .stopped:
            .secondary
        }
    }
}

private struct RuntimeCompatibilityDetailsView: View {
    let snapshot: RuntimeCompatibilitySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Global Touch Bar uses private macOS Touch Bar presentation APIs. This is expected for MTMR-style behavior and may require direct distribution outside the App Store.")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
                CompatibilityRow(
                    title: "macOS",
                    value: snapshot.macOSVersion,
                    isHealthy: true
                )
                CompatibilityRow(
                    title: "Mac Model",
                    value: snapshot.modelIdentifier.isEmpty ? "Unknown" : snapshot.modelIdentifier,
                    isHealthy: snapshot.isLikelyTouchBarMac
                )
                CompatibilityRow(
                    title: "Touch Bar",
                    value: snapshot.touchBarHardwareSummary,
                    isHealthy: snapshot.isLikelyTouchBarMac
                )
                CompatibilityRow(
                    title: "Accessibility",
                    value: snapshot.isAccessibilityTrusted ? "Enabled" : "Not granted",
                    isHealthy: snapshot.isAccessibilityTrusted
                )
                CompatibilityRow(
                    title: "DFRFoundation",
                    value: snapshot.isDFRFoundationAvailable ? "Available" : "Missing",
                    isHealthy: snapshot.isDFRFoundationAvailable
                )
                CompatibilityRow(
                    title: "System Tray API",
                    value: snapshot.isSystemTrayAPIAvailable ? "Available" : "Unavailable",
                    isHealthy: snapshot.isSystemTrayAPIAvailable
                )
                CompatibilityRow(
                    title: "System Modal API",
                    value: snapshot.isSystemModalAPIAvailable ? "Available" : "Unavailable",
                    isHealthy: snapshot.isSystemModalAPIAvailable
                )
                CompatibilityRow(
                    title: "Global Mode",
                    value: snapshot.globalModeCanStart ? "Can start" : "Fallback likely",
                    isHealthy: snapshot.globalModeCanStart
                )
            }
        }
        .padding(.top, 2)
    }
}

private struct CompatibilityRow: View {
    let title: String
    let value: String
    let isHealthy: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(isHealthy ? .green : .orange)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                Text(value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color(red: 0.985, green: 0.985, blue: 0.99))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct PermissionCenterView: View {
    @State private var items = PermissionCenterItem.currentItems()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Permission Center")
                    .font(.headline)
                Spacer()
                Button("Request Accessibility") {
                    PermissionCenterItem.requestAccessibilityPrompt()
                    items = PermissionCenterItem.currentItems()
                }
                Button("Open Accessibility Settings") {
                    PermissionCenterItem.openAccessibilitySettings()
                }
                Button {
                    items = PermissionCenterItem.currentItems()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                ForEach(items) { item in
                    HStack(spacing: 12) {
                        Image(systemName: item.symbolName)
                            .foregroundStyle(item.tint)
                            .frame(width: 28, height: 28)
                            .background(item.tint.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.callout.weight(.medium))
                            Text(item.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(.black.opacity(0.08), lineWidth: 1)
                    )
                }
            }
        }
    }
}

private struct PermissionCenterItem: Identifiable {
    var id: PermissionKind
    var title: String
    var subtitle: String
    var symbolName: String
    var tint: Color

    static func currentItems() -> [PermissionCenterItem] {
        let isAccessibilityTrusted = AXIsProcessTrusted()
        return [
            PermissionCenterItem(
                id: .accessibility,
                title: "Accessibility",
                subtitle: isAccessibilityTrusted ? "Enabled" : "Needed for keyboard shortcuts and system controls",
                symbolName: isAccessibilityTrusted ? "checkmark.circle" : "exclamationmark.triangle",
                tint: isAccessibilityTrusted ? .green : .orange
            ),
            PermissionCenterItem(
                id: .automation,
                title: "Automation",
                subtitle: "Requested only when AppleScript or Shortcuts actions need it",
                symbolName: "applescript",
                tint: .secondary
            ),
            PermissionCenterItem(
                id: .location,
                title: "Location",
                subtitle: "Optional for future weather widgets",
                symbolName: "location",
                tint: .secondary
            ),
            PermissionCenterItem(
                id: .network,
                title: "Network",
                subtitle: "Optional for weather and online integrations",
                symbolName: "network",
                tint: .secondary
            )
        ]
    }

    static func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    static func requestAccessibilityPrompt() {
        let options = [
            "AXTrustedCheckOptionPrompt": true
        ] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}

private struct LaunchAtLoginSettingsView: View {
    @State private var status = SMAppService.mainApp.status
    @State private var message: String?

    private var isEnabled: Bool {
        status == .enabled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: isEnabled ? "checkmark.circle" : "power")
                    .foregroundStyle(isEnabled ? .green : .secondary)
                    .frame(width: 28, height: 28)
                    .background((isEnabled ? Color.green : Color.secondary).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Launch at Login")
                        .font(.headline)
                    Text(statusDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("Enable", isOn: launchAtLoginBinding)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.black.opacity(0.08), lineWidth: 1)
        )
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding {
            isEnabled
        } set: { enabled in
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }

                status = SMAppService.mainApp.status
                message = enabled ? "TouchDeck will open when you log in." : "TouchDeck will no longer open at login."
            } catch {
                status = SMAppService.mainApp.status
                message = "Could not update launch at login."
            }
        }
    }

    private var statusDescription: String {
        switch status {
        case .enabled:
            return "TouchDeck is registered to open at login."
        case .requiresApproval:
            return "macOS requires approval in System Settings."
        case .notRegistered:
            return "TouchDeck is not registered to open at login."
        case .notFound:
            return "Launch service is not available for this build."
        @unknown default:
            return "Launch at login status is unknown."
        }
    }
}

private struct InspectorView: View {
    @ObservedObject var store: LayoutEditorStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Inspector")
                .font(.title2.weight(.semibold))

            if let selectedItem = store.selectedItem {
                LabeledContent("Type", value: selectedItem.kindName)
                LabeledContent("Position", value: "\(selectedItem.position)")

                if selectedItem.isSystemButton {
                    SystemButtonInspector(store: store, selectedItem: selectedItem)
                }

                if selectedItem.isAppButton {
                    AppButtonInspector(store: store, selectedItem: selectedItem)
                }

                if selectedItem.isFunctionButton {
                    FunctionButtonInspector(store: store, selectedItem: selectedItem)
                }

                if selectedItem.isWidgetButton {
                    WidgetButtonInspector(store: store, selectedItem: selectedItem)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Size")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Picker("Size", selection: sizeBinding(for: selectedItem)) {
                        ForEach(selectedItem.allowedSizes) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Button("Test Action") {
                    store.testSelectedItem()
                }
                    .buttonStyle(TouchDeckRoundedButtonStyle(prominence: .primary))

                Button("Delete Button", role: .destructive) {
                    store.removeSelectedItem()
                }
                .disabled(!store.selectedItemCanBeRemoved)
                .help(store.selectedItemCanBeRemoved ? "Delete this button" : "Switch Layout is required while multiple layouts exist.")
            } else {
                ContentUnavailableView(
                    "No Button Selected",
                    systemImage: "rectangle.dashed",
                    description: Text("Select a button in the virtual Touch Bar to edit it.")
                )
            }

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 300, idealWidth: 320, maxWidth: 360, alignment: .leading)
        .background(Color(red: 0.98, green: 0.98, blue: 0.985))
    }

    private func sizeBinding(for item: TouchBarItemConfig) -> Binding<ButtonSize> {
        Binding {
            store.selectedItem?.normalizedSize ?? item.normalizedSize
        } set: { size in
            store.resizeSelectedItem(to: size)
        }
    }
}

private struct SystemButtonInspector: View {
    @ObservedObject var store: LayoutEditorStore
    let selectedItem: TouchBarItemConfig

    private var systemConfig: SystemButtonConfig? {
        if case .system(let config) = selectedItem.type {
            return config
        }

        return nil
    }

    private var selectedDefinition: BuiltInSystemActionDefinition? {
        guard let systemConfig else {
            return nil
        }

        return BuiltInSystemActionCatalog.definition(id: systemConfig.actionId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("System Action")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Picker("System Action", selection: systemSelectionBinding) {
                ForEach(BuiltInSystemActionCatalog.all) { definition in
                    Label(definition.name, systemImage: definition.symbolName)
                        .tag(definition.id)
                }
            }
            .labelsHidden()

            if let selectedDefinition {
                ActionSupportSummary(definition: selectedDefinition)
            }
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.black.opacity(0.08), lineWidth: 1)
        )
    }

    private var systemSelectionBinding: Binding<String> {
        Binding {
            systemConfig?.actionId ?? BuiltInSystemActionCatalog.all[0].id
        } set: { actionId in
            guard let definition = BuiltInSystemActionCatalog.definition(id: actionId) else {
                return
            }

            store.updateSelectedSystemAction(to: definition)
        }
    }
}

private struct ActionSupportSummary: View {
    let definition: BuiltInSystemActionDefinition

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(statusText, systemImage: statusSymbolName)
                .font(.caption.weight(.medium))
                .foregroundStyle(statusTint)

            if !definition.requiredPermissions.isEmpty {
                Text("Requires: \(definition.requiredPermissions.map(\.displayName).joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if definition.supportStatus == .limited {
                Text("This action depends on macOS support and may vary by model or system version.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(statusTint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var statusText: String {
        switch definition.supportStatus {
        case .supported:
            "Supported"
        case .requiresPermission:
            "Permission Required"
        case .limited:
            "Limited Support"
        }
    }

    private var statusSymbolName: String {
        switch definition.supportStatus {
        case .supported:
            "checkmark.circle"
        case .requiresPermission:
            "lock.trianglebadge.exclamationmark"
        case .limited:
            "exclamationmark.triangle"
        }
    }

    private var statusTint: Color {
        switch definition.supportStatus {
        case .supported:
            .green
        case .requiresPermission:
            .orange
        case .limited:
            .secondary
        }
    }
}

private struct AppButtonInspector: View {
    @ObservedObject var store: LayoutEditorStore
    let selectedItem: TouchBarItemConfig

    private var selectedAppConfig: AppButtonConfig? {
        if case .app(let config) = selectedItem.type {
            return config
        }

        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("App")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if let selectedAppConfig {
                HStack(spacing: 10) {
                    if let icon = selectedItem.appIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                    } else {
                        Image(systemName: "app")
                            .frame(width: 28, height: 28)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedAppConfig.appName)
                            .font(.callout.weight(.medium))
                        Text(selectedAppConfig.bundleIdentifier)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()
                }
            }

            TextField("Search apps", text: $store.appSearchQuery)
                .textFieldStyle(.roundedBorder)

            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(store.filteredInstalledApps.prefix(24)) { app in
                        Button {
                            store.updateSelectedAppButton(to: app)
                        } label: {
                            AppPickerRow(
                                app: app,
                                isRunning: store.isAppRunning(bundleIdentifier: app.bundleIdentifier),
                                isActive: store.isAppActive(bundleIdentifier: app.bundleIdentifier)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 220)
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.black.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct AppPickerRow: View {
    let app: InstalledApp
    let isRunning: Bool
    let isActive: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: app.path))
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.callout)
                    .foregroundStyle(.primary)
                Text(app.bundleIdentifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if isRunning {
                Circle()
                    .fill(isActive ? Color.accentColor : Color.secondary.opacity(0.7))
                    .frame(width: isActive ? 7 : 6, height: isActive ? 7 : 6)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isActive ? Color.accentColor.opacity(0.10) : Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(isActive ? Color.accentColor.opacity(0.22) : Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct FunctionButtonInspector: View {
    @ObservedObject var store: LayoutEditorStore
    let selectedItem: TouchBarItemConfig

    private var functionConfig: FunctionButtonConfig? {
        if case .function(let config) = selectedItem.type {
            return config
        }

        return nil
    }

    private var selectedDefinition: BuiltInFunctionDefinition? {
        guard let functionConfig else {
            return nil
        }

        return BuiltInFunctionCatalog.definition(id: functionConfig.functionId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Function")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Picker("Function", selection: functionSelectionBinding) {
                ForEach(BuiltInFunctionCatalog.all) { definition in
                    Label(definition.name, systemImage: definition.symbolName)
                        .tag(definition.id)
                }
            }
            .labelsHidden()

            if let selectedDefinition, let functionConfig {
                ForEach(selectedDefinition.parameters) { parameter in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(parameter.name)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        TextField(
                            parameter.placeholder,
                            text: parameterBinding(
                                id: parameter.id,
                                currentValue: functionConfig.parameters[parameter.id] ?? ""
                            )
                        )
                        .textFieldStyle(.roundedBorder)

                        if let hint = parameter.kind.hint {
                            Text(hint)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.black.opacity(0.08), lineWidth: 1)
        )
    }

    private var functionSelectionBinding: Binding<String> {
        Binding {
            functionConfig?.functionId ?? BuiltInFunctionCatalog.all[0].id
        } set: { functionId in
            guard let definition = BuiltInFunctionCatalog.definition(id: functionId) else {
                return
            }

            store.updateSelectedFunction(to: definition)
        }
    }

    private func parameterBinding(id: String, currentValue: String) -> Binding<String> {
        Binding {
            if case .function(let config) = store.selectedItem?.type {
                return config.parameters[id] ?? currentValue
            }

            return currentValue
        } set: { value in
            store.updateSelectedFunctionParameter(id: id, value: value)
        }
    }
}

private struct WidgetButtonInspector: View {
    @ObservedObject var store: LayoutEditorStore
    let selectedItem: TouchBarItemConfig

    private var widgetConfig: WidgetButtonConfig? {
        if case .widget(let config) = selectedItem.type {
            return config
        }

        return nil
    }

    private var selectedDefinition: BuiltInWidgetDefinition? {
        guard let widgetConfig else {
            return nil
        }

        return BuiltInWidgetCatalog.definition(id: widgetConfig.widgetId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Widget")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Picker("Widget", selection: widgetSelectionBinding) {
                ForEach(BuiltInWidgetCatalog.all) { definition in
                    Label(definition.name, systemImage: definition.symbolName)
                        .tag(definition.id)
                }
            }
            .labelsHidden()

            if let selectedDefinition, let widgetConfig {
                ForEach(selectedDefinition.parameters) { parameter in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(parameter.name)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        TextField(
                            parameter.placeholder,
                            text: parameterBinding(
                                id: parameter.id,
                                currentValue: widgetConfig.parameters[parameter.id] ?? ""
                            )
                        )
                        .textFieldStyle(.roundedBorder)

                        if let hint = parameter.kind.hint {
                            Text(hint)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.black.opacity(0.08), lineWidth: 1)
        )
    }

    private var widgetSelectionBinding: Binding<String> {
        Binding {
            widgetConfig?.widgetId ?? BuiltInWidgetCatalog.all[0].id
        } set: { widgetId in
            guard let definition = BuiltInWidgetCatalog.definition(id: widgetId) else {
                return
            }

            store.updateSelectedWidget(to: definition)
        }
    }

    private func parameterBinding(id: String, currentValue: String) -> Binding<String> {
        Binding {
            if case .widget(let config) = store.selectedItem?.type {
                return config.parameters[id] ?? currentValue
            }

            return currentValue
        } set: { value in
            store.updateSelectedWidgetParameter(id: id, value: value)
        }
    }
}

private extension TouchBarItemConfig {
    var title: String {
        switch type {
        case .system(let config):
            BuiltInSystemActionCatalog.definition(id: config.actionId)?.name ?? config.actionId
        case .app(let config):
            config.appName
        case .function(let config):
            BuiltInFunctionCatalog.definition(id: config.functionId)?.name
                ?? config.functionId.replacingOccurrences(of: ".", with: " ")
        case .widget(let config):
            BuiltInWidgetCatalog.definition(id: config.widgetId)?.name
                ?? config.widgetId.replacingOccurrences(of: ".", with: " ")
        case .spacer:
            "Spacer"
        }
    }

    var symbolName: String {
        switch type {
        case .system:
            if case .system(let config) = type {
                return BuiltInSystemActionCatalog.definition(id: config.actionId)?.symbolName ?? "switch.2"
            }
            return "switch.2"
        case .app:
            return "app"
        case .function(let config):
            return BuiltInFunctionCatalog.definition(id: config.functionId)?.symbolName ?? "bolt"
        case .widget(let config):
            return BuiltInWidgetCatalog.definition(id: config.widgetId)?.symbolName ?? "chart.bar"
        case .spacer:
            return "rectangle.dashed"
        }
    }

    var kindName: String {
        switch type {
        case .system:
            "System"
        case .app:
            "App Button"
        case .function:
            "Function"
        case .widget:
            "Widget"
        case .spacer:
            "Spacer"
        }
    }

    var isAppButton: Bool {
        if case .app = type {
            return true
        }
        return false
    }

    var isSystemButton: Bool {
        if case .system = type {
            return true
        }

        return false
    }

    var isFunctionButton: Bool {
        if case .function = type {
            return true
        }

        return false
    }

    var isWidgetButton: Bool {
        if case .widget = type {
            return true
        }

        return false
    }

    var appConfig: AppButtonConfig? {
        if case .app(let config) = type {
            return config
        }

        return nil
    }

    var appIcon: NSImage? {
        guard
            let appPath = appConfig?.appPath,
            !appPath.isEmpty
        else {
            return nil
        }

        return NSWorkspace.shared.icon(forFile: appPath)
    }
}

private extension PermissionKind {
    var displayName: String {
        switch self {
        case .accessibility:
            "Accessibility"
        case .automation:
            "Automation"
        case .location:
            "Location"
        case .network:
            "Network"
        }
    }
}

private extension FunctionParameterKind {
    var hint: String? {
        switch self {
        case .text:
            nil
        case .url:
            "Use a full URL, for example https://apple.com."
        case .filePath:
            "Use an absolute path. Tilde paths like ~/Downloads are supported at runtime."
        case .bundleIdentifier:
            "Use an app bundle identifier like com.apple.Safari, or an absolute .app path."
        case .keyboardShortcut:
            "Use a shortcut like cmd+shift+p, ctrl+space, or option+return."
        }
    }
}

private extension WidgetParameterKind {
    var hint: String? {
        switch self {
        case .text:
            nil
        case .location:
            "Use a city or place name. Weather refreshes periodically and keeps the last value if the network fails."
        }
    }
}

private extension LayoutEditorStore {
    func isRunning(_ item: TouchBarItemConfig) -> Bool {
        guard let bundleIdentifier = item.appConfig?.bundleIdentifier else {
            return false
        }

        return isAppRunning(bundleIdentifier: bundleIdentifier)
    }

    func isActive(_ item: TouchBarItemConfig) -> Bool {
        guard let bundleIdentifier = item.appConfig?.bundleIdentifier else {
            return false
        }

        return isAppActive(bundleIdentifier: bundleIdentifier)
    }
}
