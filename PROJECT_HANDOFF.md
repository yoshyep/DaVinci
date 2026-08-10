# INSCENE iOS 项目交接清单

更新时间：2026-08-10（Task 7 已形成可运行检查点，仍有 5 项重要修正）

## 项目位置

- 工程根目录：`/Users/yoshyep/Documents/Codex/2026-08-09/html-svg/INSCENEWorkbench`
- Xcode 工程：`/Users/yoshyep/Documents/Codex/2026-08-09/html-svg/INSCENEWorkbench/INSCENEWorkbench.xcodeproj`
- Git 分支：`feature/inscene-ios`
- App 名称：`INSCENE`
- Bundle ID：`com.inscene.davinciworkbench`
- 自动签名 Team ID：`4A3TT9KN5R`
- iOS Deployment Target：iOS 26.0
- 主要验收设备：iPhone 17 Pro / iOS 26.5 Simulator

## 需求与计划文件

- 已批准设计规格：`/Users/yoshyep/Documents/Codex/2026-08-09/html-svg/docs/plans/2026-08-10-inscene-davinci-ios-design.md`
- 实施计划：`/Users/yoshyep/Documents/Codex/2026-08-09/html-svg/docs/superpowers/plans/2026-08-10-inscene-davinci-ios.md`
- 任务进度账本：`/Users/yoshyep/Documents/Codex/2026-08-09/html-svg/INSCENEWorkbench/.superpowers/sdd/2026-08-10-inscene-davinci-ios/progress.md`
- Task 7 brief：`/Users/yoshyep/Documents/Codex/2026-08-09/html-svg/INSCENEWorkbench/.superpowers/sdd/2026-08-10-inscene-davinci-ios/task-7-brief.md`
- Task 7 来源审计：`/Users/yoshyep/Documents/Codex/2026-08-09/html-svg/INSCENEWorkbench/.superpowers/sdd/2026-08-10-inscene-davinci-ios/task-7-source-audit.md`
- Task 7 报告：`/Users/yoshyep/Documents/Codex/2026-08-09/html-svg/INSCENEWorkbench/.superpowers/sdd/2026-08-10-inscene-davinci-ios/task-7-report.md`

## 已完成

- Task 1：原生 SwiftUI iPhone 工程、SwiftData、品牌资源、正确 Bundle ID。
- Task 2：本地只读双语内容模型与转换；10 个阶段、61 个快捷键、18 个配方、6 个调色流程、8 个输出配方、12 个故障指南；692 组详细双语内容已审校。
- Task 3：本地设置、项目、进度、笔记、收藏、清单、历史与版本记录模型；不含 iCloud。
- Task 4：四个原生标签页（工作台、速查、工作流、资料库）、引导页、设置、中文/English、Mac/Windows、快速/专业、外观切换。
- Task 5：工具优先的工作台首页、当前项目、阶段进度、快速工具、最近与收藏入口。
- Task 6：115 条本地可搜索记录、61 个快捷键操作、Mac/Windows 键帽、筛选、收藏、跨标签深链接、搜索排序和回滚。
- Logo 修正：主符号居中占方形约 60%，四周约 40% 留白；横版 Logo 无自带白底，浅色显示深色、深色显示白色；App Icon 为 1024×1024，图形 614×614、四边 205 px 留白。
- 本地化目录：115 个界面字符串均有 English 与简体中文值，并有目录完整性测试。

## Task 7 已形成检查点

- Task 7 提交：`c85d4e0` — 官方十阶段工作流、项目会话、规则推荐引擎、六套专业 Playbook。
- 专业来源：Cullen Kelly、Darren Mostyn、Patrick Inhofer / Mixing Light、Juan Melara、Daria Fissoun / Mixing Light、FilmLight，以及 Blackmagic 官方版本/Free/Studio 信息。
- 原则：仅使用公开一手来源；内容为原创双语总结；不复制付费课程、LUT、PowerGrade、逐字稿、节点截图或专有图示。
- 验证记录：66 个单元测试通过、16 个 UI 测试通过、模拟器构建通过；已完成 iPhone 17 Pro 浅/深色与中英文原生 QA。
- 该检查点可继续开发，但独立审查留下 5 项 Important，必须在发布前处理：
  1. Mostyn 推荐规则对非高量项目仍有默认分数，但推荐原因仍描述高镜头量；应使用真正的零基线并补未命中测试。
  2. Playbook 清单项 ID 由数组下标生成，内容重排会错配旧完成状态；应改成显式稳定 ID 并加迁移测试。
  3. Workflows 只暴露最新项目，旧项目不可重新进入；需要项目切换器。
  4. 部分阶段颜色上的白色小号数字对比度低于 4.5:1；需按背景选择前景色并加对比度测试。
  5. Cullen Kelly 的六步细节超出当前公开产品页能够直接支持的范围；需补更强的一手公开来源或收窄为已验证的 scene-referred / DWG 主张。

## 尚未完成

- Task 7 上述 5 项 Important 修正，以及推荐 sheet / Playbook detail 的补充截图复核。
- Task 8：资料库完整界面、笔记/收藏管理、原子 JSON 导入导出、设置页本地数据操作。
- Task 9：Core Spotlight、App Intents、WidgetKit 快速工具小组件。
- Task 10：完整 VoiceOver/Dynamic Type/44pt 触控检查、浅色/深色与中英文视觉 QA、全量单元/UI/构建验证、最终 Xcode 交付。
- 全分支最终代码审查与必要修复。

## 不可改变的产品约束

- iPhone-only、原生 SwiftUI，禁止 WebView。
- 全部用户数据保存在本机；禁止 iCloud、CloudKit、账号、分析、遥测、远程同步、远程 AI。
- 底部标签必须且只能是：工作台、速查、工作流、资料库；学习内容只能作为工具/步骤内的渐进式帮助。
- 工具性优先，学习为附加；Quick 与 Professional 共用同一份内容记录。
- 中文/English、Mac/Windows 必须实时切换。
- 不新增第三方运行时依赖。
- 所有交互目标至少 44×44 pt，支持 VoiceOver 和 Dynamic Type。
- 继续使用用户提供的两个 SVG，不得重画路径：
  - `/Users/yoshyep/Downloads/zaichang-logo-symbol.svg`
  - `/Users/yoshyep/Downloads/INSCENE_horizontal_lockup.svg`

## 关键提交

- `c85d4e0` — 官方工作流、项目会话、推荐引擎与六套专业 Playbook 检查点。
- `ae836ee` — Logo 60% 尺度、留白与深浅主题适配。
- `1c9a068` — 保留本机自动签名并补齐中英文目录。
- `5b5c3a8` — 完成双语速查搜索边界与关键词修正。
- `97a390e` — 本地搜索与快捷键中心主体。
- 更早任务及修复提交请运行：`git log --oneline --decorate -30`。

## 构建与验证

在工程根目录执行：

```sh
xcodebuild build -quiet \
  -project INSCENEWorkbench.xcodeproj \
  -scheme INSCENEWorkbench \
  -destination 'platform=iOS Simulator,id=084650A8-FA75-4093-9626-0C9E5AD36908'
```

```sh
xcodebuild test -quiet \
  -project INSCENEWorkbench.xcodeproj \
  -scheme INSCENEWorkbench \
  -destination 'platform=iOS Simulator,id=084650A8-FA75-4093-9626-0C9E5AD36908' \
  -only-testing:INSCENEWorkbenchTests
```

截至 `c85d4e0`，66 个单元测试与 16 个 UI 测试通过，模拟器构建通过。Xcode 26 的 UI runner 偶尔出现 `DebuggerLLDB.DebuggerVersionStore.StoreError`，应优先串行重试 UI suite，并区分工具链问题与应用失败。

## 接手步骤

1. 打开本文件、设计规格、实施计划和 progress ledger。
2. 运行 `git status --short` 与 `git log --oneline -10`，确认 `c85d4e0` 与本交接提交存在。
3. 先读 Task 7 source audit、report 和上面的 5 项 Important；用测试先行逐项修正，不要重新抓取已核验的其他来源。
4. Task 7 修正完成后，按 Task 8 → Task 9 → Task 10 顺序继续。
5. 每个任务完成后更新 progress ledger 和本文件“最新检查点”。

## 最新检查点

- 最新功能检查点：`c85d4e0`（Task 7，DONE_WITH_CONCERNS）
- 最后完全审查通过的阶段：Task 6 + Logo / 本地化，基线 `1c9a06839a5d6d4b35f4b89a3797c91fc6c517ac`
- 下一步第一优先级：修复 Task 7 的 5 项 Important；不要直接把 `c85d4e0` 当成最终可发布版本。
