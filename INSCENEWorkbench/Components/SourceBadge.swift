import SwiftUI

struct SourceBadge: View {
    enum Kind {
        case official
        case professional

        var systemImage: String {
            switch self {
            case .official: "checkmark.shield.fill"
            case .professional: "person.text.rectangle.fill"
            }
        }

        var color: Color {
            switch self {
            case .official: .blue
            case .professional: .indigo
            }
        }
    }

    let title: String
    let kind: Kind

    var body: some View {
        Label(title, systemImage: kind.systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(kind.color)
            .padding(.horizontal, 10)
            .frame(minHeight: 32)
            .background(kind.color.opacity(0.12), in: Capsule())
            .accessibilityElement(children: .combine)
    }
}
