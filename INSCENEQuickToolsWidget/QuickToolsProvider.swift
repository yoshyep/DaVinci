import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct QuickToolsEntry: TimelineEntry {
    let date: Date
    let nextChecklistItem: ChecklistItemSnapshot?
    let favoriteTools: [ToolSnapshot]
}

struct ChecklistItemSnapshot {
    let contentID: String
    let title: String
    let sessionName: String
}

struct ToolSnapshot {
    let contentID: String
    let title: String
    let kind: String
}

// MARK: - Shared Data

/// Codable container written by the main app into the shared App Group
/// `UserDefaults` so the widget extension can read favorites, the current
/// project checklist, and the media-name visibility flag.
struct QuickToolsSharedData: Codable {
    struct ChecklistItem: Codable {
        let contentID: String
        let title: String
        let isCompleted: Bool
    }

    struct FavoriteTool: Codable {
        let contentID: String
        let title: String
        let kind: String
    }

    let sessionName: String?
    let checklistItems: [ChecklistItem]
    let favoriteTools: [FavoriteTool]
    let showsMediaNames: Bool
}

/// Reads shared `UserDefaults` backed by an App Group.
enum QuickToolsSharedStore {
    static let appGroupID = "group.com.inscene.davinciworkbench"
    static let sharedDataKey = "quicktools.sharedData"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func load() -> QuickToolsSharedData? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: sharedDataKey) else {
            return nil
        }
        return try? JSONDecoder().decode(QuickToolsSharedData.self, from: data)
    }
}

// MARK: - Timeline Provider

struct QuickToolsProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickToolsEntry {
        QuickToolsEntry(date: .now, nextChecklistItem: nil, favoriteTools: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickToolsEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickToolsEntry>) -> Void) {
        let sharedData = QuickToolsSharedStore.load()

        let nextChecklistItem = sharedData?.checklistItems
            .first(where: { !$0.isCompleted })
            .map { item in
                ChecklistItemSnapshot(
                    contentID: item.contentID,
                    title: item.title,
                    sessionName: sharedData?.showsMediaNames == true
                        ? (sharedData?.sessionName ?? "")
                        : ""
                )
            }

        let favoriteTools = (sharedData?.favoriteTools ?? [])
            .prefix(4)
            .map { tool in
                ToolSnapshot(
                    contentID: tool.contentID,
                    title: tool.title,
                    kind: tool.kind
                )
            }

        let entry = QuickToolsEntry(
            date: .now,
            nextChecklistItem: nextChecklistItem,
            favoriteTools: Array(favoriteTools)
        )
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600)))
        completion(timeline)
    }
}
