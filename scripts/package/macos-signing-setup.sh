#!/usr/bin/env bash
# Import generic Apple credentials into a temporary GitHub Actions keychain.
set -euo pipefail
die() { echo "Error: $*" >&2; exit 1; }
[[ -n "${GITHUB_ENV:-}" && -n "${RUNNER_TEMP:-}" ]] || die "This script requires GitHub Actions."
[[ "${APPLE_TEAM_ID:-}" =~ ^[A-Z0-9]{10}$ ]] || die "Set the APPLE_TEAM_ID repository variable."
for name in APPLE_CERTIFICATE_P12_BASE64 APPLE_CERTIFICATE_PASSWORD APPLE_NOTARY_KEY_P8_BASE64 APPLE_NOTARY_KEY_ID APPLE_NOTARY_ISSUER_ID; do
    [[ -n "${!name:-}" ]] || die "Missing $name GitHub Actions credential."
done
umask 077
signing_dir=$(mktemp -d "$RUNNER_TEMP/apple-signing.XXXXXX")
# Record cleanup paths before importing, so failures are cleaned up too.
printf 'APPLE_SIGNING_DIR=%s\n' "$signing_dir" >> "$GITHUB_ENV"
keychain="$signing_dir/signing.keychain-db"
printf '%s' "$APPLE_CERTIFICATE_P12_BASE64" | base64 -D > "$signing_dir/developer-id.p12"
printf '%s' "$APPLE_NOTARY_KEY_P8_BASE64" | base64 -D > "$signing_dir/notary-key.p8"
/usr/bin/openssl pkey -in "$signing_dir/notary-key.p8" -noout >/dev/null
password=$(/usr/bin/openssl rand -hex 32)
security create-keychain -p "$password" "$keychain"
security set-keychain-settings -lut 21600 "$keychain"
security unlock-keychain -p "$password" "$keychain"
security import "$signing_dir/developer-id.p12" -k "$keychain" \
    -P "$APPLE_CERTIFICATE_PASSWORD" -T /usr/bin/codesign -T /usr/bin/security
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$password" "$keychain" >/dev/null
identity=$(security find-identity -v -p codesigning "$keychain" |
    awk -v team="($APPLE_TEAM_ID)" '$0 ~ /Developer ID Application:/ && index($0, team) {print $2}')
[[ "$identity" =~ ^[A-Fa-f0-9]{40}$ ]] || die "Expected one Developer ID Application identity for team $APPLE_TEAM_ID."
printf 'APPLE_SIGN_IDENTITY=%s\nAPPLE_SIGNING_KEYCHAIN=%s\nAPPLE_NOTARY_KEY=%s\n' \
    "$identity" "$keychain" "$signing_dir/notary-key.p8" >> "$GITHUB_ENV"
printf 'APPLE_TEAM_ID=%s\nAPPLE_NOTARY_KEY_ID=%s\nAPPLE_NOTARY_ISSUER_ID=%s\n' \
    "$APPLE_TEAM_ID" "$APPLE_NOTARY_KEY_ID" "$APPLE_NOTARY_ISSUER_ID" >> "$GITHUB_ENV"
echo "Developer ID signing for team $APPLE_TEAM_ID is ready."
