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

**Key Design Decision**: Binary in plugin directory, state per-project.

### Why This Matters

Traditional approach (problems):
- Binary installed to `~/bin/` → left behind on uninstall
- Global state file → can't have different settings per project
- PATH modified in `~/.zshrc` → left behind on uninstall
- Requires manual cleanup

Self-contained approach (solution):
- Binary: `~/.claude/plugins/marketplaces/claude-mediakey/mediakey`
- State: `.mediakey_enabled` in each project directory (per-project)
- No PATH modification
- **Uninstalling removes the binary automatically**

### Per-Directory State Benefits

1. **Independent Control**: Enable in project A, disable in project B
2. **No Interference**: Parallel Claude Code sessions work independently
3. **User Preference**: Each project can have its own media control setting
4. **Clean Uninstall**: Binary removed, state files become inert

### Implementation Details

1. **Binary Location**: `~/.claude/plugins/marketplaces/claude-mediakey/mediakey`
2. **State Location**: `FileManager.default.currentDirectoryPath + "/.mediakey_enabled"`
3. **Hooks**: Use full paths to plugin directory
4. **Per-Project**: Each directory has its own state file

## Enable/Disable Feature

The plugin includes a per-directory state management system:
- State stored in `.mediakey_enabled` (current working directory)
- Default: **disabled** (opt-in per directory)
- Commands: `enable`, `disable`, `status`
- Hooks silently exit when disabled in that directory
- State persists per-project, independent across directories

## Platform Requirements

- **Platform**: macOS only (`darwin`)
- **Swift**: Xcode Command Line Tools
- **Runtime**: No external dependencies

## Creating Similar Self-Contained Plugins

To create a self-contained plugin that auto-cleans on uninstall:

### 1. Use Per-Directory State Files

```swift
// Store state in current working directory (per-project)
let stateFilePath = FileManager.default.currentDirectoryPath + "/.mystate"
```

**Benefits:**
- Each project has independent state
- Parallel sessions don't interfere
- Users can have different preferences per project

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
- ✅ State files in project directories (per-directory state)
- ✅ No PATH modification
- ✅ Add state files to `.gitignore`

### Benefits

- **Auto-cleanup**: Uninstall removes everything
- **Portable**: No system-wide changes
- **Safe**: Can't leave orphaned files
- **Simple**: No manual cleanup scripts needed

## Resources

- [Claude Code Plugin Documentation](https://docs.claude.com/en/docs/claude-code/plugins)
- [Plugin Marketplaces](https://docs.claude.com/en/docs/claude-code/plugin-marketplaces)
- [Hooks Guide](https://docs.claude.com/en/docs/claude-code/hooks-guide)
