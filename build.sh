#!/bin/sh
# One-time build for Laymo UI (for distribution).
# Run this where Node.js is installed; then zip and share bs_laymo.
# End users do NOT need Node.js.

set -e
cd "$(dirname "$0")/ui"

echo "Building Laymo UI..."
command -v node >/dev/null 2>&1 || { echo "Node.js is required. Install from https://nodejs.org"; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "npm not found. Install Node.js from https://nodejs.org"; exit 1; }

npm install
npm run build

echo ""
echo "Build complete. ui/dist is ready."
echo "Zip the entire bs_laymo folder and share it. End users do not need Node.js."
