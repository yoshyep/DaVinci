import Foundation
import Testing
@testable import INSCENEWorkbench

struct BundledContentLoaderTests {
    @Test func bundledGuideHasExpectedLegacyInventory() throws {
        let content = try BundledContentLoader().load()
        #expect(content.stages.count == 10)
        #expect(content.shortcuts.count == 61)
        #expect(content.recipes.count == 18)
        #expect(content.colorPasses.count == 6)
        #expect(content.exports.count == 8)
        #expect(content.emergencies.count == 12)
    }

    @Test func everyContentRecordHasStableIDAndTwoLanguages() throws {
        let content = try BundledContentLoader().load()
        let records = content.searchableRecords
        #expect(Set(records.map { $0.id }).count == records.count)
        #expect(records.allSatisfy { !$0.title.zhHans.isEmpty && !$0.title.en.isEmpty })
    }

    @Test func loaderRejectsDuplicateStableIDs() throws {
        var json = TestFixtures.validJSON
        json = json.replacingOccurrences(of: "\"id\": \"shortcut-one\"", with: "\"id\": \"stage-one\"")

        #expect(throws: BundledContentLoaderError.duplicateID("stage-one")) {
            try BundledContentLoader(data: Data(json.utf8)).load()
        }
    }

    @Test func loaderRejectsRecordsWithAnEmptyEnglishTitle() throws {
        let json = TestFixtures.validJSON.replacingOccurrences(
            of: "\"en\": \"Stage one\"",
            with: "\"en\": \"\""
        )

        #expect(throws: BundledContentLoaderError.emptyLocalizedText(id: "stage-one", field: .title, language: .en)) {
            try BundledContentLoader(data: Data(json.utf8)).load()
        }
    }

    @Test func loaderRejectsDuplicateIDsAcrossSearchableAndReferenceRecords() throws {
        let json = TestFixtures.validJSON.replacingOccurrences(
            of: "\"id\": \"source-one\"",
            with: "\"id\": \"stage-one\""
        )

        #expect(throws: BundledContentLoaderError.duplicateID("stage-one")) {
            try BundledContentLoader(data: Data(json.utf8)).load()
        }
    }

    @Test func loaderRejectsRecordsWithAnEmptyLocalizedSummary() throws {
        let json = TestFixtures.validJSON.replacingOccurrences(
            of: "\"en\": \"Summary\"",
            with: "\"en\": \"\"",
            options: [],
            range: TestFixtures.validJSON.range(of: "\"summary\": {\"zhHans\": \"摘要\", \"en\": \"Summary\"}")
        )

        #expect(throws: BundledContentLoaderError.emptyLocalizedText(id: "stage-one", field: .summary, language: .en)) {
            try BundledContentLoader(data: Data(json.utf8)).load()
        }
    }

    @Test func loaderRejectsEmptyCreatorBioAndSourceTitle() throws {
        let creatorJSON = TestFixtures.validJSON.replacingOccurrences(of: "\"en\": \"Bio\"", with: "\"en\": \"\"")
        #expect(throws: BundledContentLoaderError.emptyLocalizedText(id: "creator-one", field: .bio, language: .en)) {
            try BundledContentLoader(data: Data(creatorJSON.utf8)).load()
        }

        let sourceJSON = TestFixtures.validJSON.replacingOccurrences(of: "\"en\": \"Source\"", with: "\"en\": \"\"")
        #expect(throws: BundledContentLoaderError.emptyLocalizedText(id: "source-one", field: .title, language: .en)) {
            try BundledContentLoader(data: Data(sourceJSON.utf8)).load()
        }
    }

    @Test func loaderRejectsEmptyShortcutEnglishMenuPath() throws {
        let json = TestFixtures.validJSON.replacingOccurrences(of: "\"en\": \"Menu\"", with: "\"en\": \"\"")
        #expect(throws: BundledContentLoaderError.emptyLocalizedText(id: "shortcut-one", field: .menu, language: .en)) {
            try BundledContentLoader(data: Data(json.utf8)).load()
        }
    }

    @Test func bundledDetailsUseResolveTerminologyInEnglish() throws {
        let content = try BundledContentLoader().load()
        let finish = try #require(content.colorPasses.first { $0.id == "color-finish" })
        #expect(finish.steps.contains { $0.en == "Finally, add film grain to unify the texture." })
        #expect(finish.commonMistakes.first?.en == "Overdoing noise reduction creates a waxy look or motion smearing.")

        let proxy = try #require(content.emergencies.first { $0.id == "em-proxy" })
        #expect(proxy.fix[1].en == "Disable proxy media, then relink the correct files.")
        #expect(proxy.prevent.en == "Standardize proxy presets and naming; do not use unknown low-bitrate files.")
    }
}
