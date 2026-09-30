#!/usr/bin/env bash
# Sign an assembled app from the inside out. Apple credentials are independent
# of the product name and bundle identifier.
set -euo pipefail
cd "$(dirname "$0")/../.."

app=${1:?Usage: macos-sign.sh /path/to/App.app}
identity=${APPLE_SIGN_IDENTITY:--}
[[ -d "$app/Contents/MacOS" ]] || { echo "App bundle not found: $app" >&2; exit 1; }

if [[ "${APPLE_REQUIRE_SIGNING:-0}" == 1 || "${APPLE_NOTARIZE:-0}" == 1 ]]; then
    [[ "$identity" != - ]] || { echo "Developer ID signing credentials are required." >&2; exit 1; }
fi

if [[ "$identity" == - ]]; then
    echo "Signing local build (ad hoc)…"
    codesign --force --sign - --preserve-metadata=entitlements,flags,runtime --timestamp=none "$app/Contents/MacOS/bun"
    codesign --force --sign - --timestamp=none "$app"
else
    [[ "${APPLE_TEAM_ID:-}" =~ ^[A-Z0-9]{10}$ ]] || { echo "APPLE_TEAM_ID is required for Developer ID signing." >&2; exit 1; }
    sign_args=(--force --sign "$identity" --options runtime --timestamp)
    if [[ -n "${APPLE_SIGNING_KEYCHAIN:-}" ]]; then
        sign_args+=(--keychain "$APPLE_SIGNING_KEYCHAIN")
    fi
    echo "Signing with Developer ID for team ${APPLE_TEAM_ID}…"
    # Bun's existing entitlements allow its JavaScript engine to use JIT.
    codesign "${sign_args[@]}" \
        --preserve-metadata=entitlements "$app/Contents/MacOS/bun"
    codesign "${sign_args[@]}" "$app"
    for code in "$app" "$app/Contents/MacOS/bun"; do
        details=$(codesign --display --verbose=4 "$code" 2>&1)
        [[ "$details" == *"Authority=Developer ID Application:"* &&
           "$details" == *"TeamIdentifier=$APPLE_TEAM_ID"* &&
           "$details" == *"(runtime)"* && "$details" == *"Timestamp="* ]] \
            || { echo "Developer ID, team, hardened runtime or timestamp verification failed: $code" >&2; exit 1; }
    done
fi
codesign --verify --deep --strict --verbose=2 "$app"

if [[ "${APPLE_NOTARIZE:-0}" == 1 ]]; then
    archive_dir=$(mktemp -d)
    trap 'rm -rf "$archive_dir"' EXIT
    ditto -c -k --keepParent "$app" "$archive_dir/notarization.zip"
    ./scripts/package/macos-notarize.sh "$archive_dir/notarization.zip"
    xcrun stapler staple "$app"
    xcrun stapler validate "$app"
    codesign --verify --deep --strict --verbose=2 "$app"
    spctl --assess --type execute --verbose=2 "$app"
fi
