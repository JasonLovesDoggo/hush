#!/bin/sh
# Installs (or updates) Hush: curl -fsSL https://raw.githubusercontent.com/JasonLovesDoggo/hush/main/install.sh | sh
set -eu

URL="https://github.com/JasonLovesDoggo/hush/releases/latest/download/Hush.zip"
DEST="/Applications"
[ -w "$DEST" ] || DEST="$HOME/Applications"
mkdir -p "$DEST"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading Hush…"
curl -fsSL "$URL" -o "$TMP/Hush.zip"
ditto -x -k "$TMP/Hush.zip" "$TMP"

pkill -x Hush 2>/dev/null || true
rm -rf "$DEST/Hush.app"
mv "$TMP/Hush.app" "$DEST/"
xattr -dr com.apple.quarantine "$DEST/Hush.app" 2>/dev/null || true
open "$DEST/Hush.app"

echo "Installed to $DEST/Hush.app — look for the Bluetooth rune in your menu bar."
