# Native GUI validation

Snapshot: 25 October 2026, local Apple Silicon development environment.
This is development-build evidence, not certification for all supported systems.

## Automated checks
| Check | Result |
| --- | --- |
| `swift test` | 68 tests passed |
| `python3 scripts/test-package-source.py` | 5 tests passed |
| `python3 scripts/smoke-test.py` | Passed |
| `python3 scripts/package-source.py` | Source archive generated |
| `scripts/build-app.sh` | Release app built and ad-hoc signed |
| `codesign --verify --deep --strict .build/MacTextify.app` | Passed |
| `git diff --check` | Passed |

Core tests cover mixed roots, same-name exports, source links, deduplication,
configuration conflicts, edited exports, recovery, locking, cancellation, source
mutation, legacy state rejection and folder-selection ordering. Packaging tests
verify exact binary contents, determinism, private-pattern rejection, invalid icon
signatures and unknown binary rejection. Privacy scanning remains heuristic.
CLI smoke checks cover exit codes, dry runs, lock contention, interrupted recovery,
installation/reinstall/upgrade/rollback, relocation and uninstall preservation.

## Native interaction checks
An independent tester exercised synthetic inputs through the native app: file and
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
