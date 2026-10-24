# Native GUI checklist

Requirements: [spec](SPEC.md). Implementation: [plan](plan.md).
Evidence and commands: [validation](validation.md).

## Implemented and locally verified
- [x] Mixed-root batch ownership, no-clobber exports, locking and recovery.
- [x] Native file/folder dialogs, queue and asynchronous enumeration.
- [x] Order-independent explicit folder selection, with recursion off by default.
- [x] Inline settings, direct/named destinations and visible validation.
- [x] Typed progress, safe stop and actionable OCR errors with engine selection.
- [x] Open/reveal controls, disclosure focus handling and clipped height transitions.
- [x] Pure black/white White/Midnight assets and native icon-switching smoke check.
- [x] Compact 544 × 720 layout, expanding empty drop area, combined picker and selectable/copyable paths.
- [x] Direct output into the selected source/parent folder, with original and export preservation checks.
- [x] Populated 17-image queue, excluded-item popover and invalid-name flow checked in the native app.
- [x] 72 Swift tests, 5 packaging tests and CLI/install smoke checks.
- [x] Source archive and locally signed application build.

## Outstanding verification and distribution
- [ ] Finder cross-application drag/drop exercised end-to-end.
- [ ] Complete keyboard traversal and VoiceOver speech checks.
- [ ] Minimum-size resizing, permission-denial dialogs and long-content checks.
- [ ] Live system appearance switching and reduced motion/transparency/high contrast.
- [ ] Minimum supported macOS and Intel runtime verification.
- [ ] Distribution signing/notarization and packaging approach established.

These unchecked items limit release readiness; completed implementation is not
an exhaustive UI, accessibility or cross-platform verification claim.
