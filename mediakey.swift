#!/usr/bin/env swift
import Foundation
import AppKit

// Media key type constants
let NX_KEYTYPE_SOUND_UP: UInt32 = 0
let NX_KEYTYPE_SOUND_DOWN: UInt32 = 1
let NX_KEYTYPE_PLAY: UInt32 = 16
let NX_KEYTYPE_NEXT: UInt32 = 17
let NX_KEYTYPE_PREVIOUS: UInt32 = 18

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
    if let keyCode = commands[command] {
        postMediaKey(key: keyCode)
    } else {
        print("Unknown command: \(command)")
        print("Usage: \(CommandLine.arguments[0]) [playpause|next|prev|volup|voldown]")
        exit(1)
    }
} else {
    // Default to playpause
    postMediaKey(key: NX_KEYTYPE_PLAY)
}
