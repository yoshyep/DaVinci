import WidgetKit
import SwiftUI

@main
struct QuickToolsWidget: Widget {
    let kind: String = "INSCENEQuickToolsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickToolsProvider()) { entry in
            QuickToolsWidgetView(entry: entry)
        }
        .configurationDisplayName("INSCENE Quick Tools")
        .description("Quick access to your favorite DaVinci Resolve tools and current project checklist.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget View

struct QuickToolsWidgetView: View {
    let entry: QuickToolsEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    // MARK: Small – four favorite tools in a 2×2 grid

    private var smallView: some View {
        VStack(spacing: 6) {
            if entry.favoriteTools.isEmpty {
                emptyFavoritesView
            } else {
                HStack(spacing: 6) {
                    toolCell(entry.favoriteTools[safe: 0])
                    toolCell(entry.favoriteTools[safe: 1])
                }
                HStack(spacing: 6) {
                    toolCell(entry.favoriteTools[safe: 2])
                    toolCell(entry.favoriteTools[safe: 3])
                }
            }
        }
        .padding(8)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    private func toolCell(_ tool: ToolSnapshot?) -> some View {
        Group {
            if let tool {
                Link(destination: deepLink(for: tool.contentID)) {
                    VStack(spacing: 4) {
                        Image(systemName: systemImage(for: tool.kind))
                            .font(.title3)
                        Text(tool.title)
                            .font(.caption2)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                Color.clear
            }
        }
    }

    // MARK: Medium – next checklist item

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checklist")
                    .font(.subheadline)
                Text("Next Checklist")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            if let item = entry.nextChecklistItem {
                VStack(alignment: .leading, spacing: 4) {
                    if !item.sessionName.isEmpty {
                        Text(item.sessionName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(item.title)
                        .font(.body)
                        .lineLimit(3)
                }
            } else {
                Text("No pending checklist items")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
        .widgetURL(URL(string: "inscene://tab/workflows"))
    }

    // MARK: Empty state

    private var emptyFavoritesView: some View {
        VStack(spacing: 6) {
            Image(systemName: "star")
                .font(.title3)
            Text("No Favorites")
                .font(.caption2)
        }
        .foregroundStyle(.secondary)
    }

    // MARK: Helpers

    private func deepLink(for contentID: String) -> URL {
        URL(string: "inscene://lookup/\(contentID)") ?? URL(string: "inscene://")!
    }

    private func systemImage(for kind: String) -> String {
        switch kind {
        case "stage": "list.number"
        case "shortcut": "keyboard"
        case "recipe": "wand.and.stars"
        case "colorPass": "circle.lefthalf.filled"
        case "export": "square.and.arrow.up"
        case "emergency": "cross.case"
        case "playbook": "book.closed"
        default: "wrench.and.screwdriver"
        }
    }
}

// MARK: - Safe Array Access

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
