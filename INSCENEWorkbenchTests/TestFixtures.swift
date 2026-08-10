import Foundation
@testable import INSCENEWorkbench

enum TestFixtures {
    static let validJSON = #"""
    {
      "contentVersion": 1,
      "stages": [{
        "id": "stage-one", "kind": "stage", "number": 1, "color": "#000000",
        "title": {"zhHans": "阶段一", "en": "Stage one"},
        "summary": {"zhHans": "摘要", "en": "Summary"},
        "quickSteps": [], "proSteps": [], "shortcutIDs": [],
        "mistake": "错误", "doneCheck": "完成", "proNotes": []
      }],
      "shortcuts": [{
        "id": "shortcut-one", "kind": "shortcut", "category": "navigation", "stages": [],
        "title": {"zhHans": "快捷键", "en": "Shortcut"},
        "summary": {"zhHans": "摘要", "en": "Summary"},
        "mac": ["A"], "win": ["A"], "menuZh": "菜单", "menuEn": "Menu", "level": "essential", "flags": []
      }],
      "recipes": [{
        "id": "recipe-one", "kind": "recipe", "category": "editing",
        "title": {"zhHans": "配方", "en": "Recipe"}, "summary": {"zhHans": "摘要", "en": "Summary"},
        "scene": "场景", "steps": [], "risk": "风险", "doneCheck": "完成", "shortcutIDs": []
      }],
      "colorPasses": [{
        "id": "color-one", "kind": "colorPass",
        "title": {"zhHans": "调色", "en": "Color pass"}, "summary": {"zhHans": "摘要", "en": "Summary"},
        "steps": [], "doneCheck": "完成", "risk": "风险", "shortcutIDs": [], "tools": [], "scopes": [], "commonMistakes": []
      }],
      "exports": [{
        "id": "export-one", "kind": "export",
        "title": {"zhHans": "导出", "en": "Export"}, "summary": {"zhHans": "摘要", "en": "Summary"},
        "specification": {}, "risk": "风险", "bitrate": "码率",
        "subtitles": [], "fileChecks": []
      }],
      "emergencies": [{
        "id": "emergency-one", "kind": "emergency",
        "title": {"zhHans": "紧急", "en": "Emergency"}, "summary": {"zhHans": "症状", "en": "Symptom"},
        "cause": "原因", "fix": [], "deep": "深入", "prevent": "预防"
      }],
      "playbooks": [{
        "id": "playbook-one", "kind": "playbook",
        "title": {"zhHans": "手册", "en": "Playbook"}, "summary": {"zhHans": "摘要", "en": "Summary"}, "steps": [], "sourceIDs": []
      }],
      "creators": [{"id": "creator-one", "name": {"zhHans": "创作者", "en": "Creator"}, "bio": {"zhHans": "简介", "en": "Bio"}}],
      "sources": [{"id": "source-one", "title": {"zhHans": "来源", "en": "Source"}, "url": "https://example.com"}]
    }
    """#

    static var sample: GuideContent {
        get throws {
            try JSONDecoder().decode(GuideContent.self, from: Data(validJSON.utf8))
        }
    }
}
