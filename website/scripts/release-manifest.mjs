import { existsSync, lstatSync, readFileSync, readdirSync } from "node:fs";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";
import { resolve } from "node:path";

export const siteRoot = fileURLToPath(new URL("../", import.meta.url));

export function validateRelease(data, readArchive) {
  if (
    data?.available !== true ||
    !/^\d+\.\d+\.\d+$/.test(data.version) ||
    !["arm64", "x86_64", "universal"].includes(data.architecture) ||
    data.signing !== "ad-hoc" ||
    !/^[a-f0-9]{40}$/.test(data.sourceRevision) ||
    !/^[a-f0-9]{64}$/.test(data.sha256) ||
    data.file !==
      `MacTextify-${data.version}-${data.architecture}-preview.zip` ||
    !Number.isSafeInteger(data.bytes) ||
    data.bytes < 1
  ) {
    throw new Error(
      "Invalid preview manifest. Re-run npm run prepare:download.",
    );
  }
  const archive = readArchive(data.file);
  if (
    archive.byteLength !== data.bytes ||
    createHash("sha256").update(archive).digest("hex") !== data.sha256
  ) {
    throw new Error(
      "Preview archive does not match its manifest. Re-run npm run prepare:download.",
    );
  }
  return data;
}

export function readRelease(root = siteRoot) {
  // Vite copies public/ verbatim. Every downloadable file must be verified,
  // including when the site falls back to source-only distribution.
  const downloads = resolve(root, "public/downloads");
  const entries = existsSync(downloads) ? readdirSync(downloads) : [];
  if (existsSync(downloads) && lstatSync(downloads).isSymbolicLink())
    throw new Error("Public downloads must not be a symbolic link.");
  const checkFiles = (allowed) => {
    for (const name of entries) {
      const stat = lstatSync(resolve(downloads, name));
      if (!allowed.includes(name) || stat.isSymbolicLink() || !stat.isFile())
        throw new Error(
          "Unverified public download. Move previous or unrelated files outside public/downloads before building.",
        );
    }
  };
  const manifest = resolve(root, ".generated/release.json");
  if (!existsSync(manifest)) {
    checkFiles([]);
    return { available: false };
  }
  if (lstatSync(manifest).isSymbolicLink())
    throw new Error("Release manifest must not be a symbolic link.");
  const data = JSON.parse(readFileSync(manifest, "utf8"));
  const release = validateRelease(data, (name) => {
    const path = resolve(root, "public/downloads", name);
    if (lstatSync(path).isSymbolicLink() || !lstatSync(path).isFile())
      throw new Error("Preview must be a regular archive file.");
    return readFileSync(path);
  });
  checkFiles([data.file, `${data.file}.sha256`]);
  const checksum = readFileSync(
    resolve(root, "public/downloads", `${data.file}.sha256`),
    "utf8",
  );
  if (checksum !== `${data.sha256}  ${data.file}\n`)
    throw new Error("Checksum file does not match the release manifest.");
  return release;
}
