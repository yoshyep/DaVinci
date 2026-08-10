import SwiftUI

struct BrandLogoView: View {
    enum Variant { case symbol, horizontal }
    let variant: Variant

    var body: some View {
        Group {
            switch variant {
            case .symbol:
                Image("BrandSymbol")
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(0.6)
            case .horizontal:
                Image("INSCENEHorizontal")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.primary)
            }
        }
            .accessibilityIdentifier(variant == .symbol ? "brand.symbol" : "brand.horizontal")
            .accessibilityLabel(variant == .symbol ? "INSCENE" : "INSCENE logo")
    }
}
