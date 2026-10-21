//
//  NotchWindow.swift
//  notch-down
//
//  Created by festomanolo on 22/01/2026.
//

import AppKit
import SwiftUI
import Combine

/// Transparent margin around the island, giving shadows, glow and the attention
/// nudge room to render inside the window.
let notchWindowPadding: CGFloat = 80

/// Coordinate space the island reports its live frame in, for hit testing.
enum NotchCoordinateSpace {
    static let root = "NotchDownRoot"
}

/// The island's current on-screen rectangle, shared from SwiftUI down to the
/// hosting view so clicks outside it pass through to the app behind.
final class IslandHitRegion {
    var rect: CGRect = .zero
}

// MARK: - Window Controller

/// Owns the panel.
///
/// The panel's **size never changes** — see `NotchPanel`. Morphing between
/// island states is animated entirely by SwiftUI inside a fixed-size window.
///
/// This is deliberate. Animating the window frame while SwiftUI simultaneously
/// animated the island's own frame put two layout systems in a feedback loop:
/// every intermediate `-[NSView setFrameSize:]` re-entered SwiftUI's
/// invalidation, which marked the window as needing another Update Constraints
/// pass, until AppKit's watchdog raised
///
///   "…already had more Update Constraints in Window passes than there are
///    views in the window"
///
/// That NSException cannot unwind through the Swift frames it was raised
/// beneath, so it surfaced as SIGSEGV in `_Unwind_RaiseException`. Keeping the
/// frame constant removes the loop at its source; only the window *origin* is
/// ever touched, and `setFrameOrigin` triggers no resize layout at all.
@MainActor
class NotchWindowController: NSWindowController {

    private var isPresented = false
    private var outsideClickMonitor: Any?
    private var escapeKeyMonitor: Any?

    convenience init(rootView: AnyView) {
        let window = NotchPanel(rootView: rootView)
        self.init(window: window)
        reposition()
        installDismissMonitors()
    }

    /// Native popover behaviour: a click anywhere outside the island, or Esc,
    /// asks it to collapse.
    ///
    /// The global monitor sees clicks delivered to *other* apps — which
    /// includes clicks in this window's transparent margin, since hit testing
    /// passes those through. Clicks on the island itself, its menus and the
    /// status item are local events and never reach it.
    private func installDismissMonitors() {
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard self?.isPresented == true else { return }
                NotificationCenter.default.post(name: .collapseDynamicIsland, object: nil)
            }
        }

        escapeKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event } // Esc
            let handled = MainActor.assumeIsolated { () -> Bool in
                guard let window = self?.window, window.isKeyWindow else { return false }
                NotificationCenter.default.post(name: .collapseDynamicIsland, object: nil)
                return true
            }
            return handled ? nil : event
        }
    }

    // MARK: - Geometry

    /// The screen the island should live on: the one under the cursor, falling
    /// back to the main screen.
    private func activeScreen() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) })
            ?? NSScreen.main
            ?? NSScreen.screens.first
    }

    /// Places the window so the island's top edge sits just below the notch.
    func reposition(to screen: NSScreen? = nil) {
        guard let window = window, let screen = screen ?? activeScreen() else { return }

        let size = window.frame.size
        let safeAreaTop = screen.safeAreaInsets.top
        let topPadding = safeAreaTop > 0 ? safeAreaTop : 32

        let x = screen.frame.origin.x + (screen.frame.width - size.width) / 2
        // The island is top-anchored `notchWindowPadding` below the window top.
        let topEdge = screen.frame.origin.y + screen.frame.height - topPadding - 8 + notchWindowPadding
        let y = topEdge - size.height

        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    func updateScreen(_ screen: NSScreen) {
        reposition(to: screen)
    }

    // MARK: - Presentation

    /// Orders the panel in. The slide-down and fade are animated by SwiftUI
    /// against the view model's `isIslandVisible`, not by moving the window.
    /// - Parameter activating: bring the app forward and make the panel key.
    ///   Required for controls that open their own popup (the action menu, the
    ///   duration pickers), which do not respond while the app is inactive.
    ///   Passive appearances — the countdown pill, periodic peeks, the urgency
    ///   pop-out — pass `false` so the island never steals focus from whatever
    ///   the user is actually doing.
    func present(activating: Bool = false) {
        guard let window = window else { return }

        if !isPresented {
            reposition()
        }

        isPresented = true

        if activating {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            window.orderFrontRegardless()
        }
    }

    /// Orders the panel out once SwiftUI has finished animating it away.
    func dismiss() {
        isPresented = false
        window?.orderOut(nil)
    }
}

// MARK: - Hosting View

/// Hosting view that only accepts clicks on the island itself, so the
/// transparent margin around it stays click-through.
class PassThroughHostingView<Content: View>: NSHostingView<Content> {

    /// Updated from SwiftUI as the island morphs.
    var hitRegion = IslandHitRegion()

    required init(rootView: Content) {
        super.init(rootView: rootView)
        self.sizingOptions = []
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.sizingOptions = []
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let region = hitRegion.rect
        guard !region.isEmpty else { return nil }

        // `point` arrives in the *superview's* coordinate system, and the
        // borderless frame view is not flipped while this view is — so it must
        // be converted before being compared with the region SwiftUI reported.
        // Testing the raw point rejected every click on the island.
        let local = convert(point, from: superview)
        let y = isFlipped ? local.y : bounds.height - local.y

        guard region.insetBy(dx: -2, dy: -2).contains(CGPoint(x: local.x, y: y)) else { return nil }
        return super.hitTest(point)
    }

    // NOTE: do not override `needsUpdateConstraints` / `updateConstraints` to
    // suppress re-entrant invalidation. Doing so leaves AppKit's constraint
    // bookkeeping inconsistent and the NSException it raises crashes the
    // process rather than being caught. The feedback loop is prevented by
    // holding the window size constant — see NotchWindowController.
}

// MARK: - Root View

private struct IslandFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        // Both the island and the toast report, so the interactive area is
        // their union. Reduction restarts from `defaultValue` on every layout
        // pass, so a dismissed toast shrinks the region back automatically.
        let next = nextValue()
        guard !next.isEmpty else { return }
        value = value.isEmpty ? next : value.union(next)
    }
}

extension View {
    /// Reports this view's live frame up to the hosting view for hit testing.
    ///
    /// Attached outside the animation modifiers, so the region tracks the
    /// island through the morph rather than jumping to its final size.
    func reportsIslandHitRegion() -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: IslandFramePreferenceKey.self,
                    value: proxy.frame(in: .named(NotchCoordinateSpace.root))
                )
            }
        )
    }
}

/// Fixed-size container: the island is top-anchored and centred, free to morph
/// within the box without ever changing the window's own dimensions.
private struct NotchRootView: View {
    let island: AnyView
    let hitRegion: IslandHitRegion
    let size: CGSize

    var body: some View {
        VStack(spacing: 8) {
            island
            // Below the island, not stacked on top of it — as an overlay the
            // toast covered the header row's controls.
            ToastContainerView()
            Spacer(minLength: 0)
        }
        .padding(notchWindowPadding)
        .frame(width: size.width, height: size.height)
        .coordinateSpace(name: NotchCoordinateSpace.root)
        .onPreferenceChange(IslandFramePreferenceKey.self) { rect in
            hitRegion.rect = rect
        }
    }
}

// MARK: - Panel

class NotchPanel: NSPanel {

    private var themeObserver: AnyCancellable?
    /// Big enough for the largest island state plus the transparent margin.
    /// Constant for the lifetime of the window — nothing may resize it.
    static var contentSize: CGSize {
        let largest = MorphingGeometry.largestStateSize
        // Slack on top of the largest configured state: the island sizes itself
        // to its content, which may exceed the nominal figure. A larger
        // transparent box costs nothing now that hit testing is exact.
        return CGSize(
            width: largest.width + notchWindowPadding * 2 + 40,
            height: largest.height + notchWindowPadding * 2 + 160
        )
    }

    init(rootView: AnyView) {
        let size = NotchPanel.contentSize
        let hitRegion = IslandHitRegion()

        let root = NotchRootView(island: rootView, hitRegion: hitRegion, size: size)
        let hostingView = PassThroughHostingView(rootView: root)
        hostingView.hitRegion = hitRegion

        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.contentView = hostingView
        self.isFloatingPanel = true
        self.level = .statusBar
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        self.backgroundColor = .clear
        self.hasShadow = false
        self.isOpaque = false
        self.isReleasedWhenClosed = false
        self.becomesKeyOnlyIfNeeded = true
        self.hidesOnDeactivate = false
        self.animationBehavior = .none
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
