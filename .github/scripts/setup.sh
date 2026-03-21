#!/bin/bash
# Generated setup script for: https://github.com/flarum/docs
# Docusaurus 2.3.1, npm, Node 20

set -e

REPO_URL="https://github.com/flarum/docs"
BRANCH="main"

echo "[INFO] Cloning repository..."
if [ -d "source-repo" ]; then
    rm -rf source-repo
fi

git clone --depth 1 --branch "$BRANCH" "$REPO_URL" source-repo
cd source-repo

echo "[INFO] Node version: $(node -v)"
echo "[INFO] NPM version: $(npm -v)"

echo "[INFO] Installing dependencies..."
npm install

echo "[INFO] Running write-translations..."
npm run write-translations

echo "[INFO] Verifying i18n output..."
if [ -d "i18n" ]; then
    find i18n -type f -name "*.json" | head -20
    COUNT=$(find i18n -type f -name "*.json" | wc -l)
    echo "[INFO] Generated $COUNT JSON files"
else
    echo "[ERROR] i18n directory not found"
    exit 1
fi

echo "[INFO] Setup completed successfully!"
