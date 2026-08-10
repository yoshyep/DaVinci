import SwiftData
import Testing
@testable import INSCENEWorkbench

struct ProjectSessionTests {
    @Test @MainActor func completingChecklistAdvancesLocalProjectProgress() throws {
        let container = try TestModelContainer.make()
        let session = ProjectSession(name: "Interview", templateID: "stage-project")
        container.mainContext.insert(session)

        session.setChecklist(contentID: "stage-fine-qc", completed: true)
        try container.mainContext.save()

        #expect(session.completedChecklistCount == 1)

        let reloadedContext = ModelContext(container)
        let sessions = try reloadedContext.fetch(FetchDescriptor<ProjectSession>())
        #expect(sessions.first(where: { $0.id == session.id })?.completedChecklistCount == 1)
    }
}

enum TestModelContainer {
    static func make() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: ProjectSession.self,
            StageProgress.self,
            ChecklistItemState.self,
            UserNote.self,
            ProjectVersionRecord.self,
            Favorite.self,
            RecentActivity.self,
            configurations: configuration
        )
    }
}
