import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UIKit

struct SettingsView: View {
    let settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var isShowingShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var isShowingImporter = false
    @State private var importError: String?
    @State private var importSuccess = false
    @State private var showingClearHistoryAlert = false
    @State private var showingResetProgressAlert = false
    @State private var showingDeleteAllAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    BrandLogoView(variant: .horizontal)
                        .frame(maxWidth: 230, minHeight: 64)
                        .padding(.vertical, 18)
                        .frame(maxWidth: .infinity)

                    Text("settings.localOnly")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("settings.section.content") {
                    Picker("settings.contentLevel", selection: binding(\.contentLevel)) {
                        Text("content.quick").tag(ContentLevel.quick)
                        Text("content.professional").tag(ContentLevel.professional)
                    }

                    Picker("settings.platform", selection: binding(\.platform)) {
                        Text("platform.mac").tag(ShortcutPlatform.mac)
                        Text("platform.windows").tag(ShortcutPlatform.windows)
                    }

                    Picker("settings.defaultTab", selection: binding(\.defaultTab)) {
                        Text("tab.workbench").tag(AppTab.workbench)
                        Text("tab.lookup").tag(AppTab.lookup)
                        Text("tab.workflows").tag(AppTab.workflows)
                        Text("tab.library").tag(AppTab.library)
                    }
                    .accessibilityIdentifier("settings.defaultTab.picker")
                    .accessibilityValue(Text(defaultTabKey))

                    LabeledContent("settings.resolveVersion", value: "Resolve 20")
                    Toggle("settings.showSources", isOn: binding(\.showsSources))
                    Toggle(
                        "settings.showProfessionalRecommendations",
                        isOn: binding(\.showsProfessionalRecommendations)
                    )
                }

                Section("settings.section.language") {
                    selectionButton(
                        title: "language.zhHans",
                        isSelected: settings.language == .zhHans,
                        identifier: "settings.language.zhHans"
                    ) { settings.language = .zhHans }
                    selectionButton(
                        title: "language.english",
                        isSelected: settings.language == .en,
                        identifier: "settings.language.english"
                    ) { settings.language = .en }
                }

                Section("settings.section.appearance") {
                    Picker("settings.appearance", selection: binding(\.appearance)) {
                        Text("appearance.system").tag(AppearanceMode.system)
                        Text("appearance.dark").tag(AppearanceMode.dark)
                        Text("appearance.light").tag(AppearanceMode.light)
                    }
                    .accessibilityIdentifier("settings.appearance.picker")
                    .accessibilityValue(Text(appearanceKey))
                    Toggle("settings.haptics", isOn: binding(\.hapticsEnabled))
                    Text("settings.systemAccessibility")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("settings.section.localData") {
                    Button("settings.export", systemImage: "square.and.arrow.up") {
                        exportData()
                    }
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("settings.export")

                    Button("settings.import", systemImage: "square.and.arrow.down") {
                        isShowingImporter = true
                    }
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("settings.import")

                    Button("settings.clearHistory", systemImage: "clock.arrow.circlepath") {
                        showingClearHistoryAlert = true
                    }
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("settings.clearHistory")

                    Button("settings.resetProgress", systemImage: "arrow.counterclockwise") {
                        showingResetProgressAlert = true
                    }
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("settings.resetProgress")

                    Button("settings.deleteAll", systemImage: "trash", role: .destructive) {
                        showingDeleteAllAlert = true
                    }
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("settings.deleteAll")
                }

                Section("settings.section.about") {
                    LabeledContent("settings.appVersion", value: appVersion)
                    LabeledContent("settings.contentVersion", value: "1")
                    Text("settings.independentDisclaimer")
                    Text("settings.copyrightDisclaimer")
                }
            }
            .navigationTitle(Text("settings.title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { dismiss() }
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
            .sheet(isPresented: $isShowingShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
            .fileImporter(
                isPresented: $isShowingImporter,
                allowedContentTypes: [.json]
            ) { result in
                handleImportResult(result)
            }
            .alert(
                copy("导入失败", "Import Failed"),
                isPresented: Binding(
                    get: { importError != nil },
                    set: { if !$0 { importError = nil } }
                )
            ) {
                Button(copy("好", "OK")) { importError = nil }
            } message: {
                if let importError {
                    Text(importError)
                }
            }
            .alert(
                copy("清除最近记录", "Clear Recent History"),
                isPresented: $showingClearHistoryAlert
            ) {
                Button(copy("取消", "Cancel"), role: .cancel) {}
                Button(copy("清除", "Clear"), role: .destructive) {
                    clearHistory()
                }
            } message: {
                Text(copy("确定要清除所有最近使用记录吗？此操作不可撤销。", "Are you sure you want to clear all recent history? This cannot be undone."))
            }
            .alert(
                copy("重置项目进度", "Reset Project Progress"),
                isPresented: $showingResetProgressAlert
            ) {
                Button(copy("取消", "Cancel"), role: .cancel) {}
                Button(copy("重置", "Reset"), role: .destructive) {
                    resetProgress()
                }
            } message: {
                Text(copy("确定要重置所有项目的阶段进度和检查表状态吗？此操作不可撤销。", "Are you sure you want to reset all project stage progress and checklist states? This cannot be undone."))
            }
            .alert(
                copy("删除全部本地数据", "Delete All Local Data"),
                isPresented: $showingDeleteAllAlert
            ) {
                Button(copy("取消", "Cancel"), role: .cancel) {}
                Button(copy("删除", "Delete"), role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text(copy("确定要删除所有本地数据吗？包括项目、笔记、收藏等。此操作不可撤销。", "Are you sure you want to delete ALL local data? This includes projects, notes, favorites, and more. This cannot be undone."))
            }
        }
        .environment(\.locale, activeLocale)
        .id(settings.language)
    }

    // MARK: - Data Operations

    private func exportData() {
        do {
            let data = try ImportExportService().export(from: modelContext, settings: settings)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("INSCENE-UserData-\(Int(Date().timeIntervalSince1970)).json")
            try data.write(to: url)
            exportedFileURL = url
            isShowingShareSheet = true
        } catch {
            importError = error.localizedDescription
        }
    }

    private func handleImportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                let didStartSecurityScope = url.startAccessingSecurityScopedResource()
                defer {
                    if didStartSecurityScope {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                let data = try Data(contentsOf: url)
                try ImportExportService().validateAndImport(data, into: modelContext, settings: settings)
                importSuccess = true
            } catch let validationError as ImportValidationError {
                importError = validationErrorMessage(validationError)
            } catch {
                importError = error.localizedDescription
            }
        case .failure(let error):
            importError = error.localizedDescription
        }
    }

    private func clearHistory() {
        do {
            let activities = try modelContext.fetch(FetchDescriptor<RecentActivity>())
            activities.forEach(modelContext.delete)
            try modelContext.save()
        } catch {
            importError = error.localizedDescription
        }
    }

    private func resetProgress() {
        do {
            let stages = try modelContext.fetch(FetchDescriptor<StageProgress>())
            let checklists = try modelContext.fetch(FetchDescriptor<ChecklistItemState>())
            stages.forEach(modelContext.delete)
            checklists.forEach(modelContext.delete)
            try modelContext.save()
        } catch {
            importError = error.localizedDescription
        }
    }

    private func deleteAllData() {
        do {
            let projects = try modelContext.fetch(FetchDescriptor<ProjectSession>())
            let stages = try modelContext.fetch(FetchDescriptor<StageProgress>())
            let checklists = try modelContext.fetch(FetchDescriptor<ChecklistItemState>())
            let notes = try modelContext.fetch(FetchDescriptor<UserNote>())
            let versions = try modelContext.fetch(FetchDescriptor<ProjectVersionRecord>())
            let favorites = try modelContext.fetch(FetchDescriptor<Favorite>())
            let activities = try modelContext.fetch(FetchDescriptor<RecentActivity>())

            projects.forEach(modelContext.delete)
            stages.forEach(modelContext.delete)
            checklists.forEach(modelContext.delete)
            notes.forEach(modelContext.delete)
            versions.forEach(modelContext.delete)
            favorites.forEach(modelContext.delete)
            activities.forEach(modelContext.delete)

            try modelContext.save()
        } catch {
            importError = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func validationErrorMessage(_ error: ImportValidationError) -> String {
        let zh = settings.language == .zhHans
        switch error {
        case .unsupportedSchemaVersion:
            return zh ? "数据版本不受支持。" : "Unsupported data version."
        case .duplicateIDs:
            return zh ? "数据中存在重复的 ID。" : "Duplicate IDs found in the data."
        case .invalidContentReference:
            return zh ? "数据中存在无效的内容引用。" : "Invalid content reference in the data."
        case .invalidEnumValue:
            return zh ? "数据中存在无效的设置值。" : "Invalid setting value in the data."
        case .decodingFailed:
            return zh ? "无法解析数据文件。" : "Could not parse the data file."
        }
    }

    private var activeLocale: Locale {
        Locale(identifier: settings.language == .zhHans ? "zh-Hans" : "en")
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var defaultTabKey: LocalizedStringKey {
        switch settings.defaultTab {
        case .workbench: "tab.workbench"
        case .lookup: "tab.lookup"
        case .workflows: "tab.workflows"
        case .library: "tab.library"
        }
    }

    private var appearanceKey: LocalizedStringKey {
        switch settings.appearance {
        case .system: "appearance.system"
        case .dark: "appearance.dark"
        case .light: "appearance.light"
        }
    }

    private func binding<Value>(_ keyPath: ReferenceWritableKeyPath<SettingsStore, Value>) -> Binding<Value> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: { settings[keyPath: keyPath] = $0 }
        )
    }

    private func selectionButton(
        title: LocalizedStringKey,
        isSelected: Bool,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .accessibilityIdentifier(identifier)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func copy(_ zhHans: String, _ en: String) -> String {
        settings.language == .zhHans ? zhHans : en
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
