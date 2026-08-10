import Foundation

enum RecommendationProjectType: String, Codable, CaseIterable, Sendable {
    case interview
    case advertising
    case documentary
    case narrative
    case archival
}

enum RecommendationShotVolume: String, Codable, CaseIterable, Sendable {
    case low
    case medium
    case high
}

enum RecommendationDelivery: String, Codable, CaseIterable, Sendable {
    case web
    case broadcast
    case cinema
    case archive
}

struct RecommendationInput: Equatable, Sendable {
    let projectType: RecommendationProjectType
    let mixedCameras: Bool
    let needsProductColorAccuracy: Bool
    let needsFilmLook: Bool
    let shotVolume: RecommendationShotVolume
    let delivery: RecommendationDelivery
    let hasStudio: Bool
}

struct PlaybookRecommendation: Identifiable, Equatable, Sendable {
    var id: String { playbookID }
    let playbookID: String
    let reason: LocalizedText
    let dontUse: LocalizedText
    let score: Int
}
