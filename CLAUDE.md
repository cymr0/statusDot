# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

StatusDot is a native macOS menu bar application (Swift/SwiftUI) that monitors network connectivity by periodically pinging configurable hosts and displaying connection quality via a color-coded dot in the menu bar.

## Build Commands

```bash
swift build                # Debug build
swift build -c release     # Release build
swift test                 # Run tests (Swift Testing framework)
swiftlint lint             # Lint (config in .swiftlint.yml)
```

Run the built executable directly: `.build/arm64-apple-macosx/debug/StatusDot`

## Architecture

The app uses Swift Package Manager (Swift 6.2, macOS 14+) with zero external dependencies — only Apple system frameworks (AppKit, SwiftUI, Charts, Observation, Foundation).

**Core flow**: `StatusDotApp` (entry point/AppDelegate) → `StatusBarController` (manages NSStatusItem + popover) → `PingMonitor` (uses `PingExecutor` protocol, tracks 120-sample history) → SwiftUI views render in the popover.

**Key components**:
- `PingMonitor` — `@MainActor` `@Observable` class. Takes a `PingExecutor` via init (defaults to `ProcessPingExecutor`). Parses latency with regex, determines `ConnectionStatus` from thresholds. Persists history to UserDefaults with stale-entry filtering (10 min cutoff). Uses named constants `statsWindow` (20) and `statusWindow` (12) for sample windows.
- `PingExecutor` — Protocol for ping execution. `ProcessPingExecutor` spawns `/sbin/ping`; tests inject a `MockPingExecutor`.
- `StatusBarController` — Bridges AppKit (NSStatusBar) with SwiftUI (NSHostingController in NSPopover). Renders the colored 10x10px dot icon.
- `AppSettings` — UserDefaults-backed settings (hosts list, ping interval). `isValidHost` is `nonisolated` (pure function).
- `PingResult` — `Codable` struct with optional `FailureReason` enum (`.timeout` / `.processError`) for diagnostic display.
- `ConnectionStatus` — Enum with color mappings and shared threshold constants. Lives in its own file.

**Views** (all SwiftUI, under `Sources/Views/`):
- `StatusDetailView` — Main popover with animated push transitions. Shows a loading spinner when history is empty. Dynamic chart label derived from ping interval.
- `LatencyGraphView` — Swift Charts bar chart, always padded to 60 slots for consistent bar widths.
- `SettingsView` — Host management with inline validation feedback, and ping interval selection.
- `StatCard` — Reusable stat display component.

**Keyboard shortcuts**: Cmd+Q quits, Cmd+, toggles settings (works because both views bind the same shortcut).

**Status thresholds**: excellent (<50ms), good (<100ms), degraded (<200ms or 20-50% loss), poor (≥200ms or >50% loss), down (100% loss).

## Tests

Tests use the Swift Testing framework (`Tests/` directory, 22 tests across 4 suites). `PingMonitor` tests inject `MockPingExecutor` to avoid spawning real processes. `parsePingLatency` and `recordResult` are `internal` to support `@testable import`. Stale history filtering and failure reason preservation are tested explicitly.

## Logging

Uses `os.Logger` (subsystem: "StatusDot"). Logs Process failures, JSON encode/decode errors. View in Console.app.
