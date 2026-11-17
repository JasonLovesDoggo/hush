#!/bin/sh
# Builds build/Hush.app (universal). Signs with your Apple Development identity if
# you have one — a stable signature keeps the Bluetooth permission across updates —
# otherwise ad-hoc.
set -eu
cd "$(dirname "$0")/.."
VERSION="${VERSION:-$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || true)}"
VERSION="${VERSION:-0.0.0}"

swift build -c release --arch arm64 --arch x86_64
BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/Hush"

APP=build/Hush.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Hush"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
sed "s/VERSION/$VERSION/g" Resources/Info.plist > "$APP/Contents/Info.plist"

IDENTITY="${SIGN_IDENTITY:-$(security find-identity -v -p codesigning 2>/dev/null | awk -F'"' '/Apple Development|Developer ID Application/ {print $2; exit}')}"
codesign --force --options runtime --sign "${IDENTITY:--}" "$APP"
echo "Built $APP ($VERSION, signed: ${IDENTITY:-ad-hoc})"
