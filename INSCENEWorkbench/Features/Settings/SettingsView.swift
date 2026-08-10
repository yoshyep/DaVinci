import SwiftUI

struct SettingsView: View {
    let settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

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
                    Text("settings.localDataUnavailable")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("settings.export", systemImage: "square.and.arrow.up") {}
                        .disabled(true)
                    Button("settings.import", systemImage: "square.and.arrow.down") {}
                        .disabled(true)
                    Button("settings.clearHistory", systemImage: "clock.arrow.circlepath") {}
                        .disabled(true)
                    Button("settings.resetProgress", systemImage: "arrow.counterclockwise") {}
                        .disabled(true)
                    Button("settings.deleteAll", systemImage: "trash", role: .destructive) {}
                        .disabled(true)
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
}
