#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/flarum/docs"
BRANCH="main"
REPO_DIR="source-repo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Clone (skip if already exists) ---
if [ ! -d "$REPO_DIR" ]; then
    git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
fi

cd "$REPO_DIR"

# --- Node version ---
# flarum/docs uses Docusaurus 2.3.1; CI pins Node 20.x
# Ensure Node >= 20
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
# CI uses npm install (npm i); repo has yarn.lock but no package-lock.json
# Use npm install (generates package-lock.json on first run)
npm install --legacy-peer-deps

# --- Apply fixes.json if present ---
FIXES_JSON="$SCRIPT_DIR/fixes.json"
if [ -f "$FIXES_JSON" ]; then
    echo "[INFO] Applying content fixes..."
    node -e "
    const fs = require('fs');
    const path = require('path');
    const fixes = JSON.parse(fs.readFileSync('$FIXES_JSON', 'utf8'));
    for (const [file, ops] of Object.entries(fixes.fixes || {})) {
        if (!fs.existsSync(file)) { console.log('  skip (not found):', file); continue; }
        let content = fs.readFileSync(file, 'utf8');
        for (const op of ops) {
            if (op.type === 'replace' && content.includes(op.find)) {
                content = content.split(op.find).join(op.replace || '');
                console.log('  fixed:', file, '-', op.comment || '');
            }
        }
        fs.writeFileSync(file, content);
    }
    for (const [file, cfg] of Object.entries(fixes.newFiles || {})) {
        const c = typeof cfg === 'string' ? cfg : cfg.content;
        fs.mkdirSync(path.dirname(file), {recursive: true});
        fs.writeFileSync(file, c);
        console.log('  created:', file);
    }
    "
fi

echo "[DONE] Repository is ready for docusaurus commands."
