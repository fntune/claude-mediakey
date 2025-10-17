#!/bin/bash
# SessionStart hook for mediakey plugin
# Builds binary if needed

PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT}"

# Build binary if it doesn't exist
if [ -f "$PLUGIN_DIR/install.sh" ] && [ ! -f "$PLUGIN_DIR/mediakey" ]; then
    cd "$PLUGIN_DIR" && ./install.sh >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        osascript -e 'display notification "installed" with title "mediakey"' 2>/dev/null
    fi
fi
