import Testing
import SwiftUI
@testable import INSCENEWorkbench

struct StageContrastTests {
    @Test func everyStageColorMeetsContrastSafeForeground() throws {
        let content = try BundledContentLoader().load()

        for stage in content.stages {
            let bgLuminance = Color.relativeLuminance(forHex: stage.color)
            let whiteContrast = Color.contrastRatio(luminance1: bgLuminance, luminance2: 1.0)
            let blackContrast = Color.contrastRatio(luminance1: bgLuminance, luminance2: 0.0)
            let bestContrast = max(whiteContrast, blackContrast)

            #expect(
                bestContrast >= 4.5,
                "Stage \(stage.number) color \(stage.color) best contrast is \(bestContrast), below 4.5:1"
            )
        }
    }

    @Test func lightBackgroundsSelectBlackForeground() {
        // #d09221 is a yellow/gold that should use black for adequate contrast
        let luminance = Color.relativeLuminance(forHex: "#d09221")
        #expect(luminance > 0.179)
        let blackContrast = Color.contrastRatio(luminance1: luminance, luminance2: 0.0)
        let whiteContrast = Color.contrastRatio(luminance1: luminance, luminance2: 1.0)
        #expect(blackContrast > whiteContrast)
    }

    @Test func darkBackgroundsSelectWhiteForeground() {
        // #596069 is a dark gray that should use white for adequate contrast
        let luminance = Color.relativeLuminance(forHex: "#596069")
        #expect(luminance <= 0.179)
        let blackContrast = Color.contrastRatio(luminance1: luminance, luminance2: 0.0)
        let whiteContrast = Color.contrastRatio(luminance1: luminance, luminance2: 1.0)
        #expect(whiteContrast > blackContrast)
    }
}
