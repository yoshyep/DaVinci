import Foundation
import SwiftData

// MARK: - Settings Snapshot

struct SettingsSnapshot: Codable, Equatable {
    var language: String = "zhHans"
    var platform: String = "mac"
    var contentLevel: String = "quick"
    var defaultTab: String = "workbench"
    var appearance: String = "system"
    var showsSources: Bool = true
    var showsProfessionalRecommendations: Bool = true
    var hapticsEnabled: Bool = true

    init() {}

    init(from settings: SettingsStore) {
        self.language = settings.language.rawValue
        self.platform = settings.platform.rawValue
        self.contentLevel = settings.contentLevel.rawValue
        self.defaultTab = settings.defaultTab.rawValue
        self.appearance = settings.appearance.rawValue
        self.showsSources = settings.showsSources
        self.showsProfessionalRecommendations = settings.showsProfessionalRecommendations
        self.hapticsEnabled = settings.hapticsEnabled
    }
}

// MARK: - Record Snapshots

struct ProjectSnapshot: Codable, Equatable {
    var id: String
    var name: String = ""
    var templateID: String = ""
    var createdAt: String = ""
    var updatedAt: String = ""

    init(from project: ProjectSession) {
        self.id = project.id.uuidString
        self.name = project.name
        self.templateID = project.templateID
        self.createdAt = ImportExportService.dateFormatter.string(from: project.createdAt)
        self.updatedAt = ImportExportService.dateFormatter.string(from: project.updatedAt)
    }
}

struct StageProgressSnapshot: Codable, Equatable {
    var id: String
    var sessionID: String? = nil
    var contentID: String = ""
    var isCompleted: Bool = false
    var createdAt: String = ""
    var updatedAt: String = ""

    init(from stage: StageProgress) {
        self.id = stage.id.uuidString
        self.sessionID = stage.session?.id.uuidString
        self.contentID = stage.contentID
        self.isCompleted = stage.isCompleted
        self.createdAt = ImportExportService.dateFormatter.string(from: stage.createdAt)
        self.updatedAt = ImportExportService.dateFormatter.string(from: stage.updatedAt)
    }
}

struct ChecklistStateSnapshot: Codable, Equatable {
    var id: String
    var sessionID: String? = nil
    var contentID: String = ""
    var isCompleted: Bool = false
    var createdAt: String = ""
    var updatedAt: String = ""

    init(from state: ChecklistItemState) {
        self.id = state.id.uuidString
        self.sessionID = state.session?.id.uuidString
        self.contentID = state.contentID
        self.isCompleted = state.isCompleted
        self.createdAt = ImportExportService.dateFormatter.string(from: state.createdAt)
        self.updatedAt = ImportExportService.dateFormatter.string(from: state.updatedAt)
    }
}

struct VersionRecordSnapshot: Codable, Equatable {
    var id: String
    var sessionID: String = ""
    var name: String = ""
    var resolveVersion: String = ""
    var createdAt: String = ""

    init(from record: ProjectVersionRecord) {
        self.id = record.id.uuidString
        self.sessionID = record.sessionID.uuidString
        self.name = record.name
        self.resolveVersion = record.resolveVersion
        self.createdAt = ImportExportService.dateFormatter.string(from: record.createdAt)
    }
}

struct NoteSnapshot: Codable, Equatable {
    var id: String
    var contentID: String = ""
    var sessionID: String? = nil
    var body: String = ""
    var createdAt: String = ""
    var updatedAt: String = ""

    init(from note: UserNote) {
        self.id = note.id.uuidString
        self.contentID = note.contentID
        self.sessionID = note.sessionID?.uuidString
        self.body = note.body
        self.createdAt = ImportExportService.dateFormatter.string(from: note.createdAt)
        self.updatedAt = ImportExportService.dateFormatter.string(from: note.updatedAt)
    }
}

struct FavoriteSnapshot: Codable, Equatable {
    var id: String
    var contentID: String = ""
    var createdAt: String = ""
    var updatedAt: String = ""

    init(from favorite: Favorite) {
        self.id = favorite.id.uuidString
        self.contentID = favorite.contentID
        self.createdAt = ImportExportService.dateFormatter.string(from: favorite.createdAt)
        self.updatedAt = ImportExportService.dateFormatter.string(from: favorite.updatedAt)
    }
}

struct RecentActivitySnapshot: Codable, Equatable {
    var id: String
    var contentID: String = ""
    var action: String = ""
    var createdAt: String = ""
    var updatedAt: String = ""

    init(from activity: RecentActivity) {
        self.id = activity.id.uuidString
        self.contentID = activity.contentID
        self.action = activity.action
        self.createdAt = ImportExportService.dateFormatter.string(from: activity.createdAt)
        self.updatedAt = ImportExportService.dateFormatter.string(from: activity.updatedAt)
    }
}

// MARK: - User Data Archive

struct UserDataArchive: Codable, Equatable {
    var schemaVersion: Int = 1
    var settings: SettingsSnapshot = SettingsSnapshot()
    var projects: [ProjectSnapshot] = []
    var stageProgress: [StageProgressSnapshot] = []
    var checklistStates: [ChecklistStateSnapshot] = []
    var versionRecords: [VersionRecordSnapshot] = []
    var notes: [NoteSnapshot] = []
    var favorites: [FavoriteSnapshot] = []
    var recentActivities: [RecentActivitySnapshot] = []
}

// MARK: - Import Validation Error

enum ImportValidationError: Error, Equatable {
    case unsupportedSchemaVersion
    case duplicateIDs
    case invalidContentReference
    case invalidEnumValue
    case decodingFailed
}

// MARK: - Import/Export Service

struct ImportExportService {
    static let currentSchemaVersion = 1

    static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    static let decoder: JSONDecoder = JSONDecoder()

    // MARK: - Export

    func export(from modelContext: ModelContext, settings: SettingsStore) throws -> Data {
        let archive = try exportArchive(from: modelContext, settings: settings)
        return try Self.encoder.encode(archive)
    }

    func exportArchive(from modelContext: ModelContext, settings: SettingsStore) throws -> UserDataArchive {
        let projects = try modelContext.fetch(FetchDescriptor<ProjectSession>())
        let stageProgress = try modelContext.fetch(FetchDescriptor<StageProgress>())
        let checklistStates = try modelContext.fetch(FetchDescriptor<ChecklistItemState>())
        let notes = try modelContext.fetch(FetchDescriptor<UserNote>())
        let versionRecords = try modelContext.fetch(FetchDescriptor<ProjectVersionRecord>())
        let favorites = try modelContext.fetch(FetchDescriptor<Favorite>())
        let recentActivities = try modelContext.fetch(FetchDescriptor<RecentActivity>())

        return UserDataArchive(
            schemaVersion: Self.currentSchemaVersion,
            settings: SettingsSnapshot(from: settings),
            projects: projects.map { ProjectSnapshot(from: $0) },
            stageProgress: stageProgress.map { StageProgressSnapshot(from: $0) },
            checklistStates: checklistStates.map { ChecklistStateSnapshot(from: $0) },
            versionRecords: versionRecords.map { VersionRecordSnapshot(from: $0) },
            notes: notes.map { NoteSnapshot(from: $0) },
            favorites: favorites.map { FavoriteSnapshot(from: $0) },
            recentActivities: recentActivities.map { RecentActivitySnapshot(from: $0) }
        )
    }

    // MARK: - Validate and Import

    func validateAndImport(
        _ data: Data,
        into modelContext: ModelContext,
        settings: SettingsStore
    ) throws {
        // Phase 1: Validation

        // 1. Decode the archive
        let archive: UserDataArchive
        do {
            archive = try Self.decoder.decode(UserDataArchive.self, from: data)
        } catch {
            throw ImportValidationError.decodingFailed
        }

        // 2. Check schema version
        guard archive.schemaVersion == Self.currentSchemaVersion else {
            throw ImportValidationError.unsupportedSchemaVersion
        }

        // 3. Check for duplicate IDs across all collections
        var allIDs: [String] = []
        allIDs.append(contentsOf: archive.projects.map(\.id))
        allIDs.append(contentsOf: archive.stageProgress.map(\.id))
        allIDs.append(contentsOf: archive.checklistStates.map(\.id))
        allIDs.append(contentsOf: archive.versionRecords.map(\.id))
        allIDs.append(contentsOf: archive.notes.map(\.id))
        allIDs.append(contentsOf: archive.favorites.map(\.id))
        allIDs.append(contentsOf: archive.recentActivities.map(\.id))

        if Set(allIDs).count != allIDs.count {
            throw ImportValidationError.duplicateIDs
        }

        // 4. Validate enum values in settings
        guard AppLanguage(rawValue: archive.settings.language) != nil,
              ShortcutPlatform(rawValue: archive.settings.platform) != nil,
              ContentLevel(rawValue: archive.settings.contentLevel) != nil,
              AppTab(rawValue: archive.settings.defaultTab) != nil,
              AppearanceMode(rawValue: archive.settings.appearance) != nil else {
            throw ImportValidationError.invalidEnumValue
        }

        // 5. Validate that all IDs are valid UUIDs
        for id in allIDs {
            guard UUID(uuidString: id) != nil else {
                throw ImportValidationError.invalidContentReference
            }
        }

        // 6. Validate content references (sessionIDs must reference existing projects)
        let projectIDs = Set(archive.projects.map(\.id))

        for stage in archive.stageProgress {
            if let sessionID = stage.sessionID, !projectIDs.contains(sessionID) {
                throw ImportValidationError.invalidContentReference
            }
        }

        for checklist in archive.checklistStates {
            if let sessionID = checklist.sessionID, !projectIDs.contains(sessionID) {
                throw ImportValidationError.invalidContentReference
            }
        }

        for note in archive.notes {
            if let sessionID = note.sessionID, !projectIDs.contains(sessionID) {
                throw ImportValidationError.invalidContentReference
            }
        }

        for version in archive.versionRecords {
            if !version.sessionID.isEmpty && !projectIDs.contains(version.sessionID) {
                throw ImportValidationError.invalidContentReference
            }
        }

        // Phase 2: Import (single SwiftData transaction)

        // Build project map for relationship setup
        var projectMap: [String: ProjectSession] = [:]

        for snapshot in archive.projects {
            let project = ProjectSession(
                id: UUID(uuidString: snapshot.id)!,
                name: snapshot.name,
                templateID: snapshot.templateID,
                createdAt: Self.parseDate(snapshot.createdAt),
                updatedAt: Self.parseDate(snapshot.updatedAt)
            )
            modelContext.insert(project)
            projectMap[snapshot.id] = project
        }

        for snapshot in archive.stageProgress {
            let progress = StageProgress(
                id: UUID(uuidString: snapshot.id)!,
                contentID: snapshot.contentID,
                isCompleted: snapshot.isCompleted,
                createdAt: Self.parseDate(snapshot.createdAt),
                updatedAt: Self.parseDate(snapshot.updatedAt)
            )
            if let sessionID = snapshot.sessionID, let project = projectMap[sessionID] {
                progress.session = project
            }
            modelContext.insert(progress)
        }

        for snapshot in archive.checklistStates {
            let state = ChecklistItemState(
                id: UUID(uuidString: snapshot.id)!,
                contentID: snapshot.contentID,
                isCompleted: snapshot.isCompleted,
                createdAt: Self.parseDate(snapshot.createdAt),
                updatedAt: Self.parseDate(snapshot.updatedAt)
            )
            if let sessionID = snapshot.sessionID, let project = projectMap[sessionID] {
                state.session = project
            }
            modelContext.insert(state)
        }

        for snapshot in archive.versionRecords {
            let record = ProjectVersionRecord(
                id: UUID(uuidString: snapshot.id)!,
                sessionID: UUID(uuidString: snapshot.sessionID)!,
                name: snapshot.name,
                resolveVersion: snapshot.resolveVersion,
                createdAt: Self.parseDate(snapshot.createdAt)
            )
            modelContext.insert(record)
        }

        for snapshot in archive.notes {
            let note = UserNote(
                id: UUID(uuidString: snapshot.id)!,
                contentID: snapshot.contentID,
                sessionID: snapshot.sessionID.flatMap { UUID(uuidString: $0) },
                body: snapshot.body,
                createdAt: Self.parseDate(snapshot.createdAt),
                updatedAt: Self.parseDate(snapshot.updatedAt)
            )
            modelContext.insert(note)
        }

        for snapshot in archive.favorites {
            let favorite = Favorite(
                id: UUID(uuidString: snapshot.id)!,
                contentID: snapshot.contentID,
                createdAt: Self.parseDate(snapshot.createdAt),
                updatedAt: Self.parseDate(snapshot.updatedAt)
            )
            modelContext.insert(favorite)
        }

        for snapshot in archive.recentActivities {
            let activity = RecentActivity(
                id: UUID(uuidString: snapshot.id)!,
                contentID: snapshot.contentID,
                action: snapshot.action,
                createdAt: Self.parseDate(snapshot.createdAt),
                updatedAt: Self.parseDate(snapshot.updatedAt)
            )
            modelContext.insert(activity)
        }

        // Update settings from archive
        settings.language = AppLanguage(rawValue: archive.settings.language) ?? .zhHans
        settings.platform = ShortcutPlatform(rawValue: archive.settings.platform) ?? .mac
        settings.contentLevel = ContentLevel(rawValue: archive.settings.contentLevel) ?? .quick
        settings.defaultTab = AppTab(rawValue: archive.settings.defaultTab) ?? .workbench
        settings.appearance = AppearanceMode(rawValue: archive.settings.appearance) ?? .system
        settings.showsSources = archive.settings.showsSources
        settings.showsProfessionalRecommendations = archive.settings.showsProfessionalRecommendations
        settings.hapticsEnabled = archive.settings.hapticsEnabled

        // Persist the transaction
        try modelContext.save()
    }

    // MARK: - Date Helpers

    private static func parseDate(_ string: String) -> Date {
        guard !string.isEmpty,
              let date = dateFormatter.date(from: string) else {
            return Date(timeIntervalSince1970: 0)
        }
        return date
    }
}
