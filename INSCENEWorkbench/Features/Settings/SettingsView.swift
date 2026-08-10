import SwiftUI

struct SettingsView: View {
    let settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var isConfirmingDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    BrandLogoView(variant: .horizontal)
                        .frame(maxWidth: 230, minHeight: 64)
                        .padding(.vertical, 18)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.white)

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
                    Toggle("settings.haptics", isOn: binding(\.hapticsEnabled))
                    Text("settings.systemAccessibility")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("settings.section.localData") {
                    Button("settings.export", systemImage: "square.and.arrow.up") {}
                    Button("settings.import", systemImage: "square.and.arrow.down") {}
                    Button("settings.clearHistory", systemImage: "clock.arrow.circlepath") {}
                    Button("settings.resetProgress", systemImage: "arrow.counterclockwise") {}
                    Button("settings.deleteAll", systemImage: "trash", role: .destructive) {
                        isConfirmingDelete = true
                    }
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
            .confirmationDialog(
                Text("settings.delete.confirm.title"),
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("settings.delete.confirm.action", role: .destructive) {}
                Button("common.cancel", role: .cancel) {}
            } message: {
                Text("settings.delete.confirm.message")
            }
        }
        .environment(\.locale, activeLocale)
        .id(settings.language)
    }

    private var activeLocale: Locale {
        Locale(identifier: settings.language == .zhHans ? "zh-Hans" : "en")
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
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
}
