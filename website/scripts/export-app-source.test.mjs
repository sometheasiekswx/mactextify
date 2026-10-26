import { test } from "node:test";
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import {
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { resolve, dirname } from "node:path";
import { exportAppSource } from "./export-app-source.mjs";

test("revision export excludes untracked Swift, extra icons and stale bundle resources", () => {
  const temp = mkdtempSync(resolve(tmpdir(), "mactextify-export-test-"));
  const repo = resolve(temp, "repo");
  mkdirSync(repo);
  const git = (args) =>
    execFileSync("git", args, { cwd: repo, encoding: "utf8" }).trim();
  const put = (path, value) => {
    const file = resolve(repo, path);
    mkdirSync(dirname(file), { recursive: true });
    writeFileSync(file, value);
  };
  try {
    git(["init", "-q"]);
    for (const name of [
      "Sources/MacTextifyApp/main.swift",
      "Tests/OCRCoreTests/Fixture.swift",
      "Package.swift",
      "VERSION",
      "assets/AppIcon.icns",
      "assets/AppIconDark.icns",
      "scripts/build-app.sh",
      "scripts/check-prerequisites.sh",
    ])
      put(name, "committed fixture");
    git(["add", "."]);
    git([
      "-c",
      "user.name=Fixture",
      "-c",
      "user.email=fixture@example.invalid",
      "commit",
      "-qm",
      "Synthetic source fixture",
    ]);
    const revision = git(["rev-parse", "HEAD"]);
    put(
      "Sources/MacTextifyApp/Injected.swift",
      "untracked source must not ship",
    );
    put("assets/Extra.icns", "extra icon must not ship");
    put(
      ".build/MacTextify.app/Contents/Resources/stale.txt",
      "stale bundle content must not ship",
    );
    put(
      "Sources/MacTextifyApp/main.swift",
      "modified working source must not ship",
    );
    const exported = resolve(temp, "export");
    exportAppSource(repo, revision, exported);
    assert.equal(
      readFileSync(
        resolve(exported, "Sources/MacTextifyApp/main.swift"),
        "utf8",
      ),
      "committed fixture",
    );
    assert.equal(
      existsSync(resolve(exported, "Sources/MacTextifyApp/Injected.swift")),
      false,
    );
    assert.equal(existsSync(resolve(exported, "assets/Extra.icns")), false);
    assert.equal(existsSync(resolve(exported, ".build")), false);
    assert.equal(existsSync(resolve(exported, "source.tar")), false);
  } finally {
    rmSync(temp, { recursive: true, force: true });
  }
});
