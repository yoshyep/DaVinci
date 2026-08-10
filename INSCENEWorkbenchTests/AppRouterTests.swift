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

    @Test func workbenchNavigationPreservesTypedDestinationOrder() {
        let suiteName = "AppRouterTests.workbenchNavigationPreservesTypedDestinationOrder"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let router = AppRouter(settings: SettingsStore(defaults: defaults))

        router.open(.quickAction(.skinCorrection))
        router.open(.workflowStage("stage-color"))
        router.open(.deliveryChecklist)

        #expect(router.workbenchPath == [
            .quickAction(.skinCorrection),
            .workflowStage("stage-color"),
            .deliveryChecklist
        ])
    }

    @Test func immediateToolPresentationRetainsItsTypedDestination() {
        let suiteName = "AppRouterTests.immediateToolPresentationRetainsItsTypedDestination"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let router = AppRouter(settings: SettingsStore(defaults: defaults))

        router.present(.quickAction(.emergency))

        #expect(router.presentedWorkbenchDestination == .quickAction(.emergency))
    }
}
