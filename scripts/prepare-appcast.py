#!/usr/bin/env python3
"""Validate and sign all three release archives; prepare feeds without publishing."""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ARCHITECTURES = ('arm64', 'x86_64', 'universal')
NS = 'http://www.andymatuschak.org/xml-namespaces/sparkle'
ET.register_namespace('sparkle', NS)
REPO = Path(__file__).resolve().parent.parent
TOOLS = REPO / '.build/artifacts/sparkle/Sparkle/bin'
ACCOUNT = 'com.mactextify.updates'

def run(*args):
    return subprocess.check_output([str(a) for a in args], text=True).strip()

def prepare(directory, output):
    if output.exists():
        raise ValueError('Output must be a new directory; never overwrite published feeds')
    public_key = (REPO / 'config/update-public-key.txt').read_text().strip()
    secret = os.environ.pop('SPARKLE_PRIVATE_KEY', None)
    if not secret and run(TOOLS / 'generate_keys', '--account', ACCOUNT, '-p') != public_key:
        raise ValueError('Keychain signing key does not match the app public key')
    feeds = {}
    version = revision = None
    for arch in ARCHITECTURES:
        manifests = list(directory.glob(f'MacTextify-*-{arch}.zip.json'))
        if len(manifests) != 1:
            raise ValueError(f'Expected exactly one {arch} release manifest')
        meta = json.loads(manifests[0].read_text())
        v = meta['version']
        if not re.fullmatch(r'\d+\.\d+\.\d+', v):
            raise ValueError('Only stable semantic versions are supported')
        name = f'MacTextify-{v}-{arch}.zip'
        if meta['file'] != name or meta['architecture'] != arch:
            raise ValueError('Archive name/architecture mismatch')
        if version is not None and (v != version or meta['sourceRevision'] != revision):
            raise ValueError('All architectures must use the same version and source revision')
        version, revision = v, meta['sourceRevision']
        archive = directory / name
        data = archive.read_bytes()
        if len(data) != meta['bytes'] or hashlib.sha256(data).hexdigest() != meta['sha256']:
            raise ValueError('Archive integrity mismatch')
        with tempfile.TemporaryDirectory(prefix='mactextify-feed-') as tmp:
            run('ditto', '-x', '-k', archive, tmp)
            app = Path(tmp) / 'MacTextify.app'
            info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
            expected_feed = f'https://mactextify.vercel.app/updates/{arch}.xml'
            if (info['CFBundleVersion'] != v or info['CFBundleShortVersionString'] != v
                    or info['SUPublicEDKey'] != public_key or info['SUFeedURL'] != expected_feed
                    or info['CFBundleIdentifier'] != 'com.mactextify.desktop'):
                raise ValueError('Bundle update configuration mismatch')
            run('codesign', '--verify', '--deep', '--strict', app)
            arches = set(run('lipo', '-archs', app / 'Contents/MacOS/MacTextifyApp').split())
            if arches != ({'arm64', 'x86_64'} if arch == 'universal' else {arch}):
                raise ValueError('Binary architecture mismatch')
        if secret:
            # stdin keeps the key out of process arguments and child environments.
            signed = subprocess.run([str(TOOLS / 'sign_update'), '--ed-key-file', '-', '-p', str(archive)],
                input=secret, text=True, capture_output=True)
            if signed.returncode:
                raise ValueError('Signing failed; tool output withheld to protect key material')
            signature = signed.stdout.strip()
        else:
            signature = run(TOOLS / 'sign_update', '--account', ACCOUNT, '-p', archive)
        if len(base64.b64decode(signature, validate=True)) != 64:
            raise ValueError('Invalid signature output')
        run('swift', REPO / 'scripts/verify-update-signature.swift', public_key, signature, archive)
        rss = ET.Element('rss', version='2.0'); channel = ET.SubElement(rss, 'channel')
        ET.SubElement(channel, 'title').text = f'MacTextify — {arch}'
        item = ET.SubElement(channel, 'item')
        ET.SubElement(item, 'title').text = f'MacTextify {v}'
        ET.SubElement(item, f'{{{NS}}}version').text = v
        ET.SubElement(item, f'{{{NS}}}shortVersionString').text = v
        ET.SubElement(item, f'{{{NS}}}minimumSystemVersion').text = '14.0'
        ET.SubElement(item, 'enclosure', {'url': f'https://github.com/sometheasiekswx/mactextify/releases/download/v{v}/{name}',
            'length': str(len(data)), 'type': 'application/octet-stream', f'{{{NS}}}edSignature': signature})
        ET.indent(rss)
        feeds[arch] = ET.tostring(rss, encoding='utf-8', xml_declaration=True)
    output.mkdir(parents=True)
    for arch, xml in feeds.items():
        (output / f'{arch}.xml').write_bytes(xml)
    print(f'Prepared {len(feeds)} signed feeds for {version}; nothing published')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('archives', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    prepare(args.archives.resolve(), args.output.resolve())
