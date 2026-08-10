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

enum LocalizedTextField: String, Sendable {
    case title, summary, category, quickStep, proStep, mistake, doneCheck, proNote
    case scene, step, risk, tool, scope, commonMistake, specificationLabel, specificationValue
    case bitrate, subtitle, fileCheck, cause, fix, deep, prevent, playbookStep, name, bio
}

protocol LocalizedTextCarrying: Sendable {
    var localizedTexts: [(LocalizedTextField, LocalizedText)] { get }
}

struct WorkflowStage: Codable, SearchableContent, LocalizedTextCarrying {
    let id: String
    let kind: ContentKind
    let number: Int
    let color: String
    let title: LocalizedText
    let summary: LocalizedText
    let quickSteps: [LocalizedText]
    let proSteps: [LocalizedText]
    let shortcutIDs: [String]
    let mistake: LocalizedText
    let doneCheck: LocalizedText
    let proNotes: [LocalizedText]

    var keywords: [String] { ["stage", String(number), color] }
    var localizedTexts: [(LocalizedTextField, LocalizedText)] { [(.title, title), (.summary, summary)] + quickSteps.map { (.quickStep, $0) } + proSteps.map { (.proStep, $0) } + [(.mistake, mistake), (.doneCheck, doneCheck)] + proNotes.map { (.proNote, $0) } }
}

struct ShortcutDefinition: Codable, SearchableContent, LocalizedTextCarrying {
    let id: String
    let kind: ContentKind
    let category: LocalizedText
    let stages: [String]
    let title: LocalizedText
    let summary: LocalizedText
    let mac: [String]
    let win: [String]
    let menuZh: String
    let menuEn: String
    let level: String
    let flags: [String]

    var keywords: [String] { [category.zhHans, category.en] + mac + win + [menuZh, menuEn, level] + flags }
    var localizedTexts: [(LocalizedTextField, LocalizedText)] { [(.category, category), (.title, title), (.summary, summary)] }
}

struct RecipeDefinition: Codable, SearchableContent, LocalizedTextCarrying {
    let id: String
    let kind: ContentKind
    let category: LocalizedText
    let title: LocalizedText
    let summary: LocalizedText
    let scene: LocalizedText
    let steps: [LocalizedText]
    let risk: LocalizedText
    let doneCheck: LocalizedText
    let shortcutIDs: [String]

    var keywords: [String] { [category.zhHans, category.en, scene.zhHans, scene.en] }
    var localizedTexts: [(LocalizedTextField, LocalizedText)] { [(.category, category), (.title, title), (.summary, summary), (.scene, scene), (.risk, risk), (.doneCheck, doneCheck)] + steps.map { (.step, $0) } }
}

struct ColorPass: Codable, SearchableContent, LocalizedTextCarrying {
    let id: String
    let kind: ContentKind
    let title: LocalizedText
    let summary: LocalizedText
    let steps: [LocalizedText]
    let doneCheck: LocalizedText
    let risk: LocalizedText
    let shortcutIDs: [String]
    let tools: [LocalizedText]
    let scopes: [LocalizedText]
    let commonMistakes: [LocalizedText]

    var keywords: [String] { (tools + scopes + commonMistakes).flatMap { [$0.zhHans, $0.en] } }
    var localizedTexts: [(LocalizedTextField, LocalizedText)] { [(.title, title), (.summary, summary), (.doneCheck, doneCheck), (.risk, risk)] + steps.map { (.step, $0) } + tools.map { (.tool, $0) } + scopes.map { (.scope, $0) } + commonMistakes.map { (.commonMistake, $0) } }
}

struct LocalizedSpecificationEntry: Codable, Hashable, Sendable {
    let label: LocalizedText
    let value: LocalizedText
}

struct ExportRecipe: Codable, SearchableContent, LocalizedTextCarrying {
    let id: String
    let kind: ContentKind
    let title: LocalizedText
    let summary: LocalizedText
    let specification: [LocalizedSpecificationEntry]
    let risk: LocalizedText
    let bitrate: LocalizedText
    let subtitles: [LocalizedText]
    let fileChecks: [LocalizedText]

    var keywords: [String] { specification.flatMap { [$0.label.zhHans, $0.label.en, $0.value.zhHans, $0.value.en] } }
    var localizedTexts: [(LocalizedTextField, LocalizedText)] { [(.title, title), (.summary, summary), (.risk, risk), (.bitrate, bitrate)] + specification.flatMap { [(.specificationLabel, $0.label), (.specificationValue, $0.value)] } + subtitles.map { (.subtitle, $0) } + fileChecks.map { (.fileCheck, $0) } }
}

struct EmergencyGuide: Codable, SearchableContent, LocalizedTextCarrying {
    let id: String
    let kind: ContentKind
    let title: LocalizedText
    let summary: LocalizedText
    let cause: LocalizedText
    let fix: [LocalizedText]
    let deep: LocalizedText
    let prevent: LocalizedText

    var keywords: [String] { [cause, deep, prevent].flatMap { [$0.zhHans, $0.en] } }
    var localizedTexts: [(LocalizedTextField, LocalizedText)] { [(.title, title), (.summary, summary), (.cause, cause), (.deep, deep), (.prevent, prevent)] + fix.map { (.fix, $0) } }
}

struct ExpertPlaybook: Codable, SearchableContent, LocalizedTextCarrying {
    let id: String
    let kind: ContentKind
    let title: LocalizedText
    let summary: LocalizedText
    let steps: [LocalizedText]
    let sourceIDs: [String]

    var keywords: [String] { sourceIDs }
    var localizedTexts: [(LocalizedTextField, LocalizedText)] { [(.title, title), (.summary, summary)] + steps.map { (.playbookStep, $0) } }
}

struct CreatorProfile: Codable, Identifiable, Sendable, LocalizedTextCarrying {
    let id: String
    let name: LocalizedText
    let bio: LocalizedText
    var localizedTexts: [(LocalizedTextField, LocalizedText)] { [(.name, name), (.bio, bio)] }
}

struct SourceReference: Codable, Identifiable, Sendable, LocalizedTextCarrying {
    let id: String
    let title: LocalizedText
    let url: String
    var localizedTexts: [(LocalizedTextField, LocalizedText)] { [(.title, title)] }
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
