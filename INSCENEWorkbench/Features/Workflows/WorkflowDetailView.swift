import SwiftUI

struct WorkflowDetailView: View {
    let stage: WorkflowStage
    let repository: GuideContentRepository
    let settings: SettingsStore

    @State private var isProfessionalExpanded: Bool

    init(
        stage: WorkflowStage,
        repository: GuideContentRepository,
        settings: SettingsStore
    ) {
        self.stage = stage
        self.repository = repository
        self.settings = settings
        _isProfessionalExpanded = State(initialValue: settings.contentLevel == .professional)
    }

    private var shortcuts: [ShortcutDefinition] {
        stage.shortcutIDs.compactMap { id in
            repository.content.shortcuts.first { $0.id == id }
        }
    }

    private var officialSources: [SourceReference] {
        repository.content.sources.filter { $0.id == "source-blackmagic-training" }
    }

    var body: some View {
        List {
            stageHeader

            Section {
                Text(stage.summary.resolved(for: settings.language))
                    .font(.headline)
                numberedRows(stage.quickSteps, color: Color(stageHex: stage.color))
            } header: {
                Label(copy("快速路径", "Quick Path"), systemImage: "bolt.fill")
            }

            Section {
                DisclosureGroup(isExpanded: $isProfessionalExpanded) {
                    VStack(alignment: .leading, spacing: 16) {
                        numberedRows(stage.proSteps, color: .indigo)
                        if !stage.proNotes.isEmpty {
                            Divider()
                            Text(copy("专业提示", "Professional Notes"))
                                .font(.headline)
                            ForEach(Array(stage.proNotes.enumerated()), id: \.offset) { _, note in
                                Label {
                                    Text(note.resolved(for: settings.language))
                                } icon: {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundStyle(.yellow)
                                }
                            }
                        }
                    }
                    .padding(.top, 10)
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(copy("展开专业说明", "Professional Disclosure"))
                            .font(.headline)
                        Text(copy(
                            "查看完整步骤、决策依据与例外。",
                            "Show the complete procedure, decision context, and exceptions."
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .frame(minHeight: 44, alignment: .leading)
                }
                .accessibilityIdentifier("workflows.stage.professionalDisclosure")
            }

            Section {
                Label {
                    Text(stage.doneCheck.resolved(for: settings.language))
                } icon: {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
                .frame(minHeight: 44)

                Label {
                    Text(stage.mistake.resolved(for: settings.language))
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
                .frame(minHeight: 44)
            } header: {
                Text(copy("完成标准与常见错误", "Done Check and Common Mistake"))
            }

            if !shortcuts.isEmpty {
                Section {
                    ForEach(shortcuts, id: \.id) { shortcut in
                        VStack(alignment: .leading, spacing: 7) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(shortcut.title.resolved(for: settings.language))
                                    .font(.subheadline.weight(.semibold))
                                Spacer(minLength: 12)
                                Text(keys(for: shortcut))
                                    .font(.caption.monospaced().weight(.semibold))
                                    .foregroundStyle(.blue)
                                    .multilineTextAlignment(.trailing)
                            }
                            Text(shortcut.menu.resolved(for: settings.language))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        .frame(minHeight: 44)
                        .accessibilityElement(children: .combine)
                    }
                } header: {
                    HStack {
                        Text(copy("快捷键", "Shortcuts"))
                        Spacer()
                        Text(settings.platform == .mac ? "Mac" : "Windows")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.blue)
                    }
                } footer: {
                    Text(copy(
                        "键位可能被自定义；执行前确认当前焦点页面。",
                        "Mappings may be customized; confirm the focused page before using a key."
                    ))
                }
            }

            if settings.showsSources {
                Section {
                    ForEach(officialSources) { source in
                        VStack(alignment: .leading, spacing: 8) {
                            SourceBadge(title: copy("Blackmagic 官方资料", "Blackmagic official material"), kind: .official)
                            Text(source.title.resolved(for: settings.language))
                                .font(.subheadline.weight(.semibold))
                            sourceMetadata(source)
                            if let url = URL(string: source.url) {
                                Link(destination: url) {
                                    Label(copy("查看公开来源", "Open Public Source"), systemImage: "arrow.up.right.square")
                                        .frame(minHeight: 44)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text(copy("来源", "Sources"))
                } footer: {
                    Text(copy(
                        "来源链接仅供核对；工作流程正文已内置，本应用不会在后台下载内容。",
                        "Links are for verification only; workflow guidance is bundled and the app never downloads content in the background."
                    ))
                }
            }
        }
        .navigationTitle(stage.title.resolved(for: settings.language))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: settings.contentLevel) { _, level in
            isProfessionalExpanded = level == .professional
        }
    }

    private var stageHeader: some View {
        HStack(alignment: .center, spacing: 15) {
            Text(String(format: "%02d", stage.number))
                .font(.title2.monospacedDigit().bold())
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Color(stageHex: stage.color), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(copy("官方流程阶段", "Official Workflow Stage"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(stageHex: stage.color))
                Text(stage.title.resolved(for: settings.language))
                    .font(.title2.bold())
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stage.number). \(stage.title.resolved(for: settings.language))")
    }

    @ViewBuilder
    private func numberedRows(_ items: [LocalizedText], color: Color) -> some View {
        ForEach(Array(items.enumerated()), id: \.offset) { index, step in
            HStack(alignment: .top, spacing: 11) {
                Text("\(index + 1)")
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(color, in: Circle())
                    .accessibilityHidden(true)
                Text(step.resolved(for: settings.language))
                    .frame(maxWidth: .infinity, minHeight: 26, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(index + 1). \(step.resolved(for: settings.language))")
        }
    }

    private func keys(for shortcut: ShortcutDefinition) -> String {
        let keys = settings.platform == .mac ? shortcut.mac : shortcut.win
        return keys.isEmpty
            ? copy("菜单", "Menu")
            : keys.joined(separator: " + ")
    }

    @ViewBuilder
    private func sourceMetadata(_ source: SourceReference) -> some View {
        let published = source.publishedDate ?? copy("未标注发布日期", "No publication date shown")
        Text("\(copy("发布", "Published")): \(published) · \(copy("复核", "Reviewed")): \(source.lastReviewedDate)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func copy(_ zhHans: String, _ en: String) -> String {
        settings.language == .zhHans ? zhHans : en
    }
}
