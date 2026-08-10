import Foundation
import SwiftData

enum ChecklistInsertionOutcome: Equatable {
    case inserted
    case alreadyPresent
}

enum FavoriteMutationOutcome: Equatable {
    case added
    case removed
    case deduplicated
    case unchanged
}

enum LocalMutationFailure: Error, Equatable {
    case saveFailed

    var message: LocalizedText {
        LocalizedText(
            zhHans: "无法保存本地更改。请重试。",
            en: "Could not save the local change. Please try again."
        )
    }
}

@MainActor
struct ModelSaveBoundary {
    let save: () throws -> Void
    let rollback: () -> Void

    init(save: @escaping () throws -> Void, rollback: @escaping () -> Void) {
        self.save = save
        self.rollback = rollback
    }

    init(modelContext: ModelContext) {
        save = { try modelContext.save() }
        rollback = { modelContext.rollback() }
    }
}

@MainActor
struct LocalUserStateMutator {
    private let modelContext: ModelContext
    private let saveBoundary: ModelSaveBoundary

    init(modelContext: ModelContext, saveBoundary: ModelSaveBoundary? = nil) {
        self.modelContext = modelContext
        self.saveBoundary = saveBoundary ?? ModelSaveBoundary(modelContext: modelContext)
    }

    func addToChecklist(
        session: ProjectSession,
        contentID: String
    ) -> Result<ChecklistInsertionOutcome, LocalMutationFailure> {
        guard !session.checklistStates.contains(where: { $0.contentID == contentID }) else {
            return .success(.alreadyPresent)
        }

        session.checklistStates.append(
            ChecklistItemState(contentID: contentID, isCompleted: false)
        )
        session.updatedAt = .now
        return commit(.inserted)
    }

    func setFavorite(
        contentID: String,
        isFavorite: Bool
    ) -> Result<FavoriteMutationOutcome, LocalMutationFailure> {
        do {
            let matches = try favorites(contentID: contentID)
            if isFavorite {
                if matches.isEmpty {
                    modelContext.insert(Favorite(contentID: contentID))
                    return commit(.added)
                }
                guard matches.count > 1 else { return .success(.unchanged) }
                matches.dropFirst().forEach(modelContext.delete)
                return commit(.deduplicated)
            }

            guard !matches.isEmpty else { return .success(.unchanged) }
            matches.forEach(modelContext.delete)
            return commit(.removed)
        } catch {
            saveBoundary.rollback()
            return .failure(.saveFailed)
        }
    }

    func recordRecent(
        contentID: String,
        action: String = "open"
    ) -> Result<Void, LocalMutationFailure> {
        do {
            let matches = try recentActivities(contentID: contentID)
                .sorted { $0.updatedAt > $1.updatedAt }
            if let retained = matches.first {
                retained.action = action
                retained.updatedAt = .now
                matches.dropFirst().forEach(modelContext.delete)
            } else {
                modelContext.insert(RecentActivity(contentID: contentID, action: action))
            }
            return commit(())
        } catch {
            saveBoundary.rollback()
            return .failure(.saveFailed)
        }
    }

    func removeRecent(contentID: String) -> Result<Void, LocalMutationFailure> {
        do {
            let matches = try recentActivities(contentID: contentID)
            guard !matches.isEmpty else { return .success(()) }
            matches.forEach(modelContext.delete)
            return commit(())
        } catch {
            saveBoundary.rollback()
            return .failure(.saveFailed)
        }
    }

    private func favorites(contentID: String) throws -> [Favorite] {
        let targetID = contentID
        return try modelContext.fetch(
            FetchDescriptor<Favorite>(
                predicate: #Predicate { $0.contentID == targetID }
            )
        )
    }

    private func recentActivities(contentID: String) throws -> [RecentActivity] {
        let targetID = contentID
        return try modelContext.fetch(
            FetchDescriptor<RecentActivity>(
                predicate: #Predicate { $0.contentID == targetID }
            )
        )
    }

    private func commit<Success>(_ success: Success) -> Result<Success, LocalMutationFailure> {
        do {
            try saveBoundary.save()
            return .success(success)
        } catch {
            saveBoundary.rollback()
            return .failure(.saveFailed)
        }
    }
}
