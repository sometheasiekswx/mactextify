#!/usr/bin/env python3
"""Packaging regressions in isolated repositories; never publish."""
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import tempfile
import unittest

REPO = Path(__file__).resolve().parent.parent

class PackagingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="mactextify-package-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "scripts").mkdir()
        shutil.copy2(REPO / "scripts/package-source.py", self.root / "scripts/package-source.py")
        (self.root / "VERSION").write_text("0.3.0")

    def package(self, files):
        for name, data in files.items():
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
        (self.root / "scripts/source-files.txt").write_text("\n".join(files) + "\n")
        return subprocess.run([sys.executable, self.root / "scripts/package-source.py"], capture_output=True, text=True)

    def test_binary_icons_are_preserved_and_archive_is_deterministic(self):
        files = {f"assets/{name}": (REPO / "assets" / name).read_bytes()
                 for name in ["AppIcon.png", "AppIconDark.png", "AppIcon.icns", "AppIconDark.icns"]}
        result = self.package(files)
        self.assertEqual(result.returncode, 0, result.stderr)
        archive = self.root / "dist/mactextify-0.3.0-source.tar.gz"
        first = archive.read_bytes()
        with tarfile.open(archive) as tar:
            for name, data in files.items():
                self.assertEqual(tar.extractfile("mactextify-0.3.0/" + name).read(), data)
        self.assertEqual(self.package(files).returncode, 0)
        self.assertEqual(first, archive.read_bytes())

    def test_private_material_in_binary_is_rejected(self):
        data = (REPO / "assets/AppIcon.png").read_bytes() + b"/" + b"Users/example/private"
        result = self.package({"assets/AppIcon.png": data})
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Potential private material", result.stderr)

    def test_unknown_binary_is_rejected(self):
        result = self.package({"unexpected.bin": b"\xff\xfe"})
        self.assertNotEqual(result.returncode, 0)

    def test_invalid_icon_signature_is_rejected(self):
        result = self.package({"assets/AppIcon.png": b"not a PNG"})
        self.assertNotEqual(result.returncode, 0)

    def test_private_text_is_still_rejected(self):
        result = self.package({"README.md": b"/" + b"Users/example/private"})
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Potential private material", result.stderr)

if __name__ == "__main__":
    unittest.main()
