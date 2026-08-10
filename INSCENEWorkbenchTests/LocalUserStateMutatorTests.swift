import SwiftData
import Testing
@testable import INSCENEWorkbench

@MainActor
struct LocalUserStateMutatorTests {
    @Test func addingExistingChecklistItemPreservesCompletedState() throws {
        let container = try TestModelContainer.make()
        let context = container.mainContext
        let session = ProjectSession(name: "Interview", templateID: "template-interview-edit")
        session.checklistStates = [ChecklistItemState(contentID: "delete-ripple", isCompleted: true)]
        context.insert(session)
        try context.save()
        let mutator = LocalUserStateMutator(modelContext: context)

        let result = mutator.addToChecklist(session: session, contentID: "delete-ripple")

        #expect(result == .success(.alreadyPresent))
        #expect(session.checklistStates.count == 1)
        #expect(session.checklistStates[0].isCompleted)
    }

    @Test func repeatedChecklistAddCreatesExactlyOnePendingItem() throws {
        let container = try TestModelContainer.make()
        let context = container.mainContext
        let session = ProjectSession(name: "Interview", templateID: "template-interview-edit")
        context.insert(session)
        try context.save()
        let mutator = LocalUserStateMutator(modelContext: context)

        #expect(mutator.addToChecklist(session: session, contentID: "delete-ripple") == .success(.inserted))
        #expect(mutator.addToChecklist(session: session, contentID: "delete-ripple") == .success(.alreadyPresent))

        let matching = session.checklistStates.filter { $0.contentID == "delete-ripple" }
        #expect(matching.count == 1)
        #expect(matching[0].isCompleted == false)
    }

    @Test func failedChecklistSaveRollsBackAndReturnsUserVisibleError() throws {
        struct ExpectedSaveFailure: Error {}

        let container = try TestModelContainer.make()
        let context = container.mainContext
        let session = ProjectSession(name: "Interview", templateID: "template-interview-edit")
        context.insert(session)
        try context.save()
        let boundary = ModelSaveBoundary(
            save: { throw ExpectedSaveFailure() },
            rollback: { context.rollback() }
        )
        let mutator = LocalUserStateMutator(modelContext: context, saveBoundary: boundary)

        let result = mutator.addToChecklist(session: session, contentID: "delete-ripple")

        #expect(result == .failure(.saveFailed))
        let reloaded = try context.fetch(FetchDescriptor<ChecklistItemState>())
        #expect(reloaded.isEmpty)
        #expect(LocalMutationFailure.saveFailed.message.zhHans == "无法保存本地更改。请重试。")
        #expect(LocalMutationFailure.saveFailed.message.en == "Could not save the local change. Please try again.")
    }

    @Test func settingFavoriteOnRepeatedlyKeepsOneRecord() throws {
        let container = try TestModelContainer.make()
        let context = container.mainContext
        let mutator = LocalUserStateMutator(modelContext: context)

        #expect(mutator.setFavorite(contentID: "recipe-skin", isFavorite: true) == .success(.added))
        #expect(mutator.setFavorite(contentID: "recipe-skin", isFavorite: true) == .success(.unchanged))

        let favorites = try context.fetch(FetchDescriptor<Favorite>())
        #expect(favorites.map(\.contentID) == ["recipe-skin"])
    }

    @Test func settingFavoriteOffRemovesEveryExistingDuplicateIdempotently() throws {
        let container = try TestModelContainer.make()
        let context = container.mainContext
        context.insert(Favorite(contentID: "recipe-skin"))
        context.insert(Favorite(contentID: "recipe-skin"))
        context.insert(Favorite(contentID: "delete-ripple"))
        try context.save()
        let mutator = LocalUserStateMutator(modelContext: context)

        #expect(mutator.setFavorite(contentID: "recipe-skin", isFavorite: false) == .success(.removed))
        #expect(mutator.setFavorite(contentID: "recipe-skin", isFavorite: false) == .success(.unchanged))

        let favorites = try context.fetch(FetchDescriptor<Favorite>())
        #expect(favorites.map(\.contentID) == ["delete-ripple"])
    }

    @Test func failedFavoriteSaveRollsBackTheInsertedRecord() throws {
        struct ExpectedSaveFailure: Error {}

        let container = try TestModelContainer.make()
        let context = container.mainContext
        let mutator = LocalUserStateMutator(
            modelContext: context,
            saveBoundary: ModelSaveBoundary(
                save: { throw ExpectedSaveFailure() },
                rollback: { context.rollback() }
            )
        )

        let result = mutator.setFavorite(contentID: "recipe-skin", isFavorite: true)

        #expect(result == .failure(.saveFailed))
        #expect(try context.fetch(FetchDescriptor<Favorite>()).isEmpty)
    }

    @Test func failedRecentSaveRollsBackTheInsertedActivity() throws {
        struct ExpectedSaveFailure: Error {}

        let container = try TestModelContainer.make()
        let context = container.mainContext
        let mutator = LocalUserStateMutator(
            modelContext: context,
            saveBoundary: ModelSaveBoundary(
                save: { throw ExpectedSaveFailure() },
                rollback: { context.rollback() }
            )
        )

        let result = mutator.recordRecent(contentID: "delete-ripple")

        guard case .failure(.saveFailed) = result else {
            Issue.record("Expected the failed recent save to return saveFailed")
            return
        }
        #expect(try context.fetch(FetchDescriptor<RecentActivity>()).isEmpty)
    }
}
