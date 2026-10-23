# Implementation status

This is the sanitized implementation record for the reusable product. The sanitized [implementation plan](../tasks/plan.md) and [acceptance status](../tasks/todo.md) are maintained in this repository. Private corpus reports remain outside it.

- [x] P1 core: native OCR adapter, language/configuration handling and synthetic fidelity tests. Platform-matrix runtime and human private-pilot visual check remain pending.
- [x] P2: Markdown/text export, keep-original default, optional no-clobber archival and failure protection.
- [x] P3: receipt-driven recovery, duplicate/configuration handling, advisory locking and index ownership; interruption tests pass.
- [x] P4 core: CLI, installed Finder chooser and usage docs. Manual Finder interaction remains unverified.
- [x] P5 automated: real-corpus copies accounted for with unchanged hashes; rerun stable. Originals remain untouched; no assistant image transcription.
- [x] P6 local: installer, distinct-version upgrade/rollback, uninstall and source-independent runtime tests. Public macOS CI configured as source only; remote/older-OS hardware evidence pending.
- [x] P7 local preparation: deterministic source archive and clean archive installation verified; no private files packaged.
- [x] P7 source publication: authorized public GitHub source repository with MIT license and private security reporting. Versioned release assets, full platform/UI validation and binary distribution remain pending.

Evidence: [validation.md](validation.md). Checkmarks above apply only to the explicitly named local implementation scope, not unverified platform/distribution claims.

## 0.2.0 accuracy repair

- [x] Reproduce private reference failure; compare legacy correction and public Live Text.
- [x] Implement async Live Text, explicit legacy engine, opt-in resampling and unavailable confidence metadata.
- [x] Preserve schema-1 meaning/rendering; test new schema and configuration conflicts.
- [x] Pass 40 tests and installation smoke checks.
- [x] Re-extract all 22 private images, preserve old exports, verify reference/hashes/rerun, and flag remaining unreliable passages.
- [ ] Full-corpus manual fidelity review and previously noted platform/UI/publication checks remain outstanding.

## 0.3.0 adaptive accuracy repair

- [x] Establish independent private visual references; distinguish source typos from OCR errors.
- [x] Compare native scaling, segmentation, document OCR and an isolated Tesseract trial. Retain only the native approach.
- [x] Implement automatic paragraph/row recognition, bounded consensus and retained candidate evidence.
- [x] Preserve old receipts and protect text outside proposed crops.
- [x] Pass 50 tests including synthetic dense/colored text, identifier/negation preservation, evidence validation and layout fallback.
- [x] Final three-image exact comparison, 22-image copy batch, backups/promotion and installed-runtime no-op verification.
