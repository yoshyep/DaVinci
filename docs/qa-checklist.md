# INSCENE DaVinci Workbench iOS — QA Checklist

## Build Verification
- [x] `xcodebuild build` succeeds on iPhone 17 Pro simulator (iOS 26.5)
- [x] No compiler warnings introduced by app code
- [x] All unit tests pass (75+ tests)
- [x] All UI tests pass (20+ tests including accessibility smoke tests)

## Four-Tab Navigation
- [x] Workbench tab shows tool-first hierarchy without photography
- [x] Quick Lookup tab shows search field and shortcut center
- [x] Workflows tab shows project sessions and templates
- [x] Library tab shows content filters and searchable records
- [x] No "Learning" tab exists

## Settings
- [x] Language switch (Simplified Chinese / English) works live
- [x] Content level switch (Quick / Professional) works
- [x] Platform switch (Mac / Windows) updates keycaps
- [x] Appearance switch (System / Dark / Light) works
- [x] Export button is enabled and produces shareable JSON
- [x] Import button is enabled and validates before importing
- [x] Clear History button shows confirmation
- [x] Reset Progress button shows confirmation
- [x] Delete All button shows confirmation
- [x] All local data operations are bilingual

## Accessibility
- [x] All interactive controls have non-empty accessibility labels
- [x] All buttons meet 44x44 pt minimum touch target
- [x] Tab bar items have accessible labels in both languages
- [x] Settings controls have accessibility identifiers
- [x] Workbench quick tools have accessibility identifiers
- [x] Library items have accessibility identifiers
- [x] Content detail actions have accessibility identifiers
- [x] Source badges include text, not color alone
- [x] Stage badges use WCAG-compliant contrast (verified by StageContrastTests)
- [x] Delivery checklist speaks distinct completed/pending VoiceOver values

## Localization
- [x] All 115+ interface strings have complete zh-Hans and en values
- [x] Content records have bilingual titles and summaries
- [x] Error messages are bilingual
- [x] Confirmation alerts are bilingual
- [x] Empty states are bilingual

## Library
- [x] Filters for all content kinds: stages, playbooks, recipes, color passes, exports, emergencies, shortcuts
- [x] Favorites filter shows user-favorited content
- [x] Notes filter shows content with user notes
- [x] Content detail supports favorite toggle
- [x] Content detail supports note creation
- [x] Content detail supports share sheet
- [x] Content detail supports add-to-project
- [x] Content detail shows 30-second explanation
- [x] Content detail shows deeper principle
- [x] Playbook detail shows source link

## Import/Export
- [x] Round-trip export/import preserves projects, notes, favorites, and settings
- [x] Duplicate IDs in import data leave destination untouched
- [x] Unsupported schema version is rejected
- [x] Empty archive imports cleanly
- [x] Two-phase validation: no mutation before validation succeeds

## Spotlight Integration
- [x] All bundled content records indexed (no user notes or media data)
- [x] Spotlight items have valid deep-link identifiers
- [x] All content kinds represented in Spotlight projection

## App Intents
- [x] OpenQuickLookupIntent opens Quick Lookup tab
- [x] ContinueWorkflowIntent opens Workflows tab
- [x] OpenDeliveryChecklistIntent opens Workflows tab
- [x] Intents only open in-app destinations, do not execute Resolve actions

## Widget (requires Widget Extension target)
- [x] Widget source files created (INSCENEQuickToolsWidget.swift, QuickToolsProvider.swift)
- [ ] Widget Extension target added in Xcode (manual step)
- [ ] Widget shows current project's next checklist item (medium size)
- [ ] Widget shows four favorite tools (small size)
- [ ] Widget deep links use inscene:// scheme

## Deep Links
- [x] inscene://workbench opens Workbench tab
- [x] inscene://lookup/{id} opens Quick Lookup with content detail
- [x] inscene://workflows opens Workflows tab
- [x] inscene://library opens Library tab
- [ ] URL scheme registered in Info.plist (requires Xcode project modification)

## Brand Assets
- [x] BrandSymbol uses exact user-supplied SVG
- [x] INSCENEHorizontal uses exact user-supplied SVG
- [x] App icon generated from symbol SVG
- [x] No hero photography on Home screen
- [x] Logo symbol centers artwork at 60% of its square

## Data Privacy
- [x] All user data stored locally on device
- [x] No iCloud, CloudKit, accounts, analytics, or remote sync
- [x] No third-party runtime dependencies
- [x] Settings use only local UserDefaults
