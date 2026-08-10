import Foundation

protocol GuideContentLoading: Sendable {
    func load() throws -> GuideContent
}

enum BundledContentLoaderError: Error, Equatable {
    case missingResource
    case invalidContent
    case duplicateID(String)
    case emptyTitle(id: String, language: AppLanguage)
}

struct BundledContentLoader: GuideContentLoading {
    private let data: Data?
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        data = nil
    }

    init(data: Data) {
        self.data = data
        bundle = .main
    }

    func load() throws -> GuideContent {
        let decodedData = try data ?? bundledData()
        let content: GuideContent

        do {
            content = try JSONDecoder().decode(GuideContent.self, from: decodedData)
        } catch {
            throw BundledContentLoaderError.invalidContent
        }

        try validate(content)
        return content
    }

    private func bundledData() throws -> Data {
        let resourceURL = bundle.url(forResource: "guide-content", withExtension: "json", subdirectory: "Content")
            ?? bundle.url(forResource: "guide-content", withExtension: "json")
        guard let resourceURL, let resourceData = try? Data(contentsOf: resourceURL) else {
            throw BundledContentLoaderError.missingResource
        }
        return resourceData
    }

    private func validate(_ content: GuideContent) throws {
        var seenIDs = Set<String>()
        for record in content.searchableRecords {
            guard seenIDs.insert(record.id).inserted else {
                throw BundledContentLoaderError.duplicateID(record.id)
            }
            guard !record.title.zhHans.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw BundledContentLoaderError.emptyTitle(id: record.id, language: .zhHans)
            }
            guard !record.title.en.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw BundledContentLoaderError.emptyTitle(id: record.id, language: .en)
            }
        }
    }
}
