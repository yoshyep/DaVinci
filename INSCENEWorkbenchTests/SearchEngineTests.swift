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
            level: "essential", flags: []
        )
        let favorite = ShortcutDefinition(
            id: "x-favorite", kind: .shortcut,
            category: LocalizedText(zhHans: "测试", en: "Test"), stages: [],
            title: LocalizedText(zhHans: "收藏", en: "Favorite"),
            summary: LocalizedText(zhHans: "needle", en: "needle"),
            mac: ["2"], win: ["2"], menu: LocalizedText(zhHans: "菜单", en: "Menu"),
            level: "essential", flags: []
        )
        let recent = ShortcutDefinition(
            id: "y-recent", kind: .shortcut,
            category: LocalizedText(zhHans: "测试", en: "Test"), stages: [],
            title: LocalizedText(zhHans: "最近", en: "Recent"),
            summary: LocalizedText(zhHans: "needle", en: "needle"),
            mac: ["3"], win: ["3"], menu: LocalizedText(zhHans: "菜单", en: "Menu"),
            level: "essential", flags: []
        )
        let stage = ShortcutDefinition(
            id: "z-stage", kind: .shortcut,
            category: LocalizedText(zhHans: "测试", en: "Test"), stages: ["stage-one"],
            title: LocalizedText(zhHans: "阶段", en: "Stage"),
            summary: LocalizedText(zhHans: "needle", en: "needle"),
            mac: ["4"], win: ["4"], menu: LocalizedText(zhHans: "菜单", en: "Menu"),
            level: "essential", flags: []
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
            flags: []
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
}
