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

## Public app downloads

The three published app ZIPs live in GitHub Releases, not in Git or the Pages bundle. `published-release.json` records their version, exact app source revision, sizes and SHA-256 hashes. Destinations are derived from the fixed repository and version rather than trusted from arbitrary URLs.

The Pages workflow runs tests, verifies all three public ZIPs and SHA256SUMS over HTTPS, then builds and deploys. A missing or changed download fails deployment. The app is ad-hoc signed and explicitly labelled not Developer ID signed or notarized. See [distribution and maintainer steps](../docs/distribution.md).

For an unpublished local preview, `npm run prepare:download` retains the original single-architecture path. Use a checkout without `published-release.json`; it builds from tracked app inputs in an isolated directory and validates the archive. Keep preview `.generated/` and `public/downloads/` outside a published website checkout: public builds reject leftover downloads so Vite cannot copy unverified files. Never commit generated binaries.

## Hosting and recovery

GitHub Pages uses `.github/workflows/website.yml`. Revert the publication change to recover source-only access if downloads become invalid. Changes to release bytes require a new version and hashes. Verify the live page, all architecture links and downloaded checksums after deployment. See [hosting](../tasks/website/hosting.md).

## Primary and fallback hosting

The primary URL is https://mactextify.vercel.app/. Vercel builds the `website` root with Node 24 using `vercel.json`; formatting, tests and published download checksum verification must pass before the production build. The linked GitHub repository deploys `main` automatically. GitHub Pages remains a fallback at https://sometheasiekswx.github.io/mactextify/. Both builds use Vercel as their canonical URL.
