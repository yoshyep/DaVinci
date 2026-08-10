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

## Review Fix Round 1/5 — 2026-08-10

### Outcome

- Modifier normalization is token-aware: exact `Opt`/`Option`/`Alt`/`⌥`, `Cmd`/`Command`/`⌘`, and `Ctrl`/`Control`/`⌃` forms canonicalize without corrupting words such as `optional`.
- English aliases now require token/phrase boundaries, preventing `fuse` from matching `confused`; CJK intent aliases retain intentional containment behavior.
- Search bodies use only localized human-facing fields. An injected playbook fixture proves an opaque source ID cannot produce a result while its title and step detail do.
- Checklist, favorite, and recent mutations share one save-or-rollback boundary with dependency-injected failure behavior and localized, user-visible save errors. Checklist insertion is idempotent and preserves existing completion.
- Favorite mutation enforces one-per-content operationally: insertion is idempotent and removal deletes every pre-existing duplicate in the same transaction.
- Generic related shortcuts are 44-point native `KeycapView` buttons with action labels and spoken keycap semantics; their typed routes open the exact shortcut detail.
- A production Workbench recent-content row calls `openQuickLookup(contentID:)`; UI coverage proves the tab switch and exact detail/keycap destination.

### Strict RED → GREEN evidence

- Modifier literals first failed because `Option` normalized to `optionion`; the focused test now covers every listed spelling/symbol plus a non-modifier word.
- `confused` initially returned the `fuse` alias fixture; intended English phrase and Chinese containment assertions stayed paired with the false-positive assertion.
- The injected expert playbook initially matched its source ID; the same fixture verifies that human title and detail remain searchable after source metadata is excluded.
- State tests were added before `LocalUserStateMutator` existed (compile RED), then exercised completed-checklist preservation, repeated insertion, duplicate-favorite cleanup, and real failing-save rollback for checklist/favorite/recent using an injected boundary.
- Related-shortcut and Workbench cross-tab UI tests first failed on missing identifiers/routes, then passed after the production controls used typed lookup navigation.

GREEN verification:

```text
Focused SearchEngine + state + router + session tests: 25/25 passed
Quick Lookup + Workbench navigation UI suites: 12/12 passed
Fresh simulator build: exit 0
Clean full scheme gate: 64/64 passed, 0 failed, 0 skipped
```

Full gate bundle:

```text
/Users/yoshyep/Library/Developer/Xcode/DerivedData/INSCENEWorkbench-dovnfwxrolgafegtzarhmumuuprl/Logs/Test/Run-INSCENEWorkbench-2026.08.10_06-45-02--0700.xcresult
```

### Files added in this fix round

- `INSCENEWorkbench/Components/LocalMutationAlert.swift`
- `INSCENEWorkbench/Data/LocalUserStateMutator.swift`
- `INSCENEWorkbenchTests/LocalUserStateMutatorTests.swift`

### Deferred reviewer minors

- Playbook is still absent from the type filter.
- Live search still recomputes results more often than necessary.
- The pre-existing `AccentColor` asset warning remains.

## Review Fix Round 2/5 — 2026-08-10

### Outcome

- Alias boundary selection now follows the alias script, not the whole query: Latin aliases always use normalized token/phrase boundaries, including mixed Chinese/English input, while CJK aliases retain intentional containment.
- Safe human-facing `keywords` are restored for stages, recipes, color passes, exports, and emergency guides. Shortcut indexing remains platform-aware, and `ExpertPlaybook.sourceIDs` remain explicitly excluded.

### Strict RED → GREEN evidence

- RED: `aliasScriptControlsBoundariesInMixedLanguageQueries()` returned `recipe-skin` for `我很 confused`; positive mixed queries for the English phrase `fix skin` and CJK alias `修正肤色` were asserted in the same real repository.
- RED: `workflowStageHumanKeywordsRemainSearchable()` failed independently for the literal keyword `stage`, number `42`, and color tag `violet cinder marker` in an injected stage fixture.
- GREEN: the full focused `SearchEngineTests` suite passed 14/14, including the prior injected `source-secret-42` exclusion fixture.
- Simulator build completed with exit 0. No routing or UI production changed, so UI/full-gate reruns were not required for this search-only fix round.

Focused result bundle:

```text
/Users/yoshyep/Library/Developer/Xcode/DerivedData/INSCENEWorkbench-dovnfwxrolgafegtzarhmumuuprl/Logs/Test/Test-INSCENEWorkbench-2026.08.10_07-04-31--0700.xcresult
```

Deferred minors remain unchanged: playbook type-filter omission, repeated live-search recomputation, and the pre-existing missing `AccentColor` asset.
