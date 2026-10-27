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
