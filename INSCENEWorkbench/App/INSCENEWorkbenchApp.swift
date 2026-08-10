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

        let environment = AppEnvironment(
            settings: settings,
            isStoredInMemoryOnly: arguments.contains("-uiTesting")
        )
        if arguments.contains("-uiTesting") && arguments.contains("-seedWorkbenchSession") {
            Self.seedWorkbenchSession(in: environment.modelContainer.mainContext)
        }
        _appEnvironment = State(initialValue: environment)
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(
                settings: appEnvironment.settings,
                repository: appEnvironment.repository
            )
                .modelContainer(appEnvironment.modelContainer)
        }
    }

    private static func seedWorkbenchSession(in context: ModelContext) {
        let session = ProjectSession(name: "Interview Cut", templateID: "template-interview-edit")
        session.stageProgress = [
            StageProgress(contentID: "stage-project", isCompleted: true),
            StageProgress(contentID: "stage-media", isCompleted: true)
        ]
        session.checklistStates = [
            ChecklistItemState(contentID: "delivery-picture", isCompleted: true),
            ChecklistItemState(contentID: "delivery-audio", isCompleted: false)
        ]
        context.insert(session)
        context.insert(RecentActivity(contentID: "delete-ripple", action: "open"))
        context.insert(RecentActivity(contentID: "recipe-skin", action: "open"))
        context.insert(Favorite(contentID: "recipe-skin"))
        context.insert(UserNote(contentID: "stage-rough", body: "Open on the strongest answer."))
        try? context.save()
    }
}
