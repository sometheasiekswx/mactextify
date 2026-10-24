# README presentation

## Acceptance criteria

- Lead with MacTextify branding and real native-app screenshots; synthetic inputs only.
- Show a successful batch and its actual output. Select captures for legibility, useful state and absence of private data.
- Generate an accessible workflow diagram using cathrynlavery/diagram-design, with editable HTML and README-compatible light/dark SVG exports.
- Keep source-build requirements, OCR limitations, privacy, recovery and CLI documentation discoverable and accurate.
- Preserve existing detailed CLI instructions in a linked guide.
- Verify rendered README at desktop and narrow widths, local links, image integrity, source packaging and unchanged synthetic originals.
- Complete local review and release-readiness checks. The initial task stopped at local readiness; the subsequent review/ship request authorizes committing and pushing the presentation to main. No binary release requested.

## Work order

1. Inspect live app/source and reference READMEs; review the exact diagram-design candidate before use.
2. Prepare synthetic inputs and capture the packaged native app before and after extraction.
3. Curate screenshots and write the visual-first README, linked CLI guide and diagram.
4. Verify rendered presentation, links and allowlisted source archive; review the final diff.

## Completion and verification

All six auto stages completed proportionately: acceptance criteria and ordered plan above, documentation/assets built, targeted verification, final local review, and source-package readiness. The subsequent review/ship request adds source publication to main; no tag or binary release is part of this change.

- The previously clean checkout at `f251841` supplied the unmodified app. Three new synthetic inputs were processed through the real native picker and Live Text engine. All three transcripts matched the intended source lines exactly, and all original image hashes were unchanged.
- Selected two 1760 × 1120 screenshot compositions after inspecting empty, queued, expanded completed, and collapsed completed states. The app UI and actual TextEdit export were captured natively; surrounding framing and captions were added separately.
- Both diagram HTML files passed diagram-design's offline self-check and geometry checker. SVG exports use system fonts, no external resources, and explicit accessible titles/descriptions. Reviewed the actual exported light/dark images; fixed an exporter-filtered eyebrow class before final verification.
- GitHub's Markdown API rendered the README for local browser inspection with GitHub-like preview styling. Desktop light/dark and 390px narrow views were inspected. All five images loaded, dark logo/diagram sources switched, and the narrow page width equaled its 390px viewport. This is a local preview, not a published GitHub-page verification.
- Local link targets in README, CLI guide and asset provenance exist. Source archive checks confirm the same targets are packaged. Both final screenshots are exact allowlist exceptions; unknown binary paths remain rejected.
- `python3 scripts/test-package-source.py`: 5 tests passed. `python3 scripts/package-source.py`: source archive prepared with the full public documentation/asset manifest and privacy checks intact. The native app built successfully in release mode from a fresh extraction of the archive.
- `git diff --check`: passed. Final review found no blocking issue in documentation accuracy, screenshot provenance, privacy boundaries or packaging scope. No product source or tests were modified. During the subsequent review/ship pass, all 75 Swift tests and the CLI/install smoke test passed. The native extraction and fresh archive release build provide additional behavior evidence.

The exact diagram-design candidate was reviewed and used from a temporary checkout, not globally installed. Its static scan reported 24 findings and partial coverage; manual triage was bounded to the used instructions/helpers, with limits documented in `docs/readme-assets.md`.

## Review and source publication

The follow-up review caught a publication blocker: the repository's broad image ignore rule also excluded the two new screenshot PNGs. Added exact exceptions for these two public synthetic captures; all other image inputs remain ignored. Rechecked the publication tree and source archive.

Local presentation readiness is complete. The authorized target is the existing public GitHub repository's main branch. Rollback is a normal revert of this presentation commit; product source and receipt formats are unchanged. Remote main and the rendered README/assets must be verified after pushing, with the resulting CI status reported separately. No binary release, signing/notarization, or broader platform/accessibility verification is claimed.
