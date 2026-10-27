#!/usr/bin/env python3
"""Build a ZIP from a fresh export of an exact Git commit, never local .build."""
import argparse
import hashlib
import json
import pathlib
import plistlib
import subprocess
import tempfile
import zipfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('architecture', choices=['arm64', 'x86_64', 'universal'])
parser.add_argument('--revision', default='HEAD')
parser.add_argument('--output', required=True, type=pathlib.Path)
args = parser.parse_args()
repo = pathlib.Path(__file__).resolve().parent.parent

def run(*command, cwd=repo):
    return subprocess.check_output(command, cwd=cwd, text=True).strip()

revision = run('git', 'rev-parse', '--verify', args.revision + '^{commit}')
output = args.output.resolve()
output.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='mactextify-release-') as directory:
    stage = pathlib.Path(directory)
    source = stage / 'source'
    source.mkdir()
    tar = stage / 'source.tar'
    run('git', 'archive', f'--output={tar}', revision, '--', 'Sources', 'Tests', 'Package.swift',
        'VERSION', 'assets/AppIcon.icns', 'assets/AppIconDark.icns',
        'scripts/build-app.sh', 'scripts/check-prerequisites.sh')
    run('tar', '-xf', str(tar), '-C', str(source))
    subprocess.run(['bash', 'scripts/check-prerequisites.sh'], cwd=source, check=True)
    subprocess.run(['bash', 'scripts/build-app.sh', args.architecture], cwd=source, check=True)
    app = source / '.build/MacTextify.app'
    version = (source / 'VERSION').read_text().strip()
    file = f'MacTextify-{version}-{args.architecture}.zip'
    archive = output / file
    metadata = output / f'{file}.json'
    if archive.exists() or metadata.exists():
        raise SystemExit('Refusing to replace an existing release artifact')
    temporary_archive = stage / file
    run('ditto', '-c', '-k', '--sequesterRsrc', '--keepParent', str(app), str(temporary_archive))
    unpacked = stage / 'unpacked'
    run('ditto', '-x', '-k', str(temporary_archive), str(unpacked))
    extracted = unpacked / 'MacTextify.app'
    run('codesign', '--verify', '--deep', '--strict', str(extracted))
    actual = set(run('lipo', '-archs', str(extracted / 'Contents/MacOS/MacTextifyApp')).split())
    expected = {'arm64', 'x86_64'} if args.architecture == 'universal' else {args.architecture}
    if actual != expected:
        raise SystemExit(f'Architecture mismatch: {actual} != {expected}')
    info = plistlib.loads((extracted / 'Contents/Info.plist').read_bytes())
    if info['CFBundleShortVersionString'] != version or info['LSMinimumSystemVersion'] != '14.0':
        raise SystemExit('Bundle version or minimum macOS mismatch')
    with zipfile.ZipFile(temporary_archive) as contents:
        for name in contents.namelist():
            if not name.startswith(('MacTextify.app/', '__MACOSX/')) or '..' in pathlib.PurePosixPath(name).parts:
                raise SystemExit(f'Unexpected archive member: {name}')
    data = temporary_archive.read_bytes()
    with archive.open('xb') as target:
        target.write(data)
    metadata.write_text(json.dumps(dict(version=version, architecture=args.architecture,
        file=file, bytes=len(data), sha256=hashlib.sha256(data).hexdigest(),
        sourceRevision=revision, signing='ad-hoc'), indent=2) + '\n')
    print(metadata.read_text())
