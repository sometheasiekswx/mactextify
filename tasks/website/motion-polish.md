# Plan: navigation and scroll motion polish

## Approach
Keep the existing Pearl/Midnight design, Anime.js, real app screenshot and download contract. Replace the floating radial navigation treatment with clear links and an active-section underline in a sticky header. On narrow screens retain the same links in a second row rather than hiding navigation. Give the theme button a fixed 44px circular hit area.

Scroll motion follows document progress and individual sections: a header progress line, restrained heading/step entrances, app capture depth, file output offsets and source/download visual arrivals. Animate only transforms/opacity; never hide meaningful content. Honor reduced motion live and clean up all observers. No scroll hijacking, new dependencies or changes to extraction/demo controls.

## Ordered slices and checks
- [x] Header: reproduce the oval; repair geometry; replace spotlight with navigation state. Verify circular bounds, anchors, focus, active state, 320/390/768/1024/1440px layouts and both themes.
- [x] Motion: add reversible Anime.js scroll sequences. Verify different intermediate transforms while scrolling, reverse scrolling, resize and reduced-motion cleanup; readable content throughout.
- [x] UI audit: apply current Web Interface Guidelines, fix related layout/readability/interaction issues. Run axe, keyboard navigation, console checks, existing tests, formatting and build. Recheck all three release download links.

## Recovery / scope
Changes are website-only, with native fallback content and anchors. Revert motion hook and CSS independently if needed. The follow-up authorizes review, fixes, push and GitHub Pages deployment. App binaries and release manifests remain unchanged. Recovery: revert this website change on main and redeploy through the existing Pages workflow.

## Review findings resolved
Reviewed against the [current Web Interface Guidelines](https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md).

- `website/src/styles.css:212` — fixed unequal theme hit-area dimensions and mobile shrink; now 44px square with circular hover/focus shape.
- `website/src/components/SectionNav.tsx:39` — replaced decorative spotlight with section anchors and aria-current; mobile links remain available.
- `website/src/styles.css:814` — disclosures now have a 44px minimum target.
- `website/src/useScrollMotion.ts:41` — text stays fully opaque during scroll movement; intermediate contrast failures removed.
- `website/src/components/ExtractionDemo.tsx:162` — labelled output container now has a group role, resolving the initial empty-state ARIA finding. Output text appears at full contrast rather than fading through low contrast.

## Evidence
Formatting, all 9 existing tests, TypeScript/Vite production build and git diff checks passed. Browser checks covered 320/390/768/1024/1440px, circular button bounds, visible mobile navigation, all section anchors below the sticky header, current-section state, keyboard theme activation, both themes, intermediate/reversed scroll transforms and live reduced-motion cleanup/restoration. Final production-page axe checks passed in both themes, including initial rendering; no runtime errors. All three release URLs and remote hashes passed verification.

Screenshots are retained under ignored `website/output/playwright/motion-*.png`. The development preview is available at http://127.0.0.1:4173/. The reviewed website changes are approved for publication to the existing GitHub Pages site.

## Shipping review
- Found and fixed short-landscape active-navigation failure: section activation now respects the actual sticky header, root anchor padding and each target scroll margin. Reproduced a missing active state at 768 × 320 before the fix; all three links then passed at 768 × 320, 320 × 568, 390 × 844 and 1440 × 1000.
- Both themes passed axe and keyboard theme activation. Circular bounds and overflow checks passed. Existing scroll/reduced-motion evidence remains applicable; no motion code changed during this review.
- Nine tests, formatting, production build and public release download verification passed. No remaining blocking findings. Native app code, binary assets and dependencies are unchanged.
- Deployment target: https://sometheasiekswx.github.io/mactextify/. Previous main revision for recovery: `77a053589021df65ad985ffb4a678c5a0bddf1ec`. Post-deploy results are verified against the published revision in the delivery report.
