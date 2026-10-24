#!/usr/bin/env python3
"""Prepare an allowlisted, deterministic source archive; never publish it."""
import gzip
import hashlib
import io
from pathlib import Path
import re
import tarfile

repo = Path(__file__).resolve().parent.parent
version = (repo / "VERSION").read_text().strip()
if not re.fullmatch(r"\d+\.\d+\.\d+", version):
    raise SystemExit("Invalid VERSION")
names = (repo / "scripts/source-files.txt").read_text().splitlines()
if len(names) != len(set(names)):
    raise SystemExit("Duplicate manifest paths")
# Binary exceptions are exact public asset paths, not arbitrary image inputs.
binary_signatures = {
    "assets/readme/app-workspace.png": b"\x89PNG\r\n\x1a\n",
    "assets/readme/app-detail.png": b"\x89PNG\r\n\x1a\n",
    "assets/AppIcon.png": b"\x89PNG\r\n\x1a\n",
    "assets/AppIconDark.png": b"\x89PNG\r\n\x1a\n",
    "assets/AppIcon.icns": b"icns",
    "assets/AppIconDark.icns": b"icns",
}
files = {}
for name in names:
    relative = Path(name)
    if relative.is_absolute() or ".." in relative.parts:
        raise SystemExit("Unsafe manifest path")
    path = repo / relative
    if path.is_symlink() or not path.is_file():
        raise SystemExit(f"Missing/nonregular source file: {name}")
    for ancestor in path.parents:
        if ancestor == repo:
            break
        if ancestor.is_symlink():
            raise SystemExit("Symlinked source directory")
    data = path.read_bytes()
    if name in binary_signatures:
        if not data.startswith(binary_signatures[name]):
            raise SystemExit(f"Invalid public icon signature: {name}")
        # Lossless byte-to-character mapping retains ASCII privacy scanning in
        # binary metadata too; never silently skip the scanner for binary files.
        text = data.decode("latin-1")
    else:
        try:
            text = data.decode("utf-8")
        except UnicodeDecodeError:
            raise SystemExit(f"Unexpected binary source file: {name}")
    # Private machine paths and common credential formats are never source artifacts.
    patterns = [r"/" + r"Users/[^/\s]+/", r"AKIA[A-Z0-9]{16}", r"ghp_[A-Za-z0-9]{30,}", r"-----BEGIN " + r"(?:RSA |EC |OPENSSH )?PRIVATE KEY-----"]
    if any(re.search(pattern, text) for pattern in patterns):
        raise SystemExit(f"Potential private material in {name}; review before packaging")
    files[name] = data
prefix = f"mactextify-{version}"
out = repo / "dist"
out.mkdir(exist_ok=True)
archive = out / f"{prefix}-source.tar.gz"
with archive.open("wb") as raw:
    with gzip.GzipFile(filename="", mode="wb", fileobj=raw, mtime=0) as zipped:
        with tarfile.open(fileobj=zipped, mode="w") as tar:
            for name, data in sorted(files.items()):
                info = tarfile.TarInfo(f"{prefix}/{name}")
                info.size = len(data)
                info.mode = 0o755 if (repo / name).stat().st_mode & 0o111 else 0o644
                info.uid = info.gid = 0
                info.mtime = 0
                tar.addfile(info, io.BytesIO(data))
checksum = hashlib.sha256(archive.read_bytes()).hexdigest()
(archive.with_suffix(archive.suffix + ".sha256")).write_text(f"{checksum}  {archive.name}\n")
print(f"Prepared {archive.name}: {len(files)} allowlisted files. SHA-256 {checksum}")
