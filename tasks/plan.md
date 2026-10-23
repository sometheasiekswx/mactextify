# Implementation plan: Local screenshot OCR for macOS

Date: 2026-10-23
Status: implemented locally through 0.3.0, with subsequent unreleased accuracy safeguards. Platform, manual UI and release validation remain incomplete.
This document preserves the implementation requirements; current behavior is described in the [README](../README.md) and [architecture](../docs/architecture.md).
Requirements: reusable, local screenshot-to-text processing for macOS.
Task status: [todo.md](todo.md). This document owns requirements and rationale; the task list owns completion status.

## Product outcome

Provide an open-source, installable macOS tool that turns screenshots from any project into searchable Markdown or plain-text files using Apple Live Text and Vision locally. Intended users include learners, researchers, developers and anyone collecting text-heavy screenshots.

Install the tool once and point it at independent folders. Preserve originals by default; offer explicit archival after successful export for inbox workflows. Optional archival uses `Processed`. Consumers include people, search tools and AI assistants; no ChatGPT or Codex account is required.

Success means repeatable extraction and safe filing with explicit uncertainty. It does not mean the OCR has understood a question, identified its correct answer, or verified its wording.

### Implementation evidence

Local implementation and validation are recorded in [todo.md](todo.md) and [validation](../docs/validation.md). The latest recorded suite has 54 passing tests, release-build and isolated installation checks. These are existing results, not tests rerun during this documentation move. Full-corpus visual accuracy, minimum-OS/Intel runtime and manual Finder interaction remain unverified.

### First-release boundaries

In scope: PNG/JPEG screenshots; top-level folder scanning; local recognition with English as the default and runtime-validated language selection; Markdown or plain-text exports; confidence warnings; an index; optional archival; safe reruns and recovery; an installable CLI and Finder folder chooser; public source distribution, macOS CI and contribution documentation.

Non-goals: PDF/HEIC support, recursive scanning, folder watching, cloud sync, cloud OCR, LLM correction, answer generation, semantic question parsing, flashcards, audio generation, a full native GUI, a privileged installer, Windows/Linux OCR, and automatic updating. These can be evaluated after the actual screenshot corpus establishes a need.

Assumptions: a local writable input folder, one active process per folder, and normal user backups. Different project folders have independent outputs, locks and receipts. Proposed support target: macOS 14 or newer, Apple Silicon and Intel, subject to build and runtime evidence before claiming support. Runtime OS requirements and source-build Swift/Xcode requirements must be documented separately. No root permissions, account, API key, paid OCR service, or background service.

## User experience and output contract

1. Install once from a versioned release of the public source project.
2. Run the CLI with an explicit folder, or open the Finder launcher, choose a folder and choose whether to archive successfully processed originals. Cancelling the chooser makes no changes. Never infer the target from the installation directory or current directory.
3. See progress using filenames, then counts for exported, review-needed, duplicate, and failed items. Screenshot text is not printed to the terminal by default.
4. Open `Extracted/index.md` to navigate outputs and review warnings.
5. Ask Codex to read specific extracted files. Reading text still consumes text tokens; OCR itself makes no model calls.

Repository and input-data separation:

```text
public-repository/                 source checkout; separate from private input data
  Package.swift
  Sources/ScreenshotOCR/
  Tests/ScreenshotOCRTests/
  Tests/Fixtures/                  synthetic, redistributable examples only
  scripts/                        install, release and Finder launcher helpers
  .github/workflows/              macOS checks and explicitly triggered release
  README.md
  LICENSE
  CONTRIBUTING.md
  SECURITY.md
  CHANGELOG.md
  docs/

any-private-project-folder/       external to repository and installation
  incoming-image.PNG
  Extracted/
    <source-stem>--<content-id>.md  or .txt
    index.md
  Processed/                      created only for requested archival
    <source-stem>--<content-id>.PNG
  .ocr-state/
    lock
    records/<content-id>.json
```

These planning documents are sanitized for the source repository. Keep private screenshots, exports, receipts, references and evaluation logs outside the repository. Repository ignore rules do not replace a staged-file audit.

The content ID is the full SHA-256 of the original image bytes. Safe filenames use a sanitized, bounded stem plus the full ID; the exact original name is retained in metadata. Different bytes with the same filename produce separate records. Identical bytes under different names reuse the existing extraction. V1 leaves duplicate incoming copies untouched and reports their existing output; it does not delete or repeatedly OCR them.

Each Markdown export contains source filename, hash, extraction time, engine/configuration version, extraction status, review warnings, relative original-image link, and recognized lines. Render OCR as literal text in Markdown with delimiters that cannot be broken by recognized backticks; escape filename labels and percent-encode link paths. This preserves the data boundary for readers but is not a guarantee against downstream LLM prompt injection. Plain-text exports contain recognized lines only; metadata and warnings remain in receipts and the index. Preserve capitalization, numbers and punctuation; do not invent option labels, remove apparent UI text, or repair technical names heuristically. Keep any later study notes separate from generated exports.

`index.md` lists filenames, output links, and review indicators without embedding question bodies. It is derived from receipts and can be rebuilt. Image links resolve to the input when originals are kept or archival is pending, and to `Processed` after archival succeeds. An interrupted link update is repaired on rerun.

### Core CLI contract

See the [README](../README.md) for current engine, layout and scaling options.

- `screenshot-ocr process --folder PATH`: recognize and export new images without moving originals; resume pending operations according to their recorded policy.
- `--archive`: explicitly move successful inputs into `Processed`. The CLI defaults to keeping sources.
- `--format markdown|text`: choose export format (default Markdown).
- `--languages en-US,...`: select supported recognition languages (default English); reject unsupported values before changing files.
- `screenshot-ocr languages`: list languages supported by the selected engine on this OS.
- `--version`: print tool version; receipts also record OS/engine and effective configuration.
- `screenshot-ocr process --folder PATH --dry-run`: report proposed work and detected conflicts without OCR, directory creation, or changes.
- `screenshot-ocr status --folder PATH`: report recorded results and pending/error states without mutation.
- `--help`: describe supported formats, output locations, duplicates, recovery and exit codes.

Configuration is explicit CLI flags with documented defaults; no hidden global project configuration in V1. Record format, languages, correction setting and archival policy per receipt. A completed content ID with a conflicting requested configuration is reported as a configuration conflict, never silently reused or overwritten. Pending transactions resume using their recorded policy; changing configuration does not mutate a partial transaction.

Exit 0: completed, including review warnings and reported duplicates. Exit 1: one or more item failures or incomplete operations. Exit 2: invocation/preflight failure, including an active run. Per-image errors do not prevent independent images from being processed.

## Architecture and decisions

Use a small Swift Package Manager executable with Apple Vision, Foundation, ImageIO, CryptoKit and Darwin where needed for filesystem locking. No external dependencies. Build during installation, not each invocation. The installed launcher locates the installed binary and uses a folder chooser, quotes paths and passes an explicit archival choice. It must work independently of the clone location. A missing installation gives a readable error and does not start processing. Core processing and formatting must contain no domain-specific terminology, personal paths, or assistant-specific behavior.

Internal responsibilities, within one executable rather than separate services:

| Component | Responsibility and contract |
|---|---|
| CLI / launcher | Validate arguments; display progress and summaries; preserve exit status |
| Input discovery | Enumerate regular, non-symlink top-level PNG/JPEG files; identify bytes and orientation |
| Vision adapter | Return ordered text observations with confidence and bounds; no file moves |
| Export formatter | Turn observations and metadata into literal text within Markdown |
| Processing coordinator | Own state transitions and failure isolation |
| State / archive store | Atomic receipts, no-clobber output publication, content checks, safe archive moves |
| Index builder | Derive navigation from committed records; never determine processing truth |

Dependency direction: CLI → coordinator → recognition and storage interfaces. The recognition adapter does not know about output folders. Filesystem failure injection belongs at the storage boundary for tests.

Decisions and tradeoffs:

- **Direct Vision over ocrmac:** Swift/Xcode already exist; avoid a Python environment and bridging dependencies. ocrmac remains an alternative if native integration proves impractical.
- **Small executable over a native app:** one repeatable action and readable outputs meet the need. A CLI is the stable interface for other projects; a small Finder helper makes the same behavior accessible. Public packaging and documentation are release requirements, while a full GUI is deferred.
- **Individual Markdown over one growing document:** precise selection, smaller context consumption, and independent recovery.
- **Versioned JSON receipts over a database:** a small local corpus does not justify database migrations. Receipts are authoritative; the index is disposable. Reject unknown newer schema versions rather than guessing.
- **Sequential OCR:** bound memory and simplify recovery. Measure the real batch before considering concurrency.
- **No destructive reprocessing in V1:** existing or edited exports are protected. An engine upgrade does not silently replace prior outputs.

Apple documents local recognition, confidence and bounds in [Recognizing Text in Images](https://developer.apple.com/documentation/vision/recognizing-text-in-images). [ocrmac](https://github.com/straussmaximilian/ocrmac) is the evaluated wrapper alternative. These sources establish capability, not accuracy on this corpus.

## Safety and recovery contract

Core invariants:

1. No original image is deleted. The only normal input mutation is a move into `Processed` after its output is saved and verified.
2. Never overwrite an existing image, text file, or unrelated state. Existing matching records are validated before reuse.
3. A failed or empty extraction leaves the input untouched. Nonempty low-confidence extraction is saved and, if requested, archived with a visible `needs-review` warning.
4. A move failure leaves the saved text and source intact, records `archive-pending`, and can be resumed without OCR.
5. Generated text is always labelled unverified. Confidence does not prove completeness or correctness; diagrams, color and answer highlighting are not reconstructed.
6. No network requests, LLM calls, hidden telemetry, shell evaluation of filenames, or execution of recognized text.

State progression per content ID:

```text
discovered → prepared → exported → archived (only if requested) → indexed
                 │          │          │
                 └──────── failures recorded; next run reconciles files
```

`prepared` stores the planned paths and input fingerprint before output publication. Write output through a temporary sibling, close it, publish without clobbering, and verify the resulting content before marking `exported`. Store the export checksum in the receipt. Update receipts atomically. Before moving, revalidate the source hash; a changed source must not be archived against stale text. Use no-replace move semantics; do not fall back to copy-and-delete across volumes.

On restart, inspect both state and actual files. Handle interruption after output publication but before receipt update, and after image move but before marking archived. Adopt files only when their identity matches the record; ambiguous conflicts are reported and left untouched. If a previously exported file has been edited or removed, do not overwrite or regenerate it automatically. A missing receipt with colliding output requires explicit reconciliation, not inferred ownership.

Use a process-scoped advisory lock so two runs cannot modify one folder simultaneously and process death releases ownership. Do not use the mere presence of a lock file as proof of a running process. Reject symlinked managed directories and image inputs; do not follow paths outside the selected folder. Reject unsupported storage arrangements rather than weakening guarantees.

Recovery covers ordinary process interruption and reported I/O errors. Do not claim protection against disk hardware failure or guaranteed power-loss durability without implementing and testing the necessary filesystem behavior. JSON state and exports supplement, not replace, backups.

## Recognition quality and performance

Start with English accurate recognition and correct image orientation; validate requested language support at runtime rather than hard-code a universal language list. Compare language correction enabled/disabled on synthetic prose, technical identifiers and multilingual strings before selecting the default; record the choice. Any custom vocabulary must be explicit and tested, not a silent rewriting layer.

Use observation geometry to establish line order; verify multi-column and split-line examples rather than assuming a global Y/X sort always works. The initial implementation used whole-image recognition. Version 0.3.0 added automatic paragraph/row recognition and retained candidate evidence. Unreleased safeguards check observation coverage and prioritize local token majorities; unsupported layouts fall back to whole-image recognition.

A configurable confidence threshold may flag review-needed lines; select and document the initial value from pilot observations. Do not describe it as a probability of correctness. Blank recognition is failure; diagrams with otherwise readable text remain explicitly outside text-only validation.

Measure cold build, warm processing time per image, total batch time and resource behavior on the validation host. Establish a baseline rather than inventing a latency SLA. Add resource limits only with evidence or an explicit operational requirement.

## Ordered implementation slices

### P1 — Prove local OCR and text fidelity

- Depends on: none.
- Areas: `Package.swift` in the separate public checkout, Vision adapter, synthetic fixtures/tests.
- Outcome: a vertical path from an image file to recognized observations, with no archive changes.
- Acceptance: compiles on the validation host and the proposed compatibility matrix; recognizes synthetic prose, question/option text, numerals and technical abbreviations; validates language selection; handles orientation and corrupt files; reports confidence; makes no application network calls.
- Verification: run compiler/package tests and compare synthetic output with known fixture text. During implementation, run a small real-image pilot in temporary output space, leaving originals untouched. Compare pilot output against independently inspected image references; keep references separate from recognition code. Record unresolved fidelity issues rather than claiming accuracy from confidence alone.
- Gate: no full-batch processing until this path and its limitations are understood.

### P2 — Deliver safe single-image export and archival

- Depends on: P1.
- Areas: discovery, formatter, coordinator, receipts/archive storage, integration tests.
- Outcome: one command produces a Markdown or text export, leaves its source in place by default, and archives into `Processed` only with `--archive`.
- Acceptance: hash-based identity, both format contracts, valid original link, no-clobber writes, source-byte preservation, nonempty/empty and review-needed policies implemented. Exercise a generic research folder as well as another independent use case; no hard-coded domain logic.
- Verification: temporary-folder tests assert expected text, identical image hashes before/after, unchanged source on export failure, collision handling, special characters/spaces in paths, and rejection of symlinks.
- Recovery: failures retain source and any committed export; no cleanup removes originals.

### P3 — Make reruns, interruption and batches reliable

- Depends on: P2.
- Areas: reconciliation logic, advisory lock, batch coordinator, index, failure-injection tests.
- Outcome: mixed batches continue past item failures; reruns neither repeat completed OCR nor overwrite exports.
- Acceptance: same/different-name duplicates, same-name different-content inputs, modified inputs/outputs, output conflicts, missing files and unknown receipt versions handled explicitly. Two concurrent invocations cannot mutate the same folder simultaneously; different folders remain independent. A changed extraction configuration cannot silently reuse an incompatible result.
- Verification: inject failures before/after each publication and move boundary; restart and inspect outcomes. Simulate denied writes/disk-write failures through the storage interface. Test process termination, lock release, archive failure, malformed images and index rebuild. Count OCR calls to prove recovery does not repeat successful extraction.

### P4 — Provide the everyday Finder and CLI experience

- Depends on: P3.
- Areas: launcher, CLI, README, help/status output.
- Outcome: one installed binary serves unrelated folders; Finder selection works without assuming the current directory or repository location.
- Acceptance: proposed commands and exit codes implemented; dry-run leaves folder contents unchanged; readable summary without full recognized text; installation failures do not touch screenshots; no compiler is needed at runtime for an already built installation. Instructions cover duplicates, review warnings, recovery and uninstall.
- Verification: actual Finder launch, folder-chooser cancellation, keep/archive selection, arbitrary working directory, paths with spaces, empty folder, missing installation simulation, active lock and partially failed batch. Compare before/after directory manifests for dry-run.
- Recovery: uninstall only managed installed executables/launcher using the installation manifest; retain every project’s images, exports and receipts. Test that unrelated files in the installation prefix survive.

### P5 — Validate private and general-purpose workflows

- Depends on: P4 and pilot review evidence from P1.
- Areas: README, validation evidence, existing screenshot batch when implementation is authorized.
- Outcome: validated private use plus redistributable synthetic examples covering at least two independent use cases (research notes and technical screenshots).
- Acceptance: account for every original input as successfully exported-and-kept, archived, unchanged duplicate, or unchanged failure; archived image hashes match input inventory; every successful record has a readable export and working image link; rerun performs no new OCR for completed items. Production recognition remains local OCR; independently inspected references are evaluation-only.
- Verification: first inventory hashes, then run the batch, inspect text summaries and filesystem reconciliation, rerun, record timings and human spot-check limitations. Run all automated tests and release build once after final changes. Never upload the real batch, extracted text, private hashes or filenames as CI fixtures or evidence.
- Gate: file-loss, overwrite, recovery, or unexplained accounting failures block handover. Unverified OCR fidelity is reported explicitly and not relabelled as validated.

### P6 — Make installation and contribution reproducible

- Depends on: P3, P4; may precede completion of private P5 review.
- Areas: clean repository, installation helper, synthetic fixtures, README, LICENSE, CONTRIBUTING, SECURITY, changelog and macOS CI.
- Outcome: an outside user follows the README from a clean checkout and processes an unrelated folder.
- Acceptance: install a selected release tag into a user-owned prefix (default `~/.local/bin` with versioned support files); no `sudo`, no network shell piping, no dependency on personal filesystem paths. Installer detects conflicts, writes only managed files and records a manifest. The repository uses MIT; verify license and copyright metadata before each release. Describe Apple framework dependency and macOS-only scope without bundling Apple components.
- Verification: build/test on explicit ARM and Intel macOS runners; validate the claimed minimum OS separately if CI cannot run it. Fresh install, PATH instructions, offline runtime, upgrade, uninstall and older binary against newer receipts all tested in isolated home/prefix directories. A clean installation must run after the source checkout is moved away. Document unsupported combinations instead of marking compile-only coverage as runtime support.
- CI security: least-privilege read-only PR checks, pinned third-party action revisions, no release credentials available to untrusted PR code, and no paid runners selected without explicit authorization. Recheck runner availability during implementation.

### P7 — Prepare a public GitHub release

- Depends on: P5, P6 and publication decisions below.
- Areas: release workflow, artifact manifest, sanitized public documentation, release notes.
- Outcome: a reviewable, versioned source release with tested installation and upgrade instructions.
- Acceptance: clean public file list; only owned/licensed synthetic fixtures; no private screenshots, exports, receipts, absolute personal paths, credentials or private logs; synthetic demonstration images and outputs must be explicitly identified and licensed. Tag version and changelog agree with `--version`. A tarball from the actual release builds and passes a smoke test. No release implies untested platform support.
- Verification: audit tracked files and history before first push; build from a clean tagged checkout; inspect archive manifest and verify published artifact checksum after authorized publication. Test README on a clean environment and track the support matrix in release notes. Prepare a rollback procedure that reinstalls a previous executable without rewriting project data.
- Gate: repo owner/name, visibility, license/copyright and installation instructions must be settled before publication. Source availability is the zero-fee baseline. A prebuilt binary release requires its own distribution validation below.

## Distribution, compatibility and maintenance

**Recommended first public release:** versioned GitHub source plus a local build/install helper. Users need compatible Xcode Command Line Tools (verify whether full Xcode is avoidable); they do not need a paid Apple developer account to build from source. This minimizes maintainer cost while delivering a genuinely installable tool. Installation may fetch source/toolchains; OCR runtime stays local and offline.

**Convenience distribution:** add a custom Homebrew tap with a formula building from the tagged source after the installation contract is stable. Do not promise Homebrew core acceptance. Publish prebuilt ARM/Intel artifacts only after checking supported targets and Gatekeeper behavior; ordinary non-developer download-and-run use needs a tested signing/notarization strategy. Never instruct users to disable Gatekeeper globally or silently strip quarantine. Developer ID credentials and any associated enrollment cost require a separate owner decision; do not invent a zero-cost notarization guarantee.

Reference: [Apple distribution/notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution) and [GitHub runner availability](https://docs.github.com/en/actions/reference/runners/github-hosted-runners). Availability and account billing must be rechecked before running release workflows.

The initial implementation was 0.1.0; 0.3.0 and subsequent unreleased safeguards are recorded in the [changelog](../CHANGELOG.md). Record breaking CLI/output/state changes in release notes; reach 1.0 only when the documented contract is stable. Keep receipt schema version independent of application version. Never silently migrate to a format an older binary will misinterpret; unsupported versions fail safely. Future migrations need backups and migration tests. No automatic update checks or telemetry.

README must include: who it is for; a synthetic before/after example; supported formats/OS/architectures; install/uninstall/upgrade; quick starts for keep and archive; language/format options; privacy and filename metadata; accuracy/diagram limits; exit codes; recovery; contribution/testing instructions. SECURITY.md explains responsible reporting without uploading sensitive documents; bug templates request synthetic reproductions and warn that filenames and OCR outputs may be private. License text, fixture provenance and maintainership details are required before public release, not assumed from this plan.

## Quality and evidence checkpoints

Verification commands (recorded results and limitations are in [validation](../docs/validation.md)):

- `swift build` (public checkout)
- `swift test` (public checkout)
- `swift build -c release` (public checkout)
- `.build/release/screenshot-ocr process --folder <temporary-fixture-folder> --dry-run`

Use Swift's package tooling and tests; no arbitrary coverage percentage or extra lint dependencies. macOS GitHub Actions build/test checks and clean-install smoke tests are part of the public-release contract. Filesystem invariants and recovery scenarios block release if failing. Confidence and speed measurements are reported diagnostics until evidence supports stronger acceptance thresholds.

Evidence checkpoints: native OCR integration (P1), export/move transaction (P2), crash/restart behavior (P3), Finder execution (P4), complete corpus accounting and repeat run (P5), clean installation/compatibility (P6), public release audit (P7). Add results to the task list as work finishes, with a linked evidence file if needed. Consult the linked validation record for completed checks; this plan does not imply all acceptance criteria have passed.

## Risks, unresolved decisions and authorization

| Risk | Mitigation / next evidence |
|---|---|
| Missing options, numbers, or reading-order errors | Synthetic assertions plus small real pilot; preserve originals and unverified labels |
| OCR cannot express a diagram or answer highlighting | Explicit limitation; user can refer to preserved source |
| Interruption separates output and image state | Receipt-driven reconciliation and injected interruption tests |
| Editing, duplicate names, or external file changes | Hash identity, no-clobber operations and checks before archival |
| Finder execution or first build fails | Validate on the validation host; readable prerequisite failure and CLI alternative |
| OS/engine updates change OCR | Record engine/configuration and preserve existing exports |

Local implementation is complete for the scopes recorded in [todo.md](todo.md). Minimum-OS/Intel runtime, manual Finder interaction and complete visual fidelity remain open. The repository records source publication separately from versioned release assets; do not infer a published release or verified remote CI from local checks. Any future release requires current distribution and platform evidence. Additional formats, a GUI or background monitoring require a separate scope decision.

This document records requirements and evidence; it does not authorize publication, installation changes, or reprocessing private data.
