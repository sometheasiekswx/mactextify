#!/usr/bin/env python3
"""Exercise Sparkle's real installer against isolated app copies, never an installed app."""
import functools
import http.server
from pathlib import Path
import plistlib
import os
import signal
import subprocess
import tempfile
import threading
import time
import uuid
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
TOOLS = ROOT / '.build/artifacts/sparkle/Sparkle/bin'
CLI = ROOT / '.build/update-verification/UpdaterTest.app/Contents/MacOS/sparkle-cli'
FRAMEWORK = ROOT / '.build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64'
NS = 'http://www.andymatuschak.org/xml-namespaces/sparkle'

def run(*args):
    return subprocess.check_output([str(a) for a in args], stderr=subprocess.STDOUT, text=True).strip()

def configure(app, identifier, version):
    p = app / 'Contents/Info.plist'
    info = plistlib.loads(p.read_bytes())
    info.update(CFBundleIdentifier=identifier, CFBundleVersion=version, CFBundleShortVersionString=version)
    p.write_bytes(plistlib.dumps(info))
    run('codesign', '--force', '--sign', '-', app)

def version(app):
    return plistlib.loads((app / 'Contents/Info.plist').read_bytes())['CFBundleVersion']

def main():
    CLI.parent.mkdir(parents=True, exist_ok=True)
    sources = sorted((ROOT / '.build/checkouts/Sparkle/sparkle-cli').glob('*.m'))
    run('clang', '-fobjc-arc', '-fmodules', '-DSPU_OBJC_DIRECT_MEMBERS=', '-DSPU_OBJC_DIRECT=',
        '-F', FRAMEWORK, '-framework', 'Sparkle', '-framework', 'Cocoa', f'-Wl,-rpath,{FRAMEWORK}', *sources, '-o', CLI)
    (CLI.parent.parent / 'Info.plist').write_bytes(plistlib.dumps(dict(CFBundleIdentifier='com.mactextify.updater-verification', CFBundleExecutable='sparkle-cli', CFBundleName='Updater Verification', CFBundleVersion='1', CFBundlePackageType='APPL', LSUIElement=True)))
    run('codesign', '--force', '--sign', '-', CLI.parent.parent.parent)
    with tempfile.TemporaryDirectory(prefix='mactextify-update-test-') as tmp:
        folder = Path(tmp)
        identifier = 'com.mactextify.update-test.' + uuid.uuid4().hex
        old = folder / 'installed/MacTextify.app'; new = folder / 'release/MacTextify.app'
        for app, v in [(old, '0.4.0'), (new, '0.4.1')]:
            app.parent.mkdir(parents=True)
            run('ditto', ROOT / '.build/MacTextify.app', app)
            configure(app, identifier, v)
        sentinel = folder / 'exported.txt'; sentinel.write_text('Preserve my extracted words.\n')
        archive = folder / 'update.zip'
        run('ditto', '-c', '-k', '--sequesterRsrc', '--keepParent', new, archive)
        signature = run(TOOLS / 'sign_update', '--account', 'com.mactextify.updates', '-p', archive)
        class QuietHandler(http.server.SimpleHTTPRequestHandler):
            def log_message(self, *args): pass
        server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), functools.partial(QuietHandler, directory=folder))
        thread = threading.Thread(target=server.serve_forever, daemon=True); thread.start()
        base = f'http://127.0.0.1:{server.server_port}'
        def feed(sig):
            rss = ET.Element('rss', version='2.0'); channel = ET.SubElement(rss, 'channel')
            ET.SubElement(channel, 'title').text = 'Isolated update test'
            item = ET.SubElement(channel, 'item')
            ET.SubElement(item, f'{{{NS}}}version').text = '0.4.1'
            ET.SubElement(item, f'{{{NS}}}minimumSystemVersion').text = '14.0'
            ET.SubElement(item, 'enclosure', {'url': base + '/update.zip', 'length': str(archive.stat().st_size),
                'type': 'application/octet-stream', f'{{{NS}}}edSignature': sig})
            (folder / 'feed.xml').write_bytes(ET.tostring(rss, xml_declaration=True, encoding='utf-8'))
        def update(url):
            return subprocess.run([str(CLI), str(old), '--check-immediately', '--feed-url', url,
                '--user-agent-name', 'MacTextify-Local-Verification', '--verbose'], capture_output=True, text=True, timeout=90)
        def wait_for_helpers():
            # Sparkle reports a rejected update before its installer finishes shutting down.
            # Wait for this fixture's helpers, not unrelated installed applications.
            deadline = time.monotonic() + 15
            while time.monotonic() < deadline:
                processes = run('ps', '-axo', 'command')
                active = [line for line in processes.splitlines() if identifier in line and ('Autoupdate' in line or 'Updater.app' in line)]
                if not active:
                    return
                time.sleep(0.2)
            raise RuntimeError('Fixture installer helpers did not exit')
        running = None
        try:
            for arch in ('arm64', 'x86_64', 'universal'):
                template = ET.parse(ROOT / f'website/public/updates/{arch}.xml').getroot()
                channel = template.find('channel')
                assert channel is not None
                # Keep this fixture offline even after real release items are published.
                for item in list(channel.findall('item')):
                    channel.remove(item)
                (folder / 'feed.xml').write_bytes(ET.tostring(template))
                empty = update(base + '/feed.xml')
                assert empty.returncode == 4 and 'No new update available' in empty.stderr, empty.stderr
                assert version(old) == '0.4.0'
            feed(('A' if signature[0] != 'A' else 'B') + signature[1:])
            rejected = update(base + '/feed.xml')
            print('Invalid-signature result:', rejected.returncode, rejected.stderr[-1600:])
            assert rejected.returncode != 0 and 'improperly signed' in rejected.stderr.lower() and version(old) == '0.4.0', 'Invalid update was not safely rejected'
            wait_for_helpers()
            feed(signature)
            running = subprocess.Popen([str(old / "Contents/MacOS/MacTextifyApp")], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            time.sleep(2)
            assert running.poll() is None, "Old test app failed to launch"
            accepted = update(base + '/feed.xml')
            # XPC registration may briefly outlive the rejected installer's process.
            # Exercise retry after that specific error, without accepting other failures.
            for attempt in range(10):
                if 'Failed to resume installing update' not in accepted.stderr:
                    break
                assert version(old) == '0.4.0'
                time.sleep(0.5)
                accepted = update(base + '/feed.xml')
            print('Valid-update result:', accepted.returncode, accepted.stderr[-1600:])
            assert accepted.returncode == 0 and version(old) == '0.4.1', 'Signed update was not installed'
            running.wait(timeout=15)
            executable = str(old / 'Contents/MacOS/MacTextifyApp')
            relaunched = False
            for _ in range(50):
                if any(len(parts := line.strip().split(None, 1)) == 2 and os.path.realpath(parts[1]) == os.path.realpath(executable) for line in run('ps', '-axo', 'pid,command').splitlines()):
                    relaunched = True
                    break
                time.sleep(0.2)
            assert relaunched, 'Updated app did not relaunch'
            run('codesign', '--verify', '--deep', '--strict', old)
            assert sentinel.read_text() == 'Preserve my extracted words.\n'
            wait_for_helpers()
            current = update(base + '/feed.xml')
            assert version(old) == '0.4.1' and 'No new update available' in current.stderr, current.stderr
            print('PASS: invalid signature rejected, real signed update installed and relaunched, already-current handled, exports preserved')
        finally:
            executable = str(old / 'Contents/MacOS/MacTextifyApp')
            for line in run('ps', '-axo', 'pid,command').splitlines():
                fields = line.strip().split(None, 1)
                if len(fields) == 2 and os.path.realpath(fields[1]) == os.path.realpath(executable):
                    try: os.kill(int(fields[0]), signal.SIGTERM)
                    except ProcessLookupError: pass
            if running is not None and running.poll() is None:
                running.terminate(); running.wait(timeout=10)
            server.shutdown(); server.server_close(); thread.join()
            # Remove only preferences for this randomly named test app.
            subprocess.run(['defaults', 'delete', identifier], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

if __name__ == '__main__':
    main()
