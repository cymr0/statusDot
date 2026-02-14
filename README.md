# StatusDot

A lightweight macOS menu bar app that monitors your network connection by pinging configurable hosts and showing the result as a color-coded dot.

- **Green** — Excellent/Good (latency < 100ms)
- **Yellow** — Degraded (latency < 200ms or moderate packet loss)
- **Orange** — Poor (latency ≥ 200ms or high packet loss)
- **Red** — Down (no connectivity)

Click the dot to see detailed stats: current/average/min/max latency, packet loss, a latency history graph, and recent ping results.

## Requirements

- macOS 14+
- Swift 6.2+

## Build & Run

```bash
swift build
.build/arm64-apple-macosx/debug/StatusDot
```

## Install

```bash
./scripts/build-app.sh
cp -R .build/release/StatusDot.app /Applications/
```

This creates a proper `.app` bundle with `LSUIElement` set (menu bar only, no Dock icon). To launch on login, add StatusDot in **System Settings > General > Login Items**.

## Test

```bash
swift test
```

## Keyboard Shortcuts

- **Cmd+,** — Toggle settings
- **Cmd+Q** — Quit

## Configuration

Click the dot and open Settings to:

- Add or remove ping target hosts (default: `8.8.8.8`, `1.1.1.1`)
- Set the ping interval (2s, 5s, 10s, 30s, or 60s)

Invalid hosts are flagged inline with specific error messages.

Settings persist across launches via UserDefaults.
