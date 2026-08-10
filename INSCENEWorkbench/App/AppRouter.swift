import Observation

enum WorkbenchDestination: Hashable, Identifiable {
    case search
    case quickAction(WorkbenchQuickAction)
    case workflowStage(String)
    case deliveryChecklist
    case recentRecords
    case favoriteTools
    case notes
    case template(String)
    case record(String)

    var id: String {
        switch self {
        case .search: "search"
        case .quickAction(let action): "quick-action-\(action.rawValue)"
        case .workflowStage(let id): "workflow-stage-\(id)"
        case .deliveryChecklist: "delivery-checklist"
        case .recentRecords: "recent-records"
        case .favoriteTools: "favorite-tools"
        case .notes: "notes"
        case .template(let id): "template-\(id)"
        case .record(let id): "record-\(id)"
        }
    }
}

@MainActor
@Observable
final class AppRouter {
    var selectedTab: AppTab
    var workbenchPath: [WorkbenchDestination] = []
    var presentedWorkbenchDestination: WorkbenchDestination?

    init(settings: SettingsStore) {
        selectedTab = settings.defaultTab
    }

    func open(_ destination: WorkbenchDestination) {
        workbenchPath.append(destination)
    }

    func present(_ destination: WorkbenchDestination) {
        presentedWorkbenchDestination = destination
    }
}
