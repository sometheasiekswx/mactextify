# Native GUI validation

Snapshot: 25 October 2026, local Apple Silicon development environment.
This is development-build evidence, not certification for all supported systems.

## Automated checks
| Check | Result |
| --- | --- |
| `swift test` | 75 tests passed |
| `python3 scripts/test-package-source.py` | 5 tests passed |
| `python3 scripts/smoke-test.py` | Passed |
| `python3 scripts/package-source.py` | Source archive generated |
| `scripts/build-app.sh` | Release app built and ad-hoc signed |
| `codesign --verify --deep --strict .build/MacTextify.app` | Passed |
| `git diff --check` | Passed |

Core tests cover mixed roots, same-name exports, source links, deduplication,
configuration conflicts, edited exports, recovery, locking, cancellation, source
mutation, legacy state rejection and folder-selection ordering. New regressions
cover direct output beside sources and in parent directories, source preservation,
rescanning after direct output, edited/unowned files, managed-state rejection,
trusted macOS temporary-directory aliases and user-created symlink ancestors. Packaging tests
verify exact binary contents, determinism, private-pattern rejection, invalid icon
signatures and unknown binary rejection. Privacy scanning remains heuristic.
CLI smoke checks cover exit codes, dry runs, lock contention, interrupted recovery,
installation/reinstall/upgrade/rollback, relocation and uninstall preservation.

## Native interaction checks
During initial GUI validation, an independent tester exercised synthetic inputs through the native app: file and
folder choosers, mixed-root extraction, direct/named destinations, text/Markdown,
invalid names, disclosure state retention/focus, rapid keyboard toggles, bounded
queues, cancellation, Vision selection and edited-export protection.

Dense synthetic images intermittently exposed an unhelpful Live Text framework
error. The error mapping now provides recovery guidance; a deterministic regression
checks it. Vision retry succeeded in the native app. The intermittent Live Text
failure did not reproduce during the final live retest, so the revised error text
is not claimed as live-verified.

Both icon variants were inspected at 16–128 pixels on light/dark backgrounds.
A native AppKit harness verified White → Midnight → White application-icon changes.
This does not establish live system appearance switching in the full app.

## Review and limitations
Review covered ownership, journal-before-output ordering, no-clobber behavior,
source selection, icon resources and packaging. Two reproduced defects—binary
packaging and order-dependent explicit subfolder selection—were fixed with failing-
then-passing regression tests. No blocking finding remained in that scoped review.

Finder drag/drop, full keyboard traversal, VoiceOver speech, minimum-size resizing,
permission denial, changed accessibility preferences and live system theme changes
remain unverified. No frame-time measurements were taken. Local results do not
establish minimum-OS or Intel compatibility. The app is not notarized or packaged
for the App Store; persistent permissions/history are outside this version.

Raw local logs, temporary fixture paths and agent-session notes are intentionally
excluded from the public repository. No private study corpus was used.

## Compact monochrome refinement
The outer scroll view was removed; only the queue and excluded-item list scroll.
A separate scene identifier lets existing installations adopt the smaller default
window without altering input/output settings. Header and drop-area spacing were
reduced, repeated introductory text removed, and brand assets regenerated in neutral
black/white. Native focus and text-selection feedback retain platform behavior.

The first compact layout's native dark-appearance verification covered a simultaneous image/folder selection
(17 images), scrolling to the final queued image, excluded-item details, mouse
selection/copying of the location path, full long-path copying with the copy action,
invalid-name blocking, collapse/reopen state retention and synthetic Vision export.
That 680 × 720 window kept settings and extraction controls visible. No
outer scroll area appeared in the accessibility tree. The synthetic invoice text
and amount were checked in the exported file; duplicate copies reused one export.

## Narrow layout, disclosure and direct-output correction
The current default is 544 × 720 points: 20% narrower than the first compact layout.
Native checks confirmed that the empty queue is absent, the drop area fills its
space, adding an image restores the compact drop bar and queue, and clearing the
queue restores the expanded drop area. Settings and extraction controls remained
visible in both states. Collapse/reopen retained direct-output settings and removed
hidden controls from the accessibility tree. Rapid keyboard toggles reached the
expected final state without leaving controls stuck. The reveal uses one clipped
height animation instead of simultaneous layout and insertion transitions.

The reported direct-output error was an overly broad source-overlap restriction.
Regression tests failed with that restriction and passed after allowing same-folder
and parent-folder destinations. A native test also reproduced an inconsistent
check of macOS's temporary-directory alias; its new regression failed before the
parent-directory check was corrected. Arbitrary symlink ancestors remain rejected.

The rebuilt native app exported a synthetic invoice as text directly into its
source folder. The expected invoice identifier and amount were present, the original
image's SHA-256 was unchanged, and no new output subfolder was created. All automated
checks in the table were rerun after the core changes, including CLI/install smoke
tests. CLI destination semantics remain unchanged.

Review covered the current UI, destination handling, preservation, regressions and
documentation. No remaining blocking finding was identified. Full light-mode
visual inspection, minimum-size interactive resizing and VoiceOver remain unverified.
Resize gestures through the native automation surface did not change the window
size, so the default-size check must not be presented as a minimum-size pass.
No quantified animation-performance claim is made.

## Missing-export and motion follow-up
The missing-export error was reproduced when an unrelated completed receipt remained
after its export had been removed. Three new regressions failed with the original
error, then passed after the correction: unrelated missing exports no longer block
a new batch or reappear; selected missing text/Markdown exports restore byte-for-byte
from saved text without OCR; differing settings cannot restore an old export.
The index excludes missing files. Existing edited-file, lock, no-clobber, cancellation
and interrupted-publication tests remain passing in the full 75-test suite.

Native verification used isolated synthetic files and copied synthetic batch state.
A new invoice exported directly into a directory with a missing old export. Its
expected text was present and the old export remained absent. Selecting the old
image and extracting again restored identical saved text, with a visible restoration
status. Original hashes were unchanged in both runs. No real destination was repaired
or processed as part of this test.

Earlier endpoint screenshots missed the animation defect. A temporary two-second
animation exposed the header/border jumping ahead of the body and controls crossing
into the drop area. Moving the animation to the shared layout and grouping panel
geometry kept them aligned in intermediate native frames during hide and show.
A stable rotating chevron replaces the changing action label. The final app restores
0.20-second timing; normal-speed collapse/reopen and rapid keyboard toggles retained
settings and hid collapsed controls from the accessibility tree. This is visual
interaction evidence, not a frame-rate benchmark. The use of grouped geometry follows
[Apple's geometryGroup documentation](https://developer.apple.com/documentation/swiftui/view/geometrygroup()).

Review covered the working diff against the preceding UI commit, restoration scope,
configuration matching, publication safety, index ownership, layout and accessibility
state. No blocking finding remained. The broader manual/platform limitations above
still apply. The CLI and storage implementation were unchanged in this follow-up;
prior CLI smoke evidence remains applicable.
