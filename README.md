# macOS Media Key Controller

A lightweight, zero-dependency command-line utility to programmatically control media playback on macOS using system-level media key events.

## Features

- **Zero Dependencies**: Pure Swift using only system frameworks (AppKit, Foundation)
- **Small Binary**: Just 55KB standalone executable
- **Non-Disruptive**: Controls media without switching windows or focus
- **Universal**: Works with any media player that responds to system media keys (YouTube in browsers, Spotify, Apple Music, etc.)

## How It Works

Sends `NSSystemDefined` events with subtype 8 (media controls) directly to the system event tap (`kCGHIDEventTap`), simulating physical keyboard media key presses at the system level.

## Installation

### Quick Install

```bash
git clone https://github.com/YOUR_USERNAME/macos-mediakey.git
cd macos-mediakey
make install
```

This will:
1. Compile the Swift binary
2. Install to `~/bin/mediakey`
3. Add `~/bin` to your PATH (if needed)

### Manual Build

```bash
swiftc mediakey.swift -o mediakey
./mediakey playpause
```

## Usage

```bash
mediakey playpause   # Toggle play/pause
mediakey play        # Play (same as playpause)
mediakey pause       # Pause (same as playpause)
mediakey next        # Next track
mediakey prev        # Previous track
mediakey volup       # Volume up
mediakey voldown     # Volume down
```

## Use Cases

### Command Line

```bash
# Pause before running a long task
mediakey pause && npm run build

# Control music from scripts
mediakey next
```

### Claude Code Hooks

Automatically pause media when you start chatting and resume when finished:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/bin/mediakey play"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/bin/mediakey pause"
          }
        ]
      }
    ]
  }
}
```

### Keyboard Shortcuts

Use with tools like [Karabiner-Elements](https://karabiner-elements.pqrs.org/) or macOS Shortcuts.app to bind custom key combinations.

## Requirements

- macOS 10.13+ (High Sierra or later)
- Swift compiler (included with Xcode Command Line Tools)

## Technical Details

The utility creates `NSEvent.systemDefined` events with:
- Type: `NSEventTypeSystemDefined`
- Subtype: `8` (NX_SUBTYPE_AUX_CONTROL_BUTTONS)
- data1: Encoded key code and press/release flags

Key codes:
- `16` - Play/Pause
- `17` - Next
- `18` - Previous
- `0` - Volume Up
- `1` - Volume Down

## Why Another Media Key Tool?

Existing solutions either:
1. Require Python + PyObjC dependencies
2. Need third-party apps like BetterTouchTool
3. Use AppleScript (which can't send system media keys)

This tool provides a single, self-contained binary with no runtime dependencies.

## License

MIT License - See [LICENSE](LICENSE) file for details.

## Contributing

Contributions welcome! Please open an issue or PR.

## Acknowledgments

Based on the [Stack Overflow discussion](https://stackoverflow.com/questions/11045814/emulate-media-key-press-on-mac) on emulating media key presses on macOS.
