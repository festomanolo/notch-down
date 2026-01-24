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
class ShortcutManager {
    static let shared = ShortcutManager()
    
    /// Registers a global hotkey for Shift + Ctrl + U
    func registerGlobalShortcut() {
        var hotKeyRef: EventHotKeyRef?
        var eventHandler: EventHandlerRef?
        let eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        // Define the handler as a traditional C-style callback for Carbon
        let handler: EventHandlerUPP = { (_, _, _) -> OSStatus in
            NotificationCenter.default.post(name: .expandDynamicIsland, object: nil)
            return noErr
        }
        
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, [eventType], nil, &eventHandler)
        
        let hotKeyID = EventHotKeyID(signature: fourCharCode("NTCH"), id: 1)
        let modifiers = UInt32(shiftKey | controlKey)
        let keyCode = UInt32(kVK_ANSI_U)
        
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
}

extension Notification.Name {
    static let expandDynamicIsland = Notification.Name("expandDynamicIsland")
}

/// Helper function to create OSType from String
func fourCharCode(_ value: String) -> OSType {
    var result: OSType = 0
    if let data = value.data(using: .ascii) {
        for byte in data {
            result = (result << 8) | OSType(byte)
        }
    }
    return result
}

func OSType(_ value: Int) -> OSType {
    return UInt32(value)
}
