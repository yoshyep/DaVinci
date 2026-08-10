import SwiftData
import SwiftUI
import UIKit

struct ShortcutDetailView: View {
    let shortcut: ShortcutDefinition
    let repository: GuideContentRepository
    let settings: SettingsStore
    let router: AppRouter

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Favorite.updatedAt, order: .reverse) private var favorites: [Favorite]
    @Query(sort: \ProjectSession.updatedAt, order: .reverse) private var sessions: [ProjectSession]
    @State private var copied = false
    @State private var mutationFailure: LocalMutationFailure?

    var body: some View {
        List {
            Section {
                Text(copy("快捷键详情", "Shortcut Detail"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("lookup.shortcut.detail")
                Text(shortcut.title.resolved(for: settings.language))
                    .font(.title.bold())
                Text(shortcut.summary.resolved(for: settings.language))
                    .font(.body)
                    .foregroundStyle(.secondary)
                Label(
                    copy("本地内置·Resolve 20", "Offline built-in · Resolve 20"),
                    systemImage: "checkmark.shield"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.blue)
            }

            Section(copy("动作与键位", "Action and keys")) {
                KeycapView(
                    contentID: shortcut.id,
                    actionTitle: shortcut.title.resolved(for: settings.language),
                    subtitle: copy("点击复制键位", "Tap to copy the keys"),
                    keys: keys,
                    language: settings.language,
                    actionHint: copy("复制键位和菜单路径", "Copies keys and menu path")
                ) {
                    copyShortcut()
                }
                if copied {
                    Label(copy("已复制", "Copied"), systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }

            Section(copy("菜单路径", "Menu path")) {
                Label(shortcut.menu.resolved(for: settings.language), systemImage: "menucard")
                    .textSelection(.enabled)
            }

            Section(copy("适用场景", "Context")) {
                Label(shortcut.category.resolved(for: settings.language), systemImage: "square.grid.2x2")
                ForEach(stageTitles, id: \.self) { title in
                    Label(title, systemImage: "flag")
                }
            }

            if shortcut.flags.contains("risk") {
                Section(copy("风险", "Risk")) {
                    Label(
                        copy("该动作可能改变时间线或当前工作状态。执行后立即检查结果，并确保可以撤销。", "This action can change the timeline or current working state. Inspect the result immediately and keep Undo available."),
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(.orange)
                }
            }

            if settings.contentLevel == .professional {
                Section(copy("专业提示", "Professional context")) {
                    Label(
                        copy("执行前先确认焦点所在的面板，自定义键位可能覆盖默认绑定。", "Confirm the focused panel first; custom keyboard mappings can override the default binding."),
                        systemImage: "lightbulb"
                    )
                    if shortcut.flags.contains("mapping") {
                        Label(
                            copy("该动作可能没有默认键位，请从键盘自定义中确认。", "This action may not have a default key; verify it in Keyboard Customization."),
                            systemImage: "keyboard.badge.ellipsis"
                        )
                    }
                    if shortcut.flags.isEmpty {
                        Label(
                            copy("没有记录到额外风险，但建议用撤销可恢复的素材先验证键位。", "No extra risk is recorded; verify the binding on material that can be recovered with Undo."),
                            systemImage: "checkmark.circle"
                        )
                        .foregroundStyle(.secondary)
                    }
                }
            }

            if !relatedShortcuts.isEmpty {
                Section(copy("相邻快捷键", "Related shortcuts")) {
                    ForEach(relatedShortcuts) { related in
                        KeycapView(
                            contentID: related.id,
                            actionTitle: related.title.resolved(for: settings.language),
                            subtitle: related.summary.resolved(for: settings.language),
                            keys: settings.platform == .mac ? related.mac : related.win,
                            language: settings.language
                        ) {
                            router.lookupPath.append(.record(related.id))
                        }
                    }
                }
            }

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

                if let session = sessions.first {
                    Button {
                        handle(
                            LocalUserStateMutator(modelContext: modelContext)
                                .addToChecklist(session: session, contentID: shortcut.id)
                        )
                    } label: {
                        Label(copy("加入当前项目检查表", "Add to Current Checklist"), systemImage: "text.badge.plus")
                    }
                    .frame(minHeight: 44)
                }

                Button {
                    copyShortcut()
                } label: {
                    Label(copy("复制键位与菜单", "Copy Keys and Menu"), systemImage: "doc.on.doc")
                }
                .frame(minHeight: 44)

                ShareLink(item: shareText) {
                    Label(copy("分享", "Share"), systemImage: "square.and.arrow.up")
                        .frame(minHeight: 44)
                }
            }
        }
        .navigationTitle(shortcut.title.resolved(for: settings.language))
        .navigationBarTitleDisplayMode(.inline)
        .task { recordRecentUse() }
        .localMutationAlert(failure: $mutationFailure, language: settings.language)
    }

    private var keys: [String] {
        settings.platform == .mac ? shortcut.mac : shortcut.win
    }

    private var stageTitles: [String] {
        shortcut.stages.compactMap { id in
            repository.content.stages.first(where: { $0.id == id })?.title.resolved(for: settings.language)
        }
    }

    private var relatedShortcuts: [ShortcutDefinition] {
        Array(repository.content.shortcuts.filter { candidate in
            candidate.id != shortcut.id && (
                candidate.category.en == shortcut.category.en ||
                !Set(candidate.stages).isDisjoint(with: shortcut.stages)
            )
        }.prefix(4))
    }

    private var isFavorite: Bool {
        favorites.contains { $0.contentID == shortcut.id }
    }

    private var shareText: String {
        let joinedKeys = keys.isEmpty ? copy("通过菜单执行", "Use the menu") : keys.joined(separator: " + ")
        return "\(shortcut.title.resolved(for: settings.language))\n\(joinedKeys)\n\(shortcut.menu.resolved(for: settings.language))"
    }

    private func copyShortcut() {
        UIPasteboard.general.string = shareText
        copied = true
    }

    private func toggleFavorite() {
        handle(
            LocalUserStateMutator(modelContext: modelContext)
                .setFavorite(contentID: shortcut.id, isFavorite: !isFavorite)
        )
    }

    private func recordRecentUse() {
        handle(
            LocalUserStateMutator(modelContext: modelContext)
                .recordRecent(contentID: shortcut.id)
        )
    }

    private func handle<Success>(_ result: Result<Success, LocalMutationFailure>) {
        if case .failure(let failure) = result { mutationFailure = failure }
    }

    private func copy(_ zhHans: String, _ en: String) -> String {
        settings.language == .zhHans ? zhHans : en
    }
}

struct QuickLookupRecordDetailView: View {
    let record: any SearchableContent
    let repository: GuideContentRepository
    let settings: SettingsStore
    let router: AppRouter

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Favorite.updatedAt, order: .reverse) private var favorites: [Favorite]
    @State private var mutationFailure: LocalMutationFailure?

    var body: some View {
        List {
            Section {
                Text(copy("工具详情", "Tool Detail"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("lookup.record.detail")
                Text(record.title.resolved(for: settings.language))
                    .font(.title.bold())
                Text(record.summary.resolved(for: settings.language))
                    .foregroundStyle(.secondary)
                Label(copy("本地内置", "Offline built-in"), systemImage: "checkmark.shield")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)
            }

            if !quickLines.isEmpty {
                Section(copy("最短操作", "Shortest answer")) {
                    ForEach(Array(quickLines.enumerated()), id: \.offset) { index, line in
                        Label(line, systemImage: "\(index + 1).circle.fill")
                    }
                }
            }

            if let risk, !risk.isEmpty {
                Section(copy("风险与检查", "Risk and check")) {
                    Label(risk, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }

            if settings.contentLevel == .professional, !professionalLines.isEmpty {
                Section(copy("专业上下文", "Professional context")) {
                    ForEach(Array(professionalLines.enumerated()), id: \.offset) { index, line in
                        Label(line, systemImage: "\(index + 1).circle")
                    }
                }
            }

            if !relatedShortcutIDs.isEmpty {
                Section(copy("相关快捷键", "Related shortcuts")) {
                    ForEach(relatedShortcutIDs, id: \.self) { id in
                        if let shortcut = repository.record(id: id) as? ShortcutDefinition {
                            KeycapView(
                                contentID: shortcut.id,
                                actionTitle: shortcut.title.resolved(for: settings.language),
                                subtitle: shortcut.summary.resolved(for: settings.language),
                                keys: settings.platform == .mac ? shortcut.mac : shortcut.win,
                                language: settings.language,
                                elementIdentifier: "lookup.related.\(shortcut.id)"
                            ) {
                                router.lookupPath.append(.record(shortcut.id))
                            }
                        }
                    }
                }
            }

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
                ShareLink(item: shareText) {
                    Label(copy("分享摘要", "Share Summary"), systemImage: "square.and.arrow.up")
                        .frame(minHeight: 44)
                }
            }
        }
        .navigationTitle(record.title.resolved(for: settings.language))
        .navigationBarTitleDisplayMode(.inline)
        .task { recordRecentUse() }
        .localMutationAlert(failure: $mutationFailure, language: settings.language)
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

    private var relatedShortcutIDs: [String] {
        if let recipe = record as? RecipeDefinition { return recipe.shortcutIDs }
        if let color = record as? ColorPass { return color.shortcutIDs }
        if let stage = record as? WorkflowStage { return stage.shortcutIDs }
        return []
    }

    private var isFavorite: Bool { favorites.contains { $0.contentID == record.id } }

    private var shareText: String {
        "\(record.title.resolved(for: settings.language))\n\(record.summary.resolved(for: settings.language))"
    }

    private func toggleFavorite() {
        handle(
            LocalUserStateMutator(modelContext: modelContext)
                .setFavorite(contentID: record.id, isFavorite: !isFavorite)
        )
    }

    private func recordRecentUse() {
        handle(
            LocalUserStateMutator(modelContext: modelContext)
                .recordRecent(contentID: record.id)
        )
    }

    private func handle<Success>(_ result: Result<Success, LocalMutationFailure>) {
        if case .failure(let failure) = result { mutationFailure = failure }
    }

    private func copy(_ zhHans: String, _ en: String) -> String {
        settings.language == .zhHans ? zhHans : en
    }
}
