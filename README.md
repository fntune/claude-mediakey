# mediakey

> **Zero-dependency macOS media controller.** 55KB binary. Works everywhere.

Control any media player from the command line or Claude Code—pause music when you focus, resume when you're done. No window switching, no external dependencies, no configuration hassle.

```bash
mediakey pause       # Pause any media player
mediakey next        # Skip to next track
mediakey enable      # Auto-pause during Claude Code sessions
```

**Compatible with:** YouTube, Spotify, Apple Music, Safari, Chrome, and any application that responds to system media keys.

---

## Why Use This?

**The Problem:** You're coding with Claude, listening to music. Claude asks a question—you switch to pause Spotify. You answer—switch back to resume. Claude finishes—pause again. Repeat all day.

**The Solution:** mediakey automates this. Music plays while Claude works (you're waiting anyway), pauses when you need to focus (reading responses, typing). No window switching, no manual control, just natural focus cycles.

**Perfect for:**
- Long coding sessions with background music
- Podcast listeners who want silence during focus moments
- Anyone tired of CMD+Tab → Pause → CMD+Tab back to Claude
- Teams running multiple Claude Code sessions across different projects (per-directory state means no interference)

---

## Table of Contents

- [Why Use This?](#why-use-this)
- [Installation](#installation)
- [Usage](#usage)
  - [Command Reference](#command-reference)
  - [Claude Code Integration](#claude-code-integration)
  - [Scripting Examples](#scripting-examples)
- [How It Works](#how-it-works)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

---

## Installation

### Option 1: Claude Code Plugin (Recommended)

Install as a Claude Code plugin for automatic pause/resume during coding sessions:

```bash
/plugin install fntune/claude-mediakey
```

**What this does:**
1. Builds the `mediakey` binary in the plugin directory
2. Configures hooks to pause media when you submit prompts
3. Adds the `/media` slash command for control
4. Everything stays self-contained—no system-wide changes

**First-time setup:**
```bash
/media enable        # Activate auto-pause/resume
```

You'll see a macOS notification confirming the state change.

### Option 2: Standalone CLI

Install as a standalone command-line utility:

```bash
git clone https://github.com/fntune/claude-mediakey
cd claude-mediakey
make build
```

**Add to PATH (optional):**
```bash
sudo cp mediakey /usr/local/bin/
```

Or use directly from the build directory:
```bash
./mediakey playpause
```

### Requirements

- **macOS 10.13+** (High Sierra or later)
- **Swift compiler** (Xcode Command Line Tools)
  ```bash
  xcode-select --install
  ```

---

## Usage

### Command Reference

#### Media Playback

| Command | Description |
|---------|-------------|
| `mediakey play` | Resume playback |
| `mediakey pause` | Pause playback |
| `mediakey playpause` | Toggle play/pause |
| `mediakey next` | Skip to next track |
| `mediakey prev` | Go to previous track |
| `mediakey volup` | Increase volume |
| `mediakey voldown` | Decrease volume |

#### State Management

| Command | Description |
|---------|-------------|
| `mediakey enable` | Enable automation hooks (Claude Code) |
| `mediakey disable` | Disable automation hooks |
| `mediakey status` | Show current state (enabled/disabled) |

**Note:** By default, mediakey starts **disabled** in each directory. Run `mediakey enable` in your project directory to activate automatic media control for that specific project.

**Per-Directory State:** Each project has its own enabled/disabled state (stored in `.mediakey_enabled`). This means:
- You can enable mediakey in project A but not project B
- Parallel Claude Code sessions in different directories won't interfere
- State persists per-project, not globally

### Claude Code Integration

When installed as a plugin, mediakey automatically:

1. **Resumes** media when you submit a prompt (Claude is working, you can relax)
2. **Pauses** media when Claude needs your input or finishes (so you can focus)
3. **Shows** macOS notifications for state changes

#### How The Workflow Works

The plugin uses hooks to create a seamless focus management experience:

```
┌─────────────────────────────────────────────────────────────┐
│ YOU: Reading docs, thinking about code                      │
│ 🔇 Media: PAUSED (you need focus)                          │
└─────────────────────────────────────────────────────────────┘
                           │
                    [You hit submit]
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ CLAUDE: Processing your request, running tools              │
│ 🎵 Media: PLAYING (you can relax, listen to music)         │
└─────────────────────────────────────────────────────────────┘
                           │
              [Claude finishes or needs input]
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ YOU: Reading response, deciding next action                 │
│ 🔇 Media: PAUSED (you need focus)                          │
└─────────────────────────────────────────────────────────────┘
                           │
                    [You hit submit]
                           ↓
                      (cycle repeats)
```

**The Philosophy:**
- **You're working** (reading, typing, thinking) → Music distracts → Pause
- **Claude is working** (processing, running tools) → You're waiting → Play

This creates natural focus cycles without manual media control.

#### Using the `/media` Slash Command

```bash
# Check status and get options
/media

# Toggle automation
/media enable
/media disable

# Manual playback control
/media next
/media pause
/media play
```

#### Workflow Example

```bash
# Enable automatic media control
/media enable

# Work on your code, chat with Claude
# Media plays while Claude processes your requests
# Media pauses when Claude needs input or finishes (so you can focus)

# Disable when you want manual control
/media disable
```

### Scripting Examples

#### Basic Integration

```bash
# Pause media before long-running tasks
mediakey pause && npm run build

# Resume after completion
npm test && mediakey play
```

#### Shell Scripts

```bash
#!/bin/bash
# deploy.sh - Pause music during deployment

mediakey pause
echo "Deploying application..."
./deploy-script.sh

if [ $? -eq 0 ]; then
    echo "✓ Deployment successful"
    mediakey play
else
    echo "✗ Deployment failed"
fi
```

#### Keyboard Shortcuts

Use with automation tools:

**[Karabiner-Elements](https://karabiner-elements.pqrs.org/):**
```json
{
  "type": "basic",
  "from": {"key_code": "f13"},
  "to": [{"shell_command": "/usr/local/bin/mediakey next"}]
}
```

**macOS Shortcuts.app:**
1. Create new shortcut
2. Add "Run Shell Script" action
3. Enter: `mediakey next`
4. Assign keyboard shortcut

#### Git Hooks

```bash
# .git/hooks/pre-push
#!/bin/bash
mediakey pause
# Run your tests...
```

---

## How It Works

mediakey sends `NSEvent.systemDefined` events directly to `kCGHIDEventTap`, the same low-level system event tap that physical keyboard media keys use. This bypasses application-specific controls and works universally with any media player.

### Technical Implementation

**Event Structure:**
- **Type:** `NSEventTypeSystemDefined`
- **Subtype:** `8` (NX_SUBTYPE_AUX_CONTROL_BUTTONS)
- **data1:** `(keyCode << 16) | (pressFlag << 8)`
- **Event Tap:** `.cghidEventTap` (system-level HID event tap)

**Media Key Codes** (from IOKit's `ev_keymap.h`):

| Key Code | Function | Constant |
|----------|----------|----------|
| `16` | Play/Pause | `NX_KEYTYPE_PLAY` |
| `17` | Next Track | `NX_KEYTYPE_NEXT` |
| `18` | Previous Track | `NX_KEYTYPE_PREVIOUS` |
| `0` | Volume Up | `NX_KEYTYPE_SOUND_UP` |
| `1` | Volume Down | `NX_KEYTYPE_SOUND_DOWN` |

**Event Sequence:**
1. Create key-down event (`pressFlag = 0xa`)
2. Post to system event tap
3. Create key-up event (`pressFlag = 0xb`)
4. Post to system event tap
5. Wait 10ms (`usleep(10000)`) to ensure processing

The 10ms delay prevents events from being dropped when the program exits immediately after posting.

### Why This Works Universally

By posting events to the HID system tap, mediakey simulates actual hardware media key presses. The operating system routes these events to the active media session, regardless of which application is playing media.

---

## Configuration

### State File

mediakey stores its enabled/disabled state in `.mediakey_enabled` in the **current working directory** (per-project).

**Location:** `.mediakey_enabled` in each project directory where you run `mediakey enable`

**Content:**
- `1` = enabled (automation active in this directory)
- `0` = disabled (automation inactive in this directory)

**Per-Directory Behavior:**
- Each project directory has its own independent state
- Run `mediakey enable` in project A → only affects project A
- Run `mediakey enable` in project B → only affects project B
- Parallel Claude Code sessions in different directories won't interfere with each other

**Gitignore:** Add `.mediakey_enabled` to your `.gitignore` since it's a local preference file

### Claude Code Hooks

When installed as a plugin, hooks are automatically configured in `hooks/hooks.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/mediakey play"
      }]
    }],
    "Notification": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/mediakey pause"
      }]
    }],
    "Stop": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/mediakey pause"
      }]
    }]
  }
}
```

**Hook Behavior:**
- **UserPromptSubmit** → Resume media (Claude is working)
- **Notification** → Pause media (you need to focus/read)
- **Stop** → Pause media (you need to read the response)

The hooks only fire when mediakey is **enabled**. When disabled, the commands exit silently without affecting playback.

---

## Troubleshooting

### Media doesn't pause/resume

**Check if enabled:**
```bash
mediakey status
# or
/media
```

**Enable automation:**
```bash
mediakey enable
# or
/media enable
```

### Binary not found

**Claude Code plugin:**
```bash
# Check if binary exists
ls -la ~/.claude/plugins/marketplaces/claude-mediakey/mediakey

# Rebuild if missing
cd ~/.claude/plugins/marketplaces/claude-mediakey
make build
```

**Standalone:**
```bash
# Rebuild
make clean && make build
```

### Notifications not appearing

Check macOS notification settings:
1. System Settings → Notifications
2. Find "Script Editor" or "osascript"
3. Enable "Allow Notifications"

### Hooks not firing (Claude Code)

1. **Verify plugin installation:**
   ```bash
   /plugin list
   ```

2. **Check hooks are registered:**
   ```bash
   ls ~/.claude/plugins/marketplaces/claude-mediakey/hooks/
   ```

3. **Restart Claude Code** to reload plugins

---

## Development

### Project Structure

```
mediakey/
├── .claude-plugin/          # Plugin metadata
│   ├── marketplace.json     # Marketplace configuration
│   └── plugin.json          # Plugin manifest
├── commands/
│   └── media.md             # /media slash command
├── hooks/
│   └── hooks.json           # Hook configuration
├── mediakey.swift           # Core implementation
├── session-start.sh         # Auto-build on first session
├── install.sh               # Build script
├── Makefile                 # Build automation
├── CLAUDE.md                # Claude Code instructions
├── PLUGIN.md                # Plugin developer docs
└── README.md                # This file
```

### Building

```bash
# Standard build
make build

# Manual build (no Makefile)
swiftc mediakey.swift -o mediakey

# Clean build artifacts
make clean
```

### Testing

```bash
# Test playback control (requires media playing)
make test

# Manual testing
./mediakey playpause        # Should pause/resume media
./mediakey status          # Should show current state
./mediakey enable          # Should show notification
```

### Plugin Development

See [PLUGIN.md](PLUGIN.md) for detailed plugin development documentation.

### Code Architecture

The implementation is a single Swift file with three main components:

1. **`postMediaKey(key:)`** – Creates and posts system-level media key events
2. **State management** – `isEnabled()`, `setEnabled()` for automation control
3. **Command parser** – Maps CLI arguments to key codes

All dependencies are system frameworks (AppKit, Foundation), ensuring zero external dependencies.

---

## Why mediakey?

### vs. Python + PyObjC

**PyObjC:** Requires Python runtime + PyObjC package installation

**mediakey:** Single 55KB binary, no runtime dependencies

### vs. AppleScript

**AppleScript:** Cannot send system-level media key events, limited to app-specific controls

**mediakey:** Uses system HID event tap, works with any media player

### vs. BetterTouchTool / Karabiner

**BetterTouchTool/Karabiner:** Requires installing and configuring third-party GUI applications

**mediakey:** Lightweight CLI tool, scriptable, integrates with existing workflows

### vs. NPM Packages

**NPM media key packages:** Require Node.js runtime, often use native bindings

**mediakey:** Pure Swift, no runtime, smaller footprint

---

## Contributing

Contributions welcome! Please:

1. **Open an issue** for bugs or feature requests
2. **Submit PRs** with clear descriptions and test results
3. **Test on your system** before submitting
4. **Follow Swift conventions** for code style

### Development Workflow

```bash
# Fork and clone
git clone https://github.com/YOUR-USERNAME/claude-mediakey
cd claude-mediakey

# Make changes
vim mediakey.swift

# Test
make build
./mediakey playpause

# Commit
git add .
git commit -m "Add feature X"
git push

# Open PR on GitHub
```

### Plugin Development

See [PLUGIN.md](PLUGIN.md) for detailed documentation on:
- Plugin architecture
- Hook configuration
- Slash command development
- Testing strategies

---

## Uninstallation

### Claude Code Plugin

```bash
/plugin uninstall claude-mediakey
```

This removes everything automatically:
- Binary
- State file
- Hooks
- Slash commands

No manual cleanup required.

### Standalone

```bash
# Remove binary
rm /usr/local/bin/mediakey  # If installed to PATH
# or
make clean                  # If using from project directory

# Remove state file
rm .mediakey_enabled
```

---

## License

MIT License – See [LICENSE](LICENSE) for details.

---

## Acknowledgments

- Based on [Stack Overflow discussion](https://stackoverflow.com/questions/11045814/emulate-media-key-press-on-mac) on media key emulation
- Built for the [Claude Code](https://claude.ai/code) plugin ecosystem
- Inspired by the need for lightweight, dependency-free developer tools

---

## Links

- **GitHub:** https://github.com/fntune/claude-mediakey
- **Issues:** https://github.com/fntune/claude-mediakey/issues
- **Claude Code Docs:** https://docs.claude.com/en/docs/claude-code

---

**Star ⭐ this repo if you find it useful!**
