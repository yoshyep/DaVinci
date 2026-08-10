import SwiftUI

struct BrandLogoView: View {
    enum Variant { case symbol, horizontal }
    let variant: Variant

    var body: some View {
        Image(variant == .symbol ? "BrandSymbol" : "INSCENEHorizontal")
            .resizable()
            .scaledToFit()
            .accessibilityIdentifier(variant == .symbol ? "brand.symbol" : "brand.horizontal")
            .accessibilityLabel(variant == .symbol ? "INSCENE" : "INSCENE logo")
    }
}
