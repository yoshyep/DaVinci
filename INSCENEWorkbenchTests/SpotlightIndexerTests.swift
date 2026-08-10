import Testing
import Foundation
@testable import INSCENEWorkbench

struct SpotlightIndexerTests {
    @Test func spotlightProjectionContainsNoUserNotesOrMediaData() throws {
        let items = SpotlightIndexer.project(content: try BundledContentLoader().load())
        #expect(items.contains { $0.uniqueIdentifier == "shortcut.delete-ripple" })
        #expect(items.allSatisfy { !$0.title.isEmpty })
        #expect(items.allSatisfy { $0.contentDescription?.contains("user note") != true })
    }

    @Test func spotlightProjectionContainsAllContentKinds() throws {
        let items = SpotlightIndexer.project(content: try BundledContentLoader().load())
        #expect(items.count > 0)
        for kind in ContentKind.allCases {
            #expect(items.contains { $0.uniqueIdentifier.hasPrefix("\(kind.rawValue).") })
        }
    }

    @Test func spotlightItemsHaveValidDeepLinkIdentifiers() throws {
        let items = SpotlightIndexer.project(content: try BundledContentLoader().load())
        #expect(items.allSatisfy { !$0.uniqueIdentifier.isEmpty })
        #expect(items.allSatisfy { !$0.domainIdentifier.isEmpty })
    }
}
