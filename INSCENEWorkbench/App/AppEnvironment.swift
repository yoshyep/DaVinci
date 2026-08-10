import Observation
import SwiftData

@MainActor
@Observable
final class AppEnvironment {
    let settings: SettingsStore
    let modelContainer: ModelContainer
    let repository: GuideContentRepository

    init(
        settings: SettingsStore = SettingsStore(),
        modelContainer: ModelContainer? = nil,
        repository: GuideContentRepository? = nil,
        isStoredInMemoryOnly: Bool = false
    ) {
        self.settings = settings
        self.modelContainer = modelContainer ?? Self.makeModelContainer(isStoredInMemoryOnly: isStoredInMemoryOnly)
        do {
            self.repository = try repository ?? GuideContentRepository()
        } catch {
            fatalError("Unable to load bundled guide content: \(error)")
        }
    }

    private static func makeModelContainer(isStoredInMemoryOnly: Bool) -> ModelContainer {
        let schema = Schema([
            ProjectSession.self,
            StageProgress.self,
            ChecklistItemState.self,
            UserNote.self,
            Favorite.self,
            RecentActivity.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create local user-data container: \(error)")
        }
    }
}
