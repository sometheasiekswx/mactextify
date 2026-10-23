# Contributing

Source repository: [sometheasiekswx/screenshot-ocr](https://github.com/sometheasiekswx/screenshot-ocr). Development builds retain the accuracy and platform limitations in [validation](docs/validation.md).

Use Swift 5.9+ and a compatible macOS SDK. Run `swift test`, `swift build -c release` and `python3 scripts/smoke-test.py` from the root. No external Swift dependencies. Keep source formatting consistent with the surrounding files.

Add behavior tests for changes to recognition, persistence, overwrite protection, recovery or installation. Generate synthetic fixtures in tests from text you own. Do not commit screenshots, receipts, extracted text or logs from real projects. Check `git diff --cached` and the complete staged file list before committing.

Never weaken file-safety checks to make a test pass. Keep CLI/output/state changes documented in CHANGELOG.md; independently version receipt schemas. Record which OS/architecture was actually tested. A cross-compile does not prove runtime support.

Contributions are intended to use the repository's MIT license. Do not introduce paid services, telemetry or new dependencies without discussing the tradeoff.
