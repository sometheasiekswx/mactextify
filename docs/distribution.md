# Distribution

MacTextify 0.3.0 is distributed as ZIP archives containing MacTextify.app for **Apple silicon (arm64)**, **Intel (x86_64)**, and **Universal (both)**. Download from the [website](https://mactextify.vercel.app/#download) or [GitHub Releases](https://github.com/sometheasiekswx/mactextify/releases). macOS 14 or later is required. Prebuilt apps do not require Xcode, Swift, Python, or Rosetta when the correct native download is selected.

## Install

1. In Apple menu → About This Mac, check **Chip** (Apple M-series) or **Processor** (Intel). Universal works on either.
2. Download the matching ZIP, double-click to extract it, then drag MacTextify.app to Applications.
3. Open MacTextify. These builds are **ad-hoc signed, not Developer ID signed or notarized by Apple**. If macOS blocks opening, dismiss the alert.
4. If you trust the download, open System Settings → Privacy & Security, scroll to Security, and choose **Open Anyway** for MacTextify. Confirm **Open** and authenticate if asked. Follow [Apple's instructions](https://support.apple.com/en-au/102445). Managed Macs may require administrator assistance.
5. Add PNG/JPEG images, choose an output folder and TXT or Markdown, then extract. Review OCR output for accuracy. Live Text availability depends on hardware and OS.

Do not disable Gatekeeper globally or remove quarantine as an installation shortcut. A damaged-app or malware warning is not the ordinary unidentified-developer prompt: stop and check the download rather than bypassing it.

## Verify your download

Each release includes `SHA256SUMS`. Run `shasum -a 256 ~/Downloads/MacTextify-0.3.0-arm64.zip` (substitute your actual filename), then compare against the release and website checksum. The published website manifest records the exact source revision, architecture, size and hash of every ZIP.

## Maintainer release path

- `scripts/package-app.py <arm64|x86_64|universal> --output <directory>` exports tracked inputs from an exact Git commit into a fresh temporary directory. It refuses to overwrite release assets.
- `scripts/build-app.sh` derives the app version from VERSION and creates a fresh, ad-hoc-signed bundle. Universal includes both architectures.
- The manually dispatched **Binary release verification** workflow runs Swift tests, packages each architecture, checks the extracted signature and launches the packaged app on a native runner. Artifacts include per-archive metadata. This workflow cannot publish a release.
- Download the verified workflow artifacts, check a common source revision/version, publish ZIPs and SHA256SUMS to the versioned GitHub Release, then record them in `website/published-release.json`.
- Pages fetches all three release archives and checks their bytes and hashes before deployment. Test live download links and hashes after deployment.

A valid ad-hoc signature and successful launch are not Apple notarization or proof of the interactive Gatekeeper experience on a clean Mac. Record that test separately; never claim it ran if unavailable.

Recovery: revert the website publication change to restore source-only access. If a release artifact is defective, withdraw it and publish a corrected version with new checksums; do not silently replace an existing version's bytes.

The MIT-licensed source remains available. Source builds require macOS 14+, full Xcode and a compatible Swift/macOS SDK. Apple frameworks are supplied by macOS and are not redistributed.

## In-app updates (prepared for 0.4.0; not yet released)

The public download remains 0.3.0. Empty feeds are deployed until the first updater-enabled release is published. That first release must be installed manually once. Subsequent stable releases can be installed using **MacTextify → Check for Updates…**, followed by Sparkle's download and install/relaunch prompts. **Automatically Check for Updates** is optional and off by default. Downloads and installation require confirmation; OCR and scanning finish before a confirmed installation proceeds. Exported files remain outside the app bundle.

The updater uses an architecture-specific HTTPS feed at `/updates/arm64.xml`, `/updates/x86_64.xml`, or `/updates/universal.xml` on the primary website. The release archive is authenticated with Sparkle's Ed25519 signature before extraction. This is separate from Developer ID signing/notarization; the app remains ad-hoc signed until that distribution setup is added. OCR inputs and output text are never included in update requests; the hosting services receive normal request metadata such as IP address and app version. System-profile reporting is disabled.

### Preparing an updater release

1. Increase `VERSION` (also used as the increasing `CFBundleVersion`). Keep `Package.resolved` and `config/update-public-key.txt` in the release source export.
2. Run Swift tests and `scripts/build-app.sh universal`, then `python3 scripts/verify-updater.py` on a logged-in Mac. The integration check uses temporary copies with unique bundle identifiers and a loopback test feed; it never updates an installed MacTextify app.
3. Package all three architectures from the same committed revision with `scripts/package-app.py`, into an otherwise empty directory. Run `scripts/verify-app.py` on the appropriate native machines.
4. Run `python3 scripts/prepare-appcast.py dist/binaries --output dist/update-feeds`. This verifies bundle configuration, architectures, hashes and signatures before producing the three feeds. It does not publish anything.
5. Upload immutable ZIPs and checksum metadata to the matching GitHub Release first. Verify their public bytes. Only then copy the generated feeds into `website/public/updates/` and update the website's published-release manifest. Run the website gates and deploy both hosts. Never publish a feed pointing to an unavailable archive.
6. Verify each live feed, its signature and enclosure URL, and test the published old-to-new update before announcing the release. Keep the previous release assets available.

The private key is held in the login Keychain under account `com.mactextify.updates`. Generate/retrieve its public key with Sparkle's `generate_keys --account com.mactextify.updates`. Do not export private key material into the repository, build logs, app or website. Back up the key securely before relying on this update channel: losing it can force another manual installation. CI packaging requires only the public key; signing feeds is currently a local release step.

If a bad feed is published, restore the previous feed to stop advertising the update. Sparkle does not automatically downgrade installed apps; ship a corrected release with a higher version. A failed download or invalid signature leaves the existing app installed. Do not modify an already signed archive or reuse a published version number.
