import Observation
import SwiftData

@MainActor
@Observable
final class AppEnvironment {
    let settings: SettingsStore
    let modelContainer: ModelContainer

    init(settings: SettingsStore = SettingsStore(), modelContainer: ModelContainer? = nil) {
        self.settings = settings
        self.modelContainer = modelContainer ?? Self.makeModelContainer()
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            ProjectSession.self,
            StageProgress.self,
            ChecklistItemState.self,
            UserNote.self,
            Favorite.self,
            RecentActivity.self
        ])
        let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .none)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create local user-data container: \(error)")
        }
    }
}
