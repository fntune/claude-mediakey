#!/usr/bin/env swift
import Foundation
import AppKit

// Media key type constants
let NX_KEYTYPE_SOUND_UP: UInt32 = 0
let NX_KEYTYPE_SOUND_DOWN: UInt32 = 1
let NX_KEYTYPE_PLAY: UInt32 = 16
let NX_KEYTYPE_NEXT: UInt32 = 17
let NX_KEYTYPE_PREVIOUS: UInt32 = 18

// State file path - store in current working directory (per-project state)
let stateFilePath = FileManager.default.currentDirectoryPath + "/.mediakey_enabled"

// Check if mediakey is enabled
func isEnabled() -> Bool {
    // If file doesn't exist, default to disabled
    guard FileManager.default.fileExists(atPath: stateFilePath) else {
        return false
    }

    if let content = try? String(contentsOfFile: stateFilePath, encoding: .utf8) {
        return content.trimmingCharacters(in: .whitespacesAndNewlines) == "1"
    }

    return false
}

// Show macOS notification
func showNotification(title: String, message: String) {
    let script = """
    display notification "\(message)" with title "\(title)"
    """
    let task = Process()
    task.launchPath = "/usr/bin/osascript"
    task.arguments = ["-e", script]
    try? task.run()
}

// Set enabled state
func setEnabled(_ enabled: Bool) {
    let value = enabled ? "1" : "0"
    try? value.write(toFile: stateFilePath, atomically: true, encoding: .utf8)
    print("mediakey \(enabled ? "enabled" : "disabled")")

    if enabled {
        showNotification(title: "mediakey", message: "enabled")
    } else {
        showNotification(title: "mediakey", message: "disabled")
    }
}

func postMediaKey(key: UInt32) {
    func doKey(down: Bool) {
        let flags = NSEvent.ModifierFlags(rawValue: (down ? 0xa00 : 0xb00))
        let data1 = Int((key << 16) | ((down ? 0xa : 0xb) << 8))

        let event = NSEvent.otherEvent(
            with: NSEvent.EventType.systemDefined,
            location: NSPoint(x: 0, y: 0),
            modifierFlags: flags,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: data1,
            data2: -1
        )

        if let cgEvent = event?.cgEvent {
            cgEvent.post(tap: .cghidEventTap)
            // Small delay to ensure event is processed
            usleep(10000) // 10ms
        }
    }

    doKey(down: true)
    doKey(down: false)
}

// Command line handling
let commands: [String: UInt32] = [
    "playpause": NX_KEYTYPE_PLAY,
    "play": NX_KEYTYPE_PLAY,
    "pause": NX_KEYTYPE_PLAY,
    "next": NX_KEYTYPE_NEXT,
    "prev": NX_KEYTYPE_PREVIOUS,
    "previous": NX_KEYTYPE_PREVIOUS,
    "volup": NX_KEYTYPE_SOUND_UP,
    "voldown": NX_KEYTYPE_SOUND_DOWN
]

if CommandLine.arguments.count > 1 {
    let command = CommandLine.arguments[1].lowercased()

    // Handle control commands first
    if command == "enable" {
        setEnabled(true)
        exit(0)
    } else if command == "disable" {
        setEnabled(false)
        exit(0)
    } else if command == "status" {
        print("mediakey is \(isEnabled() ? "enabled" : "disabled")")
        exit(0)
    }

    // Check if enabled before sending media keys
    guard isEnabled() else {
        // Silent exit if disabled
        exit(0)
    }

    // Send media key command
    if let keyCode = commands[command] {
        postMediaKey(key: keyCode)
    } else {
        print("Unknown command: \(command)")
        print("Usage: \(CommandLine.arguments[0]) [play|pause|playpause|next|prev|volup|voldown]")
        print("       \(CommandLine.arguments[0]) [enable|disable|status]")
        exit(1)
    }
} else {
    // Default to playpause (only if enabled)
    guard isEnabled() else {
        exit(0)
    }
    postMediaKey(key: NX_KEYTYPE_PLAY)
}
