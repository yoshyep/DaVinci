import SwiftData
import SwiftUI

struct WorkbenchView: View {
    let viewModel: WorkbenchViewModel
    let router: AppRouter
    let showSettings: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProjectSession.updatedAt, order: .reverse) private var sessions: [ProjectSession]
    @Query(sort: \RecentActivity.updatedAt, order: .reverse) private var recentActivities: [RecentActivity]
    @Query(sort: \Favorite.updatedAt, order: .reverse) private var favorites: [Favorite]
    @Query(sort: \UserNote.updatedAt, order: .reverse) private var notes: [UserNote]
    @State private var mutationFailure: LocalMutationFailure?

    private var snapshot: WorkbenchViewModel.Snapshot {
        viewModel.snapshot(
            session: sessions.first,
            recentActivities: recentActivities,
            favorites: favorites,
            notes: notes
        )
    }

    var body: some View {
        List {
            brandHeader
            commandSearch
            currentProject
            immediateTools
            workflowRailSection
            projectTools
            recentUsage
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        .navigationTitle(Text("tab.workbench"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: showSettings) {
                    Image(systemName: "gearshape")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel(Text("settings.title"))
                .accessibilityIdentifier("workbench.settings")
            }
        }
        .navigationDestination(for: WorkbenchDestination.self) { destination in
            destinationView(destination)
        }
        .sheet(
            item: Binding(
                get: { router.presentedWorkbenchDestination },
                set: { router.presentedWorkbenchDestination = $0 }
            )
        ) { destination in
            WorkbenchSheetContainer {
                destinationView(destination)
            }
        }
        .localMutationAlert(failure: $mutationFailure, language: viewModel.settings.language)
    }

    private var brandHeader: some View {
        HStack(spacing: 14) {
            BrandLogoView(variant: .symbol)
                .frame(width: 48, height: 48)
                .padding(5)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 13))

            VStack(alignment: .leading, spacing: 2) {
                Text("workbench.title")
                    .font(.title2.bold())
                Text("workbench.localOnly")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private var commandSearch: some View {
        Button {
            router.openQuickLookup()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("tab.lookup")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("workbench.search.routeHint")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 15)
            .frame(maxWidth: .infinity, minHeight: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityLabel(Text("tab.lookup"))
        .accessibilityHint(Text("workbench.search.routeHint"))
        .accessibilityIdentifier("workbench.quickLookup")
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    @ViewBuilder
    private var currentProject: some View {
        Section {
            switch snapshot.projectState {
            case .active:
                if let projectName = snapshot.projectName,
                   let stage = viewModel.stage(id: snapshot.currentStageID) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(projectName)
                                .font(.title3.bold())
                            Spacer()
                            Text("\(snapshot.completedStages)/\(snapshot.totalStages)")
                                .font(.caption.monospacedDigit().weight(.semibold))
                                .foregroundStyle(.green)
                                .accessibilityIdentifier("workbench.project.progress")
                        }

                        Text(stage.title.resolved(for: viewModel.settings.language))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.blue)

                        ProgressView(
                            value: Double(snapshot.completedStages),
                            total: Double(max(snapshot.totalStages, 1))
                        )
                        .tint(.green)

                        if let task = snapshot.currentTask {
                            Label {
                                Text(task.resolved(for: viewModel.settings.language))
                            } icon: {
                                Image(systemName: "target")
                                    .foregroundStyle(.yellow)
                            }
                            .font(.subheadline)
                        }

                        Button {
                            router.open(.workflowStage(stage.id))
                        } label: {
                            Label("workbench.continue", systemImage: "play.fill")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("workbench.continue")

                        Button("workbench.explain") {
                            router.open(.workflowStage(stage.id))
                        }
                        .font(.footnote.weight(.semibold))
                        .frame(minHeight: 44)
                    }
                    .padding(.vertical, 6)
                }
            case .completed:
                if let projectName = snapshot.projectName {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(projectName)
                                .font(.title3.bold())
                            Spacer()
                            Text("\(snapshot.completedStages)/\(snapshot.totalStages)")
                                .font(.caption.monospacedDigit().weight(.semibold))
                                .foregroundStyle(.green)
                                .accessibilityIdentifier("workbench.project.progress")
                        }

                        ProgressView(value: 1, total: 1)
                            .tint(.green)

                        Label("workbench.project.completed", systemImage: "checkmark.seal.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.green)
                            .accessibilityIdentifier("workbench.project.completed")

                        Button {
                            router.open(.deliveryChecklist)
                        } label: {
                            Label("workbench.reviewDelivery", systemImage: "checklist")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("workbench.reviewDelivery")
                    }
                    .padding(.vertical, 6)
                }
            case .noProject:
                VStack(alignment: .leading, spacing: 12) {
                    Label("workbench.startWorkflow", systemImage: "play.rectangle.on.rectangle")
                        .font(.title3.bold())
                    Text("workbench.startWorkflow.detail")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal) {
                        HStack(spacing: 9) {
                            ForEach(snapshot.templates) { template in
                                Button {
                                    router.open(.template(template.id))
                                } label: {
                                    Label(
                                        template.title.resolved(for: viewModel.settings.language),
                                        systemImage: template.systemImage
                                    )
                                    .font(.caption.weight(.semibold))
                                    .frame(minHeight: 44)
                                }
                                .buttonStyle(.bordered)
                                .accessibilityIdentifier("workbench.template.\(template.id)")
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
                .padding(.vertical, 6)
            }
        } header: {
            sectionHeader("workbench.currentProject", systemImage: "film.stack")
        }
    }

    private var workflowRailSection: some View {
        Section {
            workflowRail
        } header: {
            sectionHeader("workbench.workflowStages", systemImage: "point.3.connected.trianglepath.dotted")
        }
    }

    private var workflowRail: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(viewModel.stages, id: \.id) { stage in
                    StageBadge(
                        number: stage.number,
                        title: stage.title.resolved(for: viewModel.settings.language),
                        state: stageState(stage)
                    ) {
                        router.open(.workflowStage(stage.id))
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
        .accessibilityLabel(Text("workbench.workflowStages"))
        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 14, trailing: 0))
    }

    private var immediateTools: some View {
        Section {
            ForEach(viewModel.immediateTools) { tool in
                ToolActionButton(
                    titleKey: tool.titleKey,
                    detailKey: tool.detailKey,
                    systemImage: tool.systemImage,
                    tint: tint(for: tool.action),
                    shortcutKeys: tool.shortcutKeys,
                    accessibilityIdentifier: "quick.\(tool.action.rawValue)"
                ) {
                    router.present(tool.destination)
                }
            }
        } header: {
            sectionHeader("workbench.immediateTools", systemImage: "bolt.fill")
        }
    }

    private var projectTools: some View {
        Section {
            projectToolRow(
                title: "workbench.project.deliveryChecklist",
                detail: countLabel(snapshot.checklistCompleted, of: snapshot.checklistTotal),
                systemImage: "checklist",
                tint: .green,
                identifier: "project.deliveryChecklist",
                destination: .deliveryChecklist
            )
            projectToolRow(
                title: "workbench.project.recent",
                detail: countLabel(snapshot.recentContentIDs.count),
                systemImage: "clock.arrow.circlepath",
                tint: .blue,
                identifier: "project.recent",
                destination: .recentRecords
            )
            projectToolRow(
                title: "workbench.project.favorites",
                detail: countLabel(snapshot.favoriteCount),
                systemImage: "star.fill",
                tint: .yellow,
                identifier: "project.favorites",
                destination: .favoriteTools
            )
            projectToolRow(
                title: "workbench.project.notes",
                detail: countLabel(snapshot.noteCount),
                systemImage: "note.text",
                tint: .orange,
                identifier: "project.notes",
                destination: .notes
            )
        } header: {
            sectionHeader("workbench.projectTools", systemImage: "wrench.and.screwdriver")
        }
    }

    @ViewBuilder
    private var recentUsage: some View {
        Section {
            if snapshot.recentContentIDs.isEmpty {
                Label("workbench.recent.empty", systemImage: "clock")
                    .foregroundStyle(.secondary)
                    .frame(minHeight: 44)
            } else {
                ForEach(snapshot.recentContentIDs, id: \.self) { contentID in
                    if let record = viewModel.record(id: contentID) {
                        Button {
                            router.openQuickLookup(contentID: contentID)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: icon(for: record.kind))
                                    .foregroundStyle(.blue)
                                    .frame(width: 26)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(record.title.resolved(for: viewModel.settings.language))
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text(record.summary.resolved(for: viewModel.settings.language))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .frame(minHeight: 48)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("workbench.recent.\(contentID)")
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                pinRecent(contentID)
                            } label: {
                                Label("workbench.recent.pin", systemImage: "pin.fill")
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                removeRecent(contentID)
                            } label: {
                                Label("workbench.recent.remove", systemImage: "trash")
                            }
                            Button {
                                favorite(contentID)
                            } label: {
                                Label("workbench.recent.favorite", systemImage: "star.fill")
                            }
                            .tint(.yellow)
                        }
                    }
                }
            }
        } header: {
            sectionHeader("workbench.recentUsage", systemImage: "clock")
        }
    }

    private func sectionHeader(_ key: LocalizedStringKey, systemImage: String) -> some View {
        Label(key, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(.primary)
            .textCase(nil)
    }

    private func projectToolRow(
        title: LocalizedStringKey,
        detail: String,
        systemImage: String,
        tint: Color,
        identifier: String,
        destination: WorkbenchDestination
    ) -> some View {
        Button {
            router.open(destination)
        } label: {
            HStack(spacing: 13) {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                    .frame(width: 28)
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Text(detail)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }

    private func stageState(_ stage: WorkflowStage) -> StageBadge.State {
        guard sessions.first != nil else { return stage.number == 1 ? .current : .upcoming }
        let completed = Set(sessions.first?.stageProgress.filter(\.isCompleted).map(\.contentID) ?? [])
        if completed.contains(stage.id) { return .completed }
        return snapshot.currentStageID == stage.id ? .current : .upcoming
    }

    private func tint(for action: WorkbenchQuickAction) -> Color {
        switch action {
        case .deleteSegment: .yellow
        case .skinCorrection: .blue
        case .exportSettings: .green
        case .emergency: .red
        }
    }

    private func icon(for kind: ContentKind) -> String {
        switch kind {
        case .stage: "checklist"
        case .shortcut: "command"
        case .recipe: "wand.and.stars"
        case .colorPass: "scope"
        case .export: "square.and.arrow.up"
        case .emergency: "cross.case"
        case .playbook: "books.vertical"
        }
    }

    private func countLabel(_ value: Int, of total: Int? = nil) -> String {
        if let total { return "\(value)/\(total)" }
        return String(value)
    }

    private func favorite(_ contentID: String) {
        handle(
            LocalUserStateMutator(modelContext: modelContext)
                .setFavorite(contentID: contentID, isFavorite: true)
        )
    }

    private func pinRecent(_ contentID: String) {
        handle(
            LocalUserStateMutator(modelContext: modelContext)
                .recordRecent(contentID: contentID, action: "pinned")
        )
    }

    private func removeRecent(_ contentID: String) {
        handle(
            LocalUserStateMutator(modelContext: modelContext)
                .removeRecent(contentID: contentID)
        )
    }

    private func handle<Success>(_ result: Result<Success, LocalMutationFailure>) {
        if case .failure(let failure) = result { mutationFailure = failure }
    }

    @ViewBuilder
    private func destinationView(_ destination: WorkbenchDestination) -> some View {
        switch destination {
        case .quickAction(let action):
            WorkbenchRecordDetailView(
                record: viewModel.record(id: viewModel.contentID(for: action)),
                settings: viewModel.settings,
                identifier: "workbench.quick.detail"
            )
        case .workflowStage(let id):
            if let stage = viewModel.stage(id: id) {
                WorkbenchStageDetailView(stage: stage, viewModel: viewModel)
            }
        case .deliveryChecklist:
            WorkbenchDeliveryChecklistView(items: snapshot.checklistItems, settings: viewModel.settings)
        case .recentRecords:
            WorkbenchContextListView(
                titleKey: "workbench.project.recent",
                systemImage: "clock",
                count: snapshot.recentContentIDs.count
            )
        case .favoriteTools:
            WorkbenchContextListView(
                titleKey: "workbench.project.favorites",
                systemImage: "star",
                count: snapshot.favoriteCount
            )
        case .notes:
            WorkbenchContextListView(
                titleKey: "workbench.project.notes",
                systemImage: "note.text",
                count: snapshot.noteCount
            )
        case .template(let id):
            WorkbenchTemplateDetailView(templateID: id, settings: viewModel.settings)
        case .record(let id):
            WorkbenchRecordDetailView(
                record: viewModel.record(id: id),
                settings: viewModel.settings,
                identifier: "workbench.record.detail"
            )
        }
    }
}

private struct WorkbenchSheetContainer<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        NavigationStack {
            content
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("common.done") { dismiss() }
                    }
                }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct WorkbenchStageDetailView: View {
    let stage: WorkflowStage
    let viewModel: WorkbenchViewModel

    var body: some View {
        List {
            Text("workbench.stage.detail")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("workbench.stage.detail")
            Text(stage.summary.resolved(for: viewModel.settings.language))
                .font(.headline)
            ForEach(Array(viewModel.stageSteps(for: stage.id).enumerated()), id: \.offset) { index, step in
                Label {
                    Text(step.resolved(for: viewModel.settings.language))
                } icon: {
                    Text("\(index + 1)")
                        .font(.caption.monospacedDigit().bold())
                        .foregroundStyle(.blue)
                }
            }
            Label {
                Text(stage.doneCheck.resolved(for: viewModel.settings.language))
            } icon: {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            }
        }
        .navigationTitle(stage.title.resolved(for: viewModel.settings.language))
    }
}

private struct WorkbenchRecordDetailView: View {
    let record: (any SearchableContent)?
    let settings: SettingsStore
    let identifier: String

    var body: some View {
        List {
            Text("workbench.detail.shortestPath")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.blue)
                .accessibilityIdentifier(identifier)
            if let record {
                Text(record.summary.resolved(for: settings.language))
                    .font(.headline)
                detailRows(for: record)
            } else {
                ContentUnavailableView("workbench.detail.unavailable", systemImage: "questionmark.folder")
            }
        }
        .navigationTitle(record?.title.resolved(for: settings.language) ?? "")
    }

    @ViewBuilder
    private func detailRows(for record: any SearchableContent) -> some View {
        if let shortcut = record as? ShortcutDefinition {
            let keys = settings.platform == .mac ? shortcut.mac : shortcut.win
            Text(keys.joined(separator: " + "))
                .font(.title3.monospaced().bold())
                .padding(.vertical, 8)
            Label(shortcut.menu.resolved(for: settings.language), systemImage: "menubar.rectangle")
        } else if let recipe = record as? RecipeDefinition {
            ForEach(Array(visible(recipe.steps).enumerated()), id: \.offset) { index, step in
                numberedRow(index, step)
            }
            riskRow(recipe.risk)
        } else if let export = record as? ExportRecipe {
            ForEach(Array(visible(export.specification).enumerated()), id: \.offset) { _, entry in
                LabeledContent(
                    entry.label.resolved(for: settings.language),
                    value: entry.value.resolved(for: settings.language)
                )
            }
            riskRow(export.risk)
        } else if let emergency = record as? EmergencyGuide {
            Label(emergency.cause.resolved(for: settings.language), systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            ForEach(Array(visible(emergency.fix).enumerated()), id: \.offset) { index, step in
                numberedRow(index, step)
            }
        }
    }

    private func visible<T>(_ items: [T]) -> [T] {
        settings.contentLevel == .quick ? Array(items.prefix(3)) : items
    }

    private func numberedRow(_ index: Int, _ text: LocalizedText) -> some View {
        Label {
            Text(text.resolved(for: settings.language))
        } icon: {
            Text("\(index + 1)")
                .font(.caption.monospacedDigit().bold())
                .foregroundStyle(.blue)
        }
    }

    private func riskRow(_ text: LocalizedText) -> some View {
        Label {
            Text(text.resolved(for: settings.language))
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }
}

private struct WorkbenchDeliveryChecklistView: View {
    let items: [WorkbenchViewModel.ChecklistEntry]
    let settings: SettingsStore

    var body: some View {
        List {
            Section {
                ForEach(items) { item in
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isCompleted ? .green : .secondary)
                            .accessibilityHidden(true)
                            .accessibilityIdentifier(
                                "workbench.delivery.\(item.contentID).\(item.isCompleted ? "completed" : "pending")"
                            )
                        Text(item.title.resolved(for: settings.language))
                            .font(.body.weight(.semibold))
                        Spacer()
                    }
                    .frame(minHeight: 44)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text(item.title.resolved(for: settings.language)))
                    .accessibilityValue(
                        Text(item.isCompleted ? "workbench.delivery.completed" : "workbench.delivery.pending")
                    )
                    .accessibilityIdentifier("workbench.delivery.row.\(item.contentID)")
                }
            } header: {
                HStack {
                    Text("workbench.delivery.detail")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .accessibilityIdentifier("workbench.delivery.detail")
                    Spacer()
                    Text("\(items.filter(\.isCompleted).count)/\(items.count)")
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("workbench.delivery.progress")
                }
                .textCase(nil)
            }
        }
        .navigationTitle(Text("workbench.project.deliveryChecklist"))
    }
}

private struct WorkbenchContextListView: View {
    let titleKey: LocalizedStringKey
    let systemImage: String
    let count: Int

    var body: some View {
        ContentUnavailableView {
            Label(titleKey, systemImage: systemImage)
        } description: {
            HStack(spacing: 0) {
                Text("\(count)")
                Text("workbench.context.localItems")
            }
        }
        .navigationTitle(Text(titleKey))
    }
}

private struct WorkbenchTemplateDetailView: View {
    let templateID: String
    let settings: SettingsStore

    var body: some View {
        ContentUnavailableView {
            Label("workbench.startWorkflow", systemImage: "play.rectangle.on.rectangle")
        } description: {
            Text("workbench.template.localOnly")
        }
        .navigationTitle(templateID)
    }
}
