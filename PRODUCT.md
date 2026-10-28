# MacTextify

<!-- impeccable:product-schema 1 -->

## Platform
web

This record covers the public website for the native macOS app.

## Users
Mac users who want to extract words from photos, scans, screenshots and other PNG/JPEG images into reusable text files; developers who want to inspect or contribute to the source.

## Product Purpose
Explain the app, demonstrate image-to-text extraction, provide an honest installation path, and invite contributions.

## Capabilities and Constraints
Native SwiftUI app using local Apple OCR. PNG/JPEG batches, plain text and Markdown exports, original preservation and recovery records. macOS 14+. Source builds require full Xcode and Swift 5.9+. Live Text availability depends on the machine and OS. OCR results need review.

No account, subscription, or API key. OCR stays on-device; update checks contact the release server manually or by opt-in. The website demo is an illustrative interaction with synthetic content, not browser OCR.

## Brand Commitments
MacTextify name, existing logo and Pearl/Midnight black-and-white branding. User requested Anime.js motion, Vengeance UI components and Apple-inspired responsiveness.

## Evidence on Hand
README.md, docs/distribution.md, existing synthetic native app captures in assets/readme/, and public MIT source at https://github.com/sometheasiekswx/mactextify. No testimonials or benchmarks are supplied.

## Release Decision
2026-10-27: user has no Developer ID signing/notarization setup and initially requested website and release preparation. Prepare a clearly labelled locally ad-hoc-signed preview archive; do not claim notarization.

The subsequent review request authorizes fixes and publication of the website source to the existing GitHub repository. Generated binaries and local evidence are excluded from the source commit.

The subsequent hosting request selects GitHub Pages for a public website at https://sometheasiekswx.github.io/mactextify/. Deploy the site automatically after website checks pass on main. On 28 October 2026 the user authorized public unsigned app downloads for Apple silicon, Intel and Universal via GitHub Releases; the website verifies their hashes before deployment. See [hosting and recovery](tasks/website/hosting.md).

## Implementation Choice
React and TypeScript with Vite, selected for a static site using adapted Vengeance UI React interactions and Anime.js. No server, account system, analytics, or external font runtime.

On 28 October 2026 the user confirmed Vercel as the primary website at https://mactextify.vercel.app/, with GitHub Pages retained as a fallback from the same repository. GitHub Releases continues to host the app downloads.
