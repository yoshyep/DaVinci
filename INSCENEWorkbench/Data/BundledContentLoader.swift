import Foundation

protocol GuideContentLoading: Sendable {
    func load() throws -> GuideContent
}

enum BundledContentLoaderError: Error, Equatable {
    case missingResource
    case invalidContent
    case duplicateID(String)
    case emptyTitle(id: String, language: AppLanguage)
    case emptyLocalizedText(id: String, field: LocalizedTextField, language: AppLanguage)
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
        let records: [(String, any LocalizedTextCarrying)] = content.stages.map { ($0.id, $0) }
            + content.shortcuts.map { ($0.id, $0) }
            + content.recipes.map { ($0.id, $0) }
            + content.colorPasses.map { ($0.id, $0) }
            + content.exports.map { ($0.id, $0) }
            + content.emergencies.map { ($0.id, $0) }
            + content.playbooks.map { ($0.id, $0) }
            + content.creators.map { ($0.id, $0) }
            + content.sources.map { ($0.id, $0) }
        var seenIDs = Set<String>()
        for (id, record) in records {
            guard seenIDs.insert(id).inserted else { throw BundledContentLoaderError.duplicateID(id) }
            for (field, text) in record.localizedTexts {
                if text.zhHans.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { throw BundledContentLoaderError.emptyLocalizedText(id: id, field: field, language: .zhHans) }
                if text.en.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { throw BundledContentLoaderError.emptyLocalizedText(id: id, field: field, language: .en) }
            }
        }
    }
}
