#!/usr/bin/env python3
"""Publish immutable release assets, verify public bytes, then update website metadata."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
import urllib.request
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
ARCHES = ('arm64', 'universal', 'x86_64')
REPO = 'sometheasiekswx/mactextify'
NS = '{http://www.andymatuschak.org/xml-namespaces/sparkle}'

def command(*args, **kwargs):
    return subprocess.check_output(list(args), cwd=ROOT, text=True, **kwargs).strip()

def api(endpoint, body=None):
    args = ['gh', 'api', f'repos/{REPO}/{endpoint}']
    if body is not None:
        args += ['--method', 'POST', '--input', '-']
    return json.loads(command(*args, input=json.dumps(body) if body is not None else None))

def validate_manifest(metadata, version, revision):
    if len(metadata) != 3 or {m['architecture'] for m in metadata} != set(ARCHES):
        raise ValueError('Exactly three distinct architectures required')
    for m in metadata:
        if (m['version'] != version or m['sourceRevision'] != revision or m['signing'] != 'ad-hoc'
                or m['file'] != f"MacTextify-{version}-{m['architecture']}.zip"):
            raise ValueError('Mixed source, version, signing or archive identity')
    return dict(version=version, sourceRevision=revision, signing='ad-hoc', available=True,
                assets=[{k: m[k] for k in ('architecture', 'file', 'bytes', 'sha256')} for m in metadata])

def prepare():
    version = (ROOT / 'VERSION').read_text().strip()
    revision = command('git', 'rev-parse', 'HEAD')
    directory = ROOT / 'dist/binaries'
    metadata = [json.loads((directory / f'MacTextify-{version}-{a}.zip.json').read_text()) for a in ARCHES]
    manifest = validate_manifest(metadata, version, revision)
    for asset in manifest['assets']:
        data = (directory / asset['file']).read_bytes()
        if len(data) != asset['bytes'] or hashlib.sha256(data).hexdigest() != asset['sha256']:
            raise ValueError('Archive checksum mismatch')
        item = ET.parse(ROOT / f"dist/update-feeds/{asset['architecture']}.xml").find('./channel/item')
        expected = f"https://github.com/{REPO}/releases/download/v{version}/{asset['file']}"
        if item is None or item.findtext(NS + 'version') != version or item.find('enclosure').get('url') != expected:
            raise ValueError('Update feed does not match release')
    (directory / 'release-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    (directory / 'SHA256SUMS').write_text(''.join(f"{a['sha256']}  {a['file']}\n" for a in manifest['assets']))
    return manifest

def validate_site(manifest):
    # Used in dry runs as well as publication.
    updates = {'website/published-release.json': json.dumps(manifest, indent=2) + '\n'}
    for arch in ARCHES:
        updates[f'website/public/updates/{arch}.xml'] = (ROOT / f'dist/update-feeds/{arch}.xml').read_text()
    for path, content in updates.items():
        (ROOT / path).write_text(content)
    for args in [('npm','ci','--ignore-scripts','--no-fund'), ('npm','run','check:format'), ('npm','test'), ('npm','run','build')]:
        subprocess.run(args, cwd=ROOT / 'website', check=True)

def publish(manifest):
    if os.environ.get('GH_REPO', REPO) != REPO:
        raise ValueError('Publishing is restricted to the MacTextify repository')
    version = manifest['version']; tag = 'v' + version; revision = manifest['sourceRevision']
    if command('git', 'rev-parse', f'{tag}^{{commit}}') != revision:
        raise ValueError('Release tag must identify this exact commit')
    updates = {'website/published-release.json': (ROOT / 'dist/binaries/release-manifest.json').read_text()}
    for arch in ARCHES:
        updates[f'website/public/updates/{arch}.xml'] = (ROOT / f'dist/update-feeds/{arch}.xml').read_text()
    base = api('git/ref/heads/main')['object']['sha']
    if base != revision:
        # A successful rerun may already have advanced main with these exact files.
        import base64
        for path, content in updates.items():
            remote = api(f'contents/{path}?ref=main')
            if base64.b64decode(remote['content']).decode() != content:
                raise ValueError('Main advanced; reconcile before publishing, never overwrite newer work')
    existing = command('gh', 'release', 'list', '--repo', REPO, '--limit', '1000', '--json', 'tagName')
    if tag not in {r['tagName'] for r in json.loads(existing)}:
        notes = ROOT / 'dist/release-notes.md'
        notes.write_text(f'''MacTextify {version}\n\nIncludes signed in-app updates, manual checks by default, and optional automatic checks. Existing users must install this updater-enabled version manually once.\n\nChoose Apple silicon, Intel, or Universal; unzip and move MacTextify.app into Applications. Requires macOS 14+. Apps are ad-hoc signed, not Developer ID signed or notarized. If macOS blocks launch and you trust the download, use System Settings → Privacy & Security → Open Anyway.\n\nSHA256SUMS and release-manifest.json record the verified assets. Built from {revision}.\n''')
        command('gh','release','create',tag,'--repo',REPO,'--draft','--verify-tag','--target',revision,'--title',f'MacTextify {version}','--notes-file',str(notes))
    release = json.loads(command('gh','release','view',tag,'--repo',REPO,'--json','assets,isDraft,targetCommitish'))
    if release['targetCommitish'] != revision:
        raise ValueError('Existing release targets a different revision')
    files = [ROOT / 'dist/binaries' / a['file'] for a in manifest['assets']]
    files += [ROOT / 'dist/binaries' / n for n in ('SHA256SUMS','release-manifest.json')]
    files += [ROOT / f'dist/update-feeds/{a}.xml' for a in ARCHES]
    existing_names = {a['name'] for a in release['assets']}
    for file in files:
        if file.name in existing_names:
            with tempfile.TemporaryDirectory() as tmp:
                command('gh','release','download',tag,'--repo',REPO,'--pattern',file.name,'--dir',tmp)
                if (Path(tmp)/file.name).read_bytes() != file.read_bytes():
                    raise ValueError('Refusing to replace different immutable release bytes: ' + file.name)
        elif release['isDraft']:
            command('gh','release','upload',tag,str(file),'--repo',REPO)
        else:
            raise ValueError('Published release is missing an expected asset')
    if release['isDraft']:
        command('gh','release','edit',tag,'--repo',REPO,'--draft=false','--latest')
    # Verify without credentials before changing any user-facing download or feed.
    for file in files:
        url = f'https://github.com/{REPO}/releases/download/{tag}/{file.name}'
        for attempt in range(6):
            try:
                with urllib.request.urlopen(url, timeout=60) as response:
                    if response.read() != file.read_bytes(): raise ValueError('Public bytes differ')
                break
            except Exception:
                if attempt == 5: raise
                time.sleep(5)
    if base == revision:
        tree = api('git/trees', dict(base_tree=api(f'git/commits/{base}')['tree']['sha'], tree=[
            dict(path=p,mode='100644',type='blob',content=c) for p,c in updates.items()]))
        commit = api('git/commits', dict(message=f'Publish MacTextify {version} download manifest and update feeds',tree=tree['sha'],parents=[base]))
        # Non-force ref update fails if main changed concurrently.
        command('gh','api',f'repos/{REPO}/git/refs/heads/main','--method','PATCH','--input','-',
                input=json.dumps(dict(sha=commit['sha'],force=False)))
    # GITHUB_TOKEN-created commits do not trigger another Actions push workflow.
    command('gh','workflow','run','website.yml','--repo',REPO,'--ref','main')
    print(f'Published {tag}; verified public assets and dispatched website deployment')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--prepare-only', action='store_true')
    mode.add_argument('--publish', action='store_true')
    args = parser.parse_args()
    manifest = prepare()
    validate_site(manifest)
    if args.publish: publish(manifest)
    else: print('Release metadata prepared; no remote changes')
