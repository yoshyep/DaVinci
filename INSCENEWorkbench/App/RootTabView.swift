import SwiftUI

struct RootTabView: View {
    let settings: SettingsStore
    let repository: GuideContentRepository
    @State private var router: AppRouter
    @State private var workbenchViewModel: WorkbenchViewModel
    @State private var isShowingSettings = false
    @State private var isShowingOnboarding: Bool

    init(settings: SettingsStore, repository: GuideContentRepository) {
        self.settings = settings
        self.repository = repository
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

            NavigationStack(path: $router.lookupPath) {
                QuickLookupView(repository: repository, settings: settings, router: router)
                    .navigationDestination(for: QuickLookupDestination.self) { destination in
                        switch destination {
                        case .record(let id):
                            if let shortcut = repository.record(id: id) as? ShortcutDefinition {
                                ShortcutDetailView(
                                    shortcut: shortcut,
                                    repository: repository,
                                    settings: settings,
                                    router: router
                                )
                            } else if let record = repository.record(id: id) {
                                QuickLookupRecordDetailView(
                                    record: record,
                                    repository: repository,
                                    settings: settings,
                                    router: router
                                )
                            } else {
                                ContentUnavailableView(
                                    settings.language == .zhHans ? "内容不存在" : "Content unavailable",
                                    systemImage: "questionmark.folder"
                                )
                            }
                        }
                    }
            }
            .tabItem { Label("tab.lookup", systemImage: "magnifyingglass") }
            .tag(AppTab.lookup)

            NavigationStack {
                WorkflowListView(repository: repository, settings: settings)
            }
            .tabItem { Label("tab.workflows", systemImage: "checklist") }
            .tag(AppTab.workflows)

            NavigationStack {
                LibraryView(repository: repository, settings: settings)
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
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "inscene" else { return }
        let host = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "workbench":
            router.selectedTab = .workbench
        case "lookup":
            router.selectedTab = .lookup
            if let id = pathComponents.first {
                router.lookupPath = [.record(id)]
            }
        case "workflows":
            router.selectedTab = .workflows
        case "library":
            router.selectedTab = .library
        default:
            break
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
