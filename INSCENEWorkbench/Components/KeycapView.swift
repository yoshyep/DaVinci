import SwiftUI

struct KeycapView: View {
    let contentID: String
    let actionTitle: String
    let subtitle: String?
    let keys: [String]
    let language: AppLanguage
    var elementIdentifier: String? = nil
    var actionHint: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 8)
                    keycaps
                }
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .accessibilityIdentifier(elementIdentifier ?? "lookup.keycaps.\(contentID)")
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(actionHint ?? (language == .zhHans ? "打开快捷键详情" : "Opens shortcut details"))
        .buttonStyle(.plain)
    }

    private var keycaps: some View {
        HStack(spacing: 4) {
            if keys.isEmpty {
                Image(systemName: "menucard")
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
        .fixedSize(horizontal: true, vertical: false)
    }

    private var accessibilityLabel: String {
        let separator = language == .zhHans ? " 加 " : " plus "
        let spokenKeys = keys.map(spokenKey).joined(separator: separator)
        if spokenKeys.isEmpty {
            return language == .zhHans ? "\(actionTitle)，通过菜单执行" : "\(actionTitle), menu action"
        }
        return "\(actionTitle), \(spokenKeys)"
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

    private func spokenKey(_ key: String) -> String {
        let chinese = language == .zhHans
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
