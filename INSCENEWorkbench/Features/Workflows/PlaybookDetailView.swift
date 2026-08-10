import SwiftData
import SwiftUI

struct PlaybookDetailView: View {
    let playbook: ExpertPlaybook
    let repository: GuideContentRepository
    let settings: SettingsStore

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProjectSession.updatedAt, order: .reverse) private var sessions: [ProjectSession]
    @State private var isProfessionalExpanded: Bool
    @State private var mutationFailure: LocalMutationFailure?
    @State private var applicationMessage: String?

    init(
        playbook: ExpertPlaybook,
        repository: GuideContentRepository,
        settings: SettingsStore
    ) {
        self.playbook = playbook
        self.repository = repository
        self.settings = settings
        _isProfessionalExpanded = State(initialValue: settings.contentLevel == .professional)
    }

    private var creator: CreatorProfile? {
        repository.content.creators.first { $0.id == playbook.creatorID }
    }

    private var sources: [SourceReference] {
        playbook.sourceIDs.compactMap { id in
            repository.content.sources.first { $0.id == id }
        }
    }

    var body: some View {
        List {
            identitySection
            problemSection
            fitSection
            nonFitSection
            professionalDisclosure
            checklistSection
            applySection
            if settings.showsSources { sourcesSection }
        }
        .navigationTitle(playbook.title.resolved(for: settings.language))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: settings.contentLevel) { _, level in
            isProfessionalExpanded = level == .professional
        }
        .localMutationAlert(failure: $mutationFailure, language: settings.language)
    }

    private var identitySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                SourceBadge(title: copy("公开专业来源", "Public professional source"), kind: .professional)
                Text(playbook.title.resolved(for: settings.language))
                    .font(.title2.bold())
                if let creator {
                    Text(creator.name.resolved(for: settings.language))
                        .font(.headline)
                        .foregroundStyle(.indigo)
                    Text(creator.bio.resolved(for: settings.language))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(playbook.summary.resolved(for: settings.language))
                    .font(.body)
            }
            .padding(.vertical, 8)

            LabeledContent(copy("Resolve 版本", "Resolve version"), value: playbook.resolveVersion)
            LabeledContent(copy("兼容性", "Compatibility"), value: compatibilityLabel)
            LabeledContent(
                copy("资料复核", "Source reviewed"),
                value: playbook.lastReviewedDate
            )
        } footer: {
            Text(copy(
                "这是基于公开一手资料撰写的原创工作摘要，并非创作者背书或官方课程复制。",
                "This is an original working summary based on public primary material, not creator endorsement or copied course material."
            ))
        }
    }

    private var problemSection: some View {
        Section {
            Label {
                Text(playbook.problem.resolved(for: settings.language))
            } icon: {
                Image(systemName: "target")
                    .foregroundStyle(.blue)
            }
        } header: {
            Text(copy("要解决的问题", "Problem to Solve"))
        }
    }

    private var fitSection: some View {
        Section {
            bulletRows(playbook.fit, systemImage: "checkmark.circle.fill", color: .green)
        } header: {
            Text(copy("适用情况", "Use When"))
        }
    }

    private var nonFitSection: some View {
        Section {
            bulletRows(playbook.nonFit, systemImage: "exclamationmark.triangle.fill", color: .orange)
        } header: {
            Text(copy("不适用情况", "Do Not Use When"))
        }
    }

    private var professionalDisclosure: some View {
        Section {
            DisclosureGroup(isExpanded: $isProfessionalExpanded) {
                VStack(alignment: .leading, spacing: 20) {
                    detailGroup(copy("前置要求", "Requirements"), playbook.requirements, "checkmark.shield", .blue)
                    detailGroup(copy("步骤", "Procedure"), playbook.steps, "list.number", .indigo, numbered: true)
                    detailGroup(copy("判断标准", "Judgment Criteria"), playbook.judgmentCriteria, "scope", .green)
                    detailGroup(copy("常见错误", "Common Mistakes"), playbook.mistakes, "exclamationmark.octagon", .orange)
                    detailGroup(copy("回退路径", "Rollback"), playbook.rollback, "arrow.uturn.backward.circle", .blue)
                    detailGroup(copy("与官方流程的差异", "Difference from Official Workflow"), playbook.officialDifferences, "arrow.triangle.branch", .purple)
                }
                .padding(.top, 12)
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(copy("展开专业执行细节", "Professional Execution Details"))
                        .font(.headline)
                    Text(copy(
                        "前置条件、完整步骤、判断、错误与回退。",
                        "Requirements, full procedure, judgment, mistakes, and rollback."
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .frame(minHeight: 44, alignment: .leading)
            }
            .accessibilityIdentifier("workflows.playbook.professionalDisclosure")
        }
    }

    private var checklistSection: some View {
        Section {
            ForEach(Array(playbook.checklist.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 11) {
                    Image(systemName: "square")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text(item.resolved(for: settings.language))
                        .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(index + 1). \(item.resolved(for: settings.language))")
            }
        } header: {
            Text(copy("可应用检查表", "Actionable Checklist"))
        }
    }

    private var applySection: some View {
        Section {
            if let session = sessions.first {
                Button {
                    apply(to: session)
                } label: {
                    Label(copy("应用到当前项目", "Apply to Current Project"), systemImage: "text.badge.plus")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("workflows.playbook.apply")

                Text(copy("当前项目：\(session.name)", "Current project: \(session.name)"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Label(copy("请先在“工作流程”中新建项目", "Create a project in Workflows first"), systemImage: "folder.badge.plus")
                    .foregroundStyle(.secondary)
                    .frame(minHeight: 44)
            }

            if let applicationMessage {
                Label(applicationMessage, systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
                    .accessibilityIdentifier("workflows.playbook.applied")
            }
        }
    }

    private var sourcesSection: some View {
        Section {
            ForEach(sources) { source in
                VStack(alignment: .leading, spacing: 8) {
                    SourceBadge(
                        title: source.id.hasPrefix("source-blackmagic")
                            ? copy("官方资料", "Official material")
                            : copy("公开专业资料", "Public professional material"),
                        kind: source.id.hasPrefix("source-blackmagic") ? .official : .professional
                    )
                    Text(source.title.resolved(for: settings.language))
                        .font(.subheadline.weight(.semibold))
                    Text(sourceDateLine(source))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let url = URL(string: source.url) {
                        Link(destination: url) {
                            Label(copy("查看公开来源", "Open Public Source"), systemImage: "arrow.up.right.square")
                                .frame(minHeight: 44)
                        }
                    }
                }
                .padding(.vertical, 5)
            }
        } header: {
            Text(copy("来源与日期", "Sources and Dates"))
        } footer: {
            Text(copy(
                "发布日期为来源公开标注；未标注时明确显示。复核日期表示本应用最后核查该公开页面的日期。",
                "Publication dates reflect the source where shown; missing dates are explicit. Review date is this app's latest check of the public page."
            ))
        }
    }

    @ViewBuilder
    private func bulletRows(_ items: [LocalizedText], systemImage: String, color: Color) -> some View {
        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
            Label {
                Text(item.resolved(for: settings.language))
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(color)
            }
            .frame(minHeight: 36)
        }
    }

    @ViewBuilder
    private func detailGroup(
        _ title: String,
        _ items: [LocalizedText],
        _ systemImage: String,
        _ color: Color,
        numbered: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(color)
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 10) {
                    if numbered {
                        Text("\(index + 1)")
                            .font(.caption.monospacedDigit().bold())
                            .foregroundStyle(color)
                            .frame(width: 22)
                    } else {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(color)
                            .frame(width: 22, height: 20)
                            .accessibilityHidden(true)
                    }
                    Text(item.resolved(for: settings.language))
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var compatibilityLabel: String {
        switch playbook.compatibility {
        case .freeAndStudio: copy("免费版与 Studio", "Free and Studio")
        case .studioPreferred: copy("建议 Studio", "Studio preferred")
        case .studioRequired: copy("需要 Studio", "Studio required")
        }
    }

    private func sourceDateLine(_ source: SourceReference) -> String {
        let published = source.publishedDate ?? copy("未标注发布日期", "No publication date shown")
        return "\(copy("发布", "Published")): \(published) · \(copy("复核", "Reviewed")): \(source.lastReviewedDate)"
    }

    private func apply(to session: ProjectSession) {
        let result = LocalUserStateMutator(modelContext: modelContext).applyPlaybook(playbook, to: session)
        switch result {
        case .success(let count):
            applicationMessage = count == 0
                ? copy("检查项目已存在，没有重复添加。", "Checklist items already exist; no duplicates were added.")
                : copy("已添加 \(count) 个检查项目。", "Added \(count) checklist items.")
        case .failure(let failure):
            mutationFailure = failure
        }
    }

    private func copy(_ zhHans: String, _ en: String) -> String {
        settings.language == .zhHans ? zhHans : en
    }
}
