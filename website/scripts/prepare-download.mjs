// Only creates local preview artifacts. Never signs with a credential or publishes.
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import {
  copyFileSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  renameSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { resolve } from "node:path";
import { siteRoot, readRelease } from "./release-manifest.mjs";
import { exportAppSource } from "./export-app-source.mjs";

if (process.platform !== "darwin")
  throw new Error("The preview app must be built on macOS with full Xcode.");
const repo = resolve(siteRoot, "..");
const run = (command, args, options = {}) =>
  execFileSync(command, args, { cwd: repo, encoding: "utf8", ...options });
const sourceRevision = run("git", ["rev-parse", "HEAD"]).trim();
const stage = mkdtempSync(resolve(tmpdir(), "mactextify-website-preview-"));
try {
  const source = resolve(stage, "source");
  exportAppSource(repo, sourceRevision, source);
  run("bash", ["scripts/check-prerequisites.sh"], {
    stdio: "inherit",
    cwd: source,
  });
  run("bash", ["scripts/build-app.sh"], { stdio: "inherit", cwd: source });
  const app = resolve(source, ".build/MacTextify.app");
  const version = readFileSync(resolve(source, "VERSION"), "utf8").trim();
  const bundleVersion = run("/usr/libexec/PlistBuddy", [
    "-c",
    "Print :CFBundleShortVersionString",
    `${app}/Contents/Info.plist`,
  ]).trim();
  if (bundleVersion !== version || !/^\d+\.\d+\.\d+$/.test(version))
    throw new Error("App bundle version does not match VERSION.");
  run("codesign", ["--verify", "--deep", "--strict", app], {
    stdio: "inherit",
  });
  const arches = run("lipo", ["-archs", `${app}/Contents/MacOS/MacTextifyApp`])
    .trim()
    .split(/\s+/);
  const architecture =
    arches.length === 2 && arches.includes("arm64") && arches.includes("x86_64")
      ? "universal"
      : arches.length === 1 && ["arm64", "x86_64"].includes(arches[0])
        ? arches[0]
        : null;
  if (!architecture)
    throw new Error(`Unsupported architecture: ${arches.join(", ")}`);

  const file = `MacTextify-${version}-${architecture}-preview.zip`;
  const archive = resolve(stage, file);
  run("ditto", ["-c", "-k", "--sequesterRsrc", "--keepParent", app, archive]);
  const unpacked = resolve(stage, "verify");
  mkdirSync(unpacked);
  run("ditto", ["-x", "-k", archive, unpacked]);
  run(
    "codesign",
    ["--verify", "--deep", "--strict", resolve(unpacked, "MacTextify.app")],
    { stdio: "inherit" },
  );
  const bytes = readFileSync(archive);
  const sha256 = createHash("sha256").update(bytes).digest("hex");
  const downloads = resolve(siteRoot, "public/downloads");
  const generated = resolve(siteRoot, ".generated");
  mkdirSync(downloads, { recursive: true });
  mkdirSync(generated, { recursive: true });
  copyFileSync(archive, resolve(downloads, `${file}.tmp`));
  renameSync(resolve(downloads, `${file}.tmp`), resolve(downloads, file));
  writeFileSync(resolve(downloads, `${file}.sha256`), `${sha256}  ${file}\n`);
  writeFileSync(
    resolve(generated, "release.json"),
    JSON.stringify(
      {
        available: true,
        version,
        architecture,
        bytes: bytes.length,
        sha256,
        file,
        sourceRevision,
        signing: "ad-hoc",
      },
      null,
      2,
    ) + "\n",
  );
  readRelease();
  console.log(
    `Prepared ${file} (${bytes.length} bytes)\nSHA-256 ${sha256}\nLocal preview only; not Developer ID signed or notarized. Fresh downloaded-copy Gatekeeper testing remains required before public release.`,
  );
} finally {
  rmSync(stage, { recursive: true, force: true });
}
