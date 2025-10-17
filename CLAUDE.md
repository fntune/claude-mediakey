# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**mediakey** is a zero-dependency Swift CLI utility and Claude Code plugin that programmatically sends system-level media key events on macOS. The 55KB binary controls any media player (YouTube, Spotify, Apple Music, etc.) without switching focus or requiring external dependencies.

The project includes a full Claude Code plugin with pre-configured hooks and slash commands for automatic media control during coding sessions.

## Build and Test Commands

```bash
# Build binary
make build              # Compiles mediakey.swift to ./mediakey

# Test locally
make test               # Builds and tests play/pause (requires media playing)
./mediakey playpause    # Manual test

# Control commands
./mediakey enable       # Enable media control hooks
./mediakey disable      # Disable media control hooks
./mediakey status       # Check current state

# Clean
make clean              # Removes build artifacts

# For plugin installation
./install.sh            # Called by SessionStart hook on first run
```

## Architecture

### Project Structure

```
mediakey/
├── .claude-plugin/
│   └── plugin.json         # Claude Code plugin manifest
├── commands/
│   └── media.md            # /media slash command
├── hooks/
│   └── hooks.json          # Pre-configured hooks for media control
├── mediakey.swift          # Core implementation
├── Makefile                # Build system
├── CLAUDE.md               # This file
├── PLUGIN.md               # Plugin developer documentation
└── README.md               # User documentation
```

### Core Implementation (mediakey.swift)

**Single-file architecture** with three main components:

1. **postMediaKey(key:)** - System event generator
   - Creates `NSEvent.systemDefined` events with subtype 8 (media controls)
   - Encodes key code in data1: `(key << 16) | ((down ? 0xa : 0xb) << 8)`
   - Posts to `kCGHIDEventTap` - the same low-level tap used by physical keyboard
   - 10ms delay (`usleep(10000)`) ensures event processing before function returns

2. **Enable/Disable state management**
   - State file: `.mediakey_enabled` (current working directory - per-project)
   - Functions: `isEnabled()`, `setEnabled()`
   - Default: disabled (opt-in)
   - Commands exit silently when disabled
   - Uses `FileManager.default.currentDirectoryPath` for per-directory state

3. **Command-line parser** - Maps strings to key codes
   - Media commands: play, pause, playpause, next, prev, volup, voldown
   - Control commands: enable, disable, status
   - Case-insensitive command matching

### Key Technical Details

**Media Key Codes** (from IOKit's `ev_keymap.h`):
- `16` = Play/Pause (NX_KEYTYPE_PLAY)
- `17` = Next (NX_KEYTYPE_NEXT)
- `18` = Previous (NX_KEYTYPE_PREVIOUS)
- `0` = Volume Up (NX_KEYTYPE_SOUND_UP)
- `1` = Volume Down (NX_KEYTYPE_SOUND_DOWN)

**Event Structure**:
- Type: `NSEventTypeSystemDefined` (not regular key events)
- Subtype: `8` (NX_SUBTYPE_AUX_CONTROL_BUTTONS)
- Flags: `0xa00` (key down) / `0xb00` (key up)
- data1: `(keyCode << 16) | (pressFlag << 8)`
- Posts to: `.cghidEventTap` (system-level event tap)

**Why this works**: Simulates hardware media key events at the HID system level, bypassing application-specific controls. This is why it works universally across browsers, native apps, etc.

## Making Changes

### Adding New Key Codes

1. Find key code constant in IOKit's `ev_keymap.h`
2. Add constant at top: `let NX_KEYTYPE_NAME: UInt32 = <code>`
3. Add command mapping in `commands` dictionary

### Modifying Event Timing

The `usleep(10000)` delay (10ms) ensures events are processed before the program exits. Removing this can cause events to be dropped. Increasing it adds latency but may improve reliability on slower systems.

### Testing Changes

Since this controls system-level events, testing requires:
1. Media must be playing/paused before testing
2. Run `make test` or `./mediakey playpause` and observe behavior
3. No unit tests possible - this is integration testing by nature

## Claude Code Plugin Integration

### Plugin Installation

Users can install mediakey as a Claude Code plugin:
```bash
/plugin install fntune/claude-mediakey
```

This automatically:
1. Clones the repository to `~/.claude/plugins/marketplaces/claude-mediakey/`
2. Registers hooks from `hooks/hooks.json`
3. Adds `/media` slash command
4. Binary auto-builds on first session via `SessionStart` hook

### Self-Contained Architecture

**Binary stays in the plugin directory** - no system-wide installation:
- Binary: `~/.claude/plugins/marketplaces/claude-mediakey/mediakey`
- State: `.mediakey_enabled` in each project directory (per-directory state)
- No PATH modification required
- Hooks reference full path to plugin directory

**Per-Directory State:**
- Each project has its own `.mediakey_enabled` file
- Enables independent control across multiple projects
- Parallel Claude Code sessions don't interfere with each other

**Benefit**: Uninstalling the plugin removes the binary. Project state files remain but become inert.

### Pre-configured Hooks

The plugin includes four hooks (from `hooks/hooks.json`):

1. **SessionStart** - Auto-builds binary on first session if not present
2. **UserPromptSubmit** - Resumes media when user submits a prompt (Claude is working)
3. **Notification** - Pauses media when Claude needs user input (user needs to focus)
4. **Stop** - Pauses media when Claude stops responding (user needs to read)

All hooks use full paths to the plugin directory and respect the enable/disable state.

### Plugin Files

- `.claude-plugin/plugin.json` - Plugin manifest with metadata
- `.claude-plugin/marketplace.json` - Marketplace configuration
- `commands/media.md` - Documentation for the `/media` slash command
- `hooks/hooks.json` - Hook configuration for automatic media control
- `install.sh` - Build script (called by SessionStart hook)
- `PLUGIN.md` - Developer documentation for the plugin structure

## Common Use Cases

**Claude Code Plugin** - Automatic pause/resume during coding sessions

**Script Integration**:
```bash
mediakey pause && long-running-command
```

**Keyboard Shortcuts** - Use with Karabiner-Elements or macOS Shortcuts.app

## Requirements

- macOS 10.13+ (High Sierra)
- Swift compiler (Xcode Command Line Tools: `xcode-select --install`)
- No runtime dependencies (uses only system frameworks)

## Why This Approach

Alternative methods and their limitations:
1. **AppleScript** - Cannot send system media keys, only app-specific controls
2. **Python + PyObjC** - Requires external dependencies
3. **Key code 16 via CGEvent** - Doesn't work for media keys (they need NSSystemDefined events)
4. **Third-party apps** - BetterTouchTool, BeardedSpice, etc. are not zero-dependency

This implementation posts NSSystemDefined events directly to CGHIDEventTap, which is the correct low-level mechanism for media keys.
