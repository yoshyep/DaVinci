import SwiftUI
import SwiftData

struct ContentDetailView: View {
    let record: any SearchableContent
    let repository: GuideContentRepository
    let settings: SettingsStore

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Favorite.updatedAt, order: .reverse) private var favorites: [Favorite]
    @Query(sort: \UserNote.updatedAt, order: .reverse) private var allNotes: [UserNote]
    @Query(sort: \ProjectSession.updatedAt, order: .reverse) private var sessions: [ProjectSession]

    @State private var newNoteText = ""
    @State private var showingNoteEditor = false
    @State private var selectedSessionID: UUID?
    @State private var mutationFailure: LocalMutationFailure?
    @State private var addResultMessage: String?

    var body: some View {
        List {
            identitySection
            quickExplanationSection
            deeperPrincipleSection
            sourceSection
            notesSection
            actionsSection
        }
        .navigationTitle(record.title.resolved(for: settings.language))
        .navigationBarTitleDisplayMode(.inline)
        .localMutationAlert(failure: $mutationFailure, language: settings.language)
    }

    // MARK: - Identity Section

    private var identitySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Label(kindTitle, systemImage: kindSymbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(kindTint)
                Text(record.title.resolved(for: settings.language))
                    .font(.title.bold())
                Text(record.summary.resolved(for: settings.language))
                    .font(.body)
                    .foregroundStyle(.secondary)
                Label(copy("本地内置", "Offline built-in"), systemImage: "checkmark.shield")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Quick Explanation (30-second)

    private var quickExplanationSection: some View {
        Section {
            if quickLines.isEmpty {
                Label(copy("暂无快速摘要", "No quick summary available"), systemImage: "clock")
                    .foregroundStyle(.secondary)
                    .frame(minHeight: 44)
            } else {
                ForEach(Array(quickLines.enumerated()), id: \.offset) { index, line in
                    Label(line, systemImage: "\(index + 1).circle.fill")
                        .frame(minHeight: 36)
                }
            }
        } header: {
            Text(copy("30 秒说明", "30-Second Explanation"))
        }
    }

    // MARK: - Deeper Principle

    private var deeperPrincipleSection: some View {
        Group {
            if !professionalLines.isEmpty {
                Section {
                    ForEach(Array(professionalLines.enumerated()), id: \.offset) { index, line in
                        Label(line, systemImage: "\(index + 1).circle")
                            .frame(minHeight: 36)
                    }
                } header: {
                    Text(copy("深入原理", "Deeper Principle"))
                }
            }

            if let risk = risk, !risk.isEmpty {
                Section {
                    Label(risk, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .frame(minHeight: 44)
                } header: {
                    Text(copy("风险与检查", "Risk and Check"))
                }
            }
        }
    }

    // MARK: - Source Section (for playbooks)

    private var sourceSection: some View {
        Group {
            if let playbook = record as? ExpertPlaybook, settings.showsSources {
                Section {
                    if let url = URL(string: playbook.sourceURL) {
                        Link(destination: url) {
                            Label(copy("查看公开来源", "Open Public Source"), systemImage: "arrow.up.right.square")
                                .frame(minHeight: 44)
                        }
                        .accessibilityIdentifier("library.detail.sourceLink")
                    }
                    LabeledContent(
                        copy("资料复核", "Source reviewed"),
                        value: playbook.lastReviewedDate
                    )
                } header: {
                    Text(copy("来源", "Source"))
                }
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        Section {
            ForEach(contentNotes) { note in
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.body)
                        .font(.body)
                    Text(note.createdAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(minHeight: 44, alignment: .leading)
            }

            if showingNoteEditor {
                VStack(alignment: .leading, spacing: 8) {
                    TextField(
                        copy("输入笔记…", "Write a note…"),
                        text: $newNoteText,
                        axis: .vertical
                    )
                    .textFieldStyle(.roundedBorder)
                    .frame(minHeight: 44)

                    HStack {
                        Button(copy("取消", "Cancel")) {
                            newNoteText = ""
                            showingNoteEditor = false
                        }
                        .frame(minHeight: 44)

                        Spacer()

                        Button(copy("保存", "Save")) {
                            saveNote()
                        }
                        .frame(minHeight: 44)
                        .disabled(newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            } else {
                Button {
                    showingNoteEditor = true
                } label: {
                    Label(copy("添加笔记", "Add Note"), systemImage: "note.text.badge.plus")
                        .frame(minHeight: 44)
                }
                .accessibilityIdentifier("library.detail.addNote")
            }
        } header: {
            HStack {
                Text(copy("笔记", "Notes"))
                Spacer()
                if !contentNotes.isEmpty {
                    Text("\(contentNotes.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        Section {
            Button {
                toggleFavorite()
            } label: {
                Label(
                    isFavorite ? copy("取消收藏", "Remove Favorite") : copy("收藏", "Favorite"),
                    systemImage: isFavorite ? "star.fill" : "star"
                )
            }
            .frame(minHeight: 44)
            .accessibilityIdentifier("library.detail.favorite")

            ShareLink(item: shareText) {
                Label(copy("分享", "Share"), systemImage: "square.and.arrow.up")
                    .frame(minHeight: 44)
            }
            .accessibilityIdentifier("library.detail.share")

            if !sessions.isEmpty {
                Picker(selection: Binding(
                    get: { selectedSessionID ?? sessions.first?.id },
                    set: { selectedSessionID = $0 }
                )) {
                    ForEach(sessions) { session in
                        Text(session.name).tag(Optional(session.id))
                    }
                } label: {
                    Text(copy("目标项目", "Target project"))
                }

                Button {
                    addToProject()
                } label: {
                    Label(copy("加入项目检查表", "Add to Checklist"), systemImage: "text.badge.plus")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("library.detail.addToProject")
            }

            if let addResultMessage {
                Label(addResultMessage, systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
            }
        }
    }

    // MARK: - Computed Properties

    private var contentNotes: [UserNote] {
        allNotes.filter { $0.contentID == record.id }
    }

    private var isFavorite: Bool {
        favorites.contains { $0.contentID == record.id }
    }

    private var shareText: String {
        "\(record.title.resolved(for: settings.language))\n\(record.summary.resolved(for: settings.language))"
    }

    private var quickLines: [String] {
        let language = settings.language
        if let recipe = record as? RecipeDefinition { return Array(recipe.steps.prefix(3)).map { $0.resolved(for: language) } }
        if let color = record as? ColorPass { return Array(color.steps.prefix(3)).map { $0.resolved(for: language) } }
        if let export = record as? ExportRecipe {
            return Array(export.specification.prefix(3)).map { "\($0.label.resolved(for: language)): \($0.value.resolved(for: language))" }
        }
        if let emergency = record as? EmergencyGuide { return Array(emergency.fix.prefix(3)).map { $0.resolved(for: language) } }
        if let stage = record as? WorkflowStage { return Array(stage.quickSteps.prefix(3)).map { $0.resolved(for: language) } }
        if let playbook = record as? ExpertPlaybook { return Array(playbook.steps.prefix(3)).map { $0.resolved(for: language) } }
        if let shortcut = record as? ShortcutDefinition {
            let keys = settings.platform == .mac ? shortcut.mac : shortcut.win
            return [keys.isEmpty ? copy("通过菜单执行", "Use the menu") : keys.joined(separator: " + ")]
        }
        return []
    }

    private var professionalLines: [String] {
        let language = settings.language
        if let recipe = record as? RecipeDefinition { return recipe.steps.map { $0.resolved(for: language) } + [recipe.doneCheck.resolved(for: language)] }
        if let color = record as? ColorPass { return color.steps.map { $0.resolved(for: language) } + color.tools.map { $0.resolved(for: language) } + color.scopes.map { $0.resolved(for: language) } }
        if let export = record as? ExportRecipe { return [export.bitrate.resolved(for: language)] + export.subtitles.map { $0.resolved(for: language) } + export.fileChecks.map { $0.resolved(for: language) } }
        if let emergency = record as? EmergencyGuide { return emergency.fix.map { $0.resolved(for: language) } + [emergency.deep.resolved(for: language), emergency.prevent.resolved(for: language)] }
        if let stage = record as? WorkflowStage { return stage.proSteps.map { $0.resolved(for: language) } + stage.proNotes.map { $0.resolved(for: language) } }
        if let playbook = record as? ExpertPlaybook { return playbook.steps.map { $0.resolved(for: language) } }
        return []
    }

    private var risk: String? {
        let language = settings.language
        if let recipe = record as? RecipeDefinition { return recipe.risk.resolved(for: language) }
        if let color = record as? ColorPass { return color.risk.resolved(for: language) }
        if let export = record as? ExportRecipe { return export.risk.resolved(for: language) }
        if let emergency = record as? EmergencyGuide { return emergency.cause.resolved(for: language) }
        if let stage = record as? WorkflowStage { return stage.mistake.resolved(for: language) }
        return nil
    }

    private var kindTitle: String {
        let zh = settings.language == .zhHans
        switch record.kind {
        case .shortcut: return zh ? "快捷键" : "Shortcut"
        case .recipe: return zh ? "经典操作" : "Action"
        case .colorPass: return zh ? "调色" : "Color"
        case .export: return zh ? "输出" : "Export"
        case .emergency: return zh ? "故障急救" : "Troubleshooting"
        case .stage: return zh ? "官方流程" : "Workflow"
        case .playbook: return zh ? "专业流程" : "Professional"
        }
    }

    private var kindSymbol: String {
        switch record.kind {
        case .shortcut: "keyboard"
        case .recipe: "bolt"
        case .colorPass: "scope"
        case .export: "square.and.arrow.up"
        case .emergency: "cross.case"
        case .stage: "checklist"
        case .playbook: "person.text.rectangle"
        }
    }

    private var kindTint: Color {
        switch record.kind {
        case .emergency: .red
        case .export: .green
        case .colorPass: .purple
        default: .blue
        }
    }

    // MARK: - Actions

    private func toggleFavorite() {
        handle(
            LocalUserStateMutator(modelContext: modelContext)
                .setFavorite(contentID: record.id, isFavorite: !isFavorite)
        )
    }

    private func saveNote() {
        let body = newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }

        let note = UserNote(contentID: record.id, body: body)
        modelContext.insert(note)

        do {
            try modelContext.save()
            newNoteText = ""
            showingNoteEditor = false
        } catch {
            mutationFailure = .saveFailed
            modelContext.rollback()
        }
    }

    private func addToProject() {
        guard let target = sessions.first(where: { $0.id == (selectedSessionID ?? sessions.first?.id) }) else { return }
        let result = LocalUserStateMutator(modelContext: modelContext)
            .addToChecklist(session: target, contentID: record.id)

        switch result {
        case .success(let outcome):
            addResultMessage = outcome == .alreadyPresent
                ? copy("已在检查表中", "Already in checklist")
                : copy("已添加到检查表", "Added to checklist")
        case .failure(let failure):
            mutationFailure = failure
        }
    }

    private func handle<Success>(_ result: Result<Success, LocalMutationFailure>) {
        if case .failure(let failure) = result { mutationFailure = failure }
    }

    private func copy(_ zhHans: String, _ en: String) -> String {
        settings.language == .zhHans ? zhHans : en
    }
}
