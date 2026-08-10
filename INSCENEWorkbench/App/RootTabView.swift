import SwiftUI

struct RootTabView: View {
    let settings: SettingsStore
    @State private var router: AppRouter
    @State private var workbenchViewModel: WorkbenchViewModel
    @State private var isShowingSettings = false
    @State private var isShowingOnboarding: Bool

    init(settings: SettingsStore, repository: GuideContentRepository) {
        self.settings = settings
        _router = State(initialValue: AppRouter(settings: settings))
        _workbenchViewModel = State(
            initialValue: WorkbenchViewModel(repository: repository, settings: settings)
        )
        _isShowingOnboarding = State(initialValue: !settings.hasCompletedOnboarding)
    }

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.workbenchPath) {
                WorkbenchView(viewModel: workbenchViewModel, router: router) {
                    isShowingSettings = true
                }
            }
            .tabItem { Label("tab.workbench", systemImage: "square.grid.2x2") }
            .tag(AppTab.workbench)

            NavigationStack {
                FeaturePlaceholderView(
                    titleKey: "tab.lookup",
                    messageKey: "lookup.placeholder",
                    systemImage: "magnifyingglass"
                )
            }
            .tabItem { Label("tab.lookup", systemImage: "magnifyingglass") }
            .tag(AppTab.lookup)

            NavigationStack {
                FeaturePlaceholderView(
                    titleKey: "tab.workflows",
                    messageKey: "workflows.placeholder",
                    systemImage: "checklist"
                )
            }
            .tabItem { Label("tab.workflows", systemImage: "checklist") }
            .tag(AppTab.workflows)

            NavigationStack {
                FeaturePlaceholderView(
                    titleKey: "tab.library",
                    messageKey: "library.placeholder",
                    systemImage: "books.vertical"
                )
            }
            .tabItem { Label("tab.library", systemImage: "books.vertical") }
            .tag(AppTab.library)
        }
        .environment(\.locale, activeLocale)
        .preferredColorScheme(preferredColorScheme)
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(settings: settings)
                .environment(\.locale, activeLocale)
        }
        .sheet(isPresented: $isShowingOnboarding) {
            OnboardingView(settings: settings) {
                settings.hasCompletedOnboarding = true
                isShowingOnboarding = false
            }
            .environment(\.locale, activeLocale)
            .interactiveDismissDisabled()
        }
    }

    private var activeLocale: Locale {
        Locale(identifier: settings.language == .zhHans ? "zh-Hans" : "en")
    }

    private var preferredColorScheme: ColorScheme? {
        switch settings.appearance {
        case .system: nil
        case .dark: .dark
        case .light: .light
        }
    }
}

private struct FeaturePlaceholderView: View {
    let titleKey: LocalizedStringKey
    let messageKey: LocalizedStringKey
    let systemImage: String

    var body: some View {
        ContentUnavailableView {
            Label(titleKey, systemImage: systemImage)
        } description: {
            Text(messageKey)
        }
        .navigationTitle(Text(titleKey))
    }
}
