export type Release =
  | { available: false }
  | {
      available: true;
      version: string;
      architecture: string;
      bytes: number;
      sha256: string;
      file: string;
      sourceRevision: string;
      signing: "ad-hoc";
    };
declare const __RELEASE__: Release;
export const release = __RELEASE__;
export const repo = "https://github.com/sometheasiekswx/mactextify";
