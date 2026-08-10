import Foundation
import Observation

enum WorkbenchQuickAction: String, CaseIterable, Hashable {
    case deleteSegment
    case skinCorrection
    case exportSettings
    case emergency
}

@MainActor
@Observable
final class WorkbenchViewModel {
    enum ProjectState: Equatable {
        case noProject
        case active
        case completed
    }

    struct ChecklistEntry: Identifiable, Equatable {
        var id: String { contentID }
        let contentID: String
        let title: LocalizedText
        let isCompleted: Bool
    }

    struct Template: Identifiable, Equatable {
        let id: String
        let title: LocalizedText
        let systemImage: String
    }

    struct ImmediateTool: Identifiable, Equatable {
        var id: WorkbenchQuickAction { action }
        let action: WorkbenchQuickAction
        let titleKey: String
        let detailKey: String
        let systemImage: String
        let contentID: String
        let shortcutKeys: [String]
        let destination: WorkbenchDestination
    }

    struct Snapshot: Equatable {
        let projectState: ProjectState
        let projectName: String?
        let currentStageID: String?
        let completedStages: Int
        let totalStages: Int
        let currentTask: LocalizedText?
        let checklistCompleted: Int
        let checklistTotal: Int
        let checklistItems: [ChecklistEntry]
        let recentContentIDs: [String]
        let favoriteCount: Int
        let noteCount: Int
        let templates: [Template]
    }

    let repository: GuideContentRepository
    let settings: SettingsStore

    init(repository: GuideContentRepository, settings: SettingsStore) {
        self.repository = repository
        self.settings = settings
    }

    var stages: [WorkflowStage] {
        repository.content.stages.sorted { $0.number < $1.number }
    }

    var immediateTools: [ImmediateTool] {
        [
            makeImmediateTool(
                action: .deleteSegment,
                titleKey: "workbench.quick.deleteSegment",
                detailKey: "workbench.quick.deleteSegment.detail",
                systemImage: "scissors",
                contentID: "delete-ripple"
            ),
            makeImmediateTool(
                action: .skinCorrection,
                titleKey: "workbench.quick.skinCorrection",
                detailKey: "workbench.quick.skinCorrection.detail",
                systemImage: "scope",
                contentID: "recipe-skin"
            ),
            makeImmediateTool(
                action: .exportSettings,
                titleKey: "workbench.quick.exportSettings",
                detailKey: "workbench.quick.exportSettings.detail",
                systemImage: "square.and.arrow.up",
                contentID: "ex-web"
            ),
            makeImmediateTool(
                action: .emergency,
                titleKey: "workbench.quick.emergency",
                detailKey: "workbench.quick.emergency.detail",
                systemImage: "cross.case",
                contentID: "em-offline"
            )
        ]
    }

    func snapshot(
        session: ProjectSession?,
        recentActivities: [RecentActivity],
        favorites: [Favorite],
        notes: [UserNote]
    ) -> Snapshot {
        let completedIDs = Set(
            session?.stageProgress
                .filter(\.isCompleted)
                .map(\.contentID) ?? []
        )
        let completedCount = stages.reduce(into: 0) { count, stage in
            if completedIDs.contains(stage.id) { count += 1 }
        }
        let currentStage = stages.first { !completedIDs.contains($0.id) }
        let projectState: ProjectState
        if session == nil {
            projectState = .noProject
        } else if currentStage == nil {
            projectState = .completed
        } else {
            projectState = .active
        }
        let currentTask: LocalizedText?
        switch settings.contentLevel {
        case .quick:
            currentTask = currentStage?.quickSteps.first
        case .professional:
            currentTask = currentStage?.proSteps.first ?? currentStage?.quickSteps.first
        }

        var recentIDs: [String] = []
        for activity in recentActivities.sorted(by: { lhs, rhs in
            let lhsPinned = lhs.action == "pinned"
            let rhsPinned = rhs.action == "pinned"
            if lhsPinned != rhsPinned { return lhsPinned }
            return lhs.updatedAt > rhs.updatedAt
        })
            where !recentIDs.contains(activity.contentID) {
            recentIDs.append(activity.contentID)
            if recentIDs.count == 3 { break }
        }

        let checklistItems = session?.checklistStates
            .map { state in
                ChecklistEntry(
                    contentID: state.contentID,
                    title: checklistTitle(for: state.contentID),
                    isCompleted: state.isCompleted
                )
            }
            .sorted { lhs, rhs in
                let lhsRank = checklistRank(for: lhs.contentID)
                let rhsRank = checklistRank(for: rhs.contentID)
                return lhsRank == rhsRank ? lhs.contentID < rhs.contentID : lhsRank < rhsRank
            } ?? []

        return Snapshot(
            projectState: projectState,
            projectName: session?.name,
            currentStageID: currentStage?.id,
            completedStages: completedCount,
            totalStages: stages.count,
            currentTask: currentTask,
            checklistCompleted: checklistItems.filter(\.isCompleted).count,
            checklistTotal: checklistItems.count,
            checklistItems: checklistItems,
            recentContentIDs: recentIDs,
            favoriteCount: favorites.count,
            noteCount: notes.count,
            templates: session == nil ? Self.localTemplates : []
        )
    }

    func stage(id: String?) -> WorkflowStage? {
        guard let id else { return nil }
        return stages.first { $0.id == id }
    }

    func stageSteps(for id: String) -> [LocalizedText] {
        guard let stage = stage(id: id) else { return [] }
        switch settings.contentLevel {
        case .quick:
            return stage.quickSteps
        case .professional:
            return stage.proSteps.isEmpty ? stage.quickSteps : stage.proSteps
        }
    }

    func record(id: String) -> (any SearchableContent)? {
        repository.record(id: id)
    }

    func contentID(for action: WorkbenchQuickAction) -> String {
        immediateTools.first(where: { $0.action == action })?.contentID ?? ""
    }

    private func makeImmediateTool(
        action: WorkbenchQuickAction,
        titleKey: String,
        detailKey: String,
        systemImage: String,
        contentID: String
    ) -> ImmediateTool {
        let shortcut = repository.record(id: contentID) as? ShortcutDefinition
        let keys: [String]
        switch settings.platform {
        case .mac:
            keys = shortcut?.mac ?? []
        case .windows:
            keys = shortcut?.win ?? []
        }
        return ImmediateTool(
            action: action,
            titleKey: titleKey,
            detailKey: detailKey,
            systemImage: systemImage,
            contentID: contentID,
            shortcutKeys: keys,
            destination: .quickAction(action)
        )
    }

    private func checklistTitle(for contentID: String) -> LocalizedText {
        switch contentID {
        case "delivery-picture":
            LocalizedText(zhHans: "画面检查", en: "Picture review")
        case "delivery-audio":
            LocalizedText(zhHans: "音频检查", en: "Audio review")
        default:
            LocalizedText(
                zhHans: Self.humanizedChecklistID(contentID),
                en: Self.humanizedChecklistID(contentID)
            )
        }
    }

    private func checklistRank(for contentID: String) -> Int {
        switch contentID {
        case "delivery-picture": 0
        case "delivery-audio": 1
        default: 2
        }
    }

    private static func humanizedChecklistID(_ contentID: String) -> String {
        let words = contentID
            .split(separator: "-")
            .map(String.init)
            .joined(separator: " ")
        guard let first = words.first else { return contentID }
        return first.uppercased() + words.dropFirst()
    }

    private static let localTemplates: [Template] = [
        Template(
            id: "template-interview-edit",
            title: LocalizedText(zhHans: "访谈剪辑", en: "Interview Edit"),
            systemImage: "person.wave.2"
        ),
        Template(
            id: "template-short-form-delivery",
            title: LocalizedText(zhHans: "短视频交付", en: "Short-form Delivery"),
            systemImage: "rectangle.portrait.and.arrow.forward"
        ),
        Template(
            id: "template-shot-matching",
            title: LocalizedText(zhHans: "调色匹配", en: "Shot Matching"),
            systemImage: "circle.lefthalf.filled"
        )
    ]
}

typealias WorkbenchSnapshot = WorkbenchViewModel.Snapshot
