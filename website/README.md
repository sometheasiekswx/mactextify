# MacTextify website

Static React + TypeScript product site. Anime.js drives the sample extraction timeline, interruptible navigation highlight, entrance choreography, and native-app scroll motion. The navigation adapts Vengeance UI's Spotlight Navbar; see [third-party notices](THIRD_PARTY_NOTICES.md). No analytics, account, backend, remote fonts, or browser OCR.

## Develop and review

Requires Node.js 22.12+ or a compatible current Node release.

```sh
cd website
npm ci --ignore-scripts
npm run dev
```

```sh
npm run check:format
npm test
npm run build
npm run preview
```

The build uses relative asset URLs, so it can be served at a domain root or a subdirectory. Deploy only `website/dist/`, never the repository root. `dist/` is the complete static artifact; no environment secrets are required. Source without locally prepared binaries renders a source-build action.

## Prepare the app download

On a Mac with full Xcode selected, from `website/`:

```sh
npm run prepare:download
npm run build
```

Preparation exports only the tracked app inputs from the recorded Git commit into a temporary directory, then runs its prerequisites and app build scripts in isolation. Untracked source, working changes and stale local bundles cannot enter this build. It checks the version, identifies the actual architecture, verifies the ad-hoc signature, ZIPs only the fresh temporary `.build/MacTextify.app`, extracts and verifies it again, and creates a checksum and `.generated/release.json`. The build refuses mismatched archive metadata. Website changes are separate from the app source revision recorded in the manifest.

Generated files are ignored:

- `public/downloads/MacTextify-<version>-<architecture>-preview.zip`
- Its `.sha256` file
- `.generated/release.json`

These must travel together. They are embedded/copied into a subsequent production build. Keep the prepared archive and checksum in a release evidence store if publishing. Re-run `npm run build` after preparing or replacing an archive; restart the dev server to refresh its compiled release metadata.

The build rejects every file in `public/downloads/` except the manifest's verified archive and checksum. Without a manifest, that directory must be empty or absent. Move previous versions and unrelated files to your release evidence store before preparing a different version or architecture; the scripts do not delete them for you.

GitHub's Website checks workflow installs the lockfile, checks formatting, runs the manifest/preparation regression tests, type-checks and builds the source-only site. The generated app ZIP and manifest are intentionally absent from a fresh clone.

The preview is ad-hoc signed, **not Developer ID signed or notarized**. It is clearly labelled before download. Only the architecture actually built is advertised; Intel users can use source builds until an Intel/universal artifact has been verified. Do not change the label to “notarized” without a separate signing/notarization implementation and verified release evidence.

## Public hosting

The selected public URL is https://sometheasiekswx.github.io/mactextify/. The `Website checks and Pages` workflow builds and publishes this site from `main` after formatting, regression tests and TypeScript/build checks pass. Pull requests run checks only. The `github-pages` environment is the production deployment target; only `website/dist/` is uploaded.

This workflow explicitly requires a source-only build. It never publishes the locally prepared app ZIP or creates a GitHub Release. Public binary distribution remains a separate release decision. See [hosting and recovery](../tasks/website/hosting.md) for setup, verification and rollback.

## Other deployment targets

For Vercel or another static host, use root directory `website`, install `npm ci --ignore-scripts`, build `npm run build`, output `dist`. A build from Git alone has the honest source-only fallback. To publish a downloadable preview, deploy the already-verified local `dist/` containing the archive, or explicitly supply the verified archive/checksum/manifest to the build. Review the archive before uploading. GitHub Pages also supports the static output with the configured relative base.

Before a public app preview, test the exact downloaded ZIP on a clean supported Mac and exercise the app-specific Gatekeeper path; a successful local launch or `codesign --verify` does not establish this. Do not disable Gatekeeper or remove quarantine as an installation shortcut. Apple guidance: https://support.apple.com/en-au/102445.

For a different target or custom domain, choose the hosting account, domain and audience; verify the live page, download status/content/hash, navigation, mobile layout and HTTPS on that actual target. Keep the previous static deployment/archive for rollback. No DNS changes or telemetry are needed by the current GitHub Pages site.

## Evidence and assets

See `../tasks/website/verification.md` for results and limits. Browser evidence is locally retained under `output/playwright/`; native build/test evidence is in `../.local-notes/website-reference/`. Original source images are untouched. `assets-provenance.json` records the copied public icon and inspected synthetic captures.

The sample animation illustrates extraction with fixed content. Copying Markdown is an illustrative snippet, not a claim that it reproduces all metadata in native-app Markdown exports. The app screenshot shows actual controls and review labels.
