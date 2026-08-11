import SwiftUI

struct ShortcutCardView: View {
    let shortcut: ShortcutDefinition
    let settings: SettingsStore
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                keycaps
                Text(shortcut.title.resolved(for: settings.language))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(shortcut.summary.resolved(for: settings.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("shortcut.card.\(shortcut.id)")
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(settings.language == .zhHans ? "打开快捷键详情" : "Opens shortcut details")
    }

    private var keys: [String] {
        settings.platform == .mac ? shortcut.mac : shortcut.win
    }

    private var keycaps: some View {
        HStack(spacing: 4) {
            if keys.isEmpty {
                Image(systemName: "menucard")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            } else {
                ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                    Text(visibleKey(key))
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 8)
                        .frame(minHeight: 30)
                        .background(.thinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(.secondary.opacity(0.35), lineWidth: 1))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func visibleKey(_ key: String) -> String {
        switch key.lowercased() {
        case "cmd": "⌘"
        case "opt": "⌥"
        case "ctrl": "⌃"
        case "shift": "⇧"
        default: key
        }
    }

    private var accessibilityLabel: String {
        let separator = settings.language == .zhHans ? " 加 " : " plus "
        let spokenKeys = keys.map(spokenKey).joined(separator: separator)
        let title = shortcut.title.resolved(for: settings.language)
        if spokenKeys.isEmpty {
            return settings.language == .zhHans ? "\(title)，通过菜单执行" : "\(title), menu action"
        }
        return "\(title), \(spokenKeys)"
    }

    private func spokenKey(_ key: String) -> String {
        let chinese = settings.language == .zhHans
        switch key.lowercased() {
        case "cmd", "command": return chinese ? "Command 键" : "Command"
        case "opt", "option", "alt": return chinese ? "Option 键" : (key.lowercased() == "alt" ? "Alt" : "Option")
        case "ctrl", "control": return chinese ? "Control 键" : "Control"
        case "shift": return chinese ? "Shift 键" : "Shift"
        case "delete": return chinese ? "Delete 键" : "Delete"
        case "backspace": return chinese ? "Backspace 键" : "Backspace"
        case "space": return chinese ? "空格键" : "Space"
        default: return key
        }
    }
}
