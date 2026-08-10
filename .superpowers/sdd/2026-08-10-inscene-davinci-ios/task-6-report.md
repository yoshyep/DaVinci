# Task 6 Report: Bilingual Local Search and Shortcut Center

Status: `IMPLEMENTED — focused verification and clean Task 6 gate green`

## Outcome

Replaced only the Quick Lookup placeholder with an offline-native SwiftUI tool center backed by all 115 bundled searchable records and all 61 shortcut actions. It supports live Chinese/English, Mac/Windows, Quick/Professional disclosure, recent suggestions, kind/category/stage filters, typed detail routes, favorites, copy/share, current-project checklist insertion, honest no-result suggestions, and no network/search service.

## RED → GREEN

Before production edits, `test-driven-development/SKILL.md` and `writing-good-tests.md` were read. Tests named independently derived breaks for punctuation/case/whitespace normalization, Chinese intent aliases, bilingual stable IDs, exact/alias/context relevance, active-platform keys, compound filters, non-indexed opaque IDs, and typed lookup deep links.

Initial RED:

```text
Cannot find type 'SearchEngine' in scope
** TEST FAILED **
```

The alias-vs-partial-title refinement also had a separate RED: `curatedAliasWeightBeatsTheSameRecordsPartialTitleWeight()` failed until the scorer compared all match classes instead of returning the first partial match. The platform/filter regression then caught an over-broad one-word alias match; restricting aliases to exact/phrase intent restored the expected filtered order.

GREEN evidence:

```text
SearchEngineTests + AppRouterTests: 13/13 passed
QuickLookup UI + Workbench entry: 4/4 passed
Full unit target: 38/38 passed
Fresh simulator build: exit 0
Clean Task 6 scheme gate: 52/52 passed
```

Gate bundle:

```text
/Users/yoshyep/Library/Developer/Xcode/DerivedData/INSCENEWorkbench-dovnfwxrolgafegtzarhmumuuprl/Logs/Test/Run-INSCENEWorkbench-2026.08.10_06-16-18--0700.xcresult
```

## Ranking and filtering design

- Normalization folds case, diacritics, width, punctuation, repeated whitespace, and common modifier spellings (`Cmd/⌘`, `Ctrl/⌃`, `Opt/⌥`) while preserving CJK text.
- Both localized titles, summaries, full typed details, menus, categories, active-platform keys, tags, English aliases, Chinese intent aliases, and curated common pinyin aliases are searched for every display language.
- Deterministic weights are exact title 100, curated alias 80, partial title 70, active-platform shortcut 65, menu 45, body 5; non-exact matches then receive current stage 25, recent 15, and favorite 10, capped below exact title.
- Ties use action-first kind priority and stable content ID. Internal IDs are never added to the index; the opaque-ID fixture proves this without conflating a human phrase with an ID.
- Kind, localized category, and stage constraints are intersected. No positive textual score means no result; the UI offers clickable local suggestions without fabricating an answer.

## Native keycap, detail, and accessibility evidence

- `KeycapView` is a native `Button` with visible text keycaps in Capsule/material surfaces and the action name beside them; no SVG keyboard, WebView, canvas, or remote asset is used.
- Mac/Windows changes live from `SettingsStore`; UI verification observed Ripple Delete changing from `Shift + Delete` to `Shift + Backspace` in the same stable detail route.
- VoiceOver receives the action plus expanded spoken modifier/key names (for example, “Ripple Delete, Shift plus Backspace”), an action-specific hint, and deterministic identifiers. Custom actions and controls use at least 44-point hit targets.
- Detail shows keys first, then menu, stage/category context, localized risk, related shortcuts, favorite, copy/share, and checklist insertion. Professional expands the same record with mapping/conflict/work-habit context; it does not select a duplicate record.
- Simulator visual inspection in Chinese dark mode confirmed legible hierarchy, native materials, horizontally scrollable controls, visible source/version/level badges, and all 61 actions in the Shortcut Center.

## Files

- `INSCENEWorkbench/App/AppRouter.swift`
- `INSCENEWorkbench/App/INSCENEWorkbenchApp.swift`
- `INSCENEWorkbench/App/RootTabView.swift`
- `INSCENEWorkbench/Components/KeycapView.swift`
- `INSCENEWorkbench/Data/SearchEngine.swift`
- `INSCENEWorkbench/Features/QuickLookup/QuickLookupView.swift`
- `INSCENEWorkbench/Features/QuickLookup/SearchResultView.swift`
- `INSCENEWorkbench/Features/QuickLookup/ShortcutDetailView.swift`
- `INSCENEWorkbenchTests/AppRouterTests.swift`
- `INSCENEWorkbenchTests/SearchEngineTests.swift`
- `INSCENEWorkbenchUITests/QuickLookupUITests.swift`
- `INSCENEWorkbenchUITests/WorkbenchNavigationUITests.swift`

## Concerns

- The clean build still reports the pre-existing asset-catalog warning that `AccentColor` is not present; Task 6 did not alter the catalog or build settings.
- Curated pinyin covers common high-value intents rather than attempting arbitrary runtime transliteration; full Chinese and English fields remain the primary offline index.
