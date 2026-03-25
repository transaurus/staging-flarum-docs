#!/usr/bin/env bash
set -euo pipefail

# Rebuild script for flarum/docs
# Runs on existing source tree (no clone). Installs deps, runs pre-build steps, builds.

# --- Node version ---
# flarum/docs uses Docusaurus 2.3.1; CI pins Node 20.x
NODE_MAJOR=$(node --version | sed 's/v//' | cut -d. -f1)
if [ "$NODE_MAJOR" -lt 20 ]; then
    echo "[INFO] Node $NODE_MAJOR detected; attempting upgrade to Node 20 via n..."
    if command -v n &>/dev/null; then
        export N_PREFIX="${N_PREFIX:-/usr/local}"
        sudo n 20 2>/dev/null || n 20 2>/dev/null || true
        export PATH="/usr/local/bin:$PATH"
        NODE_MAJOR=$(node --version | sed 's/v//' | cut -d. -f1)
    fi
    if [ "$NODE_MAJOR" -lt 20 ]; then
        echo "[ERROR] Node $NODE_MAJOR detected, but flarum/docs requires Node >=20."
        exit 1
    fi
fi
echo "[INFO] Using $(node --version)"

# --- Install dependencies ---
npm install --legacy-peer-deps

# --- Build ---
npm run build

echo "[DONE] Build complete."
