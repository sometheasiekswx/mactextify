# Image-to-text positioning — 28 October 2026

## Scope and acceptance

Position MacTextify around extracting text from images, with photos, scans and screenshots as examples. Keep the MacTextify name and existing visual identity. The main headline is “Text in images. Now text files.” Cover the README, workflow artwork, website and metadata, product/architecture documentation, Finder launcher prompt, GitHub description and discovery topics. State PNG/JPEG input and text/Markdown output accurately; do not imply PDF/HEIC input, guaranteed accuracy or new OCR capabilities. Preserve historical validation and old-command migration references.

## Delivery plan

1. Audit supported inputs and current public copy, then update the related surfaces together.
2. Check formatting, website tests/build, launcher syntax, source packaging, SVG validity and rendered layout at desktop/mobile sizes. Reuse existing OCR behavior checks because recognition code is unchanged.
3. Review the exact diff for unsupported claims, stale public positioning, layout and behavior regressions. Fix and recheck findings before pushing.
4. Commit/push the scoped changes, update the GitHub description/topics, observe Pages deployment, and verify the actual public site and repository metadata. The existing hosting runbook covers rollback; no app binary publication is included.

## Verification

Results and the deployed revision are recorded in the delivery message and local evidence under website/output/playwright/. Historical screenshot-specific test evidence remains unchanged.

## Pre-push result

Website formatting, seven release/preparation tests, TypeScript and both local-preview/source-only production builds passed. Source-package tests passed (five). Shell syntax and both embedded AppleScripts compile. Both workflow SVGs parse and agree with their source titles. Browser checks passed for playback/pause, keyboard progress, text/Markdown copying, expanded format guidance, both themes and widths 320/390/768/1024/1440; axe reported zero violations and no runtime errors were observed. Desktop/mobile renders were visually reviewed. The README workspace composition was regenerated to remove its baked-in screenshot-only caption, then inspected; native source captures retain their original hashes. Review found no remaining blockers. Native OCR code and supported formats are unchanged.
