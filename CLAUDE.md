# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Discipline Tracker is a local-first iOS 26 app (Swift 6.2, strict concurrency) for daily goal tracking with streak mechanics. It includes a WidgetKit extension for home screen interaction.

## Build & Development

The project uses **XcodeGen** — `project.yml` is the source of truth for the Xcode project. Always regenerate after modifying `project.yml`:

```bash
xcodegen generate
```

Build and run via Xcode (scheme: `DisciplineTracker`, target device: iOS simulator or physical device).

Run all tests:
```bash
xcodebuild test -scheme DisciplineTracker -destination 'platform=iOS Simulator,name=iPhone 16'
```

Run a single test suite (Swift Testing framework):
```bash
xcodebuild test -scheme DisciplineTracker -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:DisciplineTrackerTests/ConfigurationLoaderTests
```

## Architecture

Clean Architecture with strict layer separation:

```
DisciplineTracker/
├── App/              # Entry point, RootView (TabView), environment injection
├── Domain/
│   ├── Entities/     # ObjectiveDefinition (pure Swift, no framework deps)
│   ├── ValueObjects/ # DayCompletionState, StreakSnapshot, CompletionSource, ObjectiveStatus
│   ├── UseCases/     # GetTodayObjectivesUseCase, ToggleObjectiveUseCase, ComputeStatsUseCase
│   ├── Rules/        # StreakCalculator, PerfectDayCalculator (pure logic)
│   └── Services/     # DayStateService (single source of truth), GitHubSyncService
├── Data/
│   ├── Config/       # AppConfiguration, ConfigurationLoader (JSON → domain structs)
│   └── Persistence/
│       ├── SwiftDataModels/  # DayRecordModel, ObjectiveDayStatusModel (@Model)
│       └── Repositories/    # DayRecordRepository, DayRecordRepositoryProtocol
├── Features/
│   ├── Home/         # Today's objectives + streak header
│   ├── Calendar/     # Monthly calendar + day detail (retroactive editing)
│   ├── Stats/        # Heatmap, streak cards, per-objective stats
│   └── Settings/     # GitHub token, notifications
└── Shared/
    ├── Extensions/   # Date+Helpers, Color+Accent
    ├── Utils/        # WidgetDataProvider, HapticManager
    └── Errors/       # AppError
DisciplineTrackerWidget/  # WidgetKit extension (small + medium families)
```

### Key Design Decisions

**`DayStateService`** (`@MainActor @Observable`) is the central state coordinator injected via `@Environment`. All views read from it; never bypass it for state mutations. Call `load(context:)` on app launch and scene activation.

**Objective configuration** lives in `DisciplineTracker/Resources/objectives.json` (bundled). The schema is `AppConfiguration` with `objectives[]` and `notifications`. Two objective types: `manualBinary` (user toggles) and `githubAuto` (automated via GitHub API). Adding a new objective type requires changes to `ObjectiveDefinition`, `ToggleObjectiveUseCase`, and `GitHubSyncService`.

**Widget ↔ App sync** uses App Group `group.com.discipline.tracker` via `WidgetDataProvider` (serializes to `UserDefaults`). On scene activation, `DayStateService.syncWidgetChanges(context:)` merges widget-side toggles back into SwiftData. Only `manualBinary` objectives are togglable from the widget.

**SwiftData models** (`DayRecordModel`, `ObjectiveDayStatusModel`) are persistence-only — never passed to the UI layer. Views receive domain value types (`ObjectiveDefinition`, `StreakSnapshot`, etc.) from `DayStateService`.

**GitHub token** is stored in Keychain via `KeychainHelper(service: "com.discipline.tracker")`, key `"github_token"`.

## iOS 26 / Swift 6.2 Notes

- `SWIFT_STRICT_CONCURRENCY: complete` — all code must be concurrency-safe
- `GlassEffect` and `GlassEffectContainer` are iOS 26 Liquid Glass APIs used throughout the UI
- Tests use the **Swift Testing** framework (`@Suite`, `@Test`, `#expect`) — not XCTest
- Deployment target is iOS 26.0 only
