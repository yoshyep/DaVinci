import Foundation
import Observation

enum ShortcutPlatform: String, Codable, CaseIterable {
    case mac, windows
}

enum ContentLevel: String, Codable, CaseIterable {
    case quick, professional
}

enum AppTab: String, Codable, CaseIterable {
    case workbench, lookup, workflows, library
}

enum AppearanceMode: String, Codable, CaseIterable {
    case system, dark, light
}

@Observable
final class SettingsStore {
    private let defaults: UserDefaults

    var language: AppLanguage { didSet { defaults.set(language.rawValue, forKey: "language") } }
    var platform: ShortcutPlatform { didSet { defaults.set(platform.rawValue, forKey: "platform") } }
    var contentLevel: ContentLevel { didSet { defaults.set(contentLevel.rawValue, forKey: "contentLevel") } }
    var defaultTab: AppTab { didSet { defaults.set(defaultTab.rawValue, forKey: "defaultTab") } }
    var appearance: AppearanceMode { didSet { defaults.set(appearance.rawValue, forKey: "appearance") } }
    var hasCompletedOnboarding: Bool { didSet { defaults.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") } }
    var showsSources: Bool { didSet { defaults.set(showsSources, forKey: "showsSources") } }
    var showsProfessionalRecommendations: Bool { didSet { defaults.set(showsProfessionalRecommendations, forKey: "showsProfessionalRecommendations") } }
    var hapticsEnabled: Bool { didSet { defaults.set(hapticsEnabled, forKey: "hapticsEnabled") } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        language = AppLanguage(rawValue: defaults.string(forKey: "language") ?? "") ?? .zhHans
        platform = ShortcutPlatform(rawValue: defaults.string(forKey: "platform") ?? "") ?? .mac
        contentLevel = ContentLevel(rawValue: defaults.string(forKey: "contentLevel") ?? "") ?? .quick
        defaultTab = AppTab(rawValue: defaults.string(forKey: "defaultTab") ?? "") ?? .workbench
        appearance = AppearanceMode(rawValue: defaults.string(forKey: "appearance") ?? "") ?? .system
        hasCompletedOnboarding = defaults.object(forKey: "hasCompletedOnboarding") as? Bool ?? false
        showsSources = defaults.object(forKey: "showsSources") as? Bool ?? true
        showsProfessionalRecommendations = defaults.object(forKey: "showsProfessionalRecommendations") as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: "hapticsEnabled") as? Bool ?? true
    }
}
