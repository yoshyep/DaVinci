import Foundation
import CoreSpotlight
import UniformTypeIdentifiers

struct SpotlightItem {
    let uniqueIdentifier: String
    let title: String
    let contentDescription: String?
    let keywords: [String]
    let domainIdentifier: String
}

struct SpotlightIndexer {
    static let domainIdentifier = "com.inscene.davinciworkbench.content"

    /// Projects all bundled content records into Spotlight-searchable items.
    ///
    /// Only static guide content (stages, shortcuts, recipes, color passes,
    /// exports, emergencies, and playbooks) is indexed. User notes, favorites,
    /// recent activity, and media data are never included.
    static func project(content: GuideContent) -> [SpotlightItem] {
        content.searchableRecords.map { record in
            SpotlightItem(
                uniqueIdentifier: identifier(for: record),
                title: combinedTitle(record.title),
                contentDescription: combinedDescription(record.summary),
                keywords: keywords(for: record),
                domainIdentifier: domainIdentifier
            )
        }
    }

    /// Indexes all bundled content into Core Spotlight.
    static func index(content: GuideContent) {
        let items = project(content: content).map { item in
            CSSearchableItem(
                uniqueIdentifier: item.uniqueIdentifier,
                domainIdentifier: item.domainIdentifier,
                attributeSet: makeAttributeSet(for: item)
            )
        }
        CSSearchableIndex.default().indexSearchableItems(items) { _ in }
    }

    /// Extracts a content ID from a Spotlight tap activity.
    ///
    /// The `CSSearchableItemActivityIdentifier` stored in the activity's
    /// `userInfo` uses the format `"{kind}.{contentID}"`. This method strips
    /// the kind prefix and returns the bare content ID so the app can look it
    /// up in the repository.
    static func handle(userActivity: NSUserActivity) -> String? {
        guard let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return nil
        }
        guard let dotRange = identifier.range(of: ".") else {
            return identifier
        }
        let contentID = String(identifier[dotRange.upperBound...])
        return contentID.isEmpty ? nil : contentID
    }

    // MARK: - Private Helpers

    private static func identifier(for record: any SearchableContent) -> String {
        "\(record.kind.rawValue).\(record.id)"
    }

    private static func combinedTitle(_ title: LocalizedText) -> String {
        title.en == title.zhHans ? title.en : "\(title.en) / \(title.zhHans)"
    }

    private static func combinedDescription(_ summary: LocalizedText) -> String {
        summary.en == summary.zhHans ? summary.en : "\(summary.en) / \(summary.zhHans)"
    }

    /// Builds the keyword list for a content record.
    ///
    /// Following the same privacy pattern as `SearchEngine`, playbook
    /// `sourceIDs` and `creatorID` (opaque internal identifiers) are excluded
    /// from the user-facing keyword set. Only human-readable metadata such as
    /// `resolveVersion` and `compatibility` are kept for playbooks.
    private static func keywords(for record: any SearchableContent) -> [String] {
        var words: [String] = [
            record.title.en,
            record.title.zhHans,
            record.summary.en,
            record.summary.zhHans
        ]

        if let playbook = record as? ExpertPlaybook {
            words += [playbook.resolveVersion, playbook.compatibility.rawValue]
        } else {
            words += record.keywords
        }

        return Array(Set(words.filter { !$0.isEmpty }))
    }

    private static func makeAttributeSet(for item: SpotlightItem) -> CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: UTType.text.identifier)
        attributeSet.title = item.title
        attributeSet.contentDescription = item.contentDescription
        attributeSet.keywords = item.keywords
        return attributeSet
    }
}
