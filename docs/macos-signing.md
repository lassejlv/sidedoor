# macOS signing

GitHub release builds sign the app, bundled Bun runtime, and DMG with the
account holder's Developer ID Application certificate. Both the app and DMG
are notarized and stapled before the portable ZIP and checksums are produced.
A release fails if signing credentials are absent or Apple rejects notarization.

The certificate and notarization key belong to the Apple developer team, not
the product name. Renaming the app does not require new credentials. No new
product-specific Apple certificate or API key is created by this setup.

Set the repository variable `APPLE_TEAM_ID` to the certificate's Apple team.
GitHub Actions uses these encrypted repository secrets:

| Secret | Value |
| --- | --- |
| `APPLE_CERTIFICATE_P12_BASE64` | Base64-encoded Developer ID certificate and private key export |
| `APPLE_CERTIFICATE_PASSWORD` | Password protecting that P12 export |
| `APPLE_NOTARY_KEY_P8_BASE64` | Base64-encoded existing App Store Connect team API private key |
| `APPLE_NOTARY_KEY_ID` | API key ID |
| `APPLE_NOTARY_ISSUER_ID` | API issuer ID from the same Apple team |

Run the **macOS** workflow manually with **Sign and notarize the packages**
enabled to verify these credentials without publishing a release. Its artifacts
contain signed, notarized downloads. Ordinary pull request and local builds
continue to work with ad hoc signatures and require no private credentials.

The workflow imports credentials into a temporary keychain and removes it
after the job, including on failure. Private keys must never enter the repository.

For a local signed build, set `APPLE_SIGN_IDENTITY` to the certificate's
identity or SHA-1, `APPLE_TEAM_ID`, `APPLE_NOTARIZE=1`, `APPLE_NOTARY_KEY`
to the local P8 path, and the two notarization IDs before running
`scripts/package/macos.sh`. `APPLE_REQUIRE_SIGNING=1` prevents ad hoc fallback.

Validation includes nested signature verification, hardened runtime and secure
timestamps, Apple's Accepted notarization result, stapled tickets, Gatekeeper
assessment, and final archive checksums. Bun retains its upstream JIT entitlements.
