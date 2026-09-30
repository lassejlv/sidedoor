#!/usr/bin/env bash
# Submit an archive and require Apple's Accepted result. Staple disk images.
set -euo pipefail
artifact=${1:?Usage: macos-notarize.sh /path/to/archive}
for name in APPLE_NOTARY_KEY APPLE_NOTARY_KEY_ID APPLE_NOTARY_ISSUER_ID; do
    [[ -n "${!name:-}" ]] || { echo "Missing notarization credential: $name" >&2; exit 1; }
done
[[ -f "$APPLE_NOTARY_KEY" ]] || { echo "Notarization private key not found." >&2; exit 1; }
auth=(--key "$APPLE_NOTARY_KEY" --key-id "$APPLE_NOTARY_KEY_ID" --issuer "$APPLE_NOTARY_ISSUER_ID")
result=$(mktemp)
trap 'rm -f "$result"' EXIT
if ! xcrun notarytool submit "$artifact" "${auth[@]}" --wait --timeout 30m --output-format json > "$result"; then
    cat "$result"
    exit 1
fi
status=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["status"])' "$result")
submission=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["id"])' "$result")
echo "Notarization $submission: $status"
if [[ "$status" != Accepted ]]; then
    xcrun notarytool log "$submission" "${auth[@]}" || true
    exit 1
fi
if [[ "$artifact" == *.dmg ]]; then
    xcrun stapler staple "$artifact"
    xcrun stapler validate "$artifact"
    spctl --assess --type open --context context:primary-signature --verbose=2 "$artifact"
fi
