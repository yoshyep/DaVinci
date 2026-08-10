import AppIntents
import Foundation
import SwiftUI

/// Opens the Quick Lookup tab so the user can search bundled content.
struct OpenQuickLookupIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Quick Lookup"
    static var description = IntentDescription("Open the INSCENE Quick Lookup tab.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .navigateToTab, object: AppTab.lookup)
        return .result()
    }
}

/// Opens the Workflows tab so the user can continue their current project.
struct ContinueWorkflowIntent: AppIntent {
    static var title: LocalizedStringResource = "Continue Workflow"
    static var description = IntentDescription("Continue your current project workflow.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .navigateToTab, object: AppTab.workflows)
        return .result()
    }
}

/// Opens the delivery checklist in the Workflows tab.
struct OpenDeliveryChecklistIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Delivery Checklist"
    static var description = IntentDescription("Open the delivery checklist in Workflows.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .navigateToTab, object: AppTab.workflows)
        return .result()
    }
}

/// Registers Siri Shortcuts and Spotlight suggestions for the app's intents.
struct WorkbenchShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenQuickLookupIntent(),
            phrases: [
                "Open \(.applicationName) lookup",
                "Search in \(.applicationName)"
            ],
            shortTitle: "Quick Lookup",
            systemImageName: "magnifyingglass"
        )
        AppShortcut(
            intent: ContinueWorkflowIntent(),
            phrases: ["Continue \(.applicationName) workflow"],
            shortTitle: "Continue Workflow",
            systemImageName: "checklist"
        )
        AppShortcut(
            intent: OpenDeliveryChecklistIntent(),
            phrases: ["Open \(.applicationName) delivery checklist"],
            shortTitle: "Delivery Checklist",
            systemImageName: "shippingbox"
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToTab = Notification.Name("INSCENENavigateToTab")
}
