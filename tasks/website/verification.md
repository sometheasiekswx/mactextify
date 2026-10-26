# Website verification — 27 October 2026

## Prepared result

Website source in `website/`; production artifact in ignored `website/dist/`. Source publication to the existing GitHub repository is authorized by the follow-up review-and-push request. No website deployment, app tag or GitHub Release is part of this source publication.

Local preview ZIP: `MacTextify-0.3.0-arm64-preview.zip`, 523,177 bytes. Apple silicon; macOS 14+ is the app's declared minimum, not a claim of runtime validation on every OS.

App source revision: `68de4e29388e3ab5d1b5e81d8fbebc77e75d1b10`.
SHA-256: `89a3c3a7c15791f194665a8b9798db335ed1dc02e85e1eb87c087e12a688a758`.

## Checks

- TypeScript and Vite production build passed.
- Seven Node release/preparation tests passed: isolated commit export excludes untracked Swift, extra icons, modified source and stale bundle contents; valid archive, corrupted/replaced archive, source-only fallback, invalid/untrusted metadata rejection before reads, orphaned downloads and extra files outside the verified manifest.
- `swift test`: 75 passed, zero failures.
- `python3 scripts/test-package-source.py`: five passed.
- `npm audit`: zero reported vulnerabilities at installation. This is dependency advisory coverage, not a safety guarantee.
- Browser interactions passed: pause preserves progress, keyboard scrub reaches completion, format toggles, sample and build-command clipboard output, theme toggle, installation disclosure, real ZIP download, downloaded/served bytes matching displayed checksum, reduced-motion static completion.
- Live GitHub source, contribution guide, CLI guide, distribution guide, license and issues links returned HTTP 200.
- No horizontal page overflow at 320, 390, 768, 1024 or 1440 pixels. All images decoded after lazy loading was triggered.
- Axe WCAG 2 A/AA, WCAG 2.1 AA and best-practice checks: zero violations in Pearl desktop, Midnight desktop, mobile and expanded installation/checksum states. Initial icon-label and theme-transition contrast findings were fixed. Automated accessibility checks do not replace assistive-technology testing.
- Impeccable detector returned no findings. Independent finish review recorded below when complete.
- `codesign --verify --deep --strict` passed before packaging and after both extraction and browser download/extraction.
- `spctl --assess --type execute` rejected the ad-hoc preview as expected. It is not notarized or approved by Gatekeeper.

## Limits and publication prerequisites

Actual user opening of a fresh quarantined download on a clean supported Mac has not been tested. No Intel binary/runtime, notarization, Safari/Firefox pass, public hosting or domain verification is claimed. The page explicitly identifies the unsigned preview. Current evidence establishes local website behavior and package integrity, not a frictionless or Gatekeeper-approved installation. Remote CI results for the source push are reported separately against the final commit.

## Evidence paths

- `website/output/playwright/final-layout-accessibility.txt`
- `website/output/playwright/interaction-results.txt` (contains initial fixed accessibility findings; final-layout-accessibility is authoritative)
- `website/output/playwright/desktop.png`, `desktop-hero.png`, `mobile.png`, `mobile-hero.png`, `midnight-hero.png`, `mobile-install.png`
- `.local-notes/website-reference/prepare-download.log`, `swift-test.log`, `package-test.log`, `impeccable-detect.json`

## Review

Independent Impeccable finish review disposition: **ship**, scoped to the two corrected findings and local preview preparation. Both findings were scored resolved: isolated commit-based packaging, and complete source-document display. The reviewer reran all five release tests, inspected six recaptured views and verified the prepared/downloaded archive hashes. No public deployment or clean-Mac Gatekeeper readiness is implied.

Normal-motion recording: `website/output/playwright/website-demo-hd.webm` (1440 × 1050, 60 fps). A second small recording and inspected stills are retained with the browser evidence. The recording demonstrates auto playback, replay, output-format switching and navigation to the real app and download. Browser console is clean after replacing the deprecated Anime.js spring helper.

Latest correction evidence: `website/output/playwright/review-fix-results.txt`. The exported source boundary was tested using a synthetic Git repository; no user repository files or Git index were modified by that regression test.

## Design handoff

`website/DESIGN.md` and `website/.impeccable/design.json` document the implemented tokens, responsive rules, motion and components. The independent documenter validated their syntax, token references and consistency against unchanged runtime sources. No external Stitch schema or separately rendered component previews were claimed.

## Follow-up review and source publication

The user explicitly requested review, fixes and a push to the existing repository. This review covers the complete website source, download preparation, asset provenance, dependencies, documentation and CI; it does not change the native OCR implementation.

- Fixed the Markdown clipboard mismatch: PROJECT NOTES was displayed but omitted from copied Markdown. Display and clipboard now share the same formatted lines. Browser checks verified equality for both output formats.
- Fixed unverified download inclusion: Vite copied leftover files from `public/downloads/` even when they were not validated by the manifest. Regression tests failed before the fix and passed afterward. Only the verified archive/checksum are allowed; a source-only build rejects orphaned downloads.
- Corrected sample-image dimensions, reduced-motion inline-arrow behavior and theme-color metadata. Browser checks passed in both themes and at 320, 390, 768, 1024 and 1440 pixels. Axe reported zero violations in Pearl, Midnight and mobile; no page errors or console warnings were observed.
- Added a pinned-action Website checks workflow for lockfile installation, formatting, regression tests, TypeScript and production build. It exercises the source-only path on Linux alongside the existing macOS application checks.
- An isolated export of publishable source, without ignored downloads or generated metadata, passed a fresh dependency install, formatting, all seven tests and the production build. Its artifact contains no download directory. Python source-package checks also passed (five tests).

Evidence: `website/output/playwright/ship-review-browser.txt`, `ship-review-mobile.png`, and `ship-clean-build.txt`. These local artifacts, generated downloads, dependencies and build output are excluded from Git. The initial independent finish review remains historical evidence; this follow-up review was performed in the main session.

Source target: `sometheasiekswx/mactextify`, existing `main` branch. Success means the remote revision matches the local commit and the push-triggered CI runs pass. A source rollback would be a normal revert commit on `main`; no history rewrite, data migration or DNS change is involved. Website hosting and public binary publication remain separate from this push.
