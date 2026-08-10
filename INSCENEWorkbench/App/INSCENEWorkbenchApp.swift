import SwiftUI
import SwiftData

@main
struct INSCENEWorkbenchApp: App {
    @State private var appEnvironment: AppEnvironment

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let settings: SettingsStore

        if arguments.contains("-uiTesting") {
            let suiteName = "com.inscene.davinciworkbench.ui-testing"
            let defaults = UserDefaults(suiteName: suiteName)!
            if arguments.contains("-resetLocalData") {
                defaults.removePersistentDomain(forName: suiteName)
            }
            settings = SettingsStore(defaults: defaults)
            if arguments.contains("-skipOnboarding") {
                settings.hasCompletedOnboarding = true
            }
        } else {
            settings = SettingsStore()
        }

        _appEnvironment = State(initialValue: AppEnvironment(settings: settings))
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(settings: appEnvironment.settings)
                .modelContainer(appEnvironment.modelContainer)
        }
    }
}
