# Distribution and release checklist

Source is published at [sometheasiekswx/mactextify](https://github.com/sometheasiekswx/mactextify) under the existing MIT license (MacTextify contributors). Private vulnerability reporting is enabled. Local build steps do not publish tags or release assets. There is no versioned binary release.

## Source-first release

Build/install from source is the initial distribution route. The install helper does not require Python or third-party packages. Users obtain Apple developer tools separately. Runtime is local and offline. A custom Homebrew formula can later build from a release archive; no formula/core acceptance is currently promised.

Prepare a local source archive with `python3 scripts/package-source.py`. This uses an explicit file allowlist, rejects symlinks and private path patterns, and writes an archive plus SHA-256 digest into ignored `dist/`. Inspect both the allowlist and resulting archive. Build/install the extracted archive in a clean environment before publishing.

## Pending publication checks

- [x] Source repository owner/name, public visibility, existing MIT attribution and private security reporting configured.
- [x] Initial publication used a 32-file source allowlist. The current source package follows `scripts/source-files.txt`, including generic prerequisite checks, public branding and synthetic README screenshots. No private images, receipts, generated graphs or build artifacts are packaged.
- [ ] Run macOS CI on the advertised ARM/Intel and OS matrix. Record actual runtime coverage.
- [ ] Complete a manual Finder chooser test (selection, cancellation, keep and archive) on supported systems.
- [ ] Confirm VERSION, CLI version, changelog and intended tag agree.
- [ ] Build/smoke-test the exact release archive; inspect checksums and file manifest.
- [ ] Only after publication authorization: push source, create tag/release and verify downloadable checksums.

No automatic release publication workflow is provided. The manually triggered release-check workflow only tests and packages a local archive on its runner. It requires no write permission or release credentials. A human can decide how to publish after these checks.

## Optional prebuilt downloads

A prebuilt release requires actual downloaded-binary/Gatekeeper testing and a signing/notarization decision. Developer ID credentials and enrollment cost are an owner decision. Do not claim binaries are notarized or instruct users to disable Gatekeeper globally. Apple framework implementations are not redistributed with this source.

References: [Apple notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution), [GitHub runner platforms](https://docs.github.com/en/actions/reference/runners/github-hosted-runners).

## Rollback and compatibility

Reinstall a previous trusted source version to switch the current executable. Previous installation slots are retained until uninstall. Project data is never rolled back by installation. Receipt schema is independently versioned; older tools must reject unsupported newer schemas. Any future schema migration requires backups and upgrade/downgrade tests. No automatic update checks.
