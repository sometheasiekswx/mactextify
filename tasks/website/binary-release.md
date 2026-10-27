# MacTextify binary downloads

## Scope and acceptance
Publish version 0.3.0 ZIPs containing MacTextify.app for arm64, x86_64 and Universal (both slices), built from one recorded commit. Preserve the MacTextify name and local OCR behavior. All builds are ad-hoc signed, not Developer ID signed or notarized. Runtime requires macOS 14+; Xcode is only needed to build source.

Website offers all three architectures, sizes, checksums, source revision and clear chip selection / installation instructions. GitHub Release assets are the download authority; Pages never needs to store binaries in Git. Validate manifest URLs and verify remote bytes before deployment. Preserve the local-preview validation path.

## Plan
1. Extend app packaging with explicit architecture and VERSION-derived metadata, clean bundles, archive extraction/signature/architecture verification.
2. Build isolated tracked sources; test native app launch and OCR, cross-build slices; use macOS CI to verify native Intel and ARM behavior.
3. Publish verified ZIPs and SHA256SUMS at a versioned GitHub Release, then commit a public release manifest and website integration.
4. Verify website tests/build, responsive download controls, live public downloads and hashes, Pages and macOS CI. Fix findings before final delivery.

## Recovery and limits
Revert the website manifest/integration commit to restore source-only downloads; withdraw release assets only if defective. No global Gatekeeper changes or quarantine-removal installation instructions. Record clean-Mac interactive Gatekeeper testing separately from local launch, signature checks and native CI; those checks do not prove every managed Mac can open an unsigned app.

## Verification notes
- Isolated build initially omitted Tests declared by Package.swift; fixed before release. Review also added the required MIT license inside each app bundle and checks its bytes after extraction.
- Local arm64, x86_64 and Universal builds succeeded; Universal signature/architecture/extracted launch checks passed. Through the packaged Universal app's UI, the synthetic sample exported correctly to TXT and Markdown in separate temporary output folders. Original sample hash was preserved. This is local functional evidence, not a clean-Mac Gatekeeper test.
- Website checks cover malformed metadata, duplicate/missing architectures, fixed GitHub destinations, corrupt archives and stray local downloads. Responsive checks at 320/390/768/1024/1440 and mobile axe passed. One local test run encountered a temporary-directory cleanup race (ENOTEMPTY); immediate rerun passed all nine tests; no assertion was suppressed.
- Release binaries are taken from the final successful Binary release verification workflow, not earlier local preview builds. Website hashes must be replaced with those final artifact hashes before commit/deploy.

## Release evidence
- Final app revision: `307e222ae3229f484520c6e86b24651784df2cf7`.
- Binary verification run [40543127553](https://github.com/sometheasiekswx/mactextify/actions/runs/40543127553): all three jobs passed, including extracted app launch on native Intel and Apple silicon.
- App revision macOS matrix [40543122265](https://github.com/sometheasiekswx/mactextify/actions/runs/40543122265): all three OS jobs passed, including tests, release builds and installer smoke checks.
- [Release v0.3.0](https://github.com/sometheasiekswx/mactextify/releases/tag/v0.3.0) contains the three verified ZIPs, SHA256SUMS and release-manifest.json. Public downloads match all recorded sizes and SHA-256 hashes.
- Final metadata replaced the temporary local-build values before publication of the website. Original local preview artifacts were preserved in ignored `.build/release-evidence/previous-website-preview/`.
- Review: isolated source export, bundle version/license, correct architectures, native launch, fixed download destinations, checksums, responsive controls and truthful installation disclosures checked. No remaining blocking findings. Clean-Mac interactive Gatekeeper testing remains unverified and is disclosed.
