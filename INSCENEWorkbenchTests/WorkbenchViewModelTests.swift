import Foundation
import Testing
@testable import INSCENEWorkbench

@MainActor
struct WorkbenchViewModelTests {
    @Test func noProjectOffersThreeLocalWorkflowTemplates() throws {
        let viewModel = try makeViewModel()

        let snapshot = viewModel.snapshot(
            session: nil,
            recentActivities: [],
            favorites: [],
            notes: []
        )

        #expect(snapshot.projectName == nil)
        #expect(snapshot.templates.map(\.id) == [
            "template-interview-edit",
            "template-short-form-delivery",
            "template-shot-matching"
        ])
        #expect(snapshot.totalStages == 10)
    }

    @Test func snapshotFindsFirstIncompleteStageAndCountsLocalProjectContext() throws {
        let viewModel = try makeViewModel()
        let session = ProjectSession(name: "Client Interview", templateID: "template-interview-edit")
        session.stageProgress = [
            StageProgress(contentID: "stage-project", isCompleted: true),
            StageProgress(contentID: "stage-media", isCompleted: true)
        ]
        session.checklistStates = [
            ChecklistItemState(contentID: "delivery-audio", isCompleted: true),
            ChecklistItemState(contentID: "delivery-video", isCompleted: false)
        ]
        let oldRecent = RecentActivity(
            contentID: "recipe-skin",
            action: "open",
            updatedAt: Date(timeIntervalSince1970: 100)
        )
        let newRecent = RecentActivity(
            contentID: "delete-ripple",
            action: "open",
            updatedAt: Date(timeIntervalSince1970: 200)
        )

        let snapshot = viewModel.snapshot(
            session: session,
            recentActivities: [oldRecent, newRecent],
            favorites: [Favorite(contentID: "recipe-skin")],
            notes: [UserNote(contentID: "stage-rough", body: "Tighten the opening")]
        )

        #expect(snapshot.projectName == "Client Interview")
        #expect(snapshot.currentStageID == "stage-rough")
        #expect(snapshot.completedStages == 2)
        #expect(snapshot.totalStages == 10)
        #expect(snapshot.currentTask?.en == "Build the overall structure")
        #expect(snapshot.checklistCompleted == 1)
        #expect(snapshot.checklistTotal == 2)
        #expect(snapshot.recentContentIDs == ["delete-ripple", "recipe-skin"])
        #expect(snapshot.favoriteCount == 1)
        #expect(snapshot.noteCount == 1)
        #expect(snapshot.templates.isEmpty)
    }

    @Test func professionalLevelExpandsTheSameCurrentStageInsteadOfChoosingDifferentContent() throws {
        let suiteName = "WorkbenchViewModelTests.professionalLevelExpandsTheSameCurrentStage"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = SettingsStore(defaults: defaults)
        settings.contentLevel = .professional
        let repository = try GuideContentRepository()
        let viewModel = WorkbenchViewModel(repository: repository, settings: settings)
        let session = ProjectSession(name: "Commercial", templateID: "template-shot-matching")

        let snapshot = viewModel.snapshot(
            session: session,
            recentActivities: [],
            favorites: [],
            notes: []
        )

        #expect(snapshot.currentStageID == "stage-project")
        #expect(snapshot.currentTask == repository.content.stages[0].proSteps[0])
        #expect(viewModel.stageSteps(for: "stage-project") == repository.content.stages[0].proSteps)
    }

    @Test func immediateToolsUseTypedRoutesAndConfiguredShortcutPlatform() throws {
        let suiteName = "WorkbenchViewModelTests.immediateToolsUseTypedRoutes"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = SettingsStore(defaults: defaults)
        settings.platform = .windows
        let viewModel = WorkbenchViewModel(repository: try GuideContentRepository(), settings: settings)

        #expect(viewModel.immediateTools.map(\.action) == [
            .deleteSegment, .skinCorrection, .exportSettings, .emergency
        ])
        #expect(viewModel.immediateTools.map(\.destination) == [
            .quickAction(.deleteSegment),
            .quickAction(.skinCorrection),
            .quickAction(.exportSettings),
            .quickAction(.emergency)
        ])
        #expect(viewModel.immediateTools[0].shortcutKeys == ["Shift", "Backspace"])
    }

    @Test func pinnedRecentStaysAheadOfNewerUnpinnedActivity() throws {
        let viewModel = try makeViewModel()
        let pinned = RecentActivity(
            contentID: "recipe-skin",
            action: "pinned",
            updatedAt: Date(timeIntervalSince1970: 100)
        )
        let newer = RecentActivity(
            contentID: "delete-ripple",
            action: "open",
            updatedAt: Date(timeIntervalSince1970: 200)
        )

        let snapshot = viewModel.snapshot(
            session: nil,
            recentActivities: [newer, pinned],
            favorites: [],
            notes: []
        )

        #expect(snapshot.recentContentIDs == ["recipe-skin", "delete-ripple"])
    }

    private func makeViewModel() throws -> WorkbenchViewModel {
        let suiteName = "WorkbenchViewModelTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return WorkbenchViewModel(
            repository: try GuideContentRepository(),
            settings: SettingsStore(defaults: defaults)
        )
    }
}
