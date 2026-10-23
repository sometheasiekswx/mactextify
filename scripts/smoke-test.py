#!/usr/bin/env python3
"""Developer-only integration checks. Uses temporary data, never personal inputs."""
import fcntl
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time

repo = Path(__file__).resolve().parent.parent
current_version = (repo / "VERSION").read_text().strip()
parts = current_version.split(".")
next_version = ".".join(parts[:-1] + [str(int(parts[-1]) + 1)])

def run(args, code=0, **kwargs):
    result = subprocess.run([str(a) for a in args], text=True, capture_output=True, **kwargs)
    if result.returncode != code:
        raise AssertionError(f"{args[0]}: expected {code}, got {result.returncode}\n{result.stdout}\n{result.stderr}")
    return result

with tempfile.TemporaryDirectory(prefix="screenshot-ocr-smoke-") as tmp:
    temporary = Path(tmp)
    prefix = temporary / "install space"
    run([repo / "scripts/install.sh", prefix])
    binary = prefix / "bin/screenshot-ocr"
    assert run([binary, "--version"]).stdout.strip() == current_version
    run([binary, "--help"])
    run([binary, "process"], code=2)
    run([binary, "process", "--engine", "vision", "--folder", "missing"], code=2)
    run([binary, "process", "--engine", "vision", "--folder", tmp, "--format", "bad"], code=2)
    folder = temporary / "project with spaces"
    folder.mkdir()
    (folder / "broken.PNG").write_text("not an image")
    before = list(folder.iterdir())
    run([binary, "process", "--engine", "vision", "--folder", folder, "--dry-run"])
    assert list(folder.iterdir()) == before
    run([binary, "status", "--folder", folder])
    run([binary, "process", "--engine", "vision", "--folder", folder], code=1)
    assert (folder / "broken.PNG").read_text() == "not an image"

    # Real interprocess lock contention, then SIGKILL: flock must release automatically.
    lock_path = folder / ".ocr-state/lock"
    ready = temporary / "ready"
    child = subprocess.Popen([sys.executable, "-c", "import fcntl,sys,time; from pathlib import Path; f=open(sys.argv[1],'r+'); fcntl.flock(f,fcntl.LOCK_EX); Path(sys.argv[2]).touch(); time.sleep(60)", str(lock_path), str(ready)])
    try:
        deadline = time.monotonic() + 5
        while not ready.exists():
            if time.monotonic() > deadline:
                raise AssertionError("lock child did not start")
            time.sleep(0.01)
        run([binary, "process", "--engine", "vision", "--folder", folder], code=2)
    finally:
        child.kill()
        child.wait()
    run([binary, "process", "--engine", "vision", "--folder", folder], code=1)

    # Upgrade/reinstall does not change data or unrelated prefix content.
    unrelated = prefix / "bin/unrelated"
    unrelated.write_text("keep me")
    data_before = {str(p.relative_to(folder)): hashlib.sha256(p.read_bytes()).hexdigest()
                   for p in folder.rglob("*") if p.is_file()}
    run([repo / "scripts/install.sh", prefix])
    assert unrelated.read_text() == "keep me"
    # Build a distinct synthetic next version, verify switching and rollback.
    upgrade_source = temporary / "upgrade source"
    upgrade_source.mkdir()
    shutil.copy2(repo / "Package.swift", upgrade_source / "Package.swift")
    for directory in ["Sources", "Tests", "scripts"]:
        shutil.copytree(repo / directory, upgrade_source / directory)
    model = upgrade_source / "Sources/OCRCore/Models.swift"
    model.write_text(model.read_text().replace(f'toolVersion = "{current_version}"', f'toolVersion = "{next_version}"'))
    run([upgrade_source / "scripts/install.sh", prefix])
    assert run([binary, "--version"]).stdout.strip() == next_version
    shutil.rmtree(upgrade_source)
    assert run([binary, "--version"], cwd="/").stdout.strip() == next_version
    run([repo / "scripts/install.sh", prefix])
    assert run([binary, "--version"]).stdout.strip() == current_version
    # A moved installation works independently of the checkout and original prefix.
    moved = temporary / "moved prefix"
    prefix.rename(moved)
    run([moved / "bin/screenshot-ocr", "--version"], cwd="/")
    run([moved / "bin/screenshot-ocr-uninstall"])
    assert not (moved / "bin/screenshot-ocr").exists()
    assert (moved / "bin/unrelated").read_text() == "keep me"
    assert data_before == {str(p.relative_to(folder)): hashlib.sha256(p.read_bytes()).hexdigest()
                           for p in folder.rglob("*") if p.is_file()}

    conflict = temporary / "conflict"
    (conflict / "bin").mkdir(parents=True)
    (conflict / "bin/screenshot-ocr").write_text("foreign")
    run([repo / "scripts/install.sh", conflict], code=2)
    assert (conflict / "bin/screenshot-ocr").read_text() == "foreign"
print("PASS: CLI exits, dry-run, real lock contention/SIGKILL recovery, install/reinstall/upgrade/rollback, relocated runtime, uninstall preservation, install conflict.")
