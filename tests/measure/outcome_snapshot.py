#!/usr/bin/env python3
"""Record fixture paths for comparison while the fixture is quiescent.

This is a traversal, not an atomic filesystem snapshot. Root Git metadata,
ownership, ACLs, extended attributes and hardlink topology are excluded. Where
O_NOFOLLOW is unavailable, a swapped file can be opened before fstat rejects it.
"""
import argparse
import hashlib
import json
import os
import stat
from pathlib import Path


def unlinked_directory(path):
    absolute = Path(path).absolute()
    if '..' in absolute.parts:
        raise ValueError('directory path must not contain parent traversal')
    cursor = Path(absolute.anchor)
    for part in absolute.parts[1:]:
        cursor = cursor / part
        info = cursor.lstat()
        if (not stat.S_ISDIR(info.st_mode) or stat.S_ISLNK(info.st_mode) or
                getattr(info, 'st_file_attributes', 0) & getattr(stat, 'FILE_ATTRIBUTE_REPARSE_POINT', 0)):
            raise ValueError('directory must not traverse links or junctions: ' + str(cursor))
    return absolute


def snapshot(project):
    root = unlinked_directory(project)
    records = {}
    def raise_walk_error(error):
        raise error
    for directory, dirs, files in os.walk(root, followlinks=False, onerror=raise_walk_error):
        parent = Path(directory)
        kept = []
        for name in sorted(dirs):
            path = parent / name
            relative = path.relative_to(root).as_posix()
            if path == root / '.git':
                continue
            info = path.lstat()
            if stat.S_ISLNK(info.st_mode):
                records[relative] = {'kind': 'link', 'target': os.readlink(path)}
            elif getattr(info, 'st_file_attributes', 0) & getattr(stat, 'FILE_ATTRIBUTE_REPARSE_POINT', 0):
                raise ValueError('unsupported reparse point: ' + relative)
            elif stat.S_ISDIR(info.st_mode):
                records[relative] = {'kind': 'directory', 'mode': stat.S_IMODE(info.st_mode)}
                kept.append(name)
            else:
                raise ValueError('unsupported directory entry: ' + relative)
        dirs[:] = kept
        for name in sorted(files):
            path = parent / name
            if path == root / '.git':
                continue
            relative = path.relative_to(root).as_posix()
            info = path.lstat()
            if stat.S_ISLNK(info.st_mode):
                records[relative] = {'kind': 'link', 'target': os.readlink(path)}
            elif getattr(info, 'st_file_attributes', 0) & getattr(stat, 'FILE_ATTRIBUTE_REPARSE_POINT', 0):
                raise ValueError('unsupported reparse point: ' + relative)
            elif stat.S_ISREG(info.st_mode):
                digest = hashlib.sha256()
                flags = os.O_RDONLY | getattr(os, 'O_BINARY', 0) | getattr(os, 'O_NOFOLLOW', 0)
                descriptor = os.open(str(path), flags)
                def identity(item):
                    values = (item.st_dev, item.st_ino, item.st_mode, item.st_size, item.st_mtime_ns)
                    return values if os.name == 'nt' else values + (item.st_ctime_ns,)
                with os.fdopen(descriptor, 'rb') as stream:
                    opened = os.fstat(stream.fileno())
                    if identity(opened) != identity(info):
                        raise ValueError('file changed before snapshot: ' + relative)
                    for block in iter(lambda: stream.read(1024 * 1024), b''):
                        digest.update(block)
                    if identity(opened) != identity(os.fstat(stream.fileno())) or identity(opened) != identity(path.lstat()):
                        raise ValueError('file changed during snapshot: ' + relative)
                records[relative] = {'kind': 'file', 'mode': stat.S_IMODE(info.st_mode),
                                     'sha256': digest.hexdigest()}
            else:
                raise ValueError('unsupported file entry: ' + relative)
    return {'excluded': ['root .git metadata', 'ownership, ACLs, extended attributes and hardlink topology'],
            'assumption': 'Fixture is quiescent; traversal is not atomic.',
            'root_mode': stat.S_IMODE(root.lstat().st_mode), 'paths': records}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    try:
        root, output = unlinked_directory(args.project), args.output.absolute()
        unlinked_directory(output.parent)
        try:
            output.parent.resolve(strict=True).relative_to(root)
        except ValueError:
            pass
        else:
            raise ValueError('snapshot output must be outside the fixture')
        result = snapshot(root)
        with output.open('x', encoding='utf-8') as stream:
            json.dump(result, stream, sort_keys=True, indent=2)
            stream.write('\n')
        print(f"Saved {len(result['paths'])} paths; root .git metadata is excluded.")
        return 0
    except (OSError, ValueError) as exc:
        print('fixture snapshot: ' + str(exc))
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
