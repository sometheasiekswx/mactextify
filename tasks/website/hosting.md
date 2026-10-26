# Public website hosting

## Agreed scope — 27 October 2026

The user requested a hosted public URL and selected GitHub Pages. The target is the existing public `sometheasiekswx/mactextify` repository, with the default URL `https://sometheasiekswx.github.io/mactextify/`. No domain purchase or DNS changes are needed. Automatic deployment follows the existing website checks on main.

The app-preview publication question remains unresolved. This deployment publishes the existing source-only site; local app archives, generated release metadata and browser evidence are excluded. A public website and a public app binary release are distinct outcomes. The initial website accurately links users to source-build instructions.

## Deployment

- GitHub Pages uses the GitHub Actions (`workflow`) build type.
- `.github/workflows/website.yml` checks formatting, runs release/preparation tests, asserts source-only publication, type-checks and builds the static output.
- On main, the workflow uploads only `website/dist/`, then deploys through the `github-pages` environment. Pull requests cannot upload or deploy a Pages artifact.
- Build jobs have read permissions. Only the deployment job gets `pages: write` and `id-token: write`. Action revisions are pinned, and checkout does not retain Git credentials.
- Workflow concurrency serializes runs for the same ref. The environment permits deployments from the main branch only.
- Vite's relative asset base supports the `/mactextify/` project path. The page's canonical URL identifies the public site.

Run the workflow manually on main to rebuild and deploy unchanged source. Normal website pushes trigger it automatically. Site code contains no deployment credentials; GitHub supplies a short-lived workflow token.

## Verification

Observe a successful deployment for the exact published commit, then verify public HTTPS without credentials, complete asset loading, demo controls, source/contribution links, source-only download state, mobile layout, browser errors and accessibility. Record deployment and browser evidence locally under `website/output/playwright/`; report the actual deployment URL and revision in the delivery message. A successful local build alone is not evidence that the site is live.

## Recovery

If a later website change breaks production, revert the relevant source change on main and let the same checked workflow redeploy. Keep the deployment workflow in place when reverting content. For an urgent rollback, rerun a prior successful Pages workflow while its artifact is available, then repair main before the next deployment.

For the first deployment, no earlier Pages version exists. If verification fails, fix and redeploy; if the site must be withdrawn, disable Pages through repository settings. There is no database or server-side state to migrate.

## Remaining app-release work

Publishing the experimental app requires its separate publication decision and downloaded-install verification. Developer ID signing/notarization and clean-Mac installation are not established by this website deployment or the macOS command-line CI checks.
