import { execFileSync } from "node:child_process";
import { mkdirSync, rmSync } from "node:fs";
import { resolve } from "node:path";

// Only tracked inputs from the exact commit can reach the isolated Swift build.
// Neither the working tree nor an existing .build bundle is copied.
export function exportAppSource(repository, revision, destination) {
  if (!/^[a-f0-9]{40}$/.test(revision))
    throw new Error("An exact commit is required.");
  mkdirSync(destination, { recursive: false });
  const archive = resolve(destination, "source.tar");
  try {
    execFileSync(
      "git",
      [
        "archive",
        "--format=tar",
        `--output=${archive}`,
        revision,
        "--",
        "Sources",
        "Tests",
        "Package.swift",
        "VERSION",
        "assets/AppIcon.icns",
        "assets/AppIconDark.icns",
        "scripts/build-app.sh",
        "scripts/check-prerequisites.sh",
      ],
      { cwd: repository },
    );
    execFileSync("tar", ["-xf", archive, "-C", destination]);
  } finally {
    rmSync(archive, { force: true });
  }
}
