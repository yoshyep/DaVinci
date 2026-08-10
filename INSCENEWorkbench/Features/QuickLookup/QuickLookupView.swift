import SwiftData
import SwiftUI

struct QuickLookupView: View {
    let repository: GuideContentRepository
    let settings: SettingsStore
    let router: AppRouter

    @Query(sort: \ProjectSession.updatedAt, order: .reverse) private var sessions: [ProjectSession]
    @Query(sort: \RecentActivity.updatedAt, order: .reverse) private var recentActivities: [RecentActivity]
    @Query(sort: \Favorite.updatedAt, order: .reverse) private var favorites: [Favorite]

    @State private var query = ""
    @State private var selectedKind: ContentKind?
    @State private var selectedCategory: String?
    @State private var selectedStageID: String?

    private let engine: SearchEngine

    init(repository: GuideContentRepository, settings: SettingsStore, router: AppRouter) {
        self.repository = repository
        self.settings = settings
        self.router = router
        engine = SearchEngine(repository: repository)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                searchField
                platformAndLevelControls
                filterControls

                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    landingContent
                } else if searchHits.isEmpty {
                    noResults
                } else {
                    resultSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(copy("速查", "Quick Lookup"))
        .navigationBarTitleDisplayMode(.large)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField(
                copy("搜索动作、快捷键、故障…", "Search actions, shortcuts, issues…"),
                text: $query
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .accessibilityIdentifier("lookup.search")
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel(copy("清除搜索", "Clear search"))
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 4)
        .frame(minHeight: 52)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private var platformAndLevelControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(copy("快捷键平台", "Shortcut platform"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    selectionButton(
                        title: "Mac",
                        systemImage: "apple.logo",
                        isSelected: settings.platform == .mac,
                        identifier: "lookup.platform.mac"
                    ) { settings.platform = .mac }
                    selectionButton(
                        title: "Windows",
                        systemImage: "window.casement",
                        isSelected: settings.platform == .windows,
                        identifier: "lookup.platform.windows"
                    ) { settings.platform = .windows }
                    Divider().frame(height: 28)
                    selectionButton(
                        title: copy("快速", "Quick"),
                        systemImage: "bolt.fill",
                        isSelected: settings.contentLevel == .quick,
                        identifier: "lookup.level.quick"
                    ) { settings.contentLevel = .quick }
                    selectionButton(
                        title: copy("专业", "Pro"),
                        systemImage: "slider.horizontal.3",
                        isSelected: settings.contentLevel == .professional,
                        identifier: "lookup.level.professional"
                    ) { settings.contentLevel = .professional }
                }
            }
        }
    }

    private var filterControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterButton(nil, title: copy("全部", "All"), symbol: "line.3.horizontal.decrease")
                    filterButton(.shortcut, title: copy("快捷键", "Shortcuts"), symbol: "keyboard")
                    filterButton(.recipe, title: copy("操作", "Actions"), symbol: "bolt")
                    filterButton(.colorPass, title: copy("调色", "Color"), symbol: "scope")
                    filterButton(.export, title: copy("输出", "Export"), symbol: "square.and.arrow.up")
                    filterButton(.emergency, title: copy("急救", "Issues"), symbol: "cross.case")
                    filterButton(.stage, title: copy("流程", "Workflow"), symbol: "checklist")
                }
            }

            HStack(spacing: 10) {
                categoryMenu
                stageMenu
                if selectedCategory != nil || selectedStageID != nil {
                    Button(copy("重置", "Reset")) {
                        selectedCategory = nil
                        selectedStageID = nil
                    }
                    .buttonStyle(.borderless)
                    .frame(minHeight: 44)
                }
            }
        }
    }

    private var landingContent: some View {
        Group {
            if !recentRecords.isEmpty {
                lookupSection(
                    title: copy("最近使用", "Recent"),
                    subtitle: copy("保存在本机", "Stored on this device"),
                    records: recentRecords
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(copy("快捷键中心", "Shortcut Center"))
                            .font(.title2.bold())
                        Text(copy("点击动作或键帽查看菜单、场景与相关快捷键", "Tap an action or keycaps for menu, context, and related shortcuts"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(visibleShortcuts.count)")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                if visibleShortcuts.isEmpty {
                    ContentUnavailableView(
                        copy("没有符合筛选的快捷键", "No shortcuts match these filters"),
                        systemImage: "keyboard.badge.ellipsis"
                    )
                } else {
                    ForEach(visibleShortcuts) { shortcut in
                        SearchResultView(
                            record: shortcut,
                            settings: settings,
                            isFavorite: favoriteIDs.contains(shortcut.id)
                        ) { open(shortcut.id) }
                        if shortcut.id != visibleShortcuts.last?.id { Divider() }
                    }
                }
            }
        }
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(copy("最短答案优先", "Shortest answer first"))
                    .font(.title2.bold())
                Spacer()
                Text("\(searchHits.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ForEach(searchHits) { hit in
                if let record = repository.record(id: hit.contentID) {
                    SearchResultView(
                        record: record,
                        settings: settings,
                        isFavorite: favoriteIDs.contains(record.id)
                    ) { open(record.id) }
                    if hit.id != searchHits.last?.id { Divider() }
                }
            }
        }
    }

    private var noResults: some View {
        VStack(alignment: .leading, spacing: 16) {
            ContentUnavailableView {
                Label(copy("没有本地结果", "No local results"), systemImage: "magnifyingglass")
            } description: {
                Text(copy("没有找到可靠内容。试试动作名、目的或故障现象。", "No reliable match was found. Try an action, intent, or symptom."))
            }
            Text(copy("试试这些", "Try these"))
                .font(.headline)
            HStack(spacing: 8) {
                suggestionButton(copy("波纹删除", "Ripple Delete"))
                suggestionButton(copy("媒体离线", "Media Offline"))
                suggestionButton("H.264")
            }
        }
    }

    private func lookupSection(
        title: String,
        subtitle: String,
        records: [any SearchableContent]
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.title3.bold())
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
            ForEach(Array(records.enumerated()), id: \.offset) { _, record in
                SearchResultView(
                    record: record,
                    settings: settings,
                    isFavorite: favoriteIDs.contains(record.id)
                ) { open(record.id) }
            }
        }
    }

    private func selectionButton(
        title: String,
        systemImage: String,
        isSelected: Bool,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .frame(minHeight: 44)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }

    private func filterButton(_ kind: ContentKind?, title: String, symbol: String) -> some View {
        let selected = selectedKind == kind
        return Button {
            selectedKind = kind
        } label: {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .foregroundStyle(selected ? Color.white : Color.primary)
                .background(selected ? Color.accentColor : Color.secondary.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("lookup.filter.\(kind?.rawValue ?? "all")")
    }

    private var categoryMenu: some View {
        Menu {
            Button(copy("全部分类", "All categories")) { selectedCategory = nil }
            ForEach(shortcutCategories, id: \.en) { category in
                Button(category.resolved(for: settings.language)) { selectedCategory = category.en }
            }
        } label: {
            Label(
                selectedCategoryTitle ?? copy("分类", "Category"),
                systemImage: "square.grid.2x2"
            )
            .font(.subheadline.weight(.semibold))
            .frame(minHeight: 44)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("lookup.filter.category")
    }

    private var stageMenu: some View {
        Menu {
            Button(copy("全部阶段", "All stages")) { selectedStageID = nil }
            ForEach(repository.content.stages.sorted(by: { $0.number < $1.number })) { stage in
                Button(stage.title.resolved(for: settings.language)) { selectedStageID = stage.id }
            }
        } label: {
            Label(selectedStageTitle ?? copy("阶段", "Stage"), systemImage: "flag")
                .font(.subheadline.weight(.semibold))
                .frame(minHeight: 44)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("lookup.filter.stageMenu")
    }

    private func suggestionButton(_ value: String) -> some View {
        Button(value) { query = value }
            .buttonStyle(.bordered)
            .frame(minHeight: 44)
    }

    private var searchHits: [SearchHit] {
        engine.search(
            query,
            context: SearchContext(
                language: settings.language,
                platform: settings.platform,
                currentStageID: currentStageID,
                recentIDs: recentIDs,
                favoriteIDs: Array(favoriteIDs),
                filters: SearchFilters(
                    kind: selectedKind,
                    category: selectedCategory,
                    stageID: selectedStageID
                )
            )
        )
    }

    private var visibleShortcuts: [ShortcutDefinition] {
        guard selectedKind == nil || selectedKind == .shortcut else { return [] }
        return repository.content.shortcuts.filter { shortcut in
            if let selectedCategory {
                let categories = [shortcut.category.en, shortcut.category.zhHans].map(SearchEngine.normalize)
                if !categories.contains(SearchEngine.normalize(selectedCategory)) { return false }
            }
            if let selectedStageID, !shortcut.stages.contains(selectedStageID) { return false }
            return true
        }
        .sorted {
            let lhsCategory = $0.category.resolved(for: settings.language)
            let rhsCategory = $1.category.resolved(for: settings.language)
            if lhsCategory != rhsCategory { return lhsCategory.localizedStandardCompare(rhsCategory) == .orderedAscending }
            return $0.title.resolved(for: settings.language).localizedStandardCompare($1.title.resolved(for: settings.language)) == .orderedAscending
        }
    }

    private var shortcutCategories: [LocalizedText] {
        var seen = Set<String>()
        return repository.content.shortcuts.compactMap { shortcut in
            guard seen.insert(shortcut.category.en).inserted else { return nil }
            return shortcut.category
        }
        .sorted { $0.resolved(for: settings.language) < $1.resolved(for: settings.language) }
    }

    private var selectedCategoryTitle: String? {
        guard let selectedCategory else { return nil }
        return shortcutCategories.first(where: { $0.en == selectedCategory })?.resolved(for: settings.language)
    }

    private var selectedStageTitle: String? {
        repository.content.stages.first(where: { $0.id == selectedStageID })?.title.resolved(for: settings.language)
    }

    private var currentStageID: String? {
        guard let session = sessions.first else { return nil }
        let completed = Set(session.stageProgress.filter(\.isCompleted).map(\.contentID))
        return repository.content.stages.sorted(by: { $0.number < $1.number }).first { !completed.contains($0.id) }?.id
    }

    private var recentIDs: [String] {
        var seen = Set<String>()
        return recentActivities.compactMap { activity in
            guard seen.insert(activity.contentID).inserted else { return nil }
            return activity.contentID
        }
    }

    private var recentRecords: [any SearchableContent] {
        Array(recentIDs.prefix(5).compactMap(repository.record(id:)))
    }

    private var favoriteIDs: Set<String> {
        Set(favorites.map(\.contentID))
    }

    private func open(_ contentID: String) {
        router.lookupPath.append(.record(contentID))
    }

    private func copy(_ zhHans: String, _ en: String) -> String {
        settings.language == .zhHans ? zhHans : en
    }
}
