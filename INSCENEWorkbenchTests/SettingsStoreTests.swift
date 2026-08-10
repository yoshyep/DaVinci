import Foundation
import Testing
@testable import INSCENEWorkbench

struct SettingsStoreTests {
    @Test func settingsRoundTripWithoutCloudStorage() {
        let suite = UserDefaults(suiteName: #function)!
        suite.removePersistentDomain(forName: #function)
        defer { suite.removePersistentDomain(forName: #function) }

        let store = SettingsStore(defaults: suite)
        store.language = .en
        store.platform = .windows
        store.contentLevel = .professional
        store.defaultTab = .workflows
        store.appearance = .dark
        store.showsSources = false
        store.showsProfessionalRecommendations = false
        store.hapticsEnabled = false
        store.hasCompletedOnboarding = true

        let reloadedStore = SettingsStore(defaults: suite)
        #expect(reloadedStore.language == .en)
        #expect(reloadedStore.platform == .windows)
        #expect(reloadedStore.contentLevel == .professional)
        #expect(reloadedStore.defaultTab == .workflows)
        #expect(reloadedStore.appearance == .dark)
        #expect(reloadedStore.showsSources == false)
        #expect(reloadedStore.showsProfessionalRecommendations == false)
        #expect(reloadedStore.hapticsEnabled == false)
        #expect(reloadedStore.hasCompletedOnboarding == true)
    }
}
