import Testing
@testable import INSCENEWorkbench

struct RecommendationEngineTests {
    @Test func highVolumeSceneMatchingRecommendsGroupWorkflow() throws {
        let input = RecommendationInput(projectType: .interview, mixedCameras: true, needsProductColorAccuracy: false, needsFilmLook: false, shotVolume: .high, delivery: .web, hasStudio: true)
        let result = try RecommendationEngine(playbooks: BundledContentLoader().load().playbooks).recommend(for: input)
        #expect(result.first?.playbookID == "playbook-mostyn-scene-match")
        #expect(result.first?.reason.zhHans.contains("场景") == true)
    }

    @Test func productColorAccuracyWarnsAgainstRigidPFE() throws {
        let input = RecommendationInput(projectType: .advertising, mixedCameras: false, needsProductColorAccuracy: true, needsFilmLook: true, shotVolume: .medium, delivery: .broadcast, hasStudio: true)
        let result = try RecommendationEngine(playbooks: BundledContentLoader().load().playbooks).recommend(for: input)
        #expect(result.contains { $0.playbookID == "playbook-melara-editable-pfe" })
        #expect(result.contains { $0.dontUse.zhHans.contains("固定 LUT") })
    }

    @Test func everyRecommendationExplainsFitAndNonFitInBothLanguages() throws {
        let input = RecommendationInput(
            projectType: .interview,
            mixedCameras: true,
            needsProductColorAccuracy: false,
            needsFilmLook: false,
            shotVolume: .high,
            delivery: .broadcast,
            hasStudio: true
        )

        let result = try RecommendationEngine(
            playbooks: BundledContentLoader().load().playbooks
        ).recommend(for: input)

        #expect(!result.isEmpty)
        #expect(result.allSatisfy {
            !$0.reason.zhHans.isEmpty && !$0.reason.en.isEmpty
                && !$0.dontUse.zhHans.isEmpty && !$0.dontUse.en.isEmpty
        })
    }

    @Test func freeResolveInputExcludesStudioRequiredPlaybooks() throws {
        let input = RecommendationInput(
            projectType: .archival,
            mixedCameras: false,
            needsProductColorAccuracy: false,
            needsFilmLook: false,
            shotVolume: .medium,
            delivery: .archive,
            hasStudio: false
        )

        let result = try RecommendationEngine(
            playbooks: BundledContentLoader().load().playbooks
        ).recommend(for: input)

        #expect(!result.contains { $0.playbookID == "playbook-fissoun-archive-restore" })
    }
}
