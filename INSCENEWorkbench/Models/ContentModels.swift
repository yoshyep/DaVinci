import Foundation

enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case zhHans
    case en
}

struct LocalizedText: Codable, Hashable, Sendable {
    let zhHans: String
    let en: String

    func resolved(for language: AppLanguage) -> String {
        language == .zhHans ? zhHans : en
    }
}

enum ContentKind: String, Codable, CaseIterable, Sendable {
    case stage, shortcut, recipe, colorPass, export, emergency, playbook
}

protocol SearchableContent: Identifiable, Sendable where ID == String {
    var kind: ContentKind { get }
    var title: LocalizedText { get }
    var summary: LocalizedText { get }
    var keywords: [String] { get }
}

struct WorkflowStage: Codable, SearchableContent {
    let id: String
    let kind: ContentKind
    let number: Int
    let color: String
    let title: LocalizedText
    let summary: LocalizedText
    let quickSteps: [String]
    let proSteps: [String]
    let shortcutIDs: [String]
    let mistake: String
    let doneCheck: String
    let proNotes: [String]

    var keywords: [String] { ["stage", String(number), color] }
}

struct ShortcutDefinition: Codable, SearchableContent {
    let id: String
    let kind: ContentKind
    let category: String
    let stages: [String]
    let title: LocalizedText
    let summary: LocalizedText
    let mac: [String]
    let win: [String]
    let menuZh: String
    let menuEn: String
    let level: String
    let flags: [String]

    var keywords: [String] { [category] + mac + win + [menuZh, menuEn, level] + flags }
}

struct RecipeDefinition: Codable, SearchableContent {
    let id: String
    let kind: ContentKind
    let category: String
    let title: LocalizedText
    let summary: LocalizedText
    let scene: String
    let steps: [String]
    let risk: String
    let doneCheck: String
    let shortcutIDs: [String]

    var keywords: [String] { [category, scene] }
}

struct ColorPass: Codable, SearchableContent {
    let id: String
    let kind: ContentKind
    let title: LocalizedText
    let summary: LocalizedText
    let steps: [String]
    let doneCheck: String
    let risk: String
    let shortcutIDs: [String]
    let tools: [String]
    let scopes: [String]
    let commonMistakes: [String]

    var keywords: [String] { tools + scopes + commonMistakes }
}

struct ExportRecipe: Codable, SearchableContent {
    let id: String
    let kind: ContentKind
    let title: LocalizedText
    let summary: LocalizedText
    let specification: [String: String]
    let risk: String
    let bitrate: String
    let subtitles: [String]
    let fileChecks: [String]

    var keywords: [String] { Array(specification.keys) + Array(specification.values) }
}

struct EmergencyGuide: Codable, SearchableContent {
    let id: String
    let kind: ContentKind
    let title: LocalizedText
    let summary: LocalizedText
    let cause: String
    let fix: [String]
    let deep: String
    let prevent: String

    var keywords: [String] { [cause, deep, prevent] }
}

struct ExpertPlaybook: Codable, SearchableContent {
    let id: String
    let kind: ContentKind
    let title: LocalizedText
    let summary: LocalizedText
    let steps: [String]
    let sourceIDs: [String]

    var keywords: [String] { sourceIDs }
}

struct CreatorProfile: Codable, Identifiable, Sendable {
    let id: String
    let name: LocalizedText
    let bio: LocalizedText
}

struct SourceReference: Codable, Identifiable, Sendable {
    let id: String
    let title: LocalizedText
    let url: String
}

struct GuideContent: Codable, Sendable {
    let contentVersion: Int
    let stages: [WorkflowStage]
    let shortcuts: [ShortcutDefinition]
    let recipes: [RecipeDefinition]
    let colorPasses: [ColorPass]
    let exports: [ExportRecipe]
    let emergencies: [EmergencyGuide]
    let playbooks: [ExpertPlaybook]
    let creators: [CreatorProfile]
    let sources: [SourceReference]

    var searchableRecords: [any SearchableContent] {
        stages + shortcuts + recipes + colorPasses + exports + emergencies + playbooks
    }
}
