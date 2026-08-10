import Foundation

struct RecommendationEngine: Sendable {
    let playbooks: [ExpertPlaybook]

    func recommend(for input: RecommendationInput) throws -> [PlaybookRecommendation] {
        playbooks
            .compactMap { playbook -> PlaybookRecommendation? in
                guard input.hasStudio || playbook.compatibility != .studioRequired else { return nil }
                let score = score(playbookID: playbook.id, input: input)
                guard score > 0, let dontUse = playbook.nonFit.first else { return nil }
                return PlaybookRecommendation(
                    playbookID: playbook.id,
                    reason: reason(playbookID: playbook.id, input: input),
                    dontUse: dontUse,
                    score: score
                )
            }
            .sorted {
                if $0.score != $1.score { return $0.score > $1.score }
                return $0.playbookID < $1.playbookID
            }
    }

    private func score(playbookID: String, input: RecommendationInput) -> Int {
        switch playbookID {
        case "playbook-mostyn-scene-match":
            guard input.shotVolume == .high else { return 0 }
            return 60
                + (input.mixedCameras ? 45 : 0)
                + (input.projectType == .interview ? 15 : 0)
        case "playbook-melara-editable-pfe":
            return (input.needsFilmLook ? 55 : 0)
                + (input.needsProductColorAccuracy ? 45 : 0)
                + (input.projectType == .advertising ? 15 : 0)
        case "playbook-kelly-scene-referred-look":
            return (input.needsFilmLook ? 35 : 0)
                + (input.mixedCameras ? 25 : 0)
                + (input.projectType == .narrative ? 20 : 0)
        case "playbook-inhofer-pass-grading":
            return (input.shotVolume == .high ? 50 : input.shotVolume == .medium ? 20 : 0)
        case "playbook-fissoun-archive-restore":
            return (input.projectType == .archival ? 80 : 0)
                + (input.delivery == .archive ? 35 : 0)
        case "playbook-filmlight-pipeline-first":
            return (input.mixedCameras ? 35 : 0)
                + (input.delivery == .cinema || input.delivery == .broadcast ? 20 : 0)
        default:
            return 0
        }
    }

    private func reason(playbookID: String, input: RecommendationInput) -> LocalizedText {
        switch playbookID {
        case "playbook-mostyn-scene-match":
            return LocalizedText(
                zhHans: input.mixedCameras
                    ? "高镜头量与混合机型需要先按场景平衡，再用组级调整保持一致。"
                    : "高镜头量项目适合按场景建立参考镜头并批量匹配。",
                en: input.mixedCameras
                    ? "High shot volume and mixed cameras benefit from balancing by scene, then using group-level changes for consistency."
                    : "High-volume work benefits from a reference shot and scene-by-scene matching."
            )
        case "playbook-melara-editable-pfe":
            return LocalizedText(
                zhHans: input.needsProductColorAccuracy
                    ? "既要胶片观感又要产品颜色准确时，可编辑 PFE 比固定 LUT 更容易局部修正。"
                    : "需要胶片观感时，可编辑 PFE 为对比度与颜色提供可回退的控制。",
                en: input.needsProductColorAccuracy
                    ? "When a film feel and exact product color both matter, an editable PFE is easier to adjust than a fixed LUT."
                    : "For a film feel, an editable PFE keeps contrast and color decisions reversible."
            )
        case "playbook-kelly-scene-referred-look":
            return LocalizedText(
                zhHans: "在宽色域场景参考空间中建立整体观感，能让创意调整更稳定地跨镜头与机型工作。",
                en: "Building the look in a wide-gamut scene-referred space helps creative adjustments travel across shots and cameras."
            )
        case "playbook-inhofer-pass-grading":
            return LocalizedText(
                zhHans: "按遍次先解决全片最大问题，再回头精修，适合镜头量大或期限紧的项目。",
                en: "Pass-based grading solves the largest program-wide problems first, then uses remaining time for refinement."
            )
        case "playbook-fissoun-archive-restore":
            return LocalizedText(
                zhHans: "老格式母版需要先确认场序、帧率、画幅与切点，再做逐镜头恢复和升级。",
                en: "Legacy masters need field order, frame rate, aspect ratio, and cut boundaries established before shot-level restoration and upscaling."
            )
        case "playbook-filmlight-pipeline-first":
            return LocalizedText(
                zhHans: "混合机型与多交付项目应先定义输入、工作与观看色彩空间，再开始创意调色。",
                en: "Mixed-camera and multi-delivery projects benefit from defining input, working, and viewing color spaces before creative grading."
            )
        default:
            return LocalizedText(zhHans: "符合当前项目条件。", en: "Fits the current project conditions.")
        }
    }
}
