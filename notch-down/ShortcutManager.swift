//
//  ShortcutManager.swift
//  NotchDown
//
//  Created to handle global keyboard shortcuts.
//

import Foundation
import Carbon
import AppKit

/// Singleton manager for registering and handling global keyboard shortcuts
final class ShortcutManager {
    static let shared = ShortcutManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    /// Registers a global hotkey for Shift + Ctrl + U. Safe to call twice.
    func registerGlobalShortcut() {
        guard hotKeyRef == nil else { return }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        // A C callback for Carbon: it cannot capture context, so it just posts.
        let handler: EventHandlerUPP = { _, _, _ -> OSStatus in
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .expandDynamicIsland, object: nil)
            }
            return noErr
        }

        let dispatcher = GetEventDispatcherTarget()
        InstallEventHandler(dispatcher, handler, 1, &eventType, nil, &eventHandler)

        let hotKeyID = EventHotKeyID(signature: fourCharCode("NTCH"), id: 1)
        let modifiers = UInt32(shiftKey | controlKey)
        RegisterEventHotKey(UInt32(kVK_ANSI_U), modifiers, hotKeyID, dispatcher, 0, &hotKeyRef)
    }
}

extension Notification.Name {
    static let expandDynamicIsland = Notification.Name("expandDynamicIsland")
    /// Posted for an outside click or Esc; collapses an open island.
    static let collapseDynamicIsland = Notification.Name("collapseDynamicIsland")
}

/// Packs a four-character ASCII string into an OSType.
private func fourCharCode(_ value: String) -> OSType {
    value.utf8.prefix(4).reduce(0) { ($0 << 8) | OSType($1) }
}
