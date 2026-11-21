#!/usr/bin/env python3
"""Create or inspect one trial requirements document without overwriting it.

The caller must inspect the work lifecycle; this tool does not parse STATE.yml.
"""
import argparse
import hashlib
import os
import re
import stat
import sys
from pathlib import Path


def unlinked(path, directory):
    info = path.lstat()
    expected = stat.S_ISDIR(info.st_mode) if directory else stat.S_ISREG(info.st_mode)
    if (not expected or stat.S_ISLNK(info.st_mode) or
            getattr(info, 'st_file_attributes', 0) & getattr(stat, 'FILE_ATTRIBUTE_REPARSE_POINT', 0) or
            (not directory and info.st_nlink != 1)):
        raise ValueError('expected an unlinked ' + ('directory: ' if directory else 'file: ') + str(path))


def work_path(name):
    parts = Path(name).parts
    if (Path(name).is_absolute() or len(parts) != 3 or parts[:2] != ('.aid', 'works') or
            not re.fullmatch(r'work-[0-9]+-[a-zA-Z0-9][a-zA-Z0-9_-]*', parts[2])):
        raise ValueError('work must be an exact .aid/works/work-NNN-name path')
    root = Path.cwd().resolve()
    current = root
    for part in parts:
        current = current / part
        unlinked(current, True)
    unlinked(current / 'STATE.yml', False)
    return current


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['create', 'inspect', 'check'])
    parser.add_argument('--work', required=True)
    parser.add_argument('--expected-sha256')
    args = parser.parse_args()
    try:
        work = work_path(args.work)
        path = work / 'REQUIREMENTS.md'
        if args.action == 'create':
            if args.expected_sha256 is not None:
                raise ValueError('create does not accept an expected hash')
            content = sys.stdin.read()
            if not content.strip():
                raise ValueError('requirements cannot be empty')
            with path.open('x', encoding='utf-8', newline='\n') as stream:
                stream.write(content)
            print('Created ' + str(path))
            return 0
        unlinked(path, False)
        value = hashlib.sha256(path.read_bytes()).hexdigest()
        if args.action == 'check':
            if not args.expected_sha256 or not re.fullmatch(r'[a-f0-9]{64}', args.expected_sha256):
                raise ValueError('check requires a lowercase SHA-256')
            if value != args.expected_sha256:
                print('requirements changed; reconcile before editing', file=sys.stderr)
                return 1
        elif args.expected_sha256 is not None:
            raise ValueError('inspect does not accept an expected hash')
        print(value)
        return 0
    except (OSError, ValueError) as exc:
        print('work requirements: ' + str(exc), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
