import SwiftUI
import SwiftData

struct LibraryView: View {
    let repository: GuideContentRepository
    let settings: SettingsStore

    @Query(sort: \Favorite.updatedAt, order: .reverse) private var favorites: [Favorite]
    @Query(sort: \UserNote.updatedAt, order: .reverse) private var notes: [UserNote]

    @State private var query = ""
    @State private var selectedFilter: LibraryFilter = .all

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                searchField
                filterControls

                if filteredRecords.isEmpty {
                    ContentUnavailableView(
                        copy("没有符合条件的内容", "No matching content"),
                        systemImage: "books.vertical"
                    )
                    .padding(.top, 40)
                } else {
                    resultSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(copy("资料库", "Library"))
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: String.self) { id in
            if let record = repository.record(id: id) {
                ContentDetailView(record: record, repository: repository, settings: settings)
            } else {
                ContentUnavailableView(
                    copy("内容不存在", "Content unavailable"),
                    systemImage: "questionmark.folder"
                )
            }
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField(
                copy("搜索内容…", "Search content…"),
                text: $query
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .accessibilityIdentifier("library.search")
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

    // MARK: - Filter Controls

    private var filterControls: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LibraryFilter.allCases, id: \.self) { filter in
                    filterButton(filter)
                }
            }
        }
    }

    private func filterButton(_ filter: LibraryFilter) -> some View {
        let selected = selectedFilter == filter
        return Button {
            selectedFilter = filter
        } label: {
            Label(filterTitle(filter), systemImage: filterSymbol(filter))
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .foregroundStyle(selected ? Color.white : Color.primary)
                .background(selected ? Color.accentColor : Color.secondary.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("library.filter.\(filter.rawValue)")
    }

    // MARK: - Result Section

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(copy("共 \(filteredRecords.count) 条", "\(filteredRecords.count) items"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            ForEach(Array(filteredRecords.enumerated()), id: \.offset) { index, record in
                LibraryRecordRow(
                    record: record,
                    settings: settings,
                    isFavorite: favoriteIDs.contains(record.id),
                    isLast: index >= filteredRecords.count - 1
                )
            }
        }
    }

    // MARK: - Computed Properties

    private var filteredRecords: [any SearchableContent] {
        let allRecords = repository.content.searchableRecords
        let noteIDs = Set(notes.map(\.contentID))

        let baseRecords: [any SearchableContent]
        switch selectedFilter {
        case .all:
            baseRecords = allRecords
        case .stages:
            baseRecords = allRecords.filter { $0.kind == .stage }
        case .playbooks:
            baseRecords = allRecords.filter { $0.kind == .playbook }
        case .recipes:
            baseRecords = allRecords.filter { $0.kind == .recipe }
        case .colorPasses:
            baseRecords = allRecords.filter { $0.kind == .colorPass }
        case .exports:
            baseRecords = allRecords.filter { $0.kind == .export }
        case .emergencies:
            baseRecords = allRecords.filter { $0.kind == .emergency }
        case .shortcuts:
            baseRecords = allRecords.filter { $0.kind == .shortcut }
        case .favorites:
            baseRecords = allRecords.filter { favoriteIDs.contains($0.id) }
        case .notes:
            baseRecords = allRecords.filter { noteIDs.contains($0.id) }
        }

        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalizedQuery.isEmpty {
            return baseRecords
        }
        return baseRecords.filter { record in
            let title = record.title.resolved(for: settings.language).lowercased()
            let summary = record.summary.resolved(for: settings.language).lowercased()
            return title.contains(normalizedQuery) || summary.contains(normalizedQuery)
        }
    }

    private var favoriteIDs: Set<String> {
        Set(favorites.map(\.contentID))
    }

    // MARK: - Helpers

    private func filterTitle(_ filter: LibraryFilter) -> String {
        switch filter {
        case .all: copy("全部", "All")
        case .stages: copy("官方流程", "Workflow")
        case .playbooks: copy("专业流程", "Professional")
        case .recipes: copy("经典操作", "Actions")
        case .colorPasses: copy("调色", "Color")
        case .exports: copy("输出", "Export")
        case .emergencies: copy("急救", "Issues")
        case .shortcuts: copy("快捷键", "Shortcuts")
        case .favorites: copy("收藏", "Favorites")
        case .notes: copy("笔记", "Notes")
        }
    }

    private func filterSymbol(_ filter: LibraryFilter) -> String {
        switch filter {
        case .all: "line.3.horizontal.decrease"
        case .stages: "checklist"
        case .playbooks: "person.text.rectangle"
        case .recipes: "bolt"
        case .colorPasses: "scope"
        case .exports: "square.and.arrow.up"
        case .emergencies: "cross.case"
        case .shortcuts: "keyboard"
        case .favorites: "star"
        case .notes: "note.text"
        }
    }

    private func copy(_ zhHans: String, _ en: String) -> String {
        settings.language == .zhHans ? zhHans : en
    }
}

// MARK: - Library Filter

enum LibraryFilter: String, CaseIterable, Hashable {
    case all
    case stages
    case playbooks
    case recipes
    case colorPasses
    case exports
    case emergencies
    case shortcuts
    case favorites
    case notes
}

// MARK: - Library Record Row

private struct LibraryRecordRow: View {
    let record: any SearchableContent
    let settings: SettingsStore
    let isFavorite: Bool
    let isLast: Bool

    var body: some View {
        VStack {
            NavigationLink(value: record.id) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
            Label(kindTitle, systemImage: kindSymbol)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(kindTint)
                            if isFavorite {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                                    .accessibilityLabel(settings.language == .zhHans ? "已收藏" : "Favorite")
                            }
                        }
                        Text(record.title.resolved(for: settings.language))
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Text(record.summary.resolved(for: settings.language))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("library.item.\(record.id)")

            if !isLast {
                Divider()
            }
        }
    }

    private var kindTitle: String {
        let zh = settings.language == .zhHans
        switch record.kind {
        case .shortcut: return zh ? "快捷键" : "Shortcut"
        case .recipe: return zh ? "经典操作" : "Action"
        case .colorPass: return zh ? "调色" : "Color"
        case .export: return zh ? "输出" : "Export"
        case .emergency: return zh ? "故障急救" : "Troubleshooting"
        case .stage: return zh ? "官方流程" : "Workflow"
        case .playbook: return zh ? "专业流程" : "Professional"
        }
    }

    private var kindSymbol: String {
        switch record.kind {
        case .shortcut: "keyboard"
        case .recipe: "bolt"
        case .colorPass: "scope"
        case .export: "square.and.arrow.up"
        case .emergency: "cross.case"
        case .stage: "checklist"
        case .playbook: "person.text.rectangle"
        }
    }

    private var kindTint: Color {
        switch record.kind {
        case .emergency: .red
        case .export: .green
        case .colorPass: .purple
        default: .blue
        }
    }
}
