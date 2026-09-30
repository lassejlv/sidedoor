#!/usr/bin/env bash
# Package the already assembled, signed app without rebuilding it.
set -euo pipefail
cd "$(dirname "$0")/../.."
OUT="target/release/bundle"
ARCH=$(uname -m)
ZIP="Sidedoor-macos-$ARCH.zip"
DMG="Sidedoor-macos-$ARCH.dmg"
[ -d "$OUT/Sidedoor.app" ] || { echo "Build Sidedoor.app first" >&2; exit 1; }
STAGE=$(mktemp -d "$OUT/dmg.XXXXXX")
trap 'rm -rf "$STAGE"' EXIT HUP INT TERM
ditto "$OUT/Sidedoor.app" "$STAGE/Sidedoor.app"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname Sidedoor -srcfolder "$STAGE" -ov -format UDZO "$OUT/$DMG"
hdiutil verify "$OUT/$DMG"
if [[ "${APPLE_SIGN_IDENTITY:--}" != - ]]; then
    sign_args=(--force --sign "$APPLE_SIGN_IDENTITY" --timestamp)
    if [[ -n "${APPLE_SIGNING_KEYCHAIN:-}" ]]; then
        sign_args+=(--keychain "$APPLE_SIGNING_KEYCHAIN")
    fi
    codesign "${sign_args[@]}" "$OUT/$DMG"
    codesign --verify --strict --verbose=2 "$OUT/$DMG"
fi
if [[ "${APPLE_NOTARIZE:-0}" == 1 ]]; then
    ./scripts/package/macos-notarize.sh "$OUT/$DMG"
fi
# The ZIP carries the app's stapled ticket. Checksums include every signature
# and ticket, so the updater verifies exactly what is distributed.
ditto -c -k --keepParent "$OUT/Sidedoor.app" "$OUT/$ZIP"
(cd "$OUT" && shasum -a 256 "$ZIP" > "$ZIP.sha256" && shasum -a 256 "$DMG" > "$DMG.sha256")
echo "Built $OUT/$ZIP and $OUT/$DMG"
