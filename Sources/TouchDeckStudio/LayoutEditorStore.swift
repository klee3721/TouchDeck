import AppKit
import Foundation
import TouchDeckCore
import TouchDeckRuntime
import UniformTypeIdentifiers

@MainActor
final class LayoutEditorStore: ObservableObject {
    @Published var profile: TouchBarProfile
    @Published var profiles: [TouchBarProfile]
    @Published var selectedItemID: TouchBarItemConfig.ID?
    @Published var errorMessage: String?
    @Published var isDirty = false
    @Published var persistenceMessage: String?
    @Published var installedApps: [InstalledApp]
    @Published var appSearchQuery = ""
    @Published var runningBundleIdentifiers: Set<String>
    @Published var activeBundleIdentifier: String?
    @Published var widgetSnapshots: [TouchBarItemConfig.ID: WidgetSnapshot] = [:]
    @Published var selectedLayoutIndex = 0

    private let profileStore: ProfileStore?
    private let onProfilesChange: ([TouchBarProfile], TouchBarProfile) -> Void
    private let engine = LayoutEditingEngine()
    private let statsProvider = SystemStatsProvider()
    private let weatherProvider = OpenMeteoWeatherProvider()
    private let actionDispatcher = ActionDispatcher()
    private var history = HistoryStack<TouchBarProfile>()
    private var appStateObservers: [NSObjectProtocol] = []
    private let maxLayouts = 5
    private let layoutSwitchActionId = "layoutSwitch"

    init(
        profile: TouchBarProfile,
        profiles: [TouchBarProfile]? = nil,
        profileStore: ProfileStore? = nil,
        installedApps: [InstalledApp] = AppDiscovery().discoverInstalledApps(),
        onProfilesChange: @escaping ([TouchBarProfile], TouchBarProfile) -> Void = { _, _ in }
    ) {
        let normalizedProfile = profile.normalizedForCurrentRules
        let normalizedProfiles = (profiles ?? [profile]).map(\.normalizedForCurrentRules)
        self.profile = normalizedProfile
        self.profiles = normalizedProfiles
        self.profileStore = profileStore
        self.installedApps = installedApps
        self.runningBundleIdentifiers = Self.currentRunningBundleIdentifiers()
        self.activeBundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        self.onProfilesChange = onProfilesChange
        observeAppState()
        refreshWidgetSnapshots()
    }

    var page: TouchBarPage {
        page(at: selectedLayoutIndex)
    }

    var layouts: [TouchBarPage] {
        profile.layout.pages.isEmpty ? [TouchBarPage()] : profile.layout.pages
    }

    var canAddLayout: Bool {
        layouts.count < maxLayouts
    }

    var canDeleteSelectedLayout: Bool {
        layouts.count > 1
    }

    var canMoveSelectedLayoutUp: Bool {
        selectedLayoutIndex > 0
    }

    var canMoveSelectedLayoutDown: Bool {
        selectedLayoutIndex < layouts.count - 1
    }

    var selectedItem: TouchBarItemConfig? {
        page.items.first { $0.id == selectedItemID }
    }

    var selectedItemCanBeRemoved: Bool {
        guard let selectedItemID else {
            return false
        }

        return canRemove(itemID: selectedItemID)
    }

    var sortedProfiles: [TouchBarProfile] {
        profiles.sorted {
            if $0.bundleIdentifier == nil, $1.bundleIdentifier != nil {
                return true
            }
            if $0.bundleIdentifier != nil, $1.bundleIdentifier == nil {
                return false
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var filteredInstalledApps: [InstalledApp] {
        let query = appSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return installedApps
        }

        return installedApps.filter { app in
            app.name.localizedCaseInsensitiveContains(query)
                || app.bundleIdentifier.localizedCaseInsensitiveContains(query)
        }
    }

    var canUndo: Bool {
        history.canUndo
    }

    var canRedo: Bool {
        history.canRedo
    }

    func page(at index: Int) -> TouchBarPage {
        let pages = layouts
        guard pages.indices.contains(index) else {
            return pages.first ?? TouchBarPage()
        }

        return pages[index]
    }

    func add(template: LibraryButtonTemplate, to layoutIndex: Int? = nil, before targetID: TouchBarItemConfig.ID? = nil) {
        let targetLayoutIndex = normalizedLayoutIndex(layoutIndex ?? selectedLayoutIndex)
        if isLayoutSwitchType(template.itemType), page(at: targetLayoutIndex).containsLayoutSwitch(actionId: layoutSwitchActionId) {
            errorMessage = "This layout already has a Switch Layout button."
            return
        }

        let insertionIndex = insertionIndex(before: targetID, in: targetLayoutIndex)
        applyEdit {
            try engine.insert(template.makeItem(), into: page(at: targetLayoutIndex), at: insertionIndex)
        } apply: { editedPage in
            applyPage(editedPage, at: targetLayoutIndex)
        }
    }

    func selectProfile(id: TouchBarProfile.ID) {
        guard let nextProfile = profiles.first(where: { $0.id == id }) else {
            return
        }

        profile = nextProfile.normalizedForCurrentRules
        selectedItemID = nil
        selectedLayoutIndex = 0
        isDirty = false
        history.reset()
        refreshWidgetSnapshots()
        persistenceMessage = nil
        errorMessage = nil
        onProfilesChange(profiles, profile)
    }

    func applyExternalProfileSelection(
        profiles nextProfiles: [TouchBarProfile],
        selectedProfile nextProfile: TouchBarProfile
    ) {
        guard profile.id != nextProfile.id || profiles != nextProfiles else {
            return
        }

        profiles = nextProfiles.map(\.normalizedForCurrentRules)
        profile = nextProfile.normalizedForCurrentRules
        selectedItemID = nil
        selectedLayoutIndex = 0
        history.reset()
        refreshWidgetSnapshots()
        persistenceMessage = "Switched to \(nextProfile.name) for the active app."
        errorMessage = nil
    }

    func createDefaultProfile() {
        let nextProfile = TouchBarProfile(
            name: uniqueProfileName(base: "New Profile"),
            layout: TouchBarLayout()
        )
        profiles.append(nextProfile)
        selectProfile(id: nextProfile.id)
        isDirty = true
        persistenceMessage = nil
    }

    func createProfileForActiveApp() {
        guard
            let activeBundleIdentifier,
            let app = installedApps.first(where: { $0.bundleIdentifier == activeBundleIdentifier })
        else {
            errorMessage = "No active app is available for a profile."
            return
        }

        if let existingProfile = profiles.first(where: { $0.bundleIdentifier == activeBundleIdentifier }) {
            selectProfile(id: existingProfile.id)
            return
        }

        let nextProfile = TouchBarProfile(
            name: app.name,
            bundleIdentifier: app.bundleIdentifier,
            layout: TouchBarLayout()
        )
        profiles.append(nextProfile)
        selectProfile(id: nextProfile.id)
        isDirty = true
        persistenceMessage = nil
    }

    func renameCurrentProfile(to name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, trimmedName != profile.name else {
            return
        }

        history.record(profile)
        profile.name = trimmedName
        profiles = ProfileSelection.replacing(profile, in: profiles)
        isDirty = true
        persistenceMessage = nil
        errorMessage = nil
        onProfilesChange(profiles, profile)
    }

    func deleteCurrentProfile() {
        guard profiles.count > 1 else {
            errorMessage = "At least one profile is required."
            return
        }

        profiles.removeAll { $0.id == profile.id }
        profile = ProfileSelection.defaultProfile(from: profiles)
        selectedItemID = nil
        selectedLayoutIndex = 0
        isDirty = true
        history.reset()
        refreshWidgetSnapshots()
        persistenceMessage = nil
        errorMessage = nil
        onProfilesChange(profiles, profile)
    }

    func selectLayout(index: Int) {
        selectedLayoutIndex = normalizedLayoutIndex(index)
        selectedItemID = nil
        refreshWidgetSnapshots()
    }

    func addLayout() {
        guard canAddLayout else {
            errorMessage = "A profile can have up to \(maxLayouts) layouts."
            return
        }

        do {
            history.record(profile)
            var pages = layouts
            let currentIndex = normalizedLayoutIndex(selectedLayoutIndex)
            pages[currentIndex] = try pageEnsuringLayoutSwitch(pages[currentIndex])
            pages.append(defaultSwitchLayoutPage())
            profile.layout.pages = pages
            selectedLayoutIndex = pages.count - 1
            selectedItemID = nil
            markProfileEdited()
        } catch LayoutEditingError.pageCapacityExceeded {
            errorMessage = "Current layout is full. Remove a button before adding a layout so TouchDeck can add Switch Layout."
        } catch {
            errorMessage = "Could not add a new layout."
        }
    }

    func deleteSelectedLayout() {
        guard canDeleteSelectedLayout else {
            errorMessage = "At least one layout is required."
            return
        }

        history.record(profile)
        var pages = layouts
        pages.remove(at: selectedLayoutIndex)
        profile.layout.pages = pages
        selectedLayoutIndex = min(selectedLayoutIndex, pages.count - 1)
        selectedItemID = nil
        applyRequiredLayoutSwitchesAfterStructureChange()
    }

    func clearSelectedLayout() {
        history.record(profile)
        var pages = layouts
        let currentPage = pages[selectedLayoutIndex]
        pages[selectedLayoutIndex] = isLayoutSwitchRequired(in: selectedLayoutIndex, pageCount: pages.count)
            ? TouchBarPage(id: currentPage.id, items: [layoutSwitchItem()])
            : TouchBarPage(id: currentPage.id)
        profile.layout.pages = pages
        selectedItemID = nil
        markProfileEdited()
    }

    func moveSelectedLayoutUp() {
        moveSelectedLayout(by: -1)
    }

    func moveSelectedLayoutDown() {
        moveSelectedLayout(by: 1)
    }

    func move(itemID: TouchBarItemConfig.ID, to layoutIndex: Int? = nil, before targetID: TouchBarItemConfig.ID? = nil) {
        guard itemID != targetID else {
            return
        }

        let destinationLayoutIndex = normalizedLayoutIndex(layoutIndex ?? selectedLayoutIndex)
        let pages = layouts
        guard let sourceLayoutIndex = pages.firstIndex(where: { page in page.items.contains { $0.id == itemID } }) else {
            errorMessage = "Could not find this button."
            return
        }

        if sourceLayoutIndex != destinationLayoutIndex,
           isRequiredLayoutSwitch(itemID: itemID, in: sourceLayoutIndex, pageCount: pages.count) {
            errorMessage = "Switch Layout is required in this layout and cannot be moved out."
            return
        }

        if sourceLayoutIndex == destinationLayoutIndex {
            applyEdit {
                try engine.move(itemId: itemID, before: targetID, in: page(at: destinationLayoutIndex))
            } apply: { editedPage in
                applyPage(editedPage, at: destinationLayoutIndex)
            }
            return
        }

        do {
            history.record(profile)
            var nextPages = pages
            let sourcePage = try engine.remove(itemId: itemID, from: nextPages[sourceLayoutIndex])
            guard let movedItem = pages[sourceLayoutIndex].items.first(where: { $0.id == itemID }) else {
                throw LayoutEditingError.itemNotFound(itemId: itemID)
            }

            let insertionIndex = insertionIndex(before: targetID, in: destinationLayoutIndex)
            let destinationPage = try engine.insert(movedItem, into: nextPages[destinationLayoutIndex], at: insertionIndex)
            nextPages[sourceLayoutIndex] = sourcePage
            nextPages[destinationLayoutIndex] = destinationPage
            profile.layout.pages = nextPages
            selectedLayoutIndex = destinationLayoutIndex
            selectedItemID = itemID
            markProfileEdited()
        } catch LayoutEditingError.pageCapacityExceeded(let maxCells) {
            errorMessage = "This Touch Bar page can fit up to \(maxCells) cells."
        } catch {
            errorMessage = "Could not move this button."
        }
    }

    func resizeSelectedItem(to size: ButtonSize) {
        guard let selectedItemID else {
            return
        }

        applyEdit {
            guard let item = page(at: selectedLayoutIndex).items.first(where: { $0.id == selectedItemID }) else {
                return page(at: selectedLayoutIndex)
            }

            let nextSize = item.allowedSizes.contains(size) ? size : (item.allowedSizes.first ?? .small)
            return try engine.resize(itemId: selectedItemID, to: nextSize, in: page(at: selectedLayoutIndex))
        }
    }

    func removeSelectedItem() {
        guard let selectedItemID else {
            return
        }

        remove(itemID: selectedItemID)
    }

    func updateSelectedAppButton(to app: InstalledApp) {
        mutateSelectedItem { item in
            item.type = .app(
                AppButtonConfig(
                    appName: app.name,
                    bundleIdentifier: app.bundleIdentifier,
                    appPath: app.path
                )
            )
            item.size = item.normalizedSize
        }
    }

    func updateSelectedSystemAction(to definition: BuiltInSystemActionDefinition) {
        mutateSelectedItem { item in
            guard case .system = item.type else {
                return
            }

            item.type = .system(SystemButtonConfig(actionId: definition.id))

            item.size = item.normalizedSize
        }
    }

    func updateSelectedFunction(to definition: BuiltInFunctionDefinition) {
        mutateSelectedItem { item in
            guard case .function(let currentConfig) = item.type else {
                return
            }

            var parameters: [String: String] = [:]

            for parameter in definition.parameters {
                parameters[parameter.id] = currentConfig.parameters[parameter.id] ?? parameter.placeholder
            }

            item.type = .function(
                FunctionButtonConfig(
                    functionId: definition.id,
                    parameters: parameters
                )
            )

            item.size = item.normalizedSize
        }
    }

    func updateSelectedFunctionParameter(id: String, value: String) {
        mutateSelectedItem { item in
            guard case .function(var config) = item.type else {
                return
            }

            config.parameters[id] = value
            item.type = .function(config)
        }
    }

    func updateSelectedWidget(to definition: BuiltInWidgetDefinition) {
        mutateSelectedItem { item in
            guard case .widget(let currentConfig) = item.type else {
                return
            }

            var parameters: [String: String] = [:]

            for parameter in definition.parameters {
                parameters[parameter.id] = currentConfig.parameters[parameter.id] ?? parameter.placeholder
            }

            item.type = .widget(
                WidgetButtonConfig(
                    widgetId: definition.id,
                    parameters: parameters
                )
            )

            item.size = item.normalizedSize
        }
    }

    func updateSelectedWidgetParameter(id: String, value: String) {
        mutateSelectedItem { item in
            guard case .widget(var config) = item.type else {
                return
            }

            config.parameters[id] = value
            item.type = .widget(config)
        }
    }

    func isAppRunning(bundleIdentifier: String) -> Bool {
        runningBundleIdentifiers.contains(bundleIdentifier)
    }

    func isAppActive(bundleIdentifier: String) -> Bool {
        activeBundleIdentifier == bundleIdentifier
    }

    func displayTitle(for item: TouchBarItemConfig) -> String {
        if case .widget = item.type,
           let snapshot = widgetSnapshots[item.id] {
            return snapshot.title
        }

        return fallbackTitle(for: item)
    }

    func widgetSnapshot(for item: TouchBarItemConfig) -> WidgetSnapshot? {
        widgetSnapshots[item.id]
    }

    func testSelectedItem() {
        guard let selectedItem else {
            return
        }

        actionDispatcher.dispatch(item: selectedItem)
        persistenceMessage = "Tested \(displayTitle(for: selectedItem))."
        errorMessage = nil
    }

    func refreshWidgetSnapshots() {
        var snapshots: [TouchBarItemConfig.ID: WidgetSnapshot] = [:]

        for page in layouts {
            for item in page.items {
                guard case .widget(let config) = item.type else {
                    continue
                }

                if let snapshot = statsProvider.snapshot(for: config.widgetId) {
                    snapshots[item.id] = snapshot
                }
            }
        }

        widgetSnapshots = snapshots
    }

    func refreshWeatherSnapshots() async {
        var nextSnapshots = widgetSnapshots

        for page in layouts {
            for item in page.items {
                guard case .widget(let config) = item.type, config.widgetId == "weather.current" else {
                    continue
                }

                let location = config.parameters["location"] ?? "San Francisco"

                if let snapshot = await weatherProvider.snapshot(for: WeatherSnapshotRequest(location: location)) {
                    nextSnapshots[item.id] = snapshot
                }
            }
        }

        widgetSnapshots = nextSnapshots
    }

    func startWidgetRefreshLoop() async {
        refreshWidgetSnapshots()
        await refreshWeatherSnapshots()

        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else {
                return
            }
            refreshWidgetSnapshots()
            await refreshWeatherSnapshots()
        }
    }

    func remove(itemID: TouchBarItemConfig.ID) {
        guard canRemove(itemID: itemID) else {
            errorMessage = "Switch Layout is required in this layout and cannot be deleted."
            return
        }

        let targetLayoutIndex = layoutIndex(containing: itemID) ?? selectedLayoutIndex
        applyEdit {
            try engine.remove(itemId: itemID, from: page(at: targetLayoutIndex))
        } apply: { editedPage in
            applyPage(editedPage, at: targetLayoutIndex)
        }

        if selectedItemID == itemID {
            selectedItemID = nil
        }
    }

    func handleDrop(
        _ payload: TouchDeckDragPayload,
        on layoutIndex: Int? = nil,
        before targetID: TouchBarItemConfig.ID? = nil
    ) {
        let targetLayoutIndex = normalizedLayoutIndex(layoutIndex ?? selectedLayoutIndex)
        switch payload {
        case .library(let templateID):
            guard let template = LibraryButtonTemplate.template(id: templateID) else {
                errorMessage = "Unknown library item."
                return
            }
            add(template: template, to: targetLayoutIndex, before: targetID)
        case .touchBarItem(let itemID):
            move(itemID: itemID, to: targetLayoutIndex, before: targetID)
        }
    }

    func handleRemoveDrop(_ payload: TouchDeckDragPayload) {
        guard case .touchBarItem(let itemID) = payload else {
            return
        }

        remove(itemID: itemID)
    }

    func canRemove(itemID: TouchBarItemConfig.ID) -> Bool {
        guard let layoutIndex = layoutIndex(containing: itemID) else {
            return true
        }

        return !isRequiredLayoutSwitch(itemID: itemID, in: layoutIndex, pageCount: layouts.count)
    }

    private func moveSelectedLayout(by offset: Int) {
        let nextIndex = selectedLayoutIndex + offset
        guard layouts.indices.contains(nextIndex) else {
            return
        }

        history.record(profile)
        var pages = layouts
        pages.swapAt(selectedLayoutIndex, nextIndex)
        profile.layout.pages = pages
        selectedLayoutIndex = nextIndex
        selectedItemID = nil
        applyRequiredLayoutSwitchesAfterStructureChange()
    }

    private func applyRequiredLayoutSwitchesAfterStructureChange() {
        do {
            profile.layout.pages = try pagesEnsuringRequiredLayoutSwitches(layouts)
            markProfileEdited()
        } catch LayoutEditingError.pageCapacityExceeded {
            errorMessage = "A required Switch Layout button could not be added because a layout is full."
        } catch {
            errorMessage = "Could not update layout switch buttons."
        }
    }

    private func pagesEnsuringRequiredLayoutSwitches(_ pages: [TouchBarPage]) throws -> [TouchBarPage] {
        try pages.enumerated().map { index, page in
            guard isLayoutSwitchRequired(in: index, pageCount: pages.count) else {
                return page
            }

            return try pageEnsuringLayoutSwitch(page)
        }
    }

    private func pageEnsuringLayoutSwitch(_ page: TouchBarPage) throws -> TouchBarPage {
        guard !page.containsLayoutSwitch(actionId: layoutSwitchActionId) else {
            return page
        }

        return try engine.insert(layoutSwitchItem(), into: page, at: 0)
    }

    private func defaultSwitchLayoutPage() -> TouchBarPage {
        TouchBarPage(items: [layoutSwitchItem()])
    }

    private func layoutSwitchItem() -> TouchBarItemConfig {
        TouchBarItemConfig(
            position: 0,
            size: .small,
            type: .system(SystemButtonConfig(actionId: layoutSwitchActionId))
        )
    }

    private func isLayoutSwitchRequired(in layoutIndex: Int, pageCount: Int) -> Bool {
        pageCount > 1 || layoutIndex > 0
    }

    private func isRequiredLayoutSwitch(
        itemID: TouchBarItemConfig.ID,
        in layoutIndex: Int,
        pageCount: Int
    ) -> Bool {
        guard
            isLayoutSwitchRequired(in: layoutIndex, pageCount: pageCount),
            let item = page(at: layoutIndex).items.first(where: { $0.id == itemID })
        else {
            return false
        }

        return item.isLayoutSwitch(actionId: layoutSwitchActionId)
    }

    private func isLayoutSwitchType(_ type: TouchBarItemType) -> Bool {
        if case .system(let config) = type {
            return config.actionId == layoutSwitchActionId
        }

        return false
    }

    private func layoutIndex(containing itemID: TouchBarItemConfig.ID) -> Int? {
        layouts.firstIndex { page in
            page.items.contains { $0.id == itemID }
        }
    }

    private func normalizedLayoutIndex(_ index: Int) -> Int {
        let pages = layouts
        guard !pages.isEmpty else {
            return 0
        }

        return min(max(index, 0), pages.count - 1)
    }

    private func markProfileEdited() {
        profiles = ProfileSelection.replacing(profile, in: profiles)
        isDirty = true
        refreshWidgetSnapshots()
        persistenceMessage = nil
        errorMessage = nil
        onProfilesChange(profiles, profile)
    }

    func undo() {
        guard let previousProfile = history.undo(current: profile) else {
            return
        }

        applyHistoryProfile(previousProfile)
    }

    func redo() {
        guard let nextProfile = history.redo(current: profile) else {
            return
        }

        applyHistoryProfile(nextProfile)
    }

    func save() {
        guard let profileStore else {
            persistenceMessage = "No profile store is configured."
            return
        }

        do {
            profiles = ProfileSelection.replacing(profile, in: profiles)
            try profileStore.save(profiles)
            isDirty = false
            persistenceMessage = "Saved to profiles.json."
            errorMessage = nil
        } catch {
            persistenceMessage = nil
            errorMessage = "Could not save profiles.json."
        }
    }

    func exportProfiles() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "TouchDeck Profiles.json"
        savePanel.canCreateDirectories = true

        guard savePanel.runModal() == .OK, let url = savePanel.url else {
            return
        }

        do {
            profiles = ProfileSelection.replacing(profile, in: profiles)
            let data = try ProfileDocumentCodec.encode(profiles)
            try data.write(to: url, options: [.atomic])
            persistenceMessage = "Exported profiles."
            errorMessage = nil
        } catch {
            persistenceMessage = nil
            errorMessage = "Could not export profiles."
        }
    }

    func importProfiles() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false

        guard openPanel.runModal() == .OK, let url = openPanel.url else {
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let importedProfiles = try ProfileDocumentCodec.decode(data)
            profiles = importedProfiles.isEmpty ? [SampleData.defaultProfile] : importedProfiles
            profile = ProfileSelection.defaultProfile(from: profiles)
            selectedItemID = nil
            selectedLayoutIndex = 0
            isDirty = true
            persistenceMessage = "Imported profiles. Save to apply them permanently."
            errorMessage = nil
            onProfilesChange(profiles, profile)
        } catch {
            persistenceMessage = nil
            errorMessage = "Could not import profiles."
        }
    }

    func reload() {
        guard let profileStore else {
            persistenceMessage = "No profile store is configured."
            return
        }

        do {
            let profiles = try profileStore.load()
            self.profiles = profiles.isEmpty ? [SampleData.defaultProfile] : profiles
            profile = ProfileSelection.effectiveProfile(
                from: self.profiles,
                frontmostBundleIdentifier: activeBundleIdentifier
            )
            selectedItemID = nil
            selectedLayoutIndex = 0
            isDirty = false
            history.reset()
            refreshWidgetSnapshots()
            persistenceMessage = "Reloaded profiles.json."
            errorMessage = nil
            onProfilesChange(self.profiles, profile)
        } catch {
            persistenceMessage = nil
            errorMessage = "Could not reload profiles.json."
        }
    }

    private func insertionIndex(before targetID: TouchBarItemConfig.ID?, in layoutIndex: Int) -> Int? {
        guard let targetID else {
            return nil
        }

        return page(at: layoutIndex).items
            .sorted { $0.position < $1.position }
            .firstIndex { $0.id == targetID }
    }

    private func mutateSelectedItem(_ mutate: (inout TouchBarItemConfig) -> Void) {
        guard let selectedItemID else {
            return
        }

        do {
            var page = page(at: selectedLayoutIndex)

            guard let index = page.items.firstIndex(where: { $0.id == selectedItemID }) else {
                throw LayoutEditingError.itemNotFound(itemId: selectedItemID)
            }

            mutate(&page.items[index])
            let editedPage = try engine.normalized(page)
            applyPage(editedPage, at: selectedLayoutIndex)
        } catch {
            errorMessage = "Could not update this button."
        }
    }

    private func applyEdit(
        _ edit: () throws -> TouchBarPage,
        apply: (TouchBarPage) -> Void
    ) {
        do {
            let editedPage = try edit()
            apply(editedPage)
        } catch LayoutEditingError.pageCapacityExceeded(let maxCells) {
            errorMessage = "This Touch Bar page can fit up to \(maxCells) cells."
        } catch {
            errorMessage = "Could not update this layout."
        }
    }

    private func applyEdit(_ edit: () throws -> TouchBarPage) {
        applyEdit(edit) { editedPage in
            applyPage(editedPage, at: selectedLayoutIndex)
        }
    }

    private func applyPage(_ editedPage: TouchBarPage, at layoutIndex: Int) {
        history.record(profile)
        var pages = layouts
        let targetLayoutIndex = min(max(layoutIndex, 0), max(pages.count - 1, 0))

        if pages.isEmpty {
            pages = [editedPage]
        } else {
            pages[targetLayoutIndex] = editedPage
        }

        profile.layout.pages = pages
        selectedLayoutIndex = targetLayoutIndex
        markProfileEdited()
    }

    private func applyHistoryProfile(_ nextProfile: TouchBarProfile) {
        profile = nextProfile
        profiles = ProfileSelection.replacing(nextProfile, in: profiles)
        selectedItemID = nil
        selectedLayoutIndex = min(selectedLayoutIndex, max(layouts.count - 1, 0))
        isDirty = true
        persistenceMessage = nil
        errorMessage = nil
        refreshWidgetSnapshots()
        onProfilesChange(profiles, profile)
    }

    private func observeAppState() {
        let notificationCenter = NSWorkspace.shared.notificationCenter

        appStateObservers = [
            notificationCenter.addObserver(
                forName: NSWorkspace.didLaunchApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.refreshAppState()
                }
            },
            notificationCenter.addObserver(
                forName: NSWorkspace.didTerminateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.refreshAppState()
                }
            },
            notificationCenter.addObserver(
                forName: NSWorkspace.didActivateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.refreshAppState()
                }
            }
        ]
    }

    private func refreshAppState() {
        runningBundleIdentifiers = Self.currentRunningBundleIdentifiers()
        activeBundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    private static func currentRunningBundleIdentifiers() -> Set<String> {
        Set(
            NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier)
        )
    }

    private func fallbackTitle(for item: TouchBarItemConfig) -> String {
        switch item.type {
        case .system(let config):
            return BuiltInSystemActionCatalog.definition(id: config.actionId)?.name ?? config.actionId
        case .app(let config):
            return config.appName
        case .function(let config):
            return BuiltInFunctionCatalog.definition(id: config.functionId)?.name
                ?? config.functionId.replacingOccurrences(of: ".", with: " ")
        case .widget(let config):
            return BuiltInWidgetCatalog.definition(id: config.widgetId)?.name
                ?? config.widgetId.replacingOccurrences(of: ".", with: " ")
        case .spacer:
            return "Spacer"
        }
    }

    private func uniqueProfileName(base: String) -> String {
        let existingNames = Set(profiles.map(\.name))

        guard existingNames.contains(base) else {
            return base
        }

        var index = 2

        while existingNames.contains("\(base) \(index)") {
            index += 1
        }

        return "\(base) \(index)"
    }
}

private extension TouchBarPage {
    func containsLayoutSwitch(actionId: String) -> Bool {
        items.contains { $0.isLayoutSwitch(actionId: actionId) }
    }
}

private extension TouchBarItemConfig {
    func isLayoutSwitch(actionId: String) -> Bool {
        guard case .system(let config) = type else {
            return false
        }

        return config.actionId == actionId
    }
}
