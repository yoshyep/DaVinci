import Observation

@MainActor
@Observable
final class AppRouter {
    var selectedTab: AppTab

    init(settings: SettingsStore) {
        selectedTab = settings.defaultTab
    }
}
