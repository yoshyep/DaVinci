import Testing
import UIKit
@testable import INSCENEWorkbench

struct BrandAssetContractTests {
    @Test func exactBrandAssetsLoadFromTheMainBundle() {
        #expect(UIImage(named: "BrandSymbol") != nil)
        #expect(UIImage(named: "INSCENEHorizontal") != nil)
    }
}
