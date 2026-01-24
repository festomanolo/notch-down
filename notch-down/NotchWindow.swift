//
//  NotchWindow.swift
//  notch-down
//
//  Created by festomanolo on 22/01/2026.
//

//
//  NotchWindow.swift
//  notch-down
//
//  Created by festomanolo on 22/01/2026.
//

import AppKit
import SwiftUI

class NotchWindowController: NSWindowController {
    
    // MARK: - Properties
    private var currentIslandState: IslandState = .collapsed
    private var morphAnimationInProgress = false
    private let windowPadding: CGFloat = 80 // Large padding for shadows and physics
    private var clickOutsideMonitor: Any?
    
    convenience init(rootView: AnyView) {
        let window = NotchPanel(rootView: rootView)
        self.init(window: window)
        setupClickOutsideMonitor()
    }
    
    deinit {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    private func setupClickOutsideMonitor() {
        clickOutsideMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            guard let self = self, let window = self.window, window.isVisible else { return event }
            
            // Only collapse if we are expanded and clicking outside the ACTUAL island bounds
            if self.currentIslandState != .collapsed {
                let locationInWindow = event.locationInWindow
                let view = window.contentView
                
                // Check if the click is within any subview of the window
                if let hitView = view?.hitTest(locationInWindow) {
                    // Click is inside a view, don't collapse
                    return event
                }
                
                // If we get here, the click might be in the transparent padding area
                // We'll only collapse if the click is truly distant or if the window loses focus
                NotificationCenter.default.post(name: Notification.Name("CollapseDynamicIsland"), object: nil)
            }
            return event
        }
    }
    
    func show() {
        showWithMorphAnimation()
    }
    
    func showWithMorphAnimation() {
        guard let window = window, let screen = NSScreen.main else { return }
        guard !morphAnimationInProgress else { return }
        
        morphAnimationInProgress = true
        
        let screenWidth = screen.frame.width
        let screenHeight = screen.frame.height
        let safeAreaTop = screen.safeAreaInsets.top
        let topPadding = safeAreaTop > 0 ? safeAreaTop : 32
        
        let contentSize = MorphingGeometry.calculateFrame(for: .expanded)
        let windowSize = CGSize(width: contentSize.width + (windowPadding * 2), height: contentSize.height + (windowPadding * 2))
        
        let finalY = screenHeight - topPadding - contentSize.height - 8 - windowPadding
        let finalX = (screenWidth - windowSize.width) / 2
        let finalFrame = NSRect(x: finalX, y: finalY, width: windowSize.width, height: windowSize.height)
        
        let startY = screenHeight - topPadding + 10 - windowPadding
        let startFrame = NSRect(x: finalX, y: startY, width: windowSize.width, height: windowSize.height)
        
        window.setFrame(startFrame, display: false)
        window.alphaValue = 0.0
        window.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.45
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.34, 1.56, 0.64, 1.0)
            
            window.animator().setFrame(finalFrame, display: true)
            window.animator().alphaValue = 1.0
        }) { [weak self] in
            self?.morphAnimationInProgress = false
            self?.currentIslandState = .expanded
        }
    }
    
    func updateWindowFrame(for state: IslandState, animated: Bool = true) {
        guard let window = window, let screen = NSScreen.main else { return }
        
        let screenWidth = screen.frame.width
        let screenHeight = screen.frame.height
        let safeAreaTop = screen.safeAreaInsets.top
        let topPadding = safeAreaTop > 0 ? safeAreaTop : 32
        
        let contentSize = MorphingGeometry.calculateFrame(for: state)
        let windowSize = CGSize(width: contentSize.width + (windowPadding * 2), height: contentSize.height + (windowPadding * 2))
        
        let newX = (screenWidth - windowSize.width) / 2
        let newY = screenHeight - topPadding - contentSize.height - 8 - windowPadding
        let newFrame = NSRect(x: newX, y: newY, width: windowSize.width, height: windowSize.height)
        
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.5
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.34, 1.56, 0.64, 1.0)
                window.animator().setFrame(newFrame, display: true)
            }
        } else {
            window.setFrame(newFrame, display: true)
        }
        
        currentIslandState = state
    }
    
    /// Handles critical expansion for urgency states (T-minus 1 minute or 10 seconds)
    func handleCriticalExpansion() {
        guard currentIslandState == .collapsed || currentIslandState == .collapsing else { return }
        
        // Use spring animation for critical expansion
        updateWindowFrame(for: .critical, animated: true)
        
        // Add urgency visual feedback
        if let window = window {
            // Subtle shake effect for critical state
            let originalFrame = window.frame
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.1
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                
                // Small shake offset
                let shakeFrame = NSRect(
                    x: originalFrame.minX + 2,
                    y: originalFrame.minY,
                    width: originalFrame.width,
                    height: originalFrame.height
                )
                window.animator().setFrame(shakeFrame, display: true)
            } completionHandler: {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.1
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    
                    window.animator().setFrame(originalFrame, display: true)
                }
            }
        }
    }
    
    func updateScreen(_ screen: NSScreen) {
        let contentSize = MorphingGeometry.calculateFrame(for: currentIslandState)
        let windowSize = CGSize(width: contentSize.width + (windowPadding * 2), height: contentSize.height + (windowPadding * 2))
        
        let screenWidth = screen.frame.width
        let screenHeight = screen.frame.height
        let safeAreaTop = screen.safeAreaInsets.top
        let topPadding = safeAreaTop > 0 ? safeAreaTop : 32
        
        let newX = screen.frame.origin.x + (screenWidth - windowSize.width) / 2
        let newY = screen.frame.origin.y + screenHeight - topPadding - contentSize.height - 8 - windowPadding
        let newFrame = NSRect(x: newX, y: newY, width: windowSize.width, height: windowSize.height)
        
        window?.setFrame(newFrame, display: true)
    }
    
    func hide() {
        guard let window = window, let screen = NSScreen.main else { return }
        guard !morphAnimationInProgress else { return }
        
        morphAnimationInProgress = true
        
        let screenHeight = screen.frame.height
        let safeAreaTop = screen.safeAreaInsets.top
        let topPadding = safeAreaTop > 0 ? safeAreaTop : 32
        let currentFrame = window.frame
        
        let targetY = screenHeight - topPadding + 10 - windowPadding
        let targetFrame = NSRect(x: currentFrame.minX, y: targetY, width: currentFrame.width, height: currentFrame.height)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 1.0, 1.0)
            window.animator().setFrame(targetFrame, display: true)
            window.animator().alphaValue = 0
        }) { [weak self] in
            window.orderOut(nil)
            self?.morphAnimationInProgress = false
            self?.currentIslandState = .collapsed
        }
    }
}

class NotchPanel: NSPanel {
    init(rootView: AnyView) {
        let hostingController = NSHostingController(rootView: rootView.padding(80)) // Add padding in SwiftUI too
        
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 280), // Larger base size
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.contentViewController = hostingController
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        self.backgroundColor = .clear
        self.hasShadow = false
        self.isOpaque = false
    }
}
