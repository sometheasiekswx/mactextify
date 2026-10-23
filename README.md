# MacTextify

Convert text-heavy screenshots into searchable Markdown or plain text, entirely on your Mac using Apple’s public Live Text API (VisionKit), with legacy Vision available explicitly. Install once and use it for study notes, research, technical screenshots, or other folders. No AI subscription, API key, Python runtime, or network connection is needed for OCR.

**Source development version 0.3.0, with unreleased accuracy safeguards. No signed/notarized binary release.** macOS 14+ is the deployment target. See [validation](docs/validation.md) for tested platforms; do not infer Intel or older-OS runtime support from successful compilation.

## Install from source

Clone the source repository and install locally:

```sh
git clone https://github.com/sometheasiekswx/mactextify.git
cd mactextify
./scripts/install.sh
```

Requires Swift 5.9+ and a compatible macOS SDK. Full Xcode is verified locally. Command Line Tools-only compilation failed on the development machine; that route remains unverified (see validation). Install Apple developer tools yourself if missing; the installer never downloads or installs prerequisites. The installer builds in release mode and writes only to `~/.local/bin` and `~/.local/share/mactextify`. No `sudo`. A custom absolute prefix is supported:

```sh
./scripts/install.sh "$HOME/Tools/mactextify"
```

Add the prefix's `bin` directory to your PATH, or use the executable's full path. For the default installation:

```sh
export PATH="$HOME/.local/bin:$PATH"
mactextify --version
```

Builds are local; no official binary download currently exists. Do not disable Gatekeeper to run untrusted downloads. Read [distribution](docs/distribution.md) before preparing a public release.

## Use

Keep source images in place (default):

```sh
mactextify process --folder "$HOME/Documents/Research screenshots"
```

Archive successfully extracted originals:

```sh
mactextify process --folder "$HOME/Documents/Study screenshots" --archive
```

Preview the work without OCR or filesystem changes:

```sh
mactextify process --folder "$HOME/Documents/Study screenshots" --archive --dry-run
```

Plain text and language selection:

```sh
mactextify languages
mactextify process --folder "$HOME/Documents/Notes" --format text --languages en-US,fr-FR
mactextify status --folder "$HOME/Documents/Notes"
```

Only top-level PNG, JPG and JPEG regular files are considered (case insensitive). Nested directories are not scanned. Unsupported files are ignored. Symlink images and managed directories are rejected. Use local folders; cloud/network coordination and hostile concurrent file modification are outside the support contract.

The default is Apple Live Text in English with `--layout auto`. For a detected light-background, single-column text page, the tool automatically recognizes paragraphs at several vertical scales and recognizes individual rows with both Apple engines. It aligns the literal OCR candidates, rejects very different passes, and selects corroborated tokens. Repeated spellings within the same image help resolve disagreements. There are no subject-specific substitutions, dictionaries, LLM calls, or reference transcriptions in this process.

Unrecognized layouts, multiple-column gutters, unsupported orientations/language combinations and crops that would exclude recognized text keep whole-image Live Text. Use `--layout whole` to explicitly retain the previous extraction path. The detector is conservative but not a general document-layout parser: tables, diagrams, complex screenshots and ambiguous words still need review. Automatic processing is slower than one OCR pass and cannot guarantee accuracy.

All eight candidate transcripts per detected paragraph and the selected text are retained in the private receipt under `.ocr-state/records/`. They are evidence, not confidence scores. The Markdown contains the selected text and points to this evidence. The evaluation references used during development are never inputs to the OCR tool. Live Text requires supported hardware/OS; an unsupported device gets an explicit error.

Live Text does **not expose confidence scores or line geometry**. Receipts store those values as unavailable, and exports are flagged for review. A review flag does not mean an invented low score. For legacy Vision OCR, use `--engine vision`; only that engine accepts the explicit `--language-correction` flag and a confidence review threshold (`--review-threshold 0.8`). The adaptive row pass uses Vision language correction internally. Neither engine's scores nor agreement between passes prove correctness.

For a difficult image, compare a copy in a separate folder with `--image-scale 0.5` or `--image-scale 1.5` (supported range 0.5–2). Resampling can recover text or make it worse; it is opt-in, never rewrites image bytes, and its value is recorded. Do not assume a scale is universally best. `languages --engine vision` lists legacy engine language support; `languages` uses Live Text.

### Finder

Open `~/.local/bin/MacTextify.command` (or the equivalent in your custom prefix). Choose a folder, then choose **Keep originals** or **Archive originals**. Cancel makes no changes. The script runs the same CLI and reports results in Terminal. It does not infer the folder from its own location.

### Output

```text
project/
  incoming.png
  Extracted/
    incoming--<sha256>.md   # .txt with --format text
    index.md
  Processed/               # only created for --archive
    incoming--<sha256>.png
  .ocr-state/              # receipts, lock and index ownership data
```

Markdown includes an original-image link, source hash, engine/configuration metadata, review status, and literal OCR text. Plain-text files contain only recognized lines; metadata stays in the receipt and index. The index provides navigation without combining every document. Keep your own annotations in separate files.

Synthetic example: an image containing `Research notes` and `Sample count: 42` produces those lines in the export. Real OCR may misread characters, numbers, identifiers or line order. Color, diagrams, answer highlighting and semantic structure are not reconstructed. The tool never determines correct answers or sends text to a language model. Reading exports with an AI assistant is separate and may consume tokens; treat OCR as untrusted source material.

## Safety and recovery

- Originals are kept by default. With `--archive`, the export is saved before the original is moved, and original bytes are unchanged.
- Identical images are recognized once per folder. Additional identical copies are reported and left untouched. Different image bytes get different output names.
- New receipts use schema 2; schema-1 receipts retain their original Vision engine and rendering. Receipts retain recognized lines so interrupted exports/moves can resume without calling OCR again. Rerun the command to reconcile pending work.
- Pending operations resume with their saved configuration, including their archival choice, even if a later invocation has different defaults. Inspect `status` first if unsure.
- A new engine/scale/format/language/policy for an existing image is a configuration conflict, not an overwrite request. V1 has no destructive `--force` mode. To compare settings, use a separate folder containing copies of your images.
- Empty/corrupt images stay in place. Nonempty results with unavailable confidence (Live Text) or low confidence (Vision) get `needs-review`; archival still applies when explicitly selected.
- Changed or missing saved exports, changed source bytes, conflicting archives, malformed/newer receipts and edited indexes are reported, not silently replaced.
- `index.md` can be rebuilt if missing. If you edited it, preserve your edited copy elsewhere and remove the generated index before rerunning.
- On an unresolved collision, keep both files and investigate before moving/removing either. Do not delete receipts to force recovery: they establish file ownership and retain recognized data.
- Keep backups. Recovery covers ordinary process interruption and reported errors; it is not a guarantee against hardware failure, power loss or another program racing file changes.

Exit codes: **0** completed (may include review warnings or duplicates); **1** item/index failure; **2** invocation/preflight failure. Other images continue after an individual failure. `status` is a read-only snapshot of receipts, not a full integrity audit.

## Privacy

OCR runs locally. No telemetry, background monitor, automatic update checks, credentials or application network requests. Installation may require separately acquiring source and Apple tools. Receipts contain recognized text and filenames, and Markdown contains the original filename; treat all output folders as private. Console output prints sanitized filenames and errors, not full OCR bodies. New managed files/directories use restrictive permissions, subject to the user's existing folder permissions.

## Upgrade and uninstall

Run `scripts/install.sh` from the desired source version. The installer refuses unrelated executables and switches to a verified, immutable installation slot; previous slots remain for rollback. It never rewrites project data. To roll back, install a previous trusted checkout. Older versions reject unsupported receipt schemas; do not edit a schema number to bypass this check.

```sh
"$HOME/.local/bin/mactextify-uninstall"
```

Uninstall checks installed-file manifests, removes owned executables/support files only, and preserves unrelated files and every project folder. Modified installed files cause a refusal. A stale installation lock after a killed installer requires manual inspection before removing the empty `.install-lock` directory. Interrupted `.stage.*` installation folders can remain for inspection; they are never runtime state.

## Develop

```sh
swift build
swift test
swift build -c release
python3 scripts/smoke-test.py
```

Python 3 is used only for developer smoke tests and source packaging, not installation or OCR runtime. Tests generate synthetic images at runtime; never add private screenshots. See [architecture](docs/architecture.md), [contributing](CONTRIBUTING.md), [security](SECURITY.md), and [release checklist](docs/distribution.md).

MIT license; Apple Vision remains an Apple platform framework and is not bundled here.

## Renaming from Screenshot OCR

MacTextify uses the `mactextify` command and `MacTextify.command` Finder launcher. Install with `./scripts/install.sh`. Existing `.ocr-state` receipts, `Extracted` exports and `Processed` originals remain compatible and are not migrated or overwritten.

The new installation uses `share/mactextify` and can coexist with an older `screenshot-ocr` installation. Existing scripts using `screenshot-ocr` continue to use that older executable; update them explicitly to `mactextify`. To remove the older installation, use its original `screenshot-ocr-uninstall` command. Neither uninstaller removes study data.

## Custom output folder

```sh
mactextify process --folder "/path/to/images" --output-folder "/path/to/Exports"
```

The destination's parent must already exist; MacTextify creates the destination if needed. Exports, index and independent `.ocr-state` receipts/lock live in the destination. Input images and existing input-side receipts/exports are untouched. Reuse the same two paths on subsequent runs (including `status`); a destination is bound to one input folder. Markdown source links remain relative to the output location. Edited exports and unowned files are protected.

Custom output mode keeps originals in place and rejects `--archive`. Symlink destinations/ancestors, input-directory collisions and managed-state collisions are rejected. Omitting the option retains the historical folder layout and behavior. Explicitly naming the default `Extracted` path also retains historical state behavior.
