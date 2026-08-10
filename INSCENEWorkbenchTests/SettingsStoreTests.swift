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
        store.appearance = .dark

        let reloadedStore = SettingsStore(defaults: suite)
        #expect(reloadedStore.language == .en)
        #expect(reloadedStore.platform == .windows)
        #expect(reloadedStore.contentLevel == .professional)
        #expect(reloadedStore.appearance == .dark)
    }
}
