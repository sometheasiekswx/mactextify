#!/usr/bin/env python3
"""Gate stable release tags before any job can access signing credentials."""
import os
from pathlib import Path
import re
import subprocess

def validate(version, ref, event):
    if not re.fullmatch(r'(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)', version):
        raise ValueError('VERSION must be a stable semantic version')
    expected = f'refs/tags/v{version}' if event == 'push' else 'refs/heads/main'
    if ref != expected:
        raise ValueError('Tag must match VERSION; dry runs must use main')

if __name__ == '__main__':
    validate(Path('VERSION').read_text().strip(), os.environ['REF'], os.environ['EVENT'])
    subprocess.run(['git', 'merge-base', '--is-ancestor', 'HEAD', 'origin/main'], check=True)
    print('Release source and version validated')
