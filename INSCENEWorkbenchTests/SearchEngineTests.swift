import Testing
@testable import INSCENEWorkbench

struct SearchEngineTests {
    private let engine: SearchEngine

    init() throws {
        engine = SearchEngine(repository: try GuideContentRepository())
    }

    @Test func chineseIntentAliasFindsRippleDeleteAheadOfOtherEditingMaterial() {
        let context = SearchContext(
            language: .zhHans,
            platform: .mac,
            currentStageID: nil,
            recentIDs: [],
            favoriteIDs: []
        )

        let hits = engine.search("删掉中间一段但不要留空", context: context)

        #expect(hits.first?.contentID == "delete-ripple")
        #expect(hits.first?.reason == .alias)
    }

    @Test func punctuationCaseAndWhitespaceNormalizeWithoutChangingTheStableRecord() {
        let context = SearchContext(
            language: .en,
            platform: .windows,
            currentStageID: nil,
            recentIDs: [],
            favoriteIDs: []
        )

        let hits = engine.search("   RIPPLE—DELETE!!  ", context: context)

        #expect(hits.first?.contentID == "delete-ripple")
        #expect(hits.first?.reason == .exactTitle)
    }

    @Test func exactActionOutranksStageRecentAndFavoriteContext() {
        let context = SearchContext(
            language: .zhHans,
            platform: .mac,
            currentStageID: "stage-color",
            recentIDs: ["color-skin"],
            favoriteIDs: ["stage-color"]
        )

        let hits = engine.search("肤色二级修正", context: context)

        #expect(hits.first?.contentID == "recipe-skin")
        #expect(hits.first?.kind == .recipe)
        #expect(hits.first?.reason == .exactTitle)
        #expect((hits.first?.score ?? 0) > (hits.dropFirst().first?.score ?? 0))
    }

    @Test func curatedAliasWeightBeatsTheSameRecordsPartialTitleWeight() {
        let context = SearchContext(
            language: .zhHans,
            platform: .mac,
            currentStageID: nil,
            recentIDs: [],
            favoriteIDs: []
        )

        let hits = engine.search("肤色", context: context)

        #expect(hits.first?.contentID == "recipe-skin")
        #expect(hits.first?.reason == .alias)
        #expect((hits.first?.score ?? 0) > (hits.dropFirst().first?.score ?? 0))
    }

    @Test func englishAliasesRespectTokenBoundariesWhileChineseIntentsAllowContainment() {
        let context = SearchContext(
            language: .en,
            platform: .mac,
            currentStageID: nil,
            recentIDs: [],
            favoriteIDs: []
        )

        #expect(engine.search("confused", context: context).contains { $0.contentID == "recipe-skin" } == false)
        #expect(engine.search("use fuse for skin", context: context).first?.contentID == "recipe-skin")
        #expect(engine.search("我想修正肤色", context: context).first?.contentID == "recipe-skin")
    }

    @Test func aliasScriptControlsBoundariesInMixedLanguageQueries() {
        let context = SearchContext(
            language: .en,
            platform: .mac,
            currentStageID: nil,
            recentIDs: [],
            favoriteIDs: []
        )

        #expect(engine.search("我很 confused", context: context).contains { $0.contentID == "recipe-skin" } == false)
        #expect(engine.search("我要 fix skin now", context: context).first?.contentID == "recipe-skin")
        #expect(engine.search("please 修正肤色 now", context: context).first?.contentID == "recipe-skin")
    }

    @Test func bothLanguagesSearchTheSameRecordRegardlessOfDisplayLanguage() {
        let chineseContext = SearchContext(
            language: .zhHans,
            platform: .mac,
            currentStageID: nil,
            recentIDs: [],
            favoriteIDs: []
        )
        let englishContext = SearchContext(
            language: .en,
            platform: .windows,
            currentStageID: nil,
            recentIDs: [],
            favoriteIDs: []
        )

        #expect(engine.search("ripple delete", context: chineseContext).first?.contentID == "delete-ripple")
        #expect(engine.search("波纹删除", context: englishContext).first?.contentID == "delete-ripple")
    }

    @Test func shortcutKeySearchUsesOnlyTheSelectedPlatform() {
        let mac = SearchContext(
            language: .en,
            platform: .mac,
            currentStageID: nil,
            recentIDs: [],
            favoriteIDs: []
        )
        let windows = SearchContext(
            language: .en,
            platform: .windows,
            currentStageID: nil,
            recentIDs: [],
            favoriteIDs: []
        )

        #expect(engine.search("command b", context: mac).first?.contentID == "split-playhead")
        #expect(engine.search("control b", context: windows).first?.contentID == "split-playhead")
        #expect(engine.search("control b", context: mac).contains { $0.contentID == "split-playhead" } == false)
    }

    @Test func modifierNamesAndSymbolsCanonicalizeOnlyAsWholeTokens() {
        let mac = SearchContext(
            language: .en,
            platform: .mac,
            currentStageID: nil,
            recentIDs: [],
            favoriteIDs: []
        )
        let windows = SearchContext(
            language: .en,
            platform: .windows,
            currentStageID: nil,
            recentIDs: [],
            favoriteIDs: []
        )

        let macCases: [(String, String)] = [
            ("Opt S", "node-serial"),
            ("Option S", "node-serial"),
            ("⌥ S", "node-serial"),
            ("Cmd B", "split-playhead"),
            ("Command B", "split-playhead"),
            ("⌘ B", "split-playhead")
        ]
        let windowsCases: [(String, String)] = [
            ("Alt S", "node-serial"),
            ("Ctrl B", "split-playhead"),
            ("Control B", "split-playhead"),
            ("⌃ B", "split-playhead")
        ]

        for (query, expectedID) in macCases {
            #expect(engine.search(query, context: mac).first?.contentID == expectedID)
        }
        for (query, expectedID) in windowsCases {
            #expect(engine.search(query, context: windows).first?.contentID == expectedID)
        }
        #expect(engine.search("optional s", context: mac).contains { $0.contentID == "node-serial" } == false)
    }

    @Test func kindCategoryAndStageFiltersAllConstrainResults() {
        let context = SearchContext(
            language: .en,
            platform: .windows,
            currentStageID: nil,
            recentIDs: [],
            favoriteIDs: [],
            filters: SearchFilters(
                kind: .shortcut,
                category: "Editing",
                stageID: "stage-fine"
            )
        )

        let hits = engine.search("delete", context: context)

        #expect(hits.map(\.contentID) == ["delete-normal", "delete-ripple"])
        #expect(hits.allSatisfy { $0.kind == .shortcut })
    }

    @Test func stageRecentAndFavoriteBonusesHaveTheDocumentedPriorityOrder() throws {
        let fixture = try TestFixtures.sample
        let neutral = ShortcutDefinition(
            id: "a-neutral", kind: .shortcut,
            category: LocalizedText(zhHans: "测试", en: "Test"), stages: [],
            title: LocalizedText(zhHans: "普通", en: "Neutral"),
            summary: LocalizedText(zhHans: "needle", en: "needle"),
            mac: ["1"], win: ["1"], menu: LocalizedText(zhHans: "菜单", en: "Menu"),
            level: "essential", flags: [],
            steps: nil, principles: nil, warnings: nil, relatedIDs: nil
        )
        let favorite = ShortcutDefinition(
            id: "x-favorite", kind: .shortcut,
            category: LocalizedText(zhHans: "测试", en: "Test"), stages: [],
            title: LocalizedText(zhHans: "收藏", en: "Favorite"),
            summary: LocalizedText(zhHans: "needle", en: "needle"),
            mac: ["2"], win: ["2"], menu: LocalizedText(zhHans: "菜单", en: "Menu"),
            level: "essential", flags: [],
            steps: nil, principles: nil, warnings: nil, relatedIDs: nil
        )
        let recent = ShortcutDefinition(
            id: "y-recent", kind: .shortcut,
            category: LocalizedText(zhHans: "测试", en: "Test"), stages: [],
            title: LocalizedText(zhHans: "最近", en: "Recent"),
            summary: LocalizedText(zhHans: "needle", en: "needle"),
            mac: ["3"], win: ["3"], menu: LocalizedText(zhHans: "菜单", en: "Menu"),
            level: "essential", flags: [],
            steps: nil, principles: nil, warnings: nil, relatedIDs: nil
        )
        let stage = ShortcutDefinition(
            id: "z-stage", kind: .shortcut,
            category: LocalizedText(zhHans: "测试", en: "Test"), stages: ["stage-one"],
            title: LocalizedText(zhHans: "阶段", en: "Stage"),
            summary: LocalizedText(zhHans: "needle", en: "needle"),
            mac: ["4"], win: ["4"], menu: LocalizedText(zhHans: "菜单", en: "Menu"),
            level: "essential", flags: [],
            steps: nil, principles: nil, warnings: nil, relatedIDs: nil
        )
        let content = GuideContent(
            contentVersion: fixture.contentVersion,
            stages: fixture.stages,
            shortcuts: [neutral, favorite, recent, stage],
            recipes: [], colorPasses: [], exports: [], emergencies: [], playbooks: [], creators: [], sources: []
        )
        let weightedEngine = SearchEngine(repository: GuideContentRepository(content: content))
        let context = SearchContext(
            language: .en,
            platform: .mac,
            currentStageID: "stage-one",
            recentIDs: ["y-recent"],
            favoriteIDs: ["x-favorite"]
        )

        let hits = weightedEngine.search("needle", context: context)

        #expect(hits.map(\.contentID) == ["z-stage", "y-recent", "x-favorite", "a-neutral"])
    }

    @Test func unknownTermsAndInternalIDsDoNotFabricateUserResults() throws {
        let context = SearchContext(
            language: .zhHans,
            platform: .mac,
            currentStageID: nil,
            recentIDs: [],
            favoriteIDs: []
        )

        #expect(engine.search("unicorn telepathy", context: context).isEmpty)

        let fixture = try TestFixtures.sample
        let opaqueShortcut = ShortcutDefinition(
            id: "internal-zebra-417",
            kind: .shortcut,
            category: LocalizedText(zhHans: "导航", en: "Navigation"),
            stages: [],
            title: LocalizedText(zhHans: "打开项目", en: "Open Project"),
            summary: LocalizedText(zhHans: "打开项目。", en: "Open a project."),
            mac: ["P"],
            win: ["P"],
            menu: LocalizedText(zhHans: "文件 > 打开", en: "File > Open"),
            level: "essential",
            flags: [],
            steps: nil, principles: nil, warnings: nil, relatedIDs: nil
        )
        let opaqueContent = GuideContent(
            contentVersion: fixture.contentVersion,
            stages: fixture.stages,
            shortcuts: [opaqueShortcut],
            recipes: [],
            colorPasses: [],
            exports: [],
            emergencies: [],
            playbooks: [],
            creators: [],
            sources: []
        )
        let opaqueEngine = SearchEngine(repository: GuideContentRepository(content: opaqueContent))

        #expect(opaqueEngine.search("internal zebra 417", context: context).isEmpty)
    }

    @Test func playbookSourceIDsNeverEnterTheUserFacingIndex() throws {
        let fixture = try TestFixtures.sample
        let playbook = ExpertPlaybook(
            id: "playbook-private-9",
            kind: .playbook,
            creatorID: "creator-private",
            title: LocalizedText(zhHans: "镜头匹配流程", en: "Shot Matching Routine"),
            summary: LocalizedText(zhHans: "统一整场镜头。", en: "Match a complete scene."),
            problem: LocalizedText(zhHans: "镜头不一致。", en: "Shots do not match."),
            fit: [],
            nonFit: [LocalizedText(zhHans: "不适合单镜头。", en: "Do not use for one shot.")],
            requirements: [],
            steps: [LocalizedText(zhHans: "先匹配英雄镜头", en: "Match the hero shot first")],
            judgmentCriteria: [],
            mistakes: [],
            rollback: [],
            officialDifferences: [],
            checklist: [],
            resolveVersion: "20+",
            compatibility: .freeAndStudio,
            publishedDate: nil,
            lastReviewedDate: "2026-08-10",
            sourceURL: "https://example.com",
            sourceIDs: ["source-secret-42"]
        )
        let content = GuideContent(
            contentVersion: fixture.contentVersion,
            stages: [], shortcuts: [], recipes: [], colorPasses: [], exports: [], emergencies: [],
            playbooks: [playbook], creators: [], sources: []
        )
        let playbookEngine = SearchEngine(repository: GuideContentRepository(content: content))
        let context = SearchContext(
            language: .en,
            platform: .mac,
            currentStageID: nil,
            recentIDs: [],
            favoriteIDs: []
        )

        #expect(playbookEngine.search("source secret 42", context: context).isEmpty)
        #expect(playbookEngine.search("shot matching routine", context: context).first?.contentID == "playbook-private-9")
        #expect(playbookEngine.search("hero shot first", context: context).first?.contentID == "playbook-private-9")
    }

    @Test func workflowStageHumanKeywordsRemainSearchable() throws {
        let fixture = try TestFixtures.sample
        let stage = WorkflowStage(
            id: "stage-private-42",
            kind: .stage,
            number: 42,
            color: "violet-cinder-marker",
            title: LocalizedText(zhHans: "准备素材", en: "Prepare Material"),
            summary: LocalizedText(zhHans: "整理拍摄内容。", en: "Organize captured material."),
            quickSteps: [],
            proSteps: [],
            shortcutIDs: [],
            mistake: LocalizedText(zhHans: "不要遗漏素材。", en: "Do not omit material."),
            doneCheck: LocalizedText(zhHans: "素材已整理。", en: "Material is organized."),
            proNotes: []
        )
        let content = GuideContent(
            contentVersion: fixture.contentVersion,
            stages: [stage], shortcuts: [], recipes: [], colorPasses: [], exports: [], emergencies: [],
            playbooks: [], creators: [], sources: []
        )
        let stageEngine = SearchEngine(repository: GuideContentRepository(content: content))
        let context = SearchContext(
            language: .en,
            platform: .mac,
            currentStageID: nil,
            recentIDs: [],
            favoriteIDs: []
        )

        #expect(stageEngine.search("stage", context: context).first?.contentID == "stage-private-42")
        #expect(stageEngine.search("42", context: context).first?.contentID == "stage-private-42")
        #expect(stageEngine.search("violet cinder marker", context: context).first?.contentID == "stage-private-42")
    }
}
