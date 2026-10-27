#!/usr/bin/env python3
"""Verify a packaged app and launch its native executable in an isolated directory."""
import argparse
import hashlib
import json
import pathlib
import platform
import subprocess
import tempfile
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('metadata', type=pathlib.Path)
args = parser.parse_args()
metadata = json.loads(args.metadata.read_text())
archive = args.metadata.parent / metadata['file']
data = archive.read_bytes()
assert len(data) == metadata['bytes']
assert hashlib.sha256(data).hexdigest() == metadata['sha256']
with tempfile.TemporaryDirectory(prefix='mactextify-launch-') as directory:
    subprocess.run(['ditto', '-x', '-k', str(archive), directory], check=True)
    app = pathlib.Path(directory) / 'MacTextify.app'
    subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True)
    executable = app / 'Contents/MacOS/MacTextifyApp'
    arches = subprocess.check_output(['lipo', '-archs', str(executable)], text=True).split()
    assert platform.machine() in arches, 'Must verify launch on a native architecture'
    with tempfile.TemporaryFile() as log:
        process = subprocess.Popen([str(executable)], cwd=directory, stdout=log, stderr=log)
        try:
            time.sleep(8)
            if process.poll() is not None:
                log.seek(0)
                raise RuntimeError(f'App exited early ({process.returncode}): {log.read().decode()}')
            print(f'PASS: extracted app launched on {platform.machine()} and remained running')
        finally:
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=15)
