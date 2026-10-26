---
name: "MacTextify Website"
description: "The editorial web extension of MacTextify’s Pearl/Midnight identity."
colors:
  paper: "#f4f3ef"
  ink: "#1c1e1c"
  muted: "#666961"
  line: "#d7d8d0"
  surface: "#eaeae4"
  source-paper: "#fff"
  source-line: "#e6e8e2"
  result-paper: "#232722"
  result-ink: "#e6e9e2"
  result-copy: "#cbd0c5"
  result-line: "#42463e"
  app-background: "#20241f"
  app-muted: "#b5bdaf"
  terminal-background: "#242923"
  terminal-ink: "#e4e9df"
  scan: "#758d61"
  selection: "#cbd3c3"
  selection-ink: "#171917"
  midnight-paper: "#181a18"
  midnight-muted: "#b6bab0"
  midnight-line: "#42463f"
  midnight-surface: "#242824"
  contrast-muted: "#454a40"
  contrast-line: "#666d60"
  midnight-contrast-muted: "#d6dfcf"
  midnight-contrast-line: "#a4ae9d"
typography:
  display:
    fontFamily: '"Manrope Variable", system-ui, sans-serif'
    fontSize: "clamp(3rem, 6.7vw, 6rem)"
    fontWeight: 600
    lineHeight: 1.07
    letterSpacing: "-0.04em"
  headline:
    fontFamily: '"Manrope Variable", system-ui, sans-serif'
    fontSize: "clamp(2.5rem, 4.4vw, 4.4rem)"
    fontWeight: 600
    lineHeight: 1.08
    letterSpacing: "-0.04em"
  serif-emphasis:
    fontFamily: 'Georgia, "Times New Roman", serif'
    fontWeight: 400
    letterSpacing: "-0.035em"
  title:
    fontFamily: '"Manrope Variable", system-ui, sans-serif'
    fontSize: "22px"
    fontWeight: 600
    lineHeight: 1.35
    letterSpacing: "-0.02em"
  body:
    fontFamily: '"Manrope Variable", system-ui, sans-serif'
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.65
  body-small:
    fontFamily: '"Manrope Variable", system-ui, sans-serif'
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.65
  button:
    fontFamily: '"Manrope Variable", system-ui, sans-serif'
    fontSize: "14px"
    fontWeight: 650
    lineHeight: 1.5
  button-small:
    fontFamily: '"Manrope Variable", system-ui, sans-serif'
    fontSize: "12px"
    fontWeight: 650
    lineHeight: 1.5
  text-link:
    fontFamily: '"Manrope Variable", system-ui, sans-serif'
    fontSize: "13px"
    fontWeight: 650
    lineHeight: 1.65
  navigation:
    fontFamily: '"Manrope Variable", system-ui, sans-serif'
    fontSize: "12px"
    fontWeight: 600
    lineHeight: 1.65
  label:
    fontFamily: '"Manrope Variable", system-ui, sans-serif'
    fontSize: "11px"
    fontWeight: 400
    lineHeight: 1.65
  code:
    fontFamily: "monospace"
    fontSize: "10px"
    fontWeight: 400
    lineHeight: 2.2
rounded:
  segment: "4px"
  small: "7px"
  button: "9px"
  paper: "10px"
  terminal: "12px"
  panel: "14px"
  capture: "18px"
  stage: "20px"
spacing:
  icon: "8px"
  control: "12px"
  inset: "16px"
  compact: "18px"
  small: "20px"
  regular: "24px"
  medium: "28px"
  large: "32px"
  section-small: "35px"
  section-medium: "40px"
  column-compact: "60px"
  column: "80px"
  column-wide: "100px"
components:
  button-primary:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.paper}"
    typography: "{typography.button}"
    rounded: "{rounded.button}"
    padding: "13px 23px"
  button-compact:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.paper}"
    typography: "{typography.button-small}"
    rounded: "{rounded.button}"
    padding: "10px 16px"
  button-primary-hover:
    backgroundColor: "color-mix(in srgb, var(--ink) 85%, var(--paper))"
    textColor: "{colors.paper}"
  text-link:
    textColor: "{colors.ink}"
    typography: "{typography.text-link}"
  navigation-link:
    textColor: "{colors.ink}"
    typography: "{typography.navigation}"
    padding: "12px 18px"
  format-selected:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.paper}"
    rounded: "{rounded.segment}"
    padding: "4px 12px"
  file-chip:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.small}"
    padding: "12px 16px"
  extraction-result:
    backgroundColor: "{colors.result-paper}"
    textColor: "{colors.result-ink}"
    rounded: "{rounded.paper}"
  download-panel:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    rounded: "{rounded.panel}"
    padding: "37px"
  terminal:
    backgroundColor: "{colors.terminal-background}"
    textColor: "{colors.terminal-ink}"
    rounded: "{rounded.terminal}"
    typography: "{typography.code}"
---

# Design System: MacTextify Website

## Overview

**Creative North Star: "Pearl/Midnight, expressed as paper and words"**

This website extends the established MacTextify identity into an editorial web surface. Warm paper, near-black ink, generous whitespace, and a restrained dark app region make the words and the actual product the visual subjects. The existing logo and native app imagery remain authoritative; this record does not redefine the native app’s design system.

Manrope gives the interface a clear, compact voice. Georgia italics provide emphasis inside large headings, while small labels, thin rules, and gently rounded document surfaces carry the supporting information. Depth comes from paper stacks and product imagery. Motion explains extraction and responds to navigation or scrolling; it does not run as an endless background effect.

**Key Characteristics:**

- Warm paper and ink, with a user-selectable Midnight palette.
- Manrope headings and controls with selective Georgia italic emphasis.
- Asymmetric editorial layouts that become a single reading column on phones.
- Light source paper paired with a fixed dark text result and real native app imagery.
- User-controllable motion with reduced-motion and higher-contrast alternatives.

Scope: this file and `.impeccable/design.json` document only `website/`. The implementation was extracted on 2026-10-27 from `src/styles.css`, `src/App.tsx`, `src/components/ExtractionDemo.tsx`, `src/components/SpotlightNav.tsx`, and `src/hooks.ts`. The code-led direction is recorded in `../tasks/website/plan.md`; there is no approved visual comp. The descriptive North Star names that existing direction rather than introducing a new approval or identity.

Evidence inspected: `output/playwright/desktop-hero.png`, `output/playwright/mobile.png`, and `output/playwright/midnight-hero.png`. These are local implementation captures. Source and preview binary remain local; this documentation does not indicate a public release or deployment.

The frontmatter is the normative extracted token set. Token names for component roles, typography, spacing, and most radii are documentation aliases for actual CSS values, not a claim that the source declares a full token library. Runtime theme tokens are the existing `--paper`, `--ink`, `--muted`, `--line`, `--surface`, and `--radius` properties. Additional per-component values remain in the source and sidecar. The structure follows the [DESIGN.md format](https://raw.githubusercontent.com/google-labs-code/design.md/main/docs/spec.md).

## Colors

The palette is nearly monochrome with a slight warm green cast in neutrals and a muted green scan indicator.

### Primary

**Ink** drives headings, actions, selected format controls, and the range accent. **Paper** is the main Pearl canvas and the contrasting text on primary actions. They are the dominant pair; no separate marketing accent is introduced.

### Neutral

**Muted** handles supporting copy and metadata. **Line** separates controls, rows, and sections. **Surface** holds the extraction stage, file chips, and download band. The source document stays white. The result uses its own dark paper, pale ink, muted copy, and divider tokens; the native showcase and terminal retain distinct dark backgrounds.

The scan token is functional, visible only while the demonstration plays. Selection uses its own muted highlight and dark text. These small state colors do not become global brand accents.

### Theme and contrast mapping

| Runtime property | Pearl     | Midnight           |
| ---------------- | --------- | ------------------ |
| `--paper`        | `paper`   | `midnight-paper`   |
| `--ink`          | `ink`     | `paper`            |
| `--muted`        | `muted`   | `midnight-muted`   |
| `--line`         | `line`    | `midnight-line`    |
| `--surface`      | `surface` | `midnight-surface` |

Pearl is the initial state. The theme button switches the document’s `data-theme` and browser `color-scheme`; the current implementation does not persist theme choice. Under `prefers-contrast: more`, muted and divider tokens use the corresponding contrast entries, the navigation light is hidden, and result-line opacity is forced visible. This is an implemented contrast treatment, not a claim of an independent accessibility certification.

**The Theme Boundary Rule.** Theme the website’s paper, ink, muted text, dividers, and supporting surfaces together. Keep the source image, dark extraction result, dark app region, and terminal faithful to their current content treatments.

## Typography

**Display and body font:** locally bundled Manrope Variable, with system-ui and sans-serif fallbacks. The source imports `@fontsource-variable/manrope`; it does not load a remote font at runtime.

**Emphasis font:** Georgia, then Times New Roman and serif. Emphasis inherits the heading size and line height, uses an italic face, and grows slightly inside the hero (1.07em).

**Code:** the browser’s monospace family for terminal commands and checksums; there is no separately bundled monospace font.

The frontmatter records the base display, headline, title, body, button, navigation, and label roles. These are observed roles, not a strict modular type scale. Headings balance their lines. Body copy uses restrained widths, generally 31–43ch in multi-column sections, with room for text to wrap naturally. Small labels in the demonstration are intentionally subordinate to its large source/result relationship; do not reuse them as ordinary reading copy.

At tablet widths the hero display becomes `clamp(2.8rem, 8vw, 4.7rem)`. At phone widths it becomes `clamp(2.35rem, 9.5vw, 3.5rem)` with a line height of 1.14. Supporting sections have their own observed heading sizes rather than uniformly scaling every heading. Preserve these responsive rules when changing copy.

**The Emphasis Rule.** Use Georgia for an emphasized phrase inside a heading. Keep navigation, body copy, controls, and technical labels in their established families.

## Layout

The desktop reading area is centered at `min(1240px, calc(100% - 112px))`. The header distributes brand, navigation, and actions. The hero pairs its large left-aligned heading with compact supporting copy, then separates explanatory text from actions. Two-column narrative regions use unequal or equal columns according to their content; they do not form a repeated card grid.

The extraction stage uses `minmax(0, 1fr) 120px minmax(0, 1fr)` for source, connector, and result. Its source image is contained rather than cropped. The real native capture has a maximum width of 510px, and its figure caption identifies the synthetic content. Section padding varies deliberately with the content, typically 95–135px on large screens. The spacing tokens list recurring values; there is no imposed universal 8px grid.

| Viewport rule   | Implemented behavior                                                                                                                                                                                                                              |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| At least 1600px | Hero top padding increases from 65px to 90px.                                                                                                                                                                                                     |
| At most 1100px  | Outer gutters become 36px; the hero side note disappears; wide section gaps reduce to 60px; navigation links compact; the demo connector narrows to 85px.                                                                                         |
| At most 800px   | Outer gutters become 24px; the center navigation hides while brand, theme, and download actions remain; hero actions stack below the description; the demo retains two papers with a 55px connector; section spacing and type compact.            |
| At most 600px   | Outer gutters become 20px; the demo becomes source → vertical connector → result; narrative regions become one column; the fact row becomes two columns; demo controls can wrap; terminal content can scroll horizontally; footer links can wrap. |

The minimum body width is 320px. On phones the native capture centers at 91% of the content width. The source content viewport changes from 225px to 205px at tablet size and 190px on phones; the scan’s travel matches those heights. The source image retains `object-fit: contain` at every size. Preserve the logical reading order when columns collapse.

## Elevation & Depth

The system combines flat editorial surfaces with softly lifted physical objects. Thin dividers establish structure; the large dark app region supplies a strong tonal change. Paper stacks rotate in opposite directions, and modest ambient shadows separate papers from their stage. The actual app capture carries the largest shadow. No backdrop blur is used.

### Shadow vocabulary

| Role           | Observed CSS value      |
| -------------- | ----------------------- |
| Source paper   | `0 12px 32px #1a241a12` |
| Result paper   | `0 12px 32px #1a241a18` |
| Connector icon | `0 6px 20px #1112`      |
| Native capture | `0 28px 80px #0005`     |
| Download icon  | `0 14px 28px #141e1415` |

The source stack uses perspective (1000px) and settled rotations of −5° and +5°. The navigation spotlight is a small radial state treatment, and the scan wash follows the moving scan line. Neither defines the page background.

**The Material Depth Rule.** Reserve shadows for documents, the app icon, and the native capture. Editorial copy, navigation, and FAQ rows rely on whitespace and rules.

## Shapes

The shape language is softly rectangular. Buttons use the button radius; document surfaces use the paper radius; the download panel uses the shared panel radius. The wider desktop demo stage uses the stage radius, reducing to the panel radius on phones. The native capture uses the capture radius on larger screens and the terminal radius on phones. Small file chips and the format-control frame share the small radius, with tighter corners inside the selected segment.

Borders are generally one pixel. Paper surfaces clip their contents to their rounded edges. Icons use simple inline SVG paths with currentColor strokes (1.7px) and round caps/joins, normally at 14–20px; the large privacy icon is 50px. The theme control is circular. Do not turn every content paragraph into a boxed surface.

## Components

### Buttons and text links

Primary actions use ink on paper’s inverse, the documented button typography, and a minimum height of 54px. The compact header action has a minimum height of 43px. Hover lifts a primary button by 2px and mixes its background with paper; active state scales to 0.97. The transform transition is 180ms ease. Text links have an inline arrow that moves 4px on hover; they remain visually quieter than filled actions.

Keyboard focus uses a visible currentColor outline (2px, offset 5px). A skip link appears on focus. Phone controls use their specific compact padding and font rules; preserve the button labels. The theme control has no fill at rest and uses the surface color on hover.

### Navigation

The navigation is adapted from Vengeance UI’s MIT-licensed SpotlightNavbar; provenance is recorded in `THIRD_PARTY_NOTICES.md`. It keeps native anchor links, a thin lower rule, and a small radial spotlight. Pointer movement updates the light directly. Keyboard focus and pointer leave use Anime.js `spring({ stiffness: 200, damping: 28 })`, returning to the initial 70px position on pointer leave. There is no persistent active-section indicator. At 800px and below the center navigation hides; the header’s main action remains available.

### Extraction illustration

The signature illustration pairs a complete synthetic screenshot on white paper with selectable text on a dark result surface. File bars, the connector app icon, and the result footer make the transformation readable. The result is fixed sample data, not browser OCR. The page explicitly labels the illustration and links to the real app capture.

Anime.js 4.5.0 drives a 3800ms linear scan. It starts once on first entry at a 25% intersection threshold, pauses offscreen or when the document becomes hidden, and never loops on its own. Pause/play/replay and the native progress range give the user control. Scrubbing pauses playback. Lines reveal at progress thresholds of 10%, 25%, 40%, 55%, and 70%, with 220ms opacity/transform transitions. The copy button is disabled until the scan completes.

The .txt/.md segmented buttons expose `aria-pressed`; the selected segment reverses ink and paper. Both formats derive displayed lines and clipboard content from the same sample, including the PROJECT NOTES label. Copy status is announced through a live status region, clears after 3500ms, and reports “Select the text to copy” if clipboard access fails. There is a native range input rather than a custom slider implementation. No editable text field is present.

### File chips, app evidence, and terminal

File chips use the surface fill, thin inline file icon, and small radius. Three illustrative output chips step horizontally by 25px. The actual app image is a separate figure with a caption and descriptive alternative text; preserve its source and identity rather than redrawing it as generic browser chrome.

The terminal is a fixed dark surface with a dividing header, visible copy action, and horizontally scrollable commands. Code is compact and widely led. The source command block, file chips, and app workflow remain distinct evidence types.

### Download panel and disclosures

The download panel sits on the contrasting surface band and has its own paper fill. The current preview’s signing warning appears before the full-width download button. Installation instructions and checksum details use native `details`/`summary`; hashes wrap anywhere. The source-build fallback preserves the same panel treatment when a preview is unavailable. FAQ rows also use native disclosures, thin dividers, and ordinary reading copy. Documentation of these states does not authorize publication.

### Motion and accessibility

The hero’s two heading lines enter over 1000ms with outExpo easing, a 110ms stagger, 22px upward travel, and opacity from 0.45 to 1. The back papers settle over 1100ms with outExpo easing, a 100ms stagger, and 25px upward travel. The native capture moves from 26px to −14px with scroll progress across the app section, using linear easing and `sync: 0.4`.

`prefers-reduced-motion` is observed live. It bypasses hero, paper, and native-capture animation; immediately completes the scan; removes the scan line; makes navigation position changes direct; disables CSS animation/transitions and smooth scrolling; and suppresses primary button, text-link and inline-link transforms. Reduced-motion users can still scrub the sample manually, and the main demo control restores the fully revealed state. The browser theme-color metadata follows the selected Pearl/Midnight background.

The sidecar records motion, shadows, breakpoints, and ten representative components as self-contained HTML/CSS previews. Those previews show the visual system and CSS states; React event handlers, clipboard operations, and Anime.js choreography remain in the application source. Its generated tonal strips are inspection aids, not additional approved application colors.

## Do's and Don'ts

### Do:

- Do use the existing logo and distinguish the synthetic interactive illustration from the actual native app capture.
- Do preserve the Pearl/Midnight palette mapping and the fixed content colors inside the extraction result, app showcase, and terminal.
- Do keep headings in Manrope with selective Georgia emphasis, and preserve concise line lengths in supporting copy.
- Do keep the whole source image visible with object-fit: contain at every breakpoint.
- Do expose pause/replay, progress, format selection, and copy status using native controls and accessible labels.
- Do keep the preview’s signing warning above the download action and preserve the source-build alternative.
- Do provide reduced-motion and higher-contrast presentations and keep meaningful content available without entrance animation.

### Don't:

- Don’t treat these web tokens as a redesign of the native macOS app.
- Don’t replace product evidence with testimonials, benchmarks, or release assurances that the project does not supply.
- Don’t turn the soft navigation spotlight or scan wash into decorative page-wide gradients.
- Don’t add endless ambient motion or hide the completed example for reduced-motion users.
- Don’t use the illustrative scan to imply that this website uploads images or performs OCR.
- Don’t crop the sample screenshot or replace its complete words with a truncated image.
