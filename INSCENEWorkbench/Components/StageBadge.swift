import SwiftUI

struct StageBadge: View {
    enum State {
        case completed, current, upcoming
    }

    let number: Int
    let title: String
    let state: State
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 5) {
                    Image(systemName: state == .completed ? "checkmark.circle.fill" : "circle.fill")
                        .foregroundStyle(stateColor)
                    Text(String(format: "%02d", number))
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(.secondary)
                }

                Text(title)
                    .font(.caption.weight(state == .current ? .bold : .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(width: 106, alignment: .leading)
            .frame(minHeight: 62, alignment: .leading)
            .padding(10)
            .background(
                state == .current ? stateColor.opacity(0.16) : Color(uiColor: .secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(state == .current ? stateColor.opacity(0.8) : .clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(number). \(title)")
        .accessibilityValue(Text(accessibilityState))
        .accessibilityIdentifier("workbench.stage.\(number)")
    }

    private var stateColor: Color {
        switch state {
        case .completed: .green
        case .current: .blue
        case .upcoming: .secondary
        }
    }

    private var accessibilityState: LocalizedStringKey {
        switch state {
        case .completed: "workbench.stage.completed"
        case .current: "workbench.stage.current"
        case .upcoming: "workbench.stage.upcoming"
        }
    }
}
