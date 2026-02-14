import AppKit
import Combine
import SwiftUI

@MainActor
class StatusBarController {
    private var statusItem: NSStatusItem
    private var monitor: PingMonitor
    private var popover: NSPopover
    private var statusCancellable: AnyCancellable?
    private var eventMonitor: Any?

    init(monitor: PingMonitor) {
        self.monitor = monitor
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = NSPopover()

        popover.contentSize = NSSize(width: 320, height: 460)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: StatusDetailView(monitor: monitor))

        if let button = statusItem.button {
            updateIcon(status: .down)
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        let monitorRef = monitor
        statusCancellable = monitorRef.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self = self else { return }
                    self.updateIcon(status: self.monitor.status)
                }
            }

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            MainActor.assumeIsolated {
                if let self = self, self.popover.isShown {
                    self.popover.performClose(nil)
                }
            }
        }
    }

    deinit {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }

    private func updateIcon(status: ConnectionStatus) {
        guard let button = statusItem.button else { return }

        let iconSize: CGFloat = 18
        let image = NSImage(size: NSSize(width: iconSize, height: iconSize), flipped: false) { _ in
            let dotSize: CGFloat = 10
            let dotRect = NSRect(
                x: (iconSize - dotSize) / 2,
                y: (iconSize - dotSize) / 2,
                width: dotSize,
                height: dotSize
            )
            let path = NSBezierPath(ovalIn: dotRect)
            status.color.setFill()
            path.fill()
            return true
        }
        image.isTemplate = false
        button.image = image
        button.toolTip = "StatusDot — \(status.label)"
    }

    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
