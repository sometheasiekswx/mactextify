import { defineConfig } from "vite";
import { readRelease } from "./scripts/release-manifest.mjs";

export default defineConfig({
  base: "./",
  define: { __RELEASE__: JSON.stringify(readRelease()) },
  build: { target: "es2022" },
});
