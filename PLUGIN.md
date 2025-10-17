# Claude Code Plugin Structure

This document explains the Claude Code plugin structure for the mediakey plugin.

## Plugin Directory Structure

```
claude-mediakey/
├── .claude-plugin/
│   ├── plugin.json         # Plugin metadata and configuration
│   └── marketplace.json    # Marketplace configuration
├── commands/
│   └── media.md            # /media slash command documentation
├── hooks/
│   └── hooks.json          # Pre-configured event hooks
├── mediakey.swift          # Source code
├── mediakey                # Compiled binary (created by install.sh)
├── .mediakey_enabled       # State file (created by user)
├── install.sh              # Installation script (runs on SessionStart)
├── Makefile                # Build commands
├── PLUGIN.md               # This file
└── README.md               # User documentation
```

## Plugin Components

### 1. Plugin Manifest (`.claude-plugin/plugin.json`)

Defines plugin metadata following Claude Code plugin specification:

```json
{
  "name": "claude-mediakey",
  "version": "1.0.0",
  "description": "Control macOS media playback from Claude Code",
  "author": {
    "name": "fntune",
    "email": "hello@fntune.com",
    "url": "https://github.com/fntune"
  },
  "repository": "https://github.com/fntune/claude-mediakey",
  "license": "MIT"
}
```

### 2. Marketplace Configuration (`.claude-plugin/marketplace.json`)

Enables installation via marketplace:

```json
{
  "name": "claude-mediakey",
  "plugins": [
    {
      "name": "claude-mediakey",
      "source": "./",
      "version": "1.0.0"
    }
  ]
}
```

### 3. Hooks (`hooks/hooks.json`)

Pre-configured event hooks with **full paths** to plugin directory:

- **SessionStart**: Auto-builds binary on first session if not present
- **UserPromptSubmit**: Resumes media when user submits a prompt (Claude is working)
- **Notification**: Pauses media when Claude needs user input (user needs to focus)
- **Stop**: Pauses media when Claude stops responding (user needs to read)

**Important**: Hooks use full paths like `~/.claude/plugins/marketplaces/claude-mediakey/mediakey` to reference the binary in the plugin directory.

### 4. Slash Commands (`commands/media.md`)

Provides the `/media` command in Claude Code with frontmatter:

```markdown
---
description: Control macOS media playback with enable/disable toggle
---
# /media - Control macOS Media Playback
...
```

## Installation Flow

When users run `/plugin install fntune/claude-mediakey`:

1. Claude Code clones the repository to `~/.claude/plugins/marketplaces/claude-mediakey/`
2. Registers hooks from `hooks/hooks.json`
3. Registers slash command from `commands/media.md`
4. On **first session** (SessionStart hook):
   - Checks if binary exists
   - If not, runs `./install.sh` which calls `make build`
   - Binary is created at `~/.claude/plugins/marketplaces/claude-mediakey/mediakey`

## Self-Contained Architecture

**Key Design Decision**: Everything stays in the plugin directory.

### Why This Matters

Traditional approach (problems):
- Binary installed to `~/bin/` → left behind on uninstall
- State in `~/.mediakey_enabled` → left behind on uninstall
- PATH modified in `~/.zshrc` → left behind on uninstall
- Requires manual cleanup

Self-contained approach (solution):
- Binary: `~/.claude/plugins/marketplaces/claude-mediakey/mediakey`
- State: `~/.claude/plugins/marketplaces/claude-mediakey/.mediakey_enabled`
- No PATH modification
- **Uninstalling removes EVERYTHING automatically**

### Implementation Details

1. **Binary Location**: Determined using `CommandLine.arguments[0]`
2. **State Location**: Same directory as binary (`binaryDir + "/.mediakey_enabled"`)
3. **Hooks**: Use full paths to plugin directory
4. **Auto-cleanup**: When plugin directory deleted, all files gone

## Enable/Disable Feature

The plugin includes a state management system:
- State stored in `.mediakey_enabled` (same directory as binary)
- Default: **disabled** (opt-in)
- Commands: `enable`, `disable`, `status`
- Hooks silently exit when disabled
- State persists across sessions but deleted with plugin

## Platform Requirements

- **Platform**: macOS only (`darwin`)
- **Swift**: Xcode Command Line Tools
- **Runtime**: No external dependencies

## Creating Similar Self-Contained Plugins

To create a self-contained plugin that auto-cleans on uninstall:

### 1. Keep Everything in Plugin Directory

```swift
// Determine binary location from CommandLine.arguments[0]
let binaryDir = URL(fileURLWithPath: CommandLine.arguments[0])
    .deletingLastPathComponent().path
let stateFilePath = binaryDir + "/.mystate"
```

### 2. Use Full Paths in Hooks

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/plugins/marketplaces/my-plugin/mybinary action"
      }]
    }]
  }
}
```

### 3. Auto-Build on SessionStart

```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "[ -f ~/.claude/plugins/marketplaces/my-plugin/install.sh ] && [ ! -f ~/.claude/plugins/marketplaces/my-plugin/mybinary ] && cd ~/.claude/plugins/marketplaces/my-plugin && ./install.sh || true"
      }]
    }]
  }
}
```

### 4. Plugin Structure Checklist

- ✅ `.claude-plugin/plugin.json` - Plugin metadata (no install commands)
- ✅ `.claude-plugin/marketplace.json` - Marketplace config
- ✅ `hooks/hooks.json` - Hooks with full paths
- ✅ `commands/` - Slash commands with frontmatter
- ✅ `install.sh` - Build script (called by SessionStart)
- ✅ Binary stays in plugin directory
- ✅ State files stay in plugin directory
- ✅ No PATH modification

### Benefits

- **Auto-cleanup**: Uninstall removes everything
- **Portable**: No system-wide changes
- **Safe**: Can't leave orphaned files
- **Simple**: No manual cleanup scripts needed

## Resources

- [Claude Code Plugin Documentation](https://docs.claude.com/en/docs/claude-code/plugins)
- [Plugin Marketplaces](https://docs.claude.com/en/docs/claude-code/plugin-marketplaces)
- [Hooks Guide](https://docs.claude.com/en/docs/claude-code/hooks-guide)
