import Foundation
import SwiftData
@testable import INSCENEWorkbench

enum TestFixtures {
    static let validJSON = #"""
    {
      "contentVersion": 1,
      "stages": [{
        "id": "stage-one", "kind": "stage", "number": 1, "color": "#000000",
        "title": {"zhHans": "阶段一", "en": "Stage one"}, "summary": {"zhHans": "摘要", "en": "Summary"},
        "quickSteps": [], "proSteps": [], "shortcutIDs": [],
        "mistake": {"zhHans": "错误", "en": "Mistake"}, "doneCheck": {"zhHans": "完成", "en": "Done"}, "proNotes": []
      }],
      "shortcuts": [{
        "id": "shortcut-one", "kind": "shortcut", "category": {"zhHans": "导航", "en": "Navigation"}, "stages": [],
        "title": {"zhHans": "快捷键", "en": "Shortcut"},
        "summary": {"zhHans": "摘要", "en": "Summary"},
        "mac": ["A"], "win": ["A"], "menu": {"zhHans": "菜单", "en": "Menu"}, "level": "essential", "flags": []
      }],
      "recipes": [{
        "id": "recipe-one", "kind": "recipe", "category": {"zhHans": "剪辑", "en": "Editing"},
        "title": {"zhHans": "配方", "en": "Recipe"}, "summary": {"zhHans": "摘要", "en": "Summary"},
        "scene": {"zhHans": "场景", "en": "Scene"}, "steps": [], "risk": {"zhHans": "风险", "en": "Risk"}, "doneCheck": {"zhHans": "完成", "en": "Done"}, "shortcutIDs": []
      }],
      "colorPasses": [{
        "id": "color-one", "kind": "colorPass",
        "title": {"zhHans": "调色", "en": "Color pass"}, "summary": {"zhHans": "摘要", "en": "Summary"},
        "steps": [], "doneCheck": {"zhHans": "完成", "en": "Done"}, "risk": {"zhHans": "风险", "en": "Risk"}, "shortcutIDs": [], "tools": [], "scopes": [], "commonMistakes": []
      }],
      "exports": [{
        "id": "export-one", "kind": "export",
        "title": {"zhHans": "导出", "en": "Export"}, "summary": {"zhHans": "摘要", "en": "Summary"},
        "specification": [], "risk": {"zhHans": "风险", "en": "Risk"}, "bitrate": {"zhHans": "码率", "en": "Bitrate"},
        "subtitles": [], "fileChecks": []
      }],
      "emergencies": [{
        "id": "emergency-one", "kind": "emergency",
        "title": {"zhHans": "紧急", "en": "Emergency"}, "summary": {"zhHans": "症状", "en": "Symptom"},
        "cause": {"zhHans": "原因", "en": "Cause"}, "fix": [], "deep": {"zhHans": "深入", "en": "Deep"}, "prevent": {"zhHans": "预防", "en": "Prevent"}
      }],
      "playbooks": [{
        "id": "playbook-one", "kind": "playbook",
        "creatorID": "creator-one",
        "title": {"zhHans": "手册", "en": "Playbook"}, "summary": {"zhHans": "摘要", "en": "Summary"},
        "problem": {"zhHans": "问题", "en": "Problem"}, "fit": [], "nonFit": [{"zhHans": "不适用", "en": "Do not use"}],
        "requirements": [], "steps": [], "judgmentCriteria": [], "mistakes": [], "rollback": [], "officialDifferences": [],
        "checklist": [{"id": "one-chk-check-one", "text": {"zhHans": "检查一", "en": "Check one"}}],
        "resolveVersion": "20+", "compatibility": "freeAndStudio", "publishedDate": null, "lastReviewedDate": "2026-08-10",
        "sourceURL": "https://example.com", "sourceIDs": ["source-one"]
      }],
      "creators": [{"id": "creator-one", "name": {"zhHans": "创作者", "en": "Creator"}, "bio": {"zhHans": "简介", "en": "Bio"}}],
      "sources": [{"id": "source-one", "title": {"zhHans": "来源", "en": "Source"}, "url": "https://example.com", "publishedDate": null, "lastReviewedDate": "2026-08-10"}]
    }
    """#

    static var sample: GuideContent {
        get throws {
            try JSONDecoder().decode(GuideContent.self, from: Data(validJSON.utf8))
        }
    }
}

// MARK: - Test AppState

@MainActor
struct TestAppState {
    let modelContainer: ModelContainer
    let settings: SettingsStore
    let repository: GuideContentRepository

    var modelContext: ModelContext {
        modelContainer.mainContext
    }

    var snapshot: UserDataArchive {
        try! ImportExportService().exportArchive(from: modelContext, settings: settings)
    }

    static func populated() throws -> TestAppState {
        let container = try TestModelContainer.make()
        let context = container.mainContext

        let suiteName = "com.inscene.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let settings = SettingsStore(defaults: defaults)

        let content = try TestFixtures.sample
        let repository = GuideContentRepository(content: content)

        let session = ProjectSession(name: "Test Project", templateID: "template-test")
        let stage = StageProgress(contentID: "stage-one", isCompleted: true)
        session.stageProgress = [stage]
        let checklist = ChecklistItemState(contentID: "checklist-one", isCompleted: false)
        session.checklistStates = [checklist]
        context.insert(session)

        context.insert(UserNote(contentID: "stage-one", sessionID: session.id, body: "Test note"))
        context.insert(Favorite(contentID: "shortcut-one"))
        context.insert(RecentActivity(contentID: "recipe-one", action: "open"))

        try context.save()

        return TestAppState(modelContainer: container, settings: settings, repository: repository)
    }

    static func empty() throws -> TestAppState {
        let container = try TestModelContainer.make()

        let suiteName = "com.inscene.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let settings = SettingsStore(defaults: defaults)

        let content = try TestFixtures.sample
        let repository = GuideContentRepository(content: content)

        return TestAppState(modelContainer: container, settings: settings, repository: repository)
    }
}
