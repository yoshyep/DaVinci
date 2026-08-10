import Foundation

enum SearchReason: String, Sendable {
    case exactTitle
    case title
    case alias
    case shortcut
    case menu
    case body
}

struct SearchFilters: Equatable, Sendable {
    var kind: ContentKind?
    var category: String?
    var stageID: String?

    init(kind: ContentKind? = nil, category: String? = nil, stageID: String? = nil) {
        self.kind = kind
        self.category = category
        self.stageID = stageID
    }
}

struct SearchContext: Sendable {
    let language: AppLanguage
    let platform: ShortcutPlatform
    let currentStageID: String?
    let recentIDs: [String]
    let favoriteIDs: [String]
    var filters: SearchFilters

    init(
        language: AppLanguage,
        platform: ShortcutPlatform,
        currentStageID: String?,
        recentIDs: [String],
        favoriteIDs: [String],
        filters: SearchFilters = SearchFilters()
    ) {
        self.language = language
        self.platform = platform
        self.currentStageID = currentStageID
        self.recentIDs = recentIDs
        self.favoriteIDs = favoriteIDs
        self.filters = filters
    }
}

struct SearchHit: Identifiable, Sendable {
    let id: String
    let contentID: String
    let kind: ContentKind
    let score: Int
    let reason: SearchReason
}

struct SearchEngine: Sendable {
    private let records: [any SearchableContent]
    private let stages: [WorkflowStage]

    init(repository: GuideContentRepository) {
        records = repository.content.searchableRecords
        stages = repository.content.stages
    }

    func search(_ query: String, context: SearchContext) -> [SearchHit] {
        let normalizedQuery = Self.normalize(query)
        guard !normalizedQuery.isEmpty else { return [] }

        return records.compactMap { record in
            guard matchesFilters(record, filters: context.filters) else { return nil }
            guard let match = baseMatch(record, query: normalizedQuery, platform: context.platform) else {
                return nil
            }

            var score = match.score
            if match.reason != .exactTitle {
                if isRelated(record, to: context.currentStageID) { score += 25 }
                if context.recentIDs.contains(record.id) { score += 15 }
                if context.favoriteIDs.contains(record.id) { score += 10 }
                score = min(score, 99)
            }
            return SearchHit(
                id: record.id,
                contentID: record.id,
                kind: record.kind,
                score: score,
                reason: match.reason
            )
        }
        .sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            let lhsPriority = Self.kindPriority(lhs.kind)
            let rhsPriority = Self.kindPriority(rhs.kind)
            if lhsPriority != rhsPriority { return lhsPriority < rhsPriority }
            return lhs.contentID < rhs.contentID
        }
    }

    private func baseMatch(
        _ record: any SearchableContent,
        query: String,
        platform: ShortcutPlatform
    ) -> (score: Int, reason: SearchReason)? {
        let titles = [record.title.zhHans, record.title.en].map(Self.normalize)
        if titles.contains(query) {
            return (100, .exactTitle)
        }
        var candidates: [(score: Int, reason: SearchReason)] = []
        if titles.contains(where: { Self.phraseMatches($0, query: query) }) {
            candidates.append((70, .title))
        }

        let aliases = Self.aliases[record.id, default: []].map(Self.normalize)
        if aliases.contains(where: { Self.bidirectionalPhraseMatch($0, query: query) }) {
            candidates.append((80, .alias))
        }

        if let shortcut = record as? ShortcutDefinition {
            let keys = platform == .mac ? shortcut.mac : shortcut.win
            let normalizedKeys = Self.normalize(keys.joined(separator: " "))
            if !normalizedKeys.isEmpty && Self.phraseMatches(normalizedKeys, query: query) {
                candidates.append((65, .shortcut))
            }
            let menus = [shortcut.menu.zhHans, shortcut.menu.en].map(Self.normalize)
            if menus.contains(where: { Self.phraseMatches($0, query: query) }) {
                candidates.append((45, .menu))
            }
        }

        let bodyFields = searchableBody(for: record)
        if bodyFields.contains(where: { Self.phraseMatches(Self.normalize($0), query: query) }) {
            candidates.append((5, .body))
        }
        return candidates.max { $0.score < $1.score }
    }

    private func searchableBody(for record: any SearchableContent) -> [String] {
        var fields = [record.summary.zhHans, record.summary.en]
        if let carrying = record as? any LocalizedTextCarrying {
            fields += carrying.localizedTexts
                .filter { ![.title, .summary, .menu].contains($0.0) }
                .flatMap { [$0.1.zhHans, $0.1.en] }
        }
        if let shortcut = record as? ShortcutDefinition {
            fields += [shortcut.category.zhHans, shortcut.category.en] + shortcut.flags
        }
        return fields
    }

    private func matchesFilters(_ record: any SearchableContent, filters: SearchFilters) -> Bool {
        if let kind = filters.kind, record.kind != kind { return false }

        if let category = filters.category {
            let wanted = Self.normalize(category)
            let categories: [String]
            if let shortcut = record as? ShortcutDefinition {
                categories = [shortcut.category.zhHans, shortcut.category.en]
            } else if let recipe = record as? RecipeDefinition {
                categories = [recipe.category.zhHans, recipe.category.en]
            } else {
                categories = []
            }
            if !categories.map(Self.normalize).contains(wanted) { return false }
        }

        if let stageID = filters.stageID, !isRelated(record, to: stageID) { return false }
        return true
    }

    private func isRelated(_ record: any SearchableContent, to stageID: String?) -> Bool {
        guard let stageID else { return false }
        if let stage = record as? WorkflowStage { return stage.id == stageID }
        if let shortcut = record as? ShortcutDefinition { return shortcut.stages.contains(stageID) }

        guard let stage = stages.first(where: { $0.id == stageID }) else { return false }
        let relatedShortcutIDs: [String]
        if let recipe = record as? RecipeDefinition {
            relatedShortcutIDs = recipe.shortcutIDs
        } else if let colorPass = record as? ColorPass {
            relatedShortcutIDs = colorPass.shortcutIDs
        } else {
            relatedShortcutIDs = []
        }
        return !Set(relatedShortcutIDs).isDisjoint(with: stage.shortcutIDs)
    }

    private static func phraseMatches(_ field: String, query: String) -> Bool {
        guard !field.isEmpty else { return false }
        if field.contains(query) { return true }
        let queryTokens = query.split(separator: " ").map(String.init)
        return queryTokens.count > 1 && queryTokens.allSatisfy { field.contains($0) }
    }

    private static func bidirectionalPhraseMatch(_ alias: String, query: String) -> Bool {
        if alias == query { return true }
        if containsCJK(alias) || containsCJK(query) {
            return (alias.count >= 2 && query.contains(alias)) ||
                (query.count >= 2 && alias.contains(query))
        }

        let aliasTokens = alias.split(separator: " ").map(String.init)
        let queryTokens = query.split(separator: " ").map(String.init)
        guard !aliasTokens.isEmpty, !queryTokens.isEmpty else { return false }
        if containsTokenPhrase(aliasTokens, in: queryTokens) { return true }
        return queryTokens.count > 1 && queryTokens.allSatisfy(aliasTokens.contains)
    }

    private static func containsTokenPhrase(_ phrase: [String], in tokens: [String]) -> Bool {
        guard phrase.count <= tokens.count else { return false }
        for start in 0...(tokens.count - phrase.count) {
            if Array(tokens[start..<(start + phrase.count)]) == phrase { return true }
        }
        return false
    }

    private static func containsCJK(_ value: String) -> Bool {
        value.unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x3400...0x4DBF, 0x4E00...0x9FFF, 0xF900...0xFAFF: true
            default: false
            }
        }
    }

    static func normalize(_ value: String) -> String {
        let folded = value
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()

        var tokens: [String] = []
        var current = ""
        for scalar in folded.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                current.unicodeScalars.append(scalar)
                continue
            }
            if !current.isEmpty {
                tokens.append(current)
                current = ""
            }
            switch scalar {
            case "⌘": tokens.append("command")
            case "⌃": tokens.append("control")
            case "⌥": tokens.append("option")
            default: break
            }
        }
        if !current.isEmpty { tokens.append(current) }

        return tokens.map { token in
            switch token {
            case "cmd", "command": "command"
            case "ctrl", "control": "control"
            case "opt", "option", "alt": "option"
            default: token
            }
        }.joined(separator: " ")
    }

    private static func kindPriority(_ kind: ContentKind) -> Int {
        switch kind {
        case .shortcut: 0
        case .recipe: 1
        case .colorPass: 2
        case .export: 3
        case .emergency: 4
        case .stage: 5
        case .playbook: 6
        }
    }

    private static let aliases: [String: [String]] = [
        "delete-ripple": [
            "删掉中间一段但不要留空", "不要留空", "删除后自动合拢", "无缝删除",
            "delete without a gap", "remove clip and close gap", "remove gap", "bowen shanchu"
        ],
        "recipe-skin": [
            "肤色", "修正肤色", "让多机位肤色一致", "fuse", "fix skin", "skin tone", "match skin tones"
        ],
        "em-offline": [
            "媒体离线", "素材离线", "meiti lixian", "media offline", "missing media", "relink media"
        ],
        "ex-web": [
            "h264", "h 264", "web export", "youtube export", "网络导出", "wangluo daochu"
        ],
        "split-playhead": [
            "cut at playhead", "split clip", "播放头分割", "fen ge"
        ],
        "nav-color": ["进入调色", "open color page", "tiaose yemian"],
        "render-queue": ["加入渲染队列", "queue render", "render job"]
    ]
}
