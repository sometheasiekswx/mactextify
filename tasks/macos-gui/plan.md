# Native GUI implementation plan

Requirements: [specification](SPEC.md). Status: implemented; outstanding manual
checks are listed in [todo](todo.md). Evidence: [validation](validation.md).

## Implementation order and decisions
1. **Batch core and ownership.** Support multiple source roots without changing
   the CLI's single-root storage contract. Use separate versioned batch metadata
   and shared atomic/no-clobber storage. Verify recovery, collisions and locking.
2. **Native shell and selection.** Use SwiftUI and native file/folder panels,
   with background enumeration and explicit exclusions. Keep a bounded queue.
   Verify recursion, overlapping explicit selections and path deduplication.
3. **Inline output settings.** Retain the queue while settings expand in normal
   layout. Preserve values on collapse, validate names and preview the resolved
   destination. Verify direct/named output modes and invalid-name handling.
4. **Processing and cancellation.** Use typed events and sequential OCR to bound
   resource use. Freeze batch edits while running and stop safely on publication
   failures. Verify cancellation, interrupted writes and actionable engine errors.
5. **Results and appearance.** Provide open/reveal controls, accessible labels,
   focus restoration and reduced-motion behavior. Package White/Midnight icons
   and update the running app's icon with appearance changes.
6. **Packaging and validation.** Build an ad-hoc-signed development app. Include
   explicit binary assets in source packaging without disabling privacy-pattern
   checks. Run Swift, packaging and CLI smoke tests; record UI/platform limits.

## Remaining release work
Finish the manual accessibility, Finder drag/drop, resize and appearance checks
listed in the checklist. Validate minimum-OS and Intel behavior on those targets.
Choose and verify a distribution/signing approach before distributing binaries.
No database migration is required. Recovery from a faulty application build is to
restore a previous build; preserve destination state and do not delete receipts.
