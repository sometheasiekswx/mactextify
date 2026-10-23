# Design and engineering contract

The public-facing product is a macOS local screenshot OCR tool, independent of any particular subject or assistant. The package contains an executable CLI and an internal OCRCore target; the latter is an implementation boundary, not a promised stable third-party SDK.

## Boundaries

- `LocalRecognizer`: select the requested local engine without silent fallback. `LiveTextRecognizer` uses public async VisionKit analysis and stores unavailable confidence/geometry as null.
- `VisionRecognizer`: decode bytes/orientation, use accurate legacy Vision recognition, return observations and engine identity. Preserve Vision's block order rather than pretend a global coordinate sort understands columns. Geometry is retained in receipts for diagnostics.
- `Models`: versioned configuration/receipts, content hashes and safe output formatting.
- `Storage`: non-symlink file reads, restrictive new files, no-clobber publication, advisory locking, versioned receipts and index ownership.
- `Processor`: discovery, reconciliation, isolated per-image errors, conditional archival and summaries.
- CLI: flags, validation, progress and exit codes. Finder is a thin folder chooser over this interface.

Sequential processing bounds concurrent work and simplifies recovery. SHA-256 of image bytes is the per-folder identity. The tool supports one configuration per identity (including engine, layout and scale); configuration changes are explicit conflicts. No database, third-party packages or network runtime.

## Transactions

Receipt stages: `prepared → exported → archived` (archived only with the saved archive policy). Index generation is derived from receipts and not a prerequisite for preserving data.

Before the first receipt, OCR completes and source bytes are rechecked. A prepared receipt stores immutable observations, configuration, version and timestamp. Expected export bytes and their checksums are reproducible from this receipt; storing a second independent export hash is unnecessary. Temporary output is flushed and published with no-replace rename. A receipt update records exported state before moving a source. Immediately before moving, source identity and saved output are rechecked. No copy/delete fallback across volumes.

After moving, mark archived and change the original link in Markdown. During interrupted recovery, accept only the exact pre-archive or final rendering, and verify archived bytes. A simultaneously present source and archive during pending archival is ambiguous and rejected. Edited exports are never replaced. Receipts are validated for schema, ID and basename containment before paths are constructed.

Writes and moves are coordinated by an OS advisory lock. Process death releases the lock. Index replacement uses a separate ownership receipt accepting old/new hashes across an interrupted update. Missing indexes can be rebuilt; unrelated or edited indexes are protected.

## Threat and failure model

Support one user on a local filesystem with cooperative tool processes. Reject symlink inputs and managed paths, malformed receipts, unsafe basenames and nonregular reads. Escape Markdown labels/links and use a code fence longer than any recognized backtick sequence. OCR text remains untrusted for downstream assistants.

This is not a hostile multi-user filesystem sandbox. Another application racing pathname changes, hard power loss, disk corruption and network/cloud synchronization are not guaranteed safe. Original data is never deliberately deleted, and user backups remain necessary. Filesystem errors and process interruptions are covered by tests.

## First-release boundaries

PNG/JPEG, top-level folders, Markdown/text, language selection, explicit archive, CLI/Finder, source installation and synthetic tests. PDF/HEIC, recursive scans, background watching, semantic correction, cloud OCR and a full GUI are deferred. Desktop UI/Intel/minimum OS runtime claims require their own evidence.

## Accuracy correction in 0.2

An actual screenshot regression demonstrated both spelling errors and a duplicated fragment in legacy Vision output. Language correction alone did not remove the fragment. Public Live Text matched the supplied Preview passage. Corpus comparison also found that Live Text is not uniformly better, and optional resampling changes recognition. No semantic spell-fixing, answer inference, or silent paragraph merging is performed.

Schema-1 configurations missing engine/scale mean Vision at scale 1. Schema-2 configurations record the new defaults explicitly. Missing Live Text confidence/geometry stays unavailable. Existing schema-1 exports must render byte-for-byte identically for recovery ownership checks; tests cover this compatibility boundary. New records are deliberately rejected by older binaries rather than misinterpreted.

## Adaptive recognition in 0.3

The 0.2 Preview comparison was too narrow: Preview also misread the images. Independent visual references exposed omitted paragraphs, duplicated fragments and incorrect identifiers. Evaluation references remain private and are never production inputs.

`TextPageLayout` detects broad light-background text panels, rejects large graphical solids and multi-column gutters, and derives paragraph/row bands from ink density. It limits raster work to 16 million pixels and 60 paragraphs/100 rows. A whole-image Vision check verifies horizontal coverage and the union of vertical paragraph bands, converting bottom-left observation coordinates to top-left raster coordinates. Vertical bounds allow a capped line-height margin for observation whitespace/skew. Uncovered text triggers whole-image Live Text instead of cropping. Non-upright images and languages unsupported by the secondary engine retain whole-image Live Text.

`AdaptiveOCR` runs six paragraph variants and two row passes (Live Text and Vision). `OCRConsensus` aligns bounded candidate strings, excludes poor matches, and selects observed tokens by local aligned vote count. Same-image spelling frequency only breaks tied counts; equal frequencies retain the representative pass or stable candidate order. It does not correct source typos, infer answers, or introduce dictionary words. Consensus can still choose the wrong observed token, omit text all engines missed, or mis-handle complex layouts. Candidate transcripts are retained so those decisions can be inspected.

Schema 3 adds optional recognition evidence and layout configuration. Missing layout in schema 1/2 means the historical whole-image behavior, and the old rendering remains byte-compatible. Old engines explicitly remain available. Changing layout for an existing image is a configuration conflict; updating historical exports is a separate backed-up maintenance operation, not a silent overwrite.
