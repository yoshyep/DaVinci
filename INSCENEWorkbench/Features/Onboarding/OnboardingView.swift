import SwiftUI

struct OnboardingView: View {
    let settings: SettingsStore
    let finish: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    BrandLogoView(variant: .horizontal)
                        .frame(maxWidth: 230, minHeight: 62)
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 20))

                    Text("onboarding.title")
                        .font(.largeTitle.bold())
                        .accessibilityIdentifier("onboarding.title")

                    Text("onboarding.subtitle")
                        .foregroundStyle(.secondary)

                    choiceGroup(titleKey: "settings.language") {
                        choiceButton(
                            title: "language.zhHans",
                            isSelected: settings.language == .zhHans,
                            identifier: "onboarding.language.zhHans"
                        ) { settings.language = .zhHans }
                        choiceButton(
                            title: "language.english",
                            isSelected: settings.language == .en,
                            identifier: "onboarding.language.english"
                        ) { settings.language = .en }
                    }

                    choiceGroup(titleKey: "settings.platform") {
                        choiceButton(
                            title: "platform.mac",
                            isSelected: settings.platform == .mac,
                            identifier: "onboarding.platform.mac"
                        ) { settings.platform = .mac }
                        choiceButton(
                            title: "platform.windows",
                            isSelected: settings.platform == .windows,
                            identifier: "onboarding.platform.windows"
                        ) { settings.platform = .windows }
                    }

                    choiceGroup(titleKey: "settings.contentLevel") {
                        choiceButton(
                            title: "content.quick",
                            isSelected: settings.contentLevel == .quick,
                            identifier: "onboarding.level.quick"
                        ) { settings.contentLevel = .quick }
                        choiceButton(
                            title: "content.professional",
                            isSelected: settings.contentLevel == .professional,
                            identifier: "onboarding.level.professional"
                        ) { settings.contentLevel = .professional }
                    }

                    Button(action: finish) {
                        Text("onboarding.finish")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("onboarding.finish")
                }
                .padding(20)
            }
            .navigationTitle(Text("onboarding.navigationTitle"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .environment(\.locale, activeLocale)
        .id(settings.language)
    }

    private var activeLocale: Locale {
        Locale(identifier: settings.language == .zhHans ? "zh-Hans" : "en")
    }

    private func choiceGroup<Content: View>(
        titleKey: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titleKey)
                .font(.headline)
            content()
        }
    }

    private func choiceButton(
        title: LocalizedStringKey,
        isSelected: Bool,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier(identifier)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
