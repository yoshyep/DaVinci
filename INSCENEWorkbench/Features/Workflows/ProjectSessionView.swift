import SwiftData
import SwiftUI

struct ProjectSessionView: View {
    let session: ProjectSession
    let repository: GuideContentRepository
    let settings: SettingsStore

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserNote.updatedAt, order: .reverse) private var allNotes: [UserNote]
    @Query(sort: \ProjectVersionRecord.createdAt, order: .reverse) private var allVersions: [ProjectVersionRecord]
    @State private var noteBody = ""
    @State private var versionName = ""
    @State private var resolveVersion = "20"
    @State private var mutationFailure: LocalMutationFailure?

    private var stages: [WorkflowStage] {
        repository.content.stages.sorted { $0.number < $1.number }
    }

    private var notes: [UserNote] {
        allNotes.filter { $0.sessionID == session.id }
    }

    private var versions: [ProjectVersionRecord] {
        allVersions.filter { $0.sessionID == session.id }
    }

    var body: some View {
        List {
            projectHeader
            stageSection
            checklistSection
            noteSection
            versionSection
        }
        .navigationTitle(session.name)
        .navigationBarTitleDisplayMode(.inline)
        .localMutationAlert(failure: $mutationFailure, language: settings.language)
    }

    private var projectHeader: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(copy("项目进度", "Project Progress"), systemImage: "film.stack")
                        .font(.headline)
                    Spacer()
                    Text("\(completedStageCount)/\(stages.count)")
                        .font(.subheadline.monospacedDigit().bold())
                        .foregroundStyle(.green)
                }
                ProgressView(
                    value: Double(completedStageCount),
                    total: Double(max(stages.count, 1))
                )
                .tint(.green)
                LabeledContent(copy("模板", "Template"), value: templateName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label(copy("仅保存在本机", "Stored only on this device"), systemImage: "lock.iphone")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
        }
    }

    private var stageSection: some View {
        Section {
            ForEach(stages, id: \.id) { stage in
                Button {
                    toggleStage(stage)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: isStageComplete(stage.id) ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(isStageComplete(stage.id) ? .green : Color(stageHex: stage.color))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(stage.title.resolved(for: settings.language))
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(stage.doneCheck.resolved(for: settings.language))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(stage.title.resolved(for: settings.language))
                .accessibilityValue(isStageComplete(stage.id) ? copy("已完成", "Completed") : copy("待完成", "Pending"))
                .accessibilityHint(copy("切换阶段完成状态", "Toggles stage completion"))
                .accessibilityIdentifier("workflows.project.stage.\(stage.number)")
            }
        } header: {
            Text(copy("阶段检查", "Stage Checklist"))
        } footer: {
            Text(copy(
                "完成标准来自官方十阶段详情；点击一行可切换状态。",
                "Completion criteria come from the official stage details; tap a row to toggle state."
            ))
        }
    }

    private var checklistSection: some View {
        Section {
            if session.checklistStates.isEmpty {
                Label(
                    copy("尚未应用专业工作手册", "No professional playbook applied yet"),
                    systemImage: "text.badge.plus"
                )
                .foregroundStyle(.secondary)
                .frame(minHeight: 44)
            } else {
                ForEach(session.checklistStates.sorted { $0.createdAt < $1.createdAt }) { state in
                    Button {
                        toggleChecklist(state)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: state.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(state.isCompleted ? .green : .secondary)
                                .accessibilityHidden(true)
                            Text(checklistTitle(for: state.contentID))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(checklistTitle(for: state.contentID))
                    .accessibilityValue(state.isCompleted ? copy("已完成", "Completed") : copy("待完成", "Pending"))
                }
            }
        } header: {
            HStack {
                Text(copy("专业检查表", "Professional Checklist"))
                Spacer()
                if !session.checklistStates.isEmpty {
                    Text("\(session.completedChecklistCount)/\(session.checklistStates.count)")
                        .font(.caption.monospacedDigit().bold())
                        .foregroundStyle(.green)
                }
            }
        } footer: {
            Text(copy(
                "在专业工作手册详情中选择“应用到当前项目”，即可加入可勾选项目。",
                "Choose Apply to Current Project in a playbook to add its actionable checks."
            ))
        }
    }

    private var noteSection: some View {
        Section {
            TextEditor(text: $noteBody)
                .frame(minHeight: 96)
                .accessibilityLabel(copy("项目笔记", "Project note"))
                .accessibilityIdentifier("workflows.project.note")

            Button {
                addNote()
            } label: {
                Label(copy("保存笔记", "Save Note"), systemImage: "note.text.badge.plus")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .disabled(trimmedNote.isEmpty)

            ForEach(notes) { note in
                VStack(alignment: .leading, spacing: 5) {
                    Text(note.body)
                    Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text(copy("项目笔记", "Project Notes"))
        }
    }

    private var versionSection: some View {
        Section {
            TextField(copy("版本名称，例如：客户审片 v2", "Version name, e.g. Client review v2"), text: $versionName)
                .accessibilityIdentifier("workflows.project.versionName")
            TextField(copy("Resolve 版本", "Resolve version"), text: $resolveVersion)
                .textInputAutocapitalization(.never)
                .accessibilityIdentifier("workflows.project.resolveVersion")

            Button {
                addVersion()
            } label: {
                Label(copy("记录版本", "Record Version"), systemImage: "clock.badge.checkmark")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .disabled(trimmedVersionName.isEmpty || trimmedResolveVersion.isEmpty)

            ForEach(versions) { version in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(version.name)
                            .font(.subheadline.weight(.semibold))
                        Text(version.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("Resolve \(version.resolveVersion)")
                        .font(.caption.monospaced().weight(.semibold))
                        .foregroundStyle(.blue)
                }
                .padding(.vertical, 3)
            }
        } header: {
            Text(copy("版本记录", "Version Records"))
        } footer: {
            Text(copy(
                "记录用于本机交接与回退跟踪，不会读取或修改 Resolve 工程。",
                "Records support local handoff and rollback tracking; the app never reads or changes a Resolve project."
            ))
        }
    }

    private var completedStageCount: Int {
        Set(session.stageProgress.filter(\.isCompleted).map(\.contentID)).count
    }

    private var trimmedNote: String {
        noteBody.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedVersionName: String {
        versionName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedResolveVersion: String {
        resolveVersion.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var templateName: String {
        switch session.templateID {
        case "template-interview-edit": copy("访谈剪辑", "Interview Edit")
        case "template-short-form-delivery": copy("短视频交付", "Short-form Delivery")
        case "template-shot-matching": copy("调色匹配", "Shot Matching")
        default: session.templateID
        }
    }

    private func isStageComplete(_ contentID: String) -> Bool {
        session.stageProgress.first { $0.contentID == contentID }?.isCompleted == true
    }

    private func toggleStage(_ stage: WorkflowStage) {
        handle(
            LocalUserStateMutator(modelContext: modelContext).setStageCompletion(
                session: session,
                contentID: stage.id,
                completed: !isStageComplete(stage.id)
            )
        )
    }

    private func toggleChecklist(_ state: ChecklistItemState) {
        handle(
            LocalUserStateMutator(modelContext: modelContext).setChecklistCompletion(
                session: session,
                contentID: state.contentID,
                completed: !state.isCompleted
            )
        )
    }

    private func addNote() {
        let result = LocalUserStateMutator(modelContext: modelContext).addProjectNote(
            session: session,
            contentID: "project-note",
            body: trimmedNote
        )
        if case .success = result { noteBody = "" }
        handle(result)
    }

    private func addVersion() {
        let result = LocalUserStateMutator(modelContext: modelContext).recordProjectVersion(
            session: session,
            name: trimmedVersionName,
            resolveVersion: trimmedResolveVersion
        )
        if case .success = result { versionName = "" }
        handle(result)
    }

    private func checklistTitle(for contentID: String) -> String {
        let delimiter = ".checklist."
        let components = contentID.components(separatedBy: delimiter)
        if components.count == 2,
           let playbook = repository.content.playbooks.first(where: { $0.id == components[0] }),
           let item = playbook.checklist.first(where: { $0.id == components[1] }) {
            return item.text.resolved(for: settings.language)
        }
        if let record = repository.record(id: contentID) {
            return record.title.resolved(for: settings.language)
        }
        return contentID.replacingOccurrences(of: "-", with: " ")
    }

    private func handle<Success>(_ result: Result<Success, LocalMutationFailure>) {
        if case .failure(let failure) = result { mutationFailure = failure }
    }

    private func copy(_ zhHans: String, _ en: String) -> String {
        settings.language == .zhHans ? zhHans : en
    }
}

struct ProjectCreationView: View {
    let repository: GuideContentRepository
    let settings: SettingsStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var templateID = "template-interview-edit"
    @State private var mutationFailure: LocalMutationFailure?

    var body: some View {
        Form {
            Section {
                TextField(copy("项目名称", "Project name"), text: $name)
                    .accessibilityIdentifier("workflows.create.name")
                Picker(selection: $templateID) {
                    ForEach(templates, id: \.id) { template in
                        Label(template.title.resolved(for: settings.language), systemImage: template.systemImage)
                            .tag(template.id)
                    }
                } label: {
                    Text(copy("模板", "Template"))
                }
                .accessibilityIdentifier("workflows.create.template")
            } header: {
                Text(copy("项目", "Project"))
            } footer: {
                Text(copy(
                    "将创建十个官方阶段；之后可应用任意专业工作手册。",
                    "Creates all ten official stages; professional playbooks can be applied afterward."
                ))
            }

            Section {
                Button {
                    createProject()
                } label: {
                    Label(copy("创建项目", "Create Project"), systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(trimmedName.isEmpty)
                .accessibilityIdentifier("workflows.create.confirm")
            }
        }
        .navigationTitle(copy("新建项目", "New Project"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(copy("取消", "Cancel")) { dismiss() }
            }
        }
        .localMutationAlert(failure: $mutationFailure, language: settings.language)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var templates: [ProjectTemplateChoice] {
        [
            ProjectTemplateChoice(
                id: "template-interview-edit",
                title: LocalizedText(zhHans: "访谈剪辑", en: "Interview Edit"),
                systemImage: "person.wave.2"
            ),
            ProjectTemplateChoice(
                id: "template-short-form-delivery",
                title: LocalizedText(zhHans: "短视频交付", en: "Short-form Delivery"),
                systemImage: "rectangle.portrait.and.arrow.forward"
            ),
            ProjectTemplateChoice(
                id: "template-shot-matching",
                title: LocalizedText(zhHans: "调色匹配", en: "Shot Matching"),
                systemImage: "circle.lefthalf.filled"
            )
        ]
    }

    private func createProject() {
        let stageIDs = repository.content.stages
            .sorted { $0.number < $1.number }
            .map(\.id)
        let result = LocalUserStateMutator(modelContext: modelContext).createProject(
            name: trimmedName,
            templateID: templateID,
            stageIDs: stageIDs
        )
        switch result {
        case .success:
            dismiss()
        case .failure(let failure):
            mutationFailure = failure
        }
    }

    private func copy(_ zhHans: String, _ en: String) -> String {
        settings.language == .zhHans ? zhHans : en
    }
}

private struct ProjectTemplateChoice: Identifiable {
    let id: String
    let title: LocalizedText
    let systemImage: String
}
