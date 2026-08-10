import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            BrandLogoView(variant: .horizontal)
                .padding(24)
                .background(Color.white)
                .tabItem { Label("Workbench", systemImage: "square.grid.2x2") }
        }
    }
}
