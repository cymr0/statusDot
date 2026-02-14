# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

StatusDot is a native macOS menu bar application (Swift/SwiftUI) that monitors network connectivity by periodically pinging configurable hosts and displaying connection quality via a color-coded dot in the menu bar.

## Build Commands

```bash
swift build                # Debug build
swift build -c release     # Release build
```

Run the built executable directly: `.build/arm64-apple-macosx/debug/StatusDot`

There are no tests configured. Linting is available via SwiftLint (`swiftlint lint`).

## Architecture

The app uses Swift Package Manager (Swift 5.9+, macOS 13+) with zero external dependencies — only Apple system frameworks (AppKit, SwiftUI, Combine, Foundation).

**Core flow**: `StatusDotApp` (entry point/AppDelegate) → `StatusBarController` (manages NSStatusItem + popover) → `PingMonitor` (spawns `/sbin/ping` processes, tracks 120-sample history) → SwiftUI views render in the popover.

**Key components**:
- `PingMonitor` — `@MainActor` class using Combine `@Published` properties. Runs ping via `Process`, parses latency with regex, determines `ConnectionStatus` based on latency thresholds and packet loss percentages.
- `StatusBarController` — Bridges AppKit (NSStatusBar) with SwiftUI (NSHostingController in NSPopover). Renders the colored 10x10px dot icon.
- `AppSettings` — UserDefaults-backed settings (hosts list, ping interval).
- `Models` — `PingResult` struct and `ConnectionStatus` enum with color mappings.

**Views** (all SwiftUI, under `Sources/Views/`):
- `StatusDetailView` — Main popover: status header, stats grid, latency graph, recent pings list, settings toggle.
- `LatencyGraphView` — Canvas-based bar chart of last 60 pings, color-coded by latency bands (<50ms green, <200ms yellow, ≥200ms orange).
- `SettingsView` — Host management and ping interval selection.
- `StatCard` — Reusable stat display component.

**Status thresholds**: excellent (<50ms), good (<100ms), degraded (<200ms or 20-50% loss), poor (≥200ms or >50% loss), down (100% loss).
