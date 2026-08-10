import SwiftUI

struct SearchResultView: View {
    let record: any SearchableContent
    let settings: SettingsStore
    let isFavorite: Bool
    let open: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Label(kindTitle, systemImage: kindSymbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(kindTint)
                Text("R20")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                if record.kind == .shortcut {
                    Text(settings.platform == .mac ? "Mac" : "Windows")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.thinMaterial, in: Capsule())
                }
                Text(settings.contentLevel == .quick ? (settings.language == .zhHans ? "快速" : "Quick") : (settings.language == .zhHans ? "专业" : "Pro"))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Image(systemName: "checkmark.shield")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .accessibilityLabel(settings.language == .zhHans ? "本地内置来源" : "Offline built-in source")
                if isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .accessibilityLabel(settings.language == .zhHans ? "已收藏" : "Favorite")
                }
            }

            if let shortcut = record as? ShortcutDefinition {
                KeycapView(
                    contentID: shortcut.id,
                    actionTitle: shortcut.title.resolved(for: settings.language),
                    subtitle: shortcut.summary.resolved(for: settings.language),
                    keys: settings.platform == .mac ? shortcut.mac : shortcut.win,
                    language: settings.language,
                    elementIdentifier: "lookup.result.\(shortcut.id)",
                    actionHint: settings.language == .zhHans ? "打开快捷键详情" : "Opens shortcut details",
                    action: open
                )
            } else {
                Button(action: open) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(record.title.resolved(for: settings.language))
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Text(record.summary.resolved(for: settings.language))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(settings.contentLevel == .quick ? 2 : 4)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("lookup.result.\(record.id)")
            }
        }
        .padding(.vertical, 6)
    }

    private var kindTitle: String {
        let zh = settings.language == .zhHans
        switch record.kind {
        case .shortcut: return zh ? "快捷键" : "Shortcut"
        case .recipe: return zh ? "经典操作" : "Action"
        case .colorPass: return zh ? "调色" : "Color"
        case .export: return zh ? "输出" : "Export"
        case .emergency: return zh ? "故障急救" : "Troubleshooting"
        case .stage: return zh ? "官方流程" : "Workflow"
        case .playbook: return zh ? "专业流程" : "Professional"
        }
    }

    private var kindSymbol: String {
        switch record.kind {
        case .shortcut: "keyboard"
        case .recipe: "bolt"
        case .colorPass: "scope"
        case .export: "square.and.arrow.up"
        case .emergency: "cross.case"
        case .stage: "checklist"
        case .playbook: "person.text.rectangle"
        }
    }

    private var kindTint: Color {
        switch record.kind {
        case .emergency: .red
        case .export: .green
        case .colorPass: .purple
        default: .blue
        }
    }
}
