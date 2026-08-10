import Observation

@Observable
final class GuideContentRepository {
    let content: GuideContent
    private let recordsByID: [String: any SearchableContent]

    init(loader: any GuideContentLoading = BundledContentLoader()) throws {
        content = try loader.load()
        recordsByID = Dictionary(uniqueKeysWithValues: content.searchableRecords.map { ($0.id, $0) })
    }

    init(content: GuideContent) {
        self.content = content
        recordsByID = Dictionary(uniqueKeysWithValues: content.searchableRecords.map { ($0.id, $0) })
    }

    func record(id: String) -> (any SearchableContent)? {
        recordsByID[id]
    }
}
