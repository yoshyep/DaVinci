import Testing
import SwiftUI
import UIKit
@testable import INSCENEWorkbench

struct BrandAssetContractTests {
    @Test func mainBundleUsesTheINSCENEDaVinciWorkbenchIdentifier() {
        #expect(Bundle.main.bundleIdentifier == "com.inscene.davinciworkbench")
    }

    @Test func exactBrandAssetsLoadFromTheMainBundle() {
        #expect(UIImage(named: "BrandSymbol") != nil)
        #expect(UIImage(named: "INSCENEHorizontal") != nil)
    }

    @Test func appIconCentersA614PixelDarkMarkOnThe1024PixelCanvas() throws {
        let testDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let iconURL = testDirectory
            .deletingLastPathComponent()
            .appendingPathComponent(
                "INSCENEWorkbench/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
            )
        let image = try #require(UIImage(contentsOfFile: iconURL.path))
        let bounds = try #require(darkPixelBoundingBox(in: image))

        #expect(image.size == CGSize(width: 1024, height: 1024))
        #expect(abs(bounds.width - 614) <= 2)
        #expect(abs(bounds.height - 614) <= 2)
        #expect(abs(bounds.minX - 205) <= 2)
        #expect(abs(bounds.minY - 205) <= 2)
        #expect(abs((1024 - bounds.maxX) - 205) <= 2)
        #expect(abs((1024 - bounds.maxY) - 205) <= 2)
    }

    @MainActor
    @Test func horizontalLogoUsesPrimaryTemplateColorOnTransparentSurroundings() throws {
        let light = try #require(renderedHorizontalLogo(colorScheme: .light))
        let dark = try #require(renderedHorizontalLogo(colorScheme: .dark))

        #expect(try cornerAlpha(in: light) < 10)
        #expect(try cornerAlpha(in: dark) < 10)
        #expect(try opaquePixelAverageLuminance(in: light) < 0.25)
        #expect(try opaquePixelAverageLuminance(in: dark) > 0.75)
    }

    @MainActor
    @Test func symbolLogoCentersArtworkAtSixtyPercentOfItsAssignedSquare() throws {
        let image = try #require(renderedSymbolLogo())
        let bounds = try #require(darkPixelBoundingBox(in: image))

        #expect(abs(bounds.width - 60) <= 1)
        #expect(abs(bounds.height - 60) <= 1)
        #expect(abs(bounds.minX - 20) <= 1)
        #expect(abs(bounds.minY - 20) <= 1)
    }

    @MainActor
    private func renderedHorizontalLogo(colorScheme: ColorScheme) -> UIImage? {
        let renderer = ImageRenderer(
            content: BrandLogoView(variant: .horizontal)
                .frame(width: 230, height: 62)
                .environment(\.colorScheme, colorScheme)
        )
        renderer.proposedSize = ProposedViewSize(width: 230, height: 62)
        renderer.scale = 1
        renderer.isOpaque = false
        return renderer.uiImage
    }

    @MainActor
    private func renderedSymbolLogo() -> UIImage? {
        let renderer = ImageRenderer(
            content: BrandLogoView(variant: .symbol)
                .frame(width: 100, height: 100)
        )
        renderer.proposedSize = ProposedViewSize(width: 100, height: 100)
        renderer.scale = 1
        renderer.isOpaque = false
        return renderer.uiImage
    }

    private func cornerAlpha(in image: UIImage) throws -> UInt8 {
        let pixels = try rgbaPixels(in: image)
        return pixels.bytes[3]
    }

    private func opaquePixelAverageLuminance(in image: UIImage) throws -> Double {
        let pixels = try rgbaPixels(in: image)
        var luminance = 0.0
        var count = 0
        for offset in stride(from: 0, to: pixels.bytes.count, by: 4)
        where pixels.bytes[offset + 3] > 200 {
            luminance += (
                Double(pixels.bytes[offset])
                    + Double(pixels.bytes[offset + 1])
                    + Double(pixels.bytes[offset + 2])
            ) / (3 * 255)
            count += 1
        }
        guard count > 0 else { throw PixelInspectionError.noOpaquePixels }
        return luminance / Double(count)
    }

    private func darkPixelBoundingBox(in image: UIImage) -> CGRect? {
        guard let pixels = try? rgbaPixels(in: image) else { return nil }
        let width = pixels.width
        let height = pixels.height

        var minX = width
        var minY = height
        var maxX = -1
        var maxY = -1
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let isDark = pixels.bytes[offset] < 128
                    && pixels.bytes[offset + 1] < 128
                    && pixels.bytes[offset + 2] < 128
                    && pixels.bytes[offset + 3] > 127
                guard isDark else { continue }
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }
        guard maxX >= minX, maxY >= minY else { return nil }
        return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    }

    private func rgbaPixels(in image: UIImage) throws -> (bytes: [UInt8], width: Int, height: Int) {
        let cgImage = try #require(image.cgImage)
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = width * 4
        var bytes = [UInt8](repeating: 0, count: height * bytesPerRow)
        let context = try #require(CGContext(
            data: &bytes,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return (bytes, width, height)
    }

    private enum PixelInspectionError: Error {
        case noOpaquePixels
    }
}
