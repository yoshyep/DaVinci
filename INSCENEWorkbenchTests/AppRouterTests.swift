import Foundation
import Testing
@testable import INSCENEWorkbench

@MainActor
struct AppRouterTests {
    @Test func routerStartsOnTheUsersConfiguredDefaultTab() {
        let suiteName = "AppRouterTests.routerStartsOnTheUsersConfiguredDefaultTab"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = SettingsStore(defaults: defaults)
        settings.defaultTab = .library

        let router = AppRouter(settings: settings)

        #expect(router.selectedTab == .library)
    }
}
