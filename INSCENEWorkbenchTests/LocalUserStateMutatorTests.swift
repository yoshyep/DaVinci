import SwiftData
import Testing
@testable import INSCENEWorkbench

@MainActor
struct LocalUserStateMutatorTests {
    @Test func creatingProjectPersistsOneProgressRecordPerOfficialStage() throws {
        let container = try TestModelContainer.make()
        let context = container.mainContext
        let mutator = LocalUserStateMutator(modelContext: context)
        let stageIDs = (1...10).map { "stage-\($0)" }

        let result = mutator.createProject(
            name: "Interview",
            templateID: "template-interview-edit",
            stageIDs: stageIDs
        )

        guard case .success(let session) = result else {
            Issue.record("Expected project creation to succeed")
            return
        }
        #expect(session.name == "Interview")
        #expect(session.stageProgress.count == 10)
        #expect(Set(session.stageProgress.map(\.contentID)) == Set(stageIDs))
        #expect(session.stageProgress.allSatisfy { !$0.isCompleted })
        #expect(try context.fetch(FetchDescriptor<ProjectSession>()).count == 1)
    }

    @Test func applyingPlaybookAddsStableChecklistItemsOnlyOnce() throws {
        let container = try TestModelContainer.make()
        let context = container.mainContext
        let session = ProjectSession(name: "Commercial", templateID: "template-commercial")
        context.insert(session)
        try context.save()
        let mutator = LocalUserStateMutator(modelContext: context)
        let playbook = try #require(
            try TestFixtures.sample.playbooks.first { $0.id == "playbook-one" }
        )

        let first = mutator.applyPlaybook(playbook, to: session)
        let second = mutator.applyPlaybook(playbook, to: session)

        #expect(first == .success(1))
        #expect(second == .success(0))
        #expect(session.checklistStates.map(\.contentID) == ["playbook-one.checklist.one-chk-check-one"])
    }

    @Test func checklistStableIDsSurviveContentReordering() throws {
        let container = try TestModelContainer.make()
        let context = container.mainContext
        let session = ProjectSession(name: "Test", templateID: "template-test")
        context.insert(session)
        try context.save()
        let mutator = LocalUserStateMutator(modelContext: context)

        // Simulate a playbook with two checklist items in original order
        let originalPlaybook = ExpertPlaybook(
            id: "pb-reorder", kind: .playbook, creatorID: "creator-one",
            title: LocalizedText(zhHans: "测试", en: "Test"),
            summary: LocalizedText(zhHans: "摘要", en: "Summary"),
            problem: LocalizedText(zhHans: "问题", en: "Problem"),
            fit: [], nonFit: [LocalizedText(zhHans: "不适用", en: "Do not use")],
            requirements: [], steps: [], judgmentCriteria: [], mistakes: [],
            rollback: [], officialDifferences: [],
            checklist: [
                PlaybookChecklistItem(id: "alpha", text: LocalizedText(zhHans: "甲", en: "Alpha")),
                PlaybookChecklistItem(id: "beta", text: LocalizedText(zhHans: "乙", en: "Beta"))
            ],
            resolveVersion: "20+", compatibility: .freeAndStudio,
            publishedDate: nil, lastReviewedDate: "2026-08-10",
            sourceURL: "https://example.com", sourceIDs: ["source-one"]
        )

        // Apply and complete the second item
        _ = mutator.applyPlaybook(originalPlaybook, to: session)
        guard case .success = mutator.setChecklistCompletion(
            session: session,
            contentID: "pb-reorder.checklist.beta",
            completed: true
        ) else {
            Issue.record("Expected checklist completion to save")
            return
        }

        // Simulate reordering: the same items in reversed order
        let reorderedPlaybook = ExpertPlaybook(
            id: "pb-reorder", kind: .playbook, creatorID: "creator-one",
            title: LocalizedText(zhHans: "测试", en: "Test"),
            summary: LocalizedText(zhHans: "摘要", en: "Summary"),
            problem: LocalizedText(zhHans: "问题", en: "Problem"),
            fit: [], nonFit: [LocalizedText(zhHans: "不适用", en: "Do not use")],
            requirements: [], steps: [], judgmentCriteria: [], mistakes: [],
            rollback: [], officialDifferences: [],
            checklist: [
                PlaybookChecklistItem(id: "beta", text: LocalizedText(zhHans: "乙", en: "Beta")),
                PlaybookChecklistItem(id: "alpha", text: LocalizedText(zhHans: "甲", en: "Alpha"))
            ],
            resolveVersion: "20+", compatibility: .freeAndStudio,
            publishedDate: nil, lastReviewedDate: "2026-08-10",
            sourceURL: "https://example.com", sourceIDs: ["source-one"]
        )

        // Re-applying should not duplicate items
        let reapplyResult = mutator.applyPlaybook(reorderedPlaybook, to: session)
        #expect(reapplyResult == .success(0))

        // The "beta" item should still be completed despite reordering
        let betaState = session.checklistStates.first { $0.contentID == "pb-reorder.checklist.beta" }
        #expect(betaState?.isCompleted == true)

        // Content IDs must use stable item IDs, not array indices
        let contentIDs = session.checklistStates.map(\.contentID).sorted()
        #expect(contentIDs == ["pb-reorder.checklist.alpha", "pb-reorder.checklist.beta"])
    }

    @Test func projectNoteAndVersionRecordRemainAssociatedWithSession() throws {
        let container = try TestModelContainer.make()
        let context = container.mainContext
        let session = ProjectSession(name: "Archive", templateID: "template-archive")
        context.insert(session)
        try context.save()
        let mutator = LocalUserStateMutator(modelContext: context)

        let noteResult = mutator.addProjectNote(
            session: session,
            contentID: "stage-media",
            body: "Confirm source cadence."
        )
        let versionResult = mutator.recordProjectVersion(
            session: session,
            name: "Client review v2",
            resolveVersion: "20.2"
        )

        guard case .success(let note) = noteResult,
              case .success(let version) = versionResult else {
            Issue.record("Expected note and version record writes to succeed")
            return
        }
        #expect(note.sessionID == session.id)
        #expect(version.sessionID == session.id)
        #expect(try context.fetch(FetchDescriptor<UserNote>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<ProjectVersionRecord>()).count == 1)
    }

    @Test func stageAndChecklistCompletionMutationsPersistTheirState() throws {
        let container = try TestModelContainer.make()
        let context = container.mainContext
        let session = ProjectSession(name: "Interview", templateID: "template-interview-edit")
        session.stageProgress = [StageProgress(contentID: "stage-project")]
        session.checklistStates = [ChecklistItemState(contentID: "playbook-one.checklist.one-chk-check-one")]
        context.insert(session)
        try context.save()
        let mutator = LocalUserStateMutator(modelContext: context)

        guard case .success = mutator.setStageCompletion(
            session: session,
            contentID: "stage-project",
            completed: true
        ) else {
            Issue.record("Expected stage completion to save")
            return
        }
        guard case .success = mutator.setChecklistCompletion(
            session: session,
            contentID: "playbook-one.checklist.one-chk-check-one",
            completed: true
        ) else {
            Issue.record("Expected checklist completion to save")
            return
        }
        #expect(session.stageProgress.first?.isCompleted == true)
        #expect(session.checklistStates.first?.isCompleted == true)
    }

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
