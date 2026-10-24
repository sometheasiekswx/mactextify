# Native batch GUI specification

Status: implemented as a local development application. See [validation](validation.md)
for verified behavior and remaining release checks.

## Purpose and scope
Provide a native macOS interface for extracting text from multiple images without
a terminal. Recognition stays on-device. The GUI keeps originals in place and
exports plain text or Markdown. HTML, additional image formats, persistent batch
history, automatic updates and subject-specific answer interpretation are outside v1.

## Input and output behavior
- Accept multiple PNG/JPEG files and folders through native dialogs or drag/drop.
- Enumerate folders asynchronously; recursion defaults off. Explicitly selected
  subfolders are included regardless of selection order. Deduplicate paths and
  explain exclusions for unsupported, hidden, package and symbolic-link inputs.
- Show the queue before extraction. Start only on the explicit Extract action.
- Let users select an existing parent directory and either create a named
  subfolder or write directly there. Show the resolved destination continuously.
- Validate folder names as single nonempty components, excluding separators,
  leading dots and reserved state names. Existing exports are never blindly replaced.
- Offer plain text/Markdown and Apple Live Text/Vision OCR. Engine changes are
  explicit; there is no silent fallback. Duplicate image content reuses its saved
  result only when configuration matches.
- Preserve original sources, edited exports and unowned files. Reject incompatible
  CLI state and destinations overlapping selected source locations.
- Report per-item outcomes. Recognition failures may continue; publication errors
  stop the batch. Cancellation preserves completed work and recoverable state.
- Provide open-export and Reveal in Finder actions. Warn before quitting during work.

## Interface contract
Use a single SwiftUI window with semantic system colors, native controls and a
bounded queue. The layout order is header, drop area, queue, inline extracted-text
settings and an anchored extraction/status footer. The initial window is 780 × 880
points with a 620 × 640 minimum; smaller-window usability remains a manual check.

Settings start expanded. A disclosure reveals the destination chooser, named/direct
mode, conditional folder name, format, engine and resolved path. Collapsing preserves
values and removes hidden controls from accessibility traversal. Invalid destination
feedback remains visible outside the disclosure and disables extraction.

Use an interruptible critically damped spring for disclosure changes; disable it
for Reduce Motion. Provide meaningful accessibility labels and non-color status.
Full keyboard navigation, VoiceOver and alternative accessibility settings remain
acceptance requirements pending complete manual verification.

Branding uses the dark mark on White by default and the white mark on Midnight
(#151820) in dark appearance. The running header and Dock use text-free variants;
Finder and the closed app retain the default icon on the macOS 14 baseline.

## Architecture and preservation
UI → session coordinator → OCRCore batch processor → recognizer and storage.
The session owns selection and permissions. The core owns hashing, recognition,
locking, no-clobber publication and recovery. GUI owner metadata is versioned
separately from unchanged CLI receipts. A prepared batch record is persisted before
publishing its export; retries reconcile it under a destination lock.

GUI batch records are not interchangeable with standalone CLI receipts. Existing
CLI integrations retain their current workflow. No migration or source archival
is introduced. Test using synthetic data, never private image collections.

## Acceptance and release boundary
Both destination modes, mixed source roots, duplicates, configuration conflicts,
source mutation, cancellation and interrupted publication must preserve data.
See [plan](plan.md), [checklist](todo.md) and [validation](validation.md).
The app is an ad-hoc-signed development build, not a notarized public binary.
