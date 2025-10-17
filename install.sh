#!/bin/bash
# Installation script for claude-mediakey plugin

set -e

echo "Building mediakey..."
make build

echo ""
echo "✓ Installation complete!"
echo ""
echo "Binary location: $(pwd)/mediakey"
echo ""
echo "Next steps:"
echo "1. Run: $(pwd)/mediakey enable"
echo "2. The hooks will now pause/resume media during Claude sessions"
echo ""
