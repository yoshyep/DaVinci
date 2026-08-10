import SwiftData
import SwiftUI

struct WorkflowListView: View {
    let repository: GuideContentRepository
    let settings: SettingsStore

    @Query(sort: \ProjectSession.updatedAt, order: .reverse) private var sessions: [ProjectSession]
    @State private var isCreatingProject = false
    @State private var isShowingRecommendations = false
    @State private var isShowingSettings = false

    private var stages: [WorkflowStage] {
        repository.content.stages.sorted { $0.number < $1.number }
    }

    var body: some View {
        List {
            introduction
            projectSection
            officialWorkflowSection
            recommendationSection
            playbookSection
        }
        .navigationTitle(copy("工作流程", "Workflows"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel(copy("设置", "Settings"))
                .accessibilityIdentifier("workflows.settings")
            }
        }
        .sheet(isPresented: $isCreatingProject) {
            NavigationStack {
                ProjectCreationView(repository: repository, settings: settings)
            }
        }
        .sheet(isPresented: $isShowingRecommendations) {
            NavigationStack {
                WorkflowRecommendationView(repository: repository, settings: settings)
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(settings: settings)
        }
    }

    private var introduction: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Label {
                    Text(copy("本地项目工作台", "Local project workbench"))
                        .font(.headline)
                } icon: {
                    Image(systemName: "checklist.checked")
                        .foregroundStyle(.blue)
                }
                Text(copy(
                    "从官方十阶段流程开始；需要时再展开专业方法、判断标准与来源。",
                    "Start with the official ten-stage path, then disclose professional methods, judgment criteria, and sources when needed."
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                Label(copy("全部内容与项目状态只保存在本机", "All content and project state stay on this device"), systemImage: "iphone.gen3")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
        }
        .listRowBackground(Color.clear)
    }

    private var projectSection: some View {
        Section {
            ForEach(sessions) { session in
                NavigationLink {
                    ProjectSessionView(
                        session: session,
                        repository: repository,
                        settings: settings
                    )
                } label: {
                    VStack(alignment: .leading, spacing: 9) {
                        HStack {
                            Label(session.name, systemImage: "film.stack")
                                .font(.headline)
                            Spacer()
                            Text("\(completedStages(in: session))/\(stages.count)")
                                .font(.caption.monospacedDigit().weight(.bold))
                                .foregroundStyle(.green)
                        }
                        ProgressView(
                            value: Double(completedStages(in: session)),
                            total: Double(max(stages.count, 1))
                        )
                        .tint(.green)
                        if session.id == sessions.first?.id {
                            Text(copy("当前项目 · 检查表、笔记与版本记录", "Current project · checklists, notes, and version records"))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.blue)
                        } else {
                            Text(copy("继续检查表、笔记与版本记录", "Continue checklists, notes, and version records"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 5)
                    .frame(minHeight: 60)
                }
                .accessibilityIdentifier(session.id == sessions.first?.id ? "workflows.currentProject" : "workflows.project.\(session.id)")
            }

            Button {
                isCreatingProject = true
            } label: {
                Label(copy("新建项目", "New Project"), systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("workflows.createProject")
        } header: {
            Text(copy("项目", "Projects"))
        }
    }

    private var officialWorkflowSection: some View {
        Section {
            ForEach(stages, id: \.id) { stage in
                NavigationLink {
                    WorkflowDetailView(stage: stage, repository: repository, settings: settings)
                } label: {
                    HStack(alignment: .top, spacing: 13) {
                        Text(String(format: "%02d", stage.number))
                            .font(.caption.monospacedDigit().bold())
                            .foregroundStyle(Color.contrastSafeForeground(forStageHex: stage.color))
                            .frame(width: 38, height: 38)
                            .background(Color(stageHex: stage.color), in: Circle())
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(stage.title.resolved(for: settings.language))
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(stage.summary.resolved(for: settings.language))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 4)
                    .frame(minHeight: 56)
                }
                .accessibilityIdentifier("workflows.stage.\(stage.number)")
            }
        } header: {
            HStack {
                Text(copy("官方十阶段", "Official Ten-stage Workflow"))
                Spacer()
                SourceBadge(title: copy("Blackmagic 官方", "Blackmagic official"), kind: .official)
            }
        } footer: {
            Text(copy(
                "阶段颜色固定用于快速定位；快捷键会跟随 Mac 或 Windows 设置实时切换。",
                "Stable stage colors aid scanning; shortcuts follow the Mac or Windows setting live."
            ))
        }
    }

    private var recommendationSection: some View {
        Section {
            if settings.showsProfessionalRecommendations {
                Button {
                    isShowingRecommendations = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "wand.and.stars")
                            .foregroundStyle(.indigo)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(copy("匹配专业方法", "Match a Professional Method"))
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(copy(
                                "按项目类型、镜头量、机型与交付条件在本机排序。",
                                "Rank methods locally by project type, shot volume, cameras, and delivery."
                            ))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                    .frame(minHeight: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("workflows.recommend")
            } else {
                Label(
                    copy("专业推荐已在设置中关闭", "Professional recommendations are hidden in Settings"),
                    systemImage: "eye.slash"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(minHeight: 44)
            }
        } header: {
            Text(copy("项目匹配", "Project Match"))
        }
    }

    private var playbookSection: some View {
        Section {
            ForEach(repository.content.playbooks, id: \.id) { playbook in
                NavigationLink {
                    PlaybookDetailView(
                        playbook: playbook,
                        repository: repository,
                        settings: settings
                    )
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(playbook.title.resolved(for: settings.language))
                            .font(.headline)
                        if let creator = creator(for: playbook) {
                            Text(creator.name.resolved(for: settings.language))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.indigo)
                        }
                        Text(playbook.summary.resolved(for: settings.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                        HStack(spacing: 7) {
                            SourceBadge(title: copy("公开专业来源", "Public professional source"), kind: .professional)
                            Text(playbook.resolveVersion)
                                .font(.caption2.monospaced().weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                    .frame(minHeight: 72)
                }
                .accessibilityIdentifier("workflows.playbook.\(playbook.id)")
            }
        } header: {
            Text(copy("专业工作手册", "Professional Playbooks"))
        } footer: {
            Text(copy(
                "均为根据公开一手资料撰写的原创摘要，不包含课程原文、LUT、PowerGrade 或节点截图。",
                "Original summaries from public primary sources; no course text, LUTs, PowerGrades, or node screenshots are included."
            ))
        }
    }

    private func completedStages(in session: ProjectSession) -> Int {
        let completed = Set(session.stageProgress.filter(\.isCompleted).map(\.contentID))
        return stages.filter { completed.contains($0.id) }.count
    }

    private func creator(for playbook: ExpertPlaybook) -> CreatorProfile? {
        repository.content.creators.first { $0.id == playbook.creatorID }
    }

    private func copy(_ zhHans: String, _ en: String) -> String {
        settings.language == .zhHans ? zhHans : en
    }
}

private struct WorkflowRecommendationView: View {
    let repository: GuideContentRepository
    let settings: SettingsStore

    @Environment(\.dismiss) private var dismiss
    @State private var projectType = RecommendationProjectType.interview
    @State private var mixedCameras = true
    @State private var needsProductColorAccuracy = false
    @State private var needsFilmLook = false
    @State private var shotVolume = RecommendationShotVolume.high
    @State private var delivery = RecommendationDelivery.web
    @State private var hasStudio = true

    private var recommendations: [PlaybookRecommendation] {
        (try? RecommendationEngine(playbooks: repository.content.playbooks).recommend(for: input)) ?? []
    }

    private var input: RecommendationInput {
        RecommendationInput(
            projectType: projectType,
            mixedCameras: mixedCameras,
            needsProductColorAccuracy: needsProductColorAccuracy,
            needsFilmLook: needsFilmLook,
            shotVolume: shotVolume,
            delivery: delivery,
            hasStudio: hasStudio
        )
    }

    var body: some View {
        Form {
            Section {
                Picker(selection: $projectType) {
                    ForEach(RecommendationProjectType.allCases, id: \.self) { value in
                        Text(projectTypeLabel(value)).tag(value)
                    }
                } label: {
                    Text(copy("项目类型", "Project type"))
                }
                Picker(selection: $shotVolume) {
                    ForEach(RecommendationShotVolume.allCases, id: \.self) { value in
                        Text(shotVolumeLabel(value)).tag(value)
                    }
                } label: {
                    Text(copy("镜头量", "Shot volume"))
                }
                Picker(selection: $delivery) {
                    ForEach(RecommendationDelivery.allCases, id: \.self) { value in
                        Text(deliveryLabel(value)).tag(value)
                    }
                } label: {
                    Text(copy("交付", "Delivery"))
                }
                Toggle(copy("混合机型", "Mixed cameras"), isOn: $mixedCameras)
                Toggle(copy("产品色必须准确", "Exact product color"), isOn: $needsProductColorAccuracy)
                Toggle(copy("需要胶片观感", "Needs a film look"), isOn: $needsFilmLook)
                Toggle(copy("拥有 Resolve Studio", "Resolve Studio available"), isOn: $hasStudio)
            } header: {
                Text(copy("项目条件", "Project Conditions"))
            } footer: {
                Text(copy(
                    "规则仅在本机运行，不上传项目资料，也不会调用远程 AI。",
                    "Rules run entirely on device; project details are never uploaded and no remote AI is used."
                ))
            }

            Section {
                if recommendations.isEmpty {
                    ContentUnavailableView(
                        copy("没有安全匹配", "No Safe Match"),
                        systemImage: "questionmark.circle",
                        description: Text(copy(
                            "调整条件，或直接查看全部专业工作手册。",
                            "Adjust the conditions or review all professional playbooks."
                        ))
                    )
                } else {
                    ForEach(recommendations) { recommendation in
                        if let playbook = playbook(id: recommendation.playbookID) {
                            NavigationLink {
                                PlaybookDetailView(
                                    playbook: playbook,
                                    repository: repository,
                                    settings: settings
                                )
                            } label: {
                                VStack(alignment: .leading, spacing: 9) {
                                    Text(playbook.title.resolved(for: settings.language))
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    recommendationLine(
                                        title: copy("为什么", "Why"),
                                        text: recommendation.reason.resolved(for: settings.language),
                                        systemImage: "checkmark.circle.fill",
                                        color: .green
                                    )
                                    recommendationLine(
                                        title: copy("不适用情况", "Do not use when"),
                                        text: recommendation.dontUse.resolved(for: settings.language),
                                        systemImage: "exclamationmark.triangle.fill",
                                        color: .orange
                                    )
                                }
                                .padding(.vertical, 6)
                            }
                            .accessibilityIdentifier("workflows.recommendation.\(playbook.id)")
                        }
                    }
                }
            } header: {
                Text(copy("推荐结果", "Recommendations"))
            }
        }
        .navigationTitle(copy("匹配专业方法", "Match a Method"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(copy("完成", "Done")) { dismiss() }
            }
        }
    }

    private func recommendationLine(
        title: String,
        text: String,
        systemImage: String,
        color: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text("**\(title)：** \(text)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
    }

    private func playbook(id: String) -> ExpertPlaybook? {
        repository.content.playbooks.first { $0.id == id }
    }

    private func projectTypeLabel(_ value: RecommendationProjectType) -> String {
        switch value {
        case .interview: copy("访谈", "Interview")
        case .advertising: copy("广告 / 产品", "Advertising / Product")
        case .documentary: copy("纪录片", "Documentary")
        case .narrative: copy("剧情", "Narrative")
        case .archival: copy("档案恢复", "Archival restoration")
        }
    }

    private func shotVolumeLabel(_ value: RecommendationShotVolume) -> String {
        switch value {
        case .low: copy("少", "Low")
        case .medium: copy("中", "Medium")
        case .high: copy("多", "High")
        }
    }

    private func deliveryLabel(_ value: RecommendationDelivery) -> String {
        switch value {
        case .web: copy("网络", "Web")
        case .broadcast: copy("广播", "Broadcast")
        case .cinema: copy("影院", "Cinema")
        case .archive: copy("档案母版", "Archive master")
        }
    }

    private func copy(_ zhHans: String, _ en: String) -> String {
        settings.language == .zhHans ? zhHans : en
    }
}

extension Color {
    init(stageHex: String) {
        let sanitized = stageHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let value = UInt64(sanitized, radix: 16) ?? 0x5B69D8
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }

    /// WCAG 2.1 relative luminance for an sRGB hex color string.
    static func relativeLuminance(forHex hex: String) -> Double {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let value = UInt64(sanitized, radix: 16) ?? 0x5B69D8
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        func lin(_ c: Double) -> Double {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
    }

    /// WCAG 2.1 contrast ratio between two luminance values.
    static func contrastRatio(luminance1: Double, luminance2: Double) -> Double {
        let lighter = max(luminance1, luminance2)
        let darker = min(luminance1, luminance2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Returns white or black, whichever achieves >= 4.5:1 contrast with the given hex background.
    static func contrastSafeForeground(forStageHex hex: String) -> Color {
        let bgLuminance = relativeLuminance(forHex: hex)
        let whiteContrast = contrastRatio(luminance1: bgLuminance, luminance2: 1.0)
        let blackContrast = contrastRatio(luminance1: bgLuminance, luminance2: 0.0)
        return blackContrast > whiteContrast ? .black : .white
    }
}
