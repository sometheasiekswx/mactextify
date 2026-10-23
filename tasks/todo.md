# Local screenshot OCR for macOS — implementation status

Design and acceptance contract: [plan.md](plan.md). Current validation: [validation.md](../docs/validation.md). Product milestone history: [tasks.md](../docs/tasks.md).

Updated 2026-10-23 from existing repository records. Implementation is complete for the local scopes below; unchecked items retain the broader acceptance requirements. Recorded tests were not rerun for this documentation move.

- [x] **P1 local core:** native OCR, language/configuration handling, orientation and synthetic fidelity checks.
- [x] **P2:** Markdown/text export, keep-original default, optional archival, no-clobber writes and failure protection.
- [x] **P3:** receipt-driven recovery, duplicate/configuration handling, locking and index ownership, with interruption tests.
- [x] **P4 CLI core:** CLI, installed Finder launcher, dry-run, installation and launcher syntax checks.
- [x] **P5 automated scope:** independent-folder processing, source-byte preservation and no-op rerun checks. Selected visual references verified; this is not complete corpus fidelity validation.
- [x] **P6 local scope:** installation, distinct-version upgrade/rollback, uninstall, source-independent runtime and process-level network-denied OCR checks. Full Xcode build and Intel cross-build recorded.
- [x] **P7 local preparation:** sanitized source archive and fresh archive installation verified.
- [x] **P7 source publication:** recorded in the repository milestone history. This is separate from tagged releases and downloadable release assets; remote state was not reverified for this document move.

## Remaining acceptance work

- [ ] Minimum supported macOS and Intel hardware runtime validation; a cross-build is not runtime evidence.
- [ ] Manual Finder chooser, cancellation and keep/archive interaction checks.
- [ ] Full-corpus visual fidelity review and broader layout validation.
- [ ] Remote CI and release-artifact validation; signed/notarized binary distribution and Homebrew distribution remain separate work.
- [ ] Resolve or document the recorded Command Line Tools-only build failure; full Xcode builds passed.

## Accuracy changes and evidence

- **0.2.0:** Live Text became the default, with explicit legacy Vision and optional resampling. Receipt compatibility and configuration checks were retained. Recorded suite: 40 passing tests.
- **0.3.0:** automatic paragraph/row recognition, bounded consensus and candidate evidence were added. Selected independent references matched after whitespace normalization. Recorded suite: 50 passing tests.
- **Unreleased safeguards:** regression tests reproduced mixed-contrast omissions and image-wide frequency overriding local token majorities. Coverage checks and local-majority precedence were implemented. Recorded suite: 54 passing tests; release build and isolated install/upgrade/rollback/uninstall checks passed.

The latest safeguards retain a known capitalization difference against one independent reference. They were evaluated on copies and did not replace installed user tooling or private outputs. Complete visual accuracy is not established by test counts or agreement between OCR candidates.

Private image names, extracted text, annotations, backups and corpus-specific reports remain outside this repository. The portable evidence is in [validation.md](../docs/validation.md); no public link depends on a private study folder.
