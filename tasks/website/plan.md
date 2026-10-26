# Website plan

1. Establish factual release state and inspect reference component source/licenses. Use a static React build because Vengeance UI uses React, without a server framework.
2. Build an editorial monochrome landing page: oversized headline, kinetic extraction stage, actual native app proof, privacy/output story, download/install and contribution path. Keep motion coherent and controllable.
3. Prepare a versioned preview ZIP from a freshly built local app, record architecture, SHA-256 and Git revision. Validate archive and signature. Generate local download metadata; source-only is the default without an archive.
4. Verify build/types, interaction outcomes, keyboard, responsive layouts, reduced motion, console and download integrity. Review rendered desktop/mobile evidence with the skill-requested independent reviewer.
5. Document implementation, provenance, verification, hosting instructions and publication prerequisites. Complete the subsequently requested review, fix findings, and publish the scoped source changes to the existing GitHub repository. Keep the app preview and hosting deployment separate.

## Direction contract
Mode: Persuade. Existing world: Pearl/Midnight. Code-led implementation for the user-requested interactive motion; no persistent workflow preference inferred.
First viewport: quiet floating navigation, large left-aligned “Your screenshots. Now searchable.” typography, two clear actions and a horizontally composed cinematic extraction stage. Text itself is the subject. Asymmetric sections alternate light editorial space with a dark native-app showcase.
Signature: a user-controllable scan passes over a synthetic note and reveals selectable words; stacked papers settle with Anime.js. Motion defaults visible, stops when offscreen and respects reduced motion. The demonstration is separate from the actual app screenshot.
Quality bar: strong typography and whitespace, rich material detail without decorative gradients or grids, no invented metrics, no endless ambient movement, precise responsive layouts.
Hosting is now selected: GitHub Pages with its default public URL. Public binary publication remains a separate unresolved choice; Gatekeeper testing on a fresh downloaded copy remains an app-release prerequisite.

## Completion
All website implementation slices are complete. Build, browser checks, archive validation and independent review passed at the recorded scope; see [verification](verification.md). Source was published as `170f2df`. The preview ZIP remains local.

## Hosting follow-up

1. Extend website CI with a main-only Pages artifact and deployment job; preserve the existing verification gates and source-only publication boundary.
2. Check a clean source build and review workflow permissions, branch conditions, asset paths and deployment recovery.
3. Enable Pages with GitHub Actions, commit/push the scoped configuration, and observe the resulting deployment.
4. Verify the actual public HTTPS site in a browser, set the repository website link, and report the live URL and exact deployed revision. See [hosting and recovery](hosting.md).
