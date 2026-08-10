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

        #expect(throws: BundledContentLoaderError.emptyTitle(id: "stage-one", language: .en)) {
            try BundledContentLoader(data: Data(json.utf8)).load()
        }
    }
}
