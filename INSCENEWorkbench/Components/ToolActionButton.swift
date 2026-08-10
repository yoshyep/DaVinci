import SwiftUI

struct ToolActionButton: View {
    let titleKey: String
    let detailKey: String
    let systemImage: String
    let tint: Color
    let shortcutKeys: [String]
    let accessibilityIdentifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 3) {
                    Text(LocalizedStringKey(titleKey))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(LocalizedStringKey(detailKey))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                if !shortcutKeys.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(shortcutKeys, id: \.self) { key in
                            Text(key)
                                .font(.caption2.monospaced().weight(.semibold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 4)
                                .background(.tertiary, in: Capsule())
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(shortcutKeys.joined(separator: " + "))
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}
