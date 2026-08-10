import SwiftUI
import SwiftData

@main
struct INSCENEWorkbenchApp: App {
    @State private var appEnvironment: AppEnvironment

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let settings: SettingsStore

        if arguments.contains("-uiTesting") {
            let suiteName = ProcessInfo.processInfo.environment["INSCENE_UI_TEST_SUITE"]
                ?? "com.inscene.davinciworkbench.ui-testing.\(UUID().uuidString)"
            let defaults = UserDefaults(suiteName: suiteName)!
            if arguments.contains("-resetLocalData") {
                defaults.removePersistentDomain(forName: suiteName)
            }
            settings = SettingsStore(defaults: defaults)
            if arguments.contains("-resetLocalData") {
                Self.establishUITestDefaults(settings)
            }
            if arguments.contains("-seedConflictingSettings") {
                settings.language = .en
                settings.appearance = .light
                settings.defaultTab = .library
            }
            if arguments.contains("-skipOnboarding") {
                settings.hasCompletedOnboarding = true
            }
            if arguments.contains("-startQuickLookup") {
                settings.defaultTab = .lookup
            }
            if let languageFlag = arguments.firstIndex(of: "-lookupLanguage"),
               arguments.indices.contains(languageFlag + 1),
               let language = AppLanguage(rawValue: arguments[languageFlag + 1]) {
                settings.language = language
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
        if arguments.contains("-uiTesting") && arguments.contains("-seedCompletedWorkbenchSession") {
            Self.seedCompletedWorkbenchSession(
                in: environment.modelContainer.mainContext,
                stages: environment.repository.content.stages
            )
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

    private static func seedCompletedWorkbenchSession(
        in context: ModelContext,
        stages: [WorkflowStage]
    ) {
        let session = ProjectSession(
            name: "Finished Documentary",
            templateID: "template-interview-edit"
        )
        session.stageProgress = stages.map {
            StageProgress(contentID: $0.id, isCompleted: true)
        }
        session.checklistStates = [
            ChecklistItemState(contentID: "delivery-picture", isCompleted: true),
            ChecklistItemState(contentID: "delivery-audio", isCompleted: true)
        ]
        context.insert(session)
        try? context.save()
    }

    private static func establishUITestDefaults(_ settings: SettingsStore) {
        settings.language = .zhHans
        settings.platform = .mac
        settings.contentLevel = .quick
        settings.defaultTab = .workbench
        settings.appearance = .system
        settings.hasCompletedOnboarding = false
        settings.showsSources = true
        settings.showsProfessionalRecommendations = true
        settings.hapticsEnabled = true
    }
}
