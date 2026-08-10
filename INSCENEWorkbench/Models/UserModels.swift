import Foundation
import SwiftData

@Model
final class ProjectSession {
    @Attribute(.unique) var id: UUID
    var name: String
    var templateID: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \StageProgress.session)
    var stageProgress: [StageProgress] = []

    @Relationship(deleteRule: .cascade, inverse: \ChecklistItemState.session)
    var checklistStates: [ChecklistItemState] = []

    init(
        id: UUID = UUID(),
        name: String,
        templateID: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.templateID = templateID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var completedChecklistCount: Int {
        checklistStates.filter(\.isCompleted).count
    }

    func setChecklist(contentID: String, completed: Bool) {
        if let state = checklistStates.first(where: { $0.contentID == contentID }) {
            state.isCompleted = completed
            state.updatedAt = .now
        } else {
            checklistStates.append(ChecklistItemState(contentID: contentID, isCompleted: completed))
        }
        updatedAt = .now
    }
}

@Model
final class StageProgress {
    @Attribute(.unique) var id: UUID
    var contentID: String
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date
    var session: ProjectSession?

    init(
        id: UUID = UUID(),
        contentID: String,
        isCompleted: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.contentID = contentID
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class ChecklistItemState {
    @Attribute(.unique) var id: UUID
    var contentID: String
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date
    var session: ProjectSession?

    init(
        id: UUID = UUID(),
        contentID: String,
        isCompleted: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.contentID = contentID
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class UserNote {
    @Attribute(.unique) var id: UUID
    var contentID: String
    var sessionID: UUID?
    var body: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        contentID: String,
        sessionID: UUID? = nil,
        body: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.contentID = contentID
        self.sessionID = sessionID
        self.body = body
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class ProjectVersionRecord {
    @Attribute(.unique) var id: UUID
    var sessionID: UUID
    var name: String
    var resolveVersion: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        name: String,
        resolveVersion: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.sessionID = sessionID
        self.name = name
        self.resolveVersion = resolveVersion
        self.createdAt = createdAt
    }
}

@Model
final class Favorite {
    @Attribute(.unique) var id: UUID
    var contentID: String
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), contentID: String, createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.contentID = contentID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class RecentActivity {
    @Attribute(.unique) var id: UUID
    var contentID: String
    var action: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        contentID: String,
        action: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.contentID = contentID
        self.action = action
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
