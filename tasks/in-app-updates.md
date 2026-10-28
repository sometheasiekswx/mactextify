# MacTextify in-app updates

## Confirmed requirements — 29 October 2026

- Users update inside MacTextify without manually downloading and replacing the app in Finder.
- Full update downloads are sufficient; delta downloads are outside this change.
- Provide Check for Updates, followed by an explicit Install and Relaunch action.
- Checks are manual by default; users may opt into automatic checks.
- Installation requires confirmation and waits for active OCR or scanning to finish.
- Preserve exported files. OCR remains on-device.

## Accepted implementation — confirmed 29 October 2026

Use Sparkle 2 with HTTPS update feeds and Ed25519-signed archives hosted through the existing public release infrastructure. Keep the private update-signing key in the local macOS Keychain, never in source control; include only its public key in the app. This update signature is separate from Apple Developer ID signing and notarization.

Preserve Apple silicon, Intel and Universal distribution, routing each installed build to a compatible feed. Publish only stable releases. The first updater-enabled release needs a one-time manual installation for existing users, whose current apps contain no updater.

Implementation includes framework embedding/signing, increasing bundle build versions, release tooling, update controls, busy-work installation protection, privacy wording, and failure-path tests. Validate an actual old-to-new update using isolated test app copies and a test feed before claiming that installation works. Failed or invalid updates must leave the working app and exports intact.

Prepare and verify release readiness. Public release publication is a separate action from implementing this feature.

## Implementation and verification — 29 October 2026

- Added Sparkle 2.10.1 with an exact package pin and lockfile; the CLI/OCR target does not link Sparkle.
- Added native menu actions, opt-in automatic checks, disabled automatic downloads/profile reporting, and a main-actor installation gate that blocks new work and resumes once OCR/scanning finishes.
- Generated the update key in login Keychain under `com.mactextify.updates`; only the public key is in `config/`. Updated app/source packaging to include pinned dependencies, the framework, license and public configuration. Version 0.4.0 is prepared locally; 0.3.0 remains the public release.
- Passed 75 Swift tests, including 3 installation gate tests; 5 source-package tests; all 9 website tests, formatting and production build. Source archive contains 75 allowlisted files.
- Built isolated snapshot packages for arm64, x86_64 and universal; all pass architecture and deep signature checks. arm64 and universal launch checks passed on this Apple silicon Mac. Native Intel execution remains untested locally.
- Prepared and verified three signed architecture-specific appcasts locally. No feed or binary was published. Public hosting still advertises 0.3.0.
- The real Sparkle installer rejected an invalid signature and installed a valid 0.4.0-to-0.4.1 test update and relaunched the running app while preserving an external export file. Already-current checks passed. These are isolated test versions, not public releases.
- The integration harness needed its own app bundle metadata to launch Sparkle's installer. After rejection, Sparkle's helper/XPC teardown can temporarily return error 1004; the harness permits a bounded retry only for that specific error, verifies the old app remains intact, and still requires successful installation. It never treats an unrelated error as success.
- Read-only native accessibility inspection confirmed both menu controls in a freshly launched isolated app. Full interactive installation during a real OCR batch and clean-Mac Gatekeeper behavior remain manual checks; the installation gate is unit-tested.

Recovery and publication order are documented in `docs/distribution.md`. The installer/relaunch check passed. Native Intel execution and published release-host checks remain release gates. The subsequent review request authorizes fixes and a source push. Empty feeds will deploy with the website so source-built apps can check successfully before an updater-enabled binary release exists; the 0.3.0 public download remains unchanged.

## Review and source shipping

Review found and fixed missing production feed endpoints: three valid empty appcasts now ship with the website, without advertising unreleased binaries. Sparkle integration tests exercise empty feeds for each architecture, signature rejection, recovery retry, install/relaunch, already-current responses and preservation of exports. CLI installation/upgrade/rollback smoke checks also pass. Source push triggers website deployments; binary verification is run separately on native Apple silicon and Intel CI. A new public binary release is not included in this source push.
