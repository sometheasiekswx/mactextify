# Security and private data

The tool has no network OCR or telemetry. Images, extracted text and receipts may contain sensitive information. Do not attach real documents, personal paths or private OCR output to public issues. Provide a minimal synthetic reproduction instead.

Report vulnerabilities privately through [GitHub private vulnerability reporting](https://github.com/sometheasiekswx/screenshot-ocr/security/advisories/new). This channel is enabled. Do not disclose sensitive reproductions in public issues.

The supported trust model is a single user on a local filesystem, with cooperative processes. The tool rejects symlink inputs/managed directories and validates receipt paths, but is not a sandbox against hostile concurrent filesystem changes. Back up originals.

Release checks must audit source/artifact manifests for private files, use least-privilege CI, keep credentials out of fork pull requests and verify distribution behavior before advertising downloaded binaries.
