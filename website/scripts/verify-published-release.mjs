import { createHash } from "node:crypto";
import { readRelease } from "./release-manifest.mjs";
const release = readRelease();
if (!release.available || !("assets" in release))
  throw new Error("A published three-architecture release is required.");
for (const asset of release.assets) {
  const response = await fetch(asset.url, {
    signal: AbortSignal.timeout(120000),
  });
  if (!response.ok)
    throw new Error(`Download failed: ${asset.file} (${response.status})`);
  const bytes = Buffer.from(await response.arrayBuffer());
  if (
    bytes.length !== asset.bytes ||
    createHash("sha256").update(bytes).digest("hex") !== asset.sha256
  )
    throw new Error(`Published bytes do not match: ${asset.file}`);
  const sums = await fetch(asset.checksumURL, {
    signal: AbortSignal.timeout(30000),
  });
  if (
    !sums.ok ||
    !(await sums.text()).split("\n").includes(`${asset.sha256}  ${asset.file}`)
  )
    throw new Error(`Published checksum does not match: ${asset.file}`);
  console.log(`Verified ${asset.file}: ${asset.sha256}`);
}
