#!/bin/sh
# Export the game for the browser to game/build/web (needs Godot 4.7 with its export templates installed).
set -e
cd "$(dirname "$0")/.."
godot --headless --path game --script res://tests/run_tests.gd
mkdir -p game/build/web
godot --headless --path game --export-release "Web" build/web/index.html
echo "web build ready in game/build/web, serve it with: python3 server-mac/serve_web.py --bind <tailscale ip>"
