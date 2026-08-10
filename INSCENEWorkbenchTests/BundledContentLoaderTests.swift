import Foundation
import Testing
@testable import INSCENEWorkbench

struct BundledContentLoaderTests {
    @Test func bundledGuideHasExpectedLegacyInventory() throws {
        let content = try BundledContentLoader().load()
        #expect(content.stages.count == 10)
        #expect(content.shortcuts.count == 61)
        #expect(content.recipes.count == 18)
        #expect(content.colorPasses.count == 6)
        #expect(content.exports.count == 8)
        #expect(content.emergencies.count == 12)
    }

    @Test func everyContentRecordHasStableIDAndTwoLanguages() throws {
        let content = try BundledContentLoader().load()
        let records = content.searchableRecords
        #expect(Set(records.map { $0.id }).count == records.count)
        #expect(records.allSatisfy { !$0.title.zhHans.isEmpty && !$0.title.en.isEmpty })
    }

    @Test func loaderRejectsDuplicateStableIDs() throws {
        var json = TestFixtures.validJSON
        json = json.replacingOccurrences(of: "\"id\": \"shortcut-one\"", with: "\"id\": \"stage-one\"")

        #expect(throws: BundledContentLoaderError.duplicateID("stage-one")) {
            try BundledContentLoader(data: Data(json.utf8)).load()
        }
    }

    @Test func loaderRejectsRecordsWithAnEmptyEnglishTitle() throws {
        let json = TestFixtures.validJSON.replacingOccurrences(
            of: "\"en\": \"Stage one\"",
            with: "\"en\": \"\""
        )

        #expect(throws: BundledContentLoaderError.emptyLocalizedText(id: "stage-one", field: .title, language: .en)) {
            try BundledContentLoader(data: Data(json.utf8)).load()
        }
    }

    @Test func loaderRejectsDuplicateIDsAcrossSearchableAndReferenceRecords() throws {
        let json = TestFixtures.validJSON.replacingOccurrences(
            of: "\"id\": \"source-one\"",
            with: "\"id\": \"stage-one\""
        )

        #expect(throws: BundledContentLoaderError.duplicateID("stage-one")) {
            try BundledContentLoader(data: Data(json.utf8)).load()
        }
    }

    @Test func loaderRejectsRecordsWithAnEmptyLocalizedSummary() throws {
        let json = TestFixtures.validJSON.replacingOccurrences(
            of: "\"en\": \"Summary\"",
            with: "\"en\": \"\"",
            options: [],
            range: TestFixtures.validJSON.range(of: "\"summary\": {\"zhHans\": \"摘要\", \"en\": \"Summary\"}")
        )

        #expect(throws: BundledContentLoaderError.emptyLocalizedText(id: "stage-one", field: .summary, language: .en)) {
            try BundledContentLoader(data: Data(json.utf8)).load()
        }
    }

    @Test func loaderRejectsEmptyCreatorBioAndSourceTitle() throws {
        let creatorJSON = TestFixtures.validJSON.replacingOccurrences(of: "\"en\": \"Bio\"", with: "\"en\": \"\"")
        #expect(throws: BundledContentLoaderError.emptyLocalizedText(id: "creator-one", field: .bio, language: .en)) {
            try BundledContentLoader(data: Data(creatorJSON.utf8)).load()
        }

        let sourceJSON = TestFixtures.validJSON.replacingOccurrences(of: "\"en\": \"Source\"", with: "\"en\": \"\"")
        #expect(throws: BundledContentLoaderError.emptyLocalizedText(id: "source-one", field: .title, language: .en)) {
            try BundledContentLoader(data: Data(sourceJSON.utf8)).load()
        }
    }

    @Test func loaderRejectsEmptyShortcutEnglishMenuPath() throws {
        let json = TestFixtures.validJSON.replacingOccurrences(of: "\"en\": \"Menu\"", with: "\"en\": \"\"")
        #expect(throws: BundledContentLoaderError.emptyLocalizedText(id: "shortcut-one", field: .menu, language: .en)) {
            try BundledContentLoader(data: Data(json.utf8)).load()
        }
    }

    @Test func loaderRejectsPlaybookWithMissingCreatorReference() throws {
        let json = TestFixtures.validJSON.replacingOccurrences(
            of: "\"creatorID\": \"creator-one\"",
            with: "\"creatorID\": \"creator-missing\""
        )

        #expect(
            throws: BundledContentLoaderError.missingCreator(
                playbookID: "playbook-one",
                creatorID: "creator-missing"
            )
        ) {
            try BundledContentLoader(data: Data(json.utf8)).load()
        }
    }

    @Test func loaderRejectsPlaybookWithMissingSourceReference() throws {
        let json = TestFixtures.validJSON.replacingOccurrences(
            of: "\"sourceIDs\": [\"source-one\"]",
            with: "\"sourceIDs\": [\"source-missing\"]"
        )

        #expect(
            throws: BundledContentLoaderError.missingSource(
                playbookID: "playbook-one",
                sourceID: "source-missing"
            )
        ) {
            try BundledContentLoader(data: Data(json.utf8)).load()
        }
    }

    @Test func loaderRejectsNonHTTPSProfessionalSource() throws {
        let json = TestFixtures.validJSON.replacingOccurrences(
            of: "https://example.com",
            with: "http://example.com"
        )

        #expect(throws: BundledContentLoaderError.invalidSourceURL(id: "source-one")) {
            try BundledContentLoader(data: Data(json.utf8)).load()
        }
    }

    @Test func bundledPlaybooksHaveCompleteProfessionalSourceMetadata() throws {
        let content = try BundledContentLoader().load()
        let expectedCreatorIDs = Set([
            "creator-cullen-kelly",
            "creator-darren-mostyn",
            "creator-patrick-inhofer",
            "creator-juan-melara",
            "creator-daria-fissoun",
            "creator-filmlight-team"
        ])

        #expect(content.playbooks.count == 6)
        #expect(Set(content.playbooks.map(\.creatorID)) == expectedCreatorIDs)
        #expect(content.playbooks.allSatisfy {
            !$0.fit.isEmpty
                && !$0.nonFit.isEmpty
                && !$0.requirements.isEmpty
                && !$0.steps.isEmpty
                && !$0.judgmentCriteria.isEmpty
                && !$0.mistakes.isEmpty
                && !$0.rollback.isEmpty
                && !$0.officialDifferences.isEmpty
                && !$0.checklist.isEmpty
                && !$0.resolveVersion.isEmpty
                && $0.lastReviewedDate == "2026-08-10"
                && !$0.sourceIDs.isEmpty
        })
    }

    @Test func bundledWorkflowDetailsUseProfessionalPostProductionEnglish() throws {
        let content = try BundledContentLoader().load()

        let fine = try #require(content.stages.first { $0.id == "stage-fine" })
        #expect(fine.quickSteps[2].en == "Check action matches and eyelines")

        let audio = try #require(content.stages.first { $0.id == "stage-audio" })
        #expect(audio.quickSteps[0].en == "Organize tracks")

        let color = try #require(content.stages.first { $0.id == "stage-color" })
        #expect(color.quickSteps[1].en == "Open the scopes and make a primary correction")

        let subtitles = try #require(content.stages.first { $0.id == "stage-title" })
        #expect(subtitles.proSteps[5].en == "Before export, decide whether to burn in subtitles, deliver a sidecar SRT, or provide both.")

        let qc = try #require(content.stages.first { $0.id == "stage-qc" })
        #expect(qc.quickSteps[0].en == "Story pass")

        let delivery = try #require(content.stages.first { $0.id == "stage-export" })
        #expect(delivery.proSteps[0].en == "Work backward from the delivery requirements to choose the container, codec, resolution, bitrate, audio settings, and color tags.")

        let archive = try #require(content.stages.first { $0.id == "stage-archive" })
        #expect(archive.proSteps[1].en == "When using Media Management to collect used media, retain adequate handles and spot-check the relink.")
    }

    @Test func bundledShortcutAndRecipeDetailsUseResolveVocabulary() throws {
        let content = try BundledContentLoader().load()

        let insert = try #require(content.shortcuts.first { $0.id == "edit-insert" })
        #expect(insert.category.en == "Three-point editing")

        let trim = try #require(content.shortcuts.first { $0.id == "trim-extend" })
        #expect(trim.category.en == "Trim")

        let dialogue = try #require(content.recipes.first { $0.id == "recipe-dialogue" })
        #expect(dialogue.steps[0].en == "Use clip gain first to bring perceived loudness into line")

        let nodes = try #require(content.recipes.first { $0.id == "recipe-nodes" })
        #expect(nodes.doneCheck.en == "Nodes are clearly named, and their purpose remains obvious when each node is bypassed.")

        let matchFrame = try #require(content.recipes.first { $0.id == "recipe-match-frame" })
        #expect(matchFrame.scene.en == "Replacing shots and finding head or tail handles.")
    }

    @Test func bundledColorDetailsUseGradingScopesAndGrainVocabulary() throws {
        let content = try BundledContentLoader().load()

        let input = try #require(content.colorPasses.first { $0.id == "color-input" })
        #expect(input.steps[1].en == "Choose either an RCM or CST workflow")

        let balance = try #require(content.colorPasses.first { $0.id == "color-balance" })
        #expect(balance.commonMistakes[1].en == "Crushing blacks to manufacture contrast")

        let finish = try #require(content.colorPasses.first { $0.id == "color-finish" })
        #expect(finish.steps[0].en == "Complete the primary grade, then add a small amount of sharpening")
        #expect(finish.tools[2].en == "Film grain")
        #expect(finish.commonMistakes[0].en == "Overdoing noise reduction creates a waxy look or motion smearing.")
    }

    @Test func bundledExportDetailsUseDeliveryCodecBitrateAndHandleVocabulary() throws {
        let content = try BundledContentLoader().load()

        let vertical = try #require(content.exports.first { $0.id == "ex-vertical" })
        #expect(vertical.subtitles[0].en == "Keep subtitles clear of the vertical platform UI safe areas; specify whether they are burned in or delivered as sidecar files.")

        let master = try #require(content.exports.first { $0.id == "ex-master" })
        #expect(master.specification[3].label.en == "Codec")
        #expect(master.bitrate.en == "Bitrate is determined by the ProRes or DNxHR codec profile; no target bitrate is entered manually.")

        let colorTurnover = try #require(content.exports.first { $0.id == "ex-color" })
        #expect(colorTurnover.risk.en == "Confirm the turnover and round-trip workflow, handles, retiming, reframing, subtitles, and Fusion work with the colorist before handoff.")
        #expect(colorTurnover.fileChecks[1].en == "Check handles, timecode, retiming, and reframing")

        let broadcast = try #require(content.exports.first { $0.id == "ex-broadcast" })
        #expect(broadcast.specification[4].value.en == "Meet the legal-range and bitrate requirements")

        let alpha = try #require(content.exports.first { $0.id == "ex-alpha" })
        #expect(alpha.bitrate.en == "Bitrate is determined by the ProRes 4444 or DNxHR 444 codec profile, or by the PNG image sequence.")
    }

    @Test func bundledEmergencyDetailsUseProxyOriginalMediaAndRelinkVocabulary() throws {
        let content = try BundledContentLoader().load()

        let offline = try #require(content.emergencies.first { $0.id == "em-offline" })
        #expect(offline.fix[2].en == "If only proxy media is offline, switch to the originals or relink the proxy media")

        let lag = try #require(content.emergencies.first { $0.id == "em-lag" })
        #expect(lag.prevent.en == "Edit with proxy media and switch back to the original media for final output; keep the render cache on a separate fast drive.")

        let proxy = try #require(content.emergencies.first { $0.id == "em-proxy" })
        #expect(proxy.fix[1].en == "Disable proxy media, then relink the correct files.")

        let subtitle = try #require(content.emergencies.first { $0.id == "em-subtitle" })
        #expect(subtitle.deep.en == "Distinguish among burn-in, embedded, and sidecar subtitle delivery.")
    }
}
