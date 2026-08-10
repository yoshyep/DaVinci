import Testing
import SwiftData
import Foundation
@testable import INSCENEWorkbench

@MainActor
struct ImportExportServiceTests {
    @Test func exportImportRoundTripPreservesProjectsNotesFavoritesAndSettings() throws {
        let source = try TestAppState.populated()
        let data = try ImportExportService().export(from: source.modelContext, settings: source.settings)
        let destination = try TestAppState.empty()
        try ImportExportService().validateAndImport(data, into: destination.modelContext, settings: destination.settings)
        #expect(destination.snapshot == source.snapshot)
    }

    @Test func invalidDuplicateIDsLeaveDestinationUntouched() throws {
        let destination = try TestAppState.populated()
        let before = destination.snapshot
        let invalid = Data(#"{"schemaVersion":1,"notes":[{"id":"same"},{"id":"same"}]}"#.utf8)
        #expect(throws: ImportValidationError.self) {
            try ImportExportService().validateAndImport(invalid, into: destination.modelContext, settings: destination.settings)
        }
        #expect(destination.snapshot == before)
    }

    @Test func unsupportedSchemaVersionIsRejected() throws {
        let destination = try TestAppState.empty()
        let invalid = Data(#"{"schemaVersion":99}"#.utf8)
        #expect(throws: ImportValidationError.self) {
            try ImportExportService().validateAndImport(invalid, into: destination.modelContext, settings: destination.settings)
        }
    }

    @Test func emptyArchiveImportsCleanly() throws {
        let source = try TestAppState.empty()
        let data = try ImportExportService().export(from: source.modelContext, settings: source.settings)
        let destination = try TestAppState.empty()
        try ImportExportService().validateAndImport(data, into: destination.modelContext, settings: destination.settings)
        #expect(destination.snapshot == source.snapshot)
    }
}
