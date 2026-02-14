# StatusDot

A lightweight macOS menu bar app that monitors your network connection by pinging configurable hosts and showing the result as a color-coded dot.

- **Green** — Excellent/Good (latency < 100ms)
- **Yellow** — Degraded (latency < 200ms or moderate packet loss)
- **Orange** — Poor (latency ≥ 200ms or high packet loss)
- **Red** — Down (no connectivity)

Click the dot to see detailed stats: current/average/min/max latency, packet loss, a latency history graph, and recent ping results.

## Requirements

- macOS 13+
- Swift 5.9+

## Build & Run

```bash
swift build
.build/arm64-apple-macosx/debug/StatusDot
```

## Configuration

Click the dot and open Settings to:

- Add or remove ping target hosts (default: `8.8.8.8`, `1.1.1.1`)
- Set the ping interval (2s, 5s, 10s, 30s, or 60s)

Settings persist across launches via UserDefaults.
