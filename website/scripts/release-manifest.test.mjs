import { test } from "node:test";
import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { validateRelease, readRelease } from "./release-manifest.mjs";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const bytes = Buffer.from("synthetic archive fixture");
const valid = {
  available: true,
  version: "0.3.0",
  architecture: "arm64",
  signing: "ad-hoc",
  file: "MacTextify-0.3.0-arm64-preview.zip",
  sha256: createHash("sha256").update(bytes).digest("hex"),
  sourceRevision: "a".repeat(40),
  bytes: bytes.length,
};
test("verified local release can be offered", () =>
  assert.deepEqual(
    validateRelease(valid, () => bytes),
    valid,
  ));
test("corrupt or replaced archive cannot be offered", () =>
  assert.throws(
    () => validateRelease(valid, () => Buffer.from("different archive")),
    /does not match/,
  ));
test("missing preparation falls back to source, without claiming a download", () => {
  const root = mkdtempSync(join(tmpdir(), "mactextify-manifest-test-"));
  try {
    assert.deepEqual(readRelease(root), { available: false });
  } finally {
    rmSync(root, { recursive: true });
  }
});
test("untrusted metadata never reaches archive reader", () => {
  for (const bad of [
    { file: "../../secret" },
    { file: "https://example.com/app.zip" },
    { signing: "notarized" },
    { architecture: "unknown" },
    { version: "<script>" },
    { sourceRevision: "main" },
    { bytes: -1 },
    { sha256: "invalid" },
  ]) {
    assert.throws(
      () =>
        validateRelease({ ...valid, ...bad }, () => {
          assert.fail("must validate before reading");
        }),
      /Invalid preview manifest/,
    );
  }
});

function withDownloads(manifest, run) {
  const root = mkdtempSync(join(tmpdir(), "mactextify-download-test-"));
  const downloads = join(root, "public/downloads");
  mkdirSync(downloads, { recursive: true });
  if (manifest) {
    mkdirSync(join(root, ".generated"));
    writeFileSync(join(root, ".generated/release.json"), JSON.stringify(valid));
    writeFileSync(join(downloads, valid.file), bytes);
    writeFileSync(
      join(downloads, `${valid.file}.sha256`),
      `${valid.sha256}  ${valid.file}\n`,
    );
  }
  try {
    run(root, downloads);
  } finally {
    rmSync(root, { recursive: true });
  }
}

test("source-only build rejects orphaned public downloads", () => {
  withDownloads(false, (root, downloads) => {
    writeFileSync(join(downloads, "unverified.zip"), "unverified payload");
    assert.throws(() => readRelease(root), /Unverified public download/);
  });
});

test("release build rejects extra files outside its verified manifest", () => {
  withDownloads(true, (root, downloads) => {
    assert.deepEqual(readRelease(root), valid);
    writeFileSync(join(downloads, "stale.zip"), "old payload");
    assert.throws(() => readRelease(root), /Unverified public download/);
  });
});
