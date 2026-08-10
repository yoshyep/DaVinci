import Foundation
import Testing

struct LocalizationCatalogContractTests {
    @Test func everyExtractedInterfaceStringHasEnglishAndSimplifiedChineseValues() throws {
        let testDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let catalogURL = testDirectory
            .deletingLastPathComponent()
            .appendingPathComponent("INSCENEWorkbench/Resources/Localizable.xcstrings")
        let data = try Data(contentsOf: catalogURL)
        let catalog = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try #require(catalog["strings"] as? [String: Any])

        let incompleteKeys = strings.compactMap { key, rawValue -> String? in
            guard
                let value = rawValue as? [String: Any],
                let localizations = value["localizations"] as? [String: Any],
                hasTranslation("en", in: localizations),
                hasTranslation("zh-Hans", in: localizations)
            else {
                return key
            }
            return nil
        }.sorted()

        #expect(incompleteKeys == [])
    }

    private func hasTranslation(_ language: String, in localizations: [String: Any]) -> Bool {
        guard
            let localization = localizations[language] as? [String: Any],
            let stringUnit = localization["stringUnit"] as? [String: Any],
            let value = stringUnit["value"] as? String
        else {
            return false
        }
        return !value.isEmpty
    }
}
