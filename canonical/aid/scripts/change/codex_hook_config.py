#!/usr/bin/env python3
"""Manage the AID Codex hook in one project's shared hooks.json.

Usage: codex_hook_config.py install|remove --project DIR
Exit codes: 0 on success; 1 on invalid configuration or filesystem errors.
This registers a project-wide hook; Codex trust is a separate host decision.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


HANDLER = '.aid/runtime/scripts/change/codex_safeguard.py'


def owned_entry(project):
    return {'matcher': '^Bash$', 'hooks': [{
        'type': 'command',
        'command': 'python3 "$(git rev-parse --show-toplevel)/.aid/runtime/scripts/change/codex_safeguard.py"',
    }]}


def preflight(project):
    if sys.platform != 'linux':
        raise ValueError('automatic Codex hook activation is supported on WSL/Linux only')
    if not shutil.which('git') or not shutil.which('python3'):
        raise ValueError('git and python3 are required to activate the hook')
    result = subprocess.run(['git', '-C', str(project), 'rev-parse', '--show-toplevel'],
                            capture_output=True, text=True)
    if result.returncode or not result.stdout.strip() or Path(result.stdout.strip()).resolve() != project.resolve():
        raise ValueError('project must be the Git root for hook activation')


def update(project, operation):
    project = Path(project).resolve(strict=True)
    if not project.is_dir():
        raise ValueError('project must be a directory')
    directory = project / '.codex'
    path = directory / 'hooks.json'
    if directory.is_symlink() or path.is_symlink():
        raise ValueError('hook configuration must not be a symlink')
    if hasattr(os.path, 'isjunction') and os.path.isjunction(directory):
        raise ValueError('hook directory must not be a junction')
    handler = project / HANDLER
    if operation == 'install':
        preflight(project)
        if not handler.is_file():
            raise ValueError('installed AID safeguard handler is missing')
        for part in (handler, *handler.parents):
            if part == project:
                break
            if part.is_symlink() or (hasattr(os.path, 'isjunction') and os.path.isjunction(part)):
                raise ValueError('installed safeguard must not traverse links or junctions')
    owned = owned_entry(project)
    data = {'hooks': {'PreToolUse': [owned]}}
    if path.exists():
        if operation == 'install':
            try:
                existing = json.loads(path.read_text(encoding='utf-8'))
            except (ValueError, UnicodeError) as exc:
                raise ValueError('existing hooks require manual review; no changes made') from exc
            if existing == data:
                return
        raise ValueError('existing hooks require manual changes; no changes made')
    if operation == 'remove':
        return
    directory.mkdir(parents=True, exist_ok=True)
    encoded = (json.dumps(data, indent=2, ensure_ascii=False) + '\n').encode('utf-8')
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=directory, prefix='.aid-hook-', delete=False) as out:
            temporary = Path(out.name)
            out.write(encoded)
        # Linking a completed temporary file creates the destination exclusively;
        # unlike replace it cannot clobber another writer's configuration.
        os.link(temporary, path)
    finally:
        if temporary is not None and temporary.exists():
            temporary.unlink()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('operation', choices=('install', 'remove'))
    parser.add_argument('--project', required=True, type=Path)
    args = parser.parse_args()
    try:
        update(args.project, args.operation)
    except (OSError, ValueError, UnicodeError) as exc:
        print(f'codex hook: {exc}', file=sys.stderr)
        return 1
    print('Project hook updated. Codex must trust it before it can run.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
