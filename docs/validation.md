# Custom output-folder validation

58 tests pass, including destination ownership, symlink rejection, escaped source links, idempotency, edited-output protection, dry-run immutability, archive rejection and interrupted text-export recovery. Release build and CLI/install/recovery smoke checks pass. Three screenshot copies were extracted successfully into an independent destination; existing study files were unchanged.

Review covered path handling, destination binding, locking, recovery, rendering and compatibility with the default directory layout. No blocking findings. Custom output mode requires keeping originals; minimum-OS, Intel and manual Finder checks remain unverified.

---

# Current validation — unreleased accuracy safeguards

The mixed-contrast omission and image-wide frequency override were reproduced by new failing regression tests before the fixes. Automatic layout now checks horizontal and vertical observation coverage; local aligned token counts take precedence over image-wide frequency. Adaptive engine evidence identifies this algorithm as v2; receipt schema and the eight-candidate format are unchanged.

54 tests pass locally on Apple Silicon/macOS 27.0.1, including grey paragraphs at the top, middle and bottom, a conflicting-identifier 6–2 majority, tie-breaking, vertical exclusion, the existing dense/colored slide, and storage/recovery/compatibility tests. The release build and isolated installation/upgrade/rollback/uninstall smoke suite pass. The installed user CLI has not been replaced.

All 22 archived screenshot copies processed successfully under process-level network denial, with zero failures; a rerun performed zero export work. Copied original hashes matched the sources. All 70 existing files under the study archive, exports and receipt/state directories retained their original hashes and file inventory.

Two of the three independently referenced screenshots still match exactly after whitespace normalization. The third has one capitalization difference (a lowercase word initial becomes uppercase); all remaining text, prompts and options match, including the literal source typo. The stricter local vote prefers that capitalized candidate, so this is a known accuracy limitation rather than an exact-match success. No reference-driven correction is added. Across all 22 outputs, 13 match the saved text after whitespace normalization; the other 19 screenshots do not have complete visual reference verification. None of these generated results replaced study outputs. No GitHub publication or remote CI occurred. Minimum-OS/Intel runtime and manual Finder interaction remain unverified.

---

# Historical validation — 0.3.0 adaptive OCR

All three reported private screenshots exactly match an independently prepared visual reference after whitespace normalization, including complete prompts/options and identifiers. A second comparison after installing and promoting the outputs confirmed the matches. References are evaluation-only and are excluded from the software repository. A source typo was preserved after native-resolution verification.

50 automated tests pass locally on Apple Silicon/macOS 27.0.1: the prior storage/recovery suite plus synthetic dense/colored text, consensus behavior, unchanged identifiers/negation, crop exclusion checks, multi-column rejection, candidate evidence validation and legacy layout meaning. Release build and install/upgrade/rollback/uninstall smoke checks pass. The final three-image pipeline ran under process-level network denial. A separate 22-image copy batch completed with matching image hashes; this is not full-corpus visual accuracy validation.

Only the three requested private exports/receipts were replaced, with previous files and user annotations backed up. Original archive bytes and the other exports were unchanged. An installed-runtime rerun made no changes. Candidate disagreements remain available in receipts, and no confidence value or universal accuracy claim is inferred from agreement. The tool has no new runtime dependencies. A Tesseract experiment was rejected and removed.

The tests below describe earlier versions. Minimum-OS/Intel hardware runtime and manual Finder interaction remain unverified; no remote CI or publication occurred.

---

# Historical validation — 0.2.0 accuracy repair

The reported private regression was reproduced with 0.1.0. Legacy Vision with language correction still emitted an extra fragment. Public VisionKit Live Text matched the supplied Preview option B exactly (whitespace normalized). Other passages are not assumed correct merely because this reference passes.

All 22 private images were compared between engines; 15 changed beyond whitespace. Five difficult images were additionally compared at scales 0.5, 0.75, 1, 1.5 and 2. No scale improved every image. Half-size processing recovered an omitted answer option in one case, while some passages remained garbled. Private reference text, comparisons and backups stay outside this repository.

40 automated tests pass, including both engines, resampling, missing confidence, and schema-1 compatibility. The install/upgrade/rollback/uninstall smoke test passes. The repaired 22-file batch was promoted only after validating old outputs, preserving backups, checking the supplied reference and confirming archived image hashes. A rerun made no changes. Some passages remain unreliable and are explicitly recorded in the private review report; no full-corpus accuracy percentage is claimed. Hardware/UI limitations from the original validation remain applicable. Live Text scores are unavailable, not inferred from the legacy engine.

---

# Historical validation — 0.1.0

Local development verification, 2026-10-23. No GitHub remote or published release.

## Passed locally

- Swift 6.4 / full Xcode: debug and release builds on Apple Silicon, macOS 27.0.1.
- 34 Swift/XCTest tests: native Vision (English prose, numbers, technical identifiers, language correction on/off, French, two-column content, corrupt/blank images, rotated JPEG with EXIF orientation); persistence/CLI-core behavior (keep/archive, both formats, hashes, duplicate handling, configuration conflicts, dry-run, edited/missing outputs, source changes, every transaction interruption point, lock contention, symlinks, receipt traversal/schema corruption, index recovery and code-fence escaping).
- Developer smoke checks: CLI exits, dry-run immutability, real subprocess lock contention and SIGKILL release, installation, reinstall, distinct-version upgrade, rollback, relocated installation independent of source checkout, uninstall preservation and unrelated executable collision.
- A private 22-image validation corpus processed through copies outside the repository: 22 archived copies retained matching original hashes; 383 recognized lines; four low-confidence review flags. Repeat execution performed zero OCR/export work and changed no generated/state/archive file contents. Original inputs were unchanged. Batch: approximately 2.9 seconds warm; rerun approximately 0.04 seconds. Initial three-image pilot including cold initialization took approximately 27 seconds. These are observations on one machine, not an SLA.
- Synthetic native tests retain expected words/numbers. A private text-only pilot showed plausible clipping/recognition errors despite confidence 1.0; confidence does not establish correctness. Human visual comparison of the private screenshots remains outstanding.

- x86_64 release cross-compilation passed; this is not an Intel hardware test. The installed ARM binary declares macOS 14.0 as its minimum OS in `LC_BUILD_VERSION`.
- A deterministic 28-file allowlisted source archive passed extraction, fresh source installation, CLI dry-run and uninstall in a temporary prefix. Packaging scanned for private paths/common credential patterns and included no image binaries or private validation data.
- Installed runtime performed real OCR under process-level network denial (`sandbox-exec`); this is not a claim that all operating-system services were globally disconnected.
- All 22 preserved-image links from the private copy batch resolved, and the original image inventory remained byte-identical after tests.

## Limits / not yet verified

- Minimum macOS 14 runtime and Intel hardware runtime: CI matrix is prepared but has not run remotely. Cross-compilation, when reported separately, is not runtime validation.
- Command Line Tools-only build on this machine failed linking the Swift PackageDescription manifest API. Full Xcode builds pass. Do not claim this CLT installation works or alter user toolchain settings to hide the issue.
- Finder chooser interaction has been source/syntax checked, not manually exercised end-to-end. CLI and installed sibling executable behavior are covered by smoke checks.
- No actual filesystem power-loss/disk-full exercise. Interruption and blocked writes are injected at meaningful boundaries; real process termination tests cover lock release.
- No signed/notarized download, Homebrew tap, public CI result, GitHub tag/release or public security-reporting channel exists.

For exact commands see README.md. Additional packaging/cross-build results are recorded in the local task status. All test images are generated from owned synthetic strings; private fixtures and logs are excluded from source packaging.
