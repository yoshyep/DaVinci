# Task 5 Report: Tool-first Workbench Home

Status: `IMPLEMENTED — focused verification green; full-scheme gate environment concern recorded`

## Outcome

Replaced only the Workbench placeholder with a native, repository-backed tool surface. The Home hierarchy is: exact INSCENE symbol and Settings, global command field, current/local project state, four Immediate Tools, ten-stage workflow rail, Project Tools, and swipeable recent activity. Quick Lookup, Workflows, and Library remain their Task 4 placeholders.

`WorkbenchViewModel.Snapshot` derives current stage, stage completion, checklist context, recents, favorites, notes, and no-session templates from `GuideContentRepository`, `SettingsStore`, and SwiftData state. Typed `WorkbenchDestination` routes navigation and typed sheet presentation; immediate tools present native medium/large sheets.

No photography, WebView, network, CloudKit/iCloud, telemetry, or remote-sync path was added.

## RED → GREEN evidence

Before editing production code, I read `test-driven-development/SKILL.md` and `writing-good-tests.md`. Named production breaks included: missing no-session templates; choosing the wrong current stage; incorrect progress/context counts; Quick and Professional selecting different content; Windows displaying Mac keys; routes losing destination types; immediate tools navigating instead of presenting; and pinned history remaining below newer unpinned history.

### Initial RED

Focused command:

```bash
xcodebuild test -project INSCENEWorkbench.xcodeproj -scheme INSCENEWorkbench \
  -destination 'platform=iOS Simulator,id=084650A8-FA75-4093-9626-0C9E5AD36908' \
  -only-testing:INSCENEWorkbenchTests/WorkbenchViewModelTests \
  -only-testing:INSCENEWorkbenchTests/AppRouterTests
```

Observed expected failure before production implementation:

```text
cannot find type 'WorkbenchViewModel' in scope
** TEST FAILED **
```

The UI test was written before the replacement and named the supplied identifiers: absent hero image, exact brand symbol, search, Settings, all four Immediate Tools, Continue Workflow, delivery checklist, and native quick detail.

### Additional RED cycles

- Typed sheet presentation: `AppRouter` had no `present` method or `presentedWorkbenchDestination`; focused build failed as expected.
- Pin ordering: `pinnedRecentStaysAheadOfNewerUnpinnedActivity()` failed against timestamp-only sorting, then passed after pinned-first ordering was implemented.
- The first UI pass found Immediate Tools unrealized below a tall fresh-state template stack. The no-project templates became a horizontal native selector and the stage rail moved after Immediate Tools, preserving hierarchy while keeping all four urgent actions in the initial accessibility tree.

### GREEN

Fresh full unit target:

```text
result: Passed
totalTestCount: 25
passedTests: 25
failedTests: 0
```

Result bundle:

```text
/Users/yoshyep/Library/Developer/Xcode/DerivedData/INSCENEWorkbench-dovnfwxrolgafegtzarhmumuuprl/Logs/Test/Test-INSCENEWorkbench-2026.08.10_05-10-10--0700.xcresult
```

Fresh Workbench UI class:

```text
result: Passed
totalTestCount: 4
passedTests: 4
failedTests: 0
```

Result bundle:

```text
/Users/yoshyep/Library/Developer/Xcode/DerivedData/INSCENEWorkbench-dovnfwxrolgafegtzarhmumuuprl/Logs/Test/Test-INSCENEWorkbench-2026.08.10_05-13-59--0700.xcresult
```

## Quick / Professional, bilingual, and platform behavior

- Quick and Professional resolve the same repository stage/tool IDs. Quick uses the first short task or first three detail items; Professional expands the same record's professional steps.
- Stage and tool prose is always resolved from bundled `LocalizedText`; Home chrome and three local template names have complete English and Simplified Chinese catalog/local values.
- The 89-key catalog has zero missing English or Chinese values after Task 5 additions.
- Visible Ripple Delete keycaps derive from the repository and switch between `Shift + Delete` on Mac and `Shift + Backspace` on Windows.
- Language and appearance read the existing live `SettingsStore`, so Chinese/English and System/Dark/Light refresh without duplicating guide content or user data.

## Accessibility and design evidence

- Exact `BrandSymbol` asset remains on a white symbol surface with `brand.symbol`; no substitute mark or handcrafted SVG exists.
- Simulator screenshots were visually inspected in Chinese dark and English light appearance. Both preserve hierarchy and contrast; material is confined to search/system navigation.
- All custom interactions use native `Button`, `List`, `Sheet`, `NavigationStack`, `ProgressView`, swipe actions, SF Symbols, and semantic Dynamic Type fonts.
- Custom actions are at least 44 points; StageBadge uses icon + text status, and completion/attention/risk use green/checkmark, yellow/target, and red/warning semantics rather than color alone.
- VoiceOver identifiers cover logo, search, Settings, actions, templates, stages, project tools, and routed details. The no-photo UI assertion passes.
- Source audit found no production `workbench.hero.cover`, `AsyncImage`, PhotosUI, WebView/WKWebView, URLSession, telemetry, or analytics reference.

## Simulator build and Task 5 gate

Fresh simulator build:

```bash
xcodebuild build -quiet -project INSCENEWorkbench.xcodeproj -scheme INSCENEWorkbench \
  -destination 'platform=iOS Simulator,id=084650A8-FA75-4093-9626-0C9E5AD36908'
```

Result: exit 0.

The full Task 5 scheme gate was invoked exactly once after focused verification and build:

```bash
xcodebuild test -quiet -project INSCENEWorkbench.xcodeproj -scheme INSCENEWorkbench \
  -destination 'platform=iOS Simulator,id=084650A8-FA75-4093-9626-0C9E5AD36908' \
  -parallel-testing-enabled NO
```

Gate bundle:

```text
/Users/yoshyep/Library/Developer/Xcode/DerivedData/INSCENEWorkbench-dovnfwxrolgafegtzarhmumuuprl/Logs/Test/Test-INSCENEWorkbench-2026.08.10_05-15-12--0700.xcresult
```

Gate result: 30 passed, 2 pre-existing Settings UI tests failed. The failure hierarchy showed the app starting in externally forced English/light test defaults from the manual appearance screenshot (`Simplified Chinese`, English tab labels), so the longer English Settings rows left identifiers below the lazy Form viewport. This was simulator preference pollution, not a Workbench or Settings production regression. After booting the simulator, deleting the externally written `com.inscene.davinciworkbench.ui-testing` domain, and rerunning only the affected Settings class, all 3/3 passed:

```text
/Users/yoshyep/Library/Developer/Xcode/DerivedData/INSCENEWorkbench-dovnfwxrolgafegtzarhmumuuprl/Logs/Test/Test-INSCENEWorkbench-2026.08.10_05-18-10--0700.xcresult
```

Per the explicit “Task 5 gate once” instruction, the full gate was not invoked a second time. This environment-specific gate artifact is the only concern.

## Files

- `INSCENEWorkbench/App/AppEnvironment.swift`
- `INSCENEWorkbench/App/AppRouter.swift`
- `INSCENEWorkbench/App/INSCENEWorkbenchApp.swift`
- `INSCENEWorkbench/App/RootTabView.swift`
- `INSCENEWorkbench/Components/StageBadge.swift`
- `INSCENEWorkbench/Components/ToolActionButton.swift`
- `INSCENEWorkbench/Features/Workbench/WorkbenchView.swift`
- `INSCENEWorkbench/Features/Workbench/WorkbenchViewModel.swift`
- `INSCENEWorkbench/Resources/Localizable.xcstrings`
- `INSCENEWorkbenchTests/AppRouterTests.swift`
- `INSCENEWorkbenchTests/WorkbenchViewModelTests.swift`
- `INSCENEWorkbenchUITests/WorkbenchNavigationUITests.swift`

## Concerns

- The one full-scheme gate artifact is red only because of simulator preferences deliberately changed for visual inspection; the affected class is green after external-domain cleanup. Parent review should run its normal clean-environment gate.
- Template selection currently routes to typed local template context; project creation/progression belongs to the later workflow implementation task and was not implemented early.
