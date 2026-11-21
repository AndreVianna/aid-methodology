#!/usr/bin/env python3
"""Install or remove the experimental skill in one explicitly named project.

This does not install hooks, grant trust, update AID or change the default skill.
"""
import argparse
import hashlib
import json
import os
import stat
import sys
import tempfile
from pathlib import Path

SOURCE = Path(__file__).resolve().parent
REPOSITORY = SOURCE.parent.parent
FILES = {'SKILL.md': SOURCE / 'aid-outcome/SKILL.md',
         'references/coverage.md': SOURCE / 'aid-outcome/references/coverage.md',
         'references/review.md': SOURCE / 'aid-outcome/references/review.md',
         'references/start-and-resume.md': SOURCE / 'aid-outcome/references/start-and-resume.md',
         'scripts/outcome_coverage.py': SOURCE / 'outcome_coverage.py',
         'scripts/work_requirements.py': SOURCE / 'work_requirements.py'}
MANIFEST = '.aid-outcome-trial.json'


def unlinked_directory(path):
    info = path.lstat()
    if (not stat.S_ISDIR(info.st_mode) or stat.S_ISLNK(info.st_mode) or
            getattr(info, 'st_file_attributes', 0) & getattr(stat, 'FILE_ATTRIBUTE_REPARSE_POINT', 0)):
        raise ValueError('directory must not be linked: ' + str(path))


def digest(path):
    info = path.lstat()
    if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1:
        raise ValueError('file must be an unlinked regular file: ' + str(path))
    return hashlib.sha256(path.read_bytes()).hexdigest()


def project_paths(project):
    root = Path(project).absolute()
    cursor = Path(root.anchor)
    for part in root.parts[1:]:
        cursor = cursor / part
        unlinked_directory(cursor)
    agents = root / '.agents'
    skills = agents / 'skills'
    unlinked_directory(agents)
    unlinked_directory(skills)
    return root, skills, skills / 'aid-outcome'


def install(project):
    root, skills, destination = project_paths(project)
    for parts, source in ((('.aid', 'runtime', 'templates', 'work-initiation-gate.md'),
                           REPOSITORY / 'canonical/aid/templates/work-initiation-gate.md'),
                          (('.aid', 'runtime', 'scripts', 'change', 'state.py'),
                           REPOSITORY / 'canonical/aid/scripts/change/state.py'),
                          (('.aid', 'runtime', 'templates', 'direct-state-template.yml'),
                           REPOSITORY / 'canonical/aid/templates/direct-state-template.yml'),
                          (('.aid', 'runtime', 'scripts', 'config', 'read-setting.sh'),
                           REPOSITORY / 'canonical/aid/scripts/config/read-setting.sh'),
                          (('.aid', 'runtime', 'scripts', 'execute', 'writeback-state.sh'),
                           REPOSITORY / 'canonical/aid/scripts/execute/writeback-state.sh'),
                          (('.aid', 'runtime', 'scripts', 'grade.sh'),
                           REPOSITORY / 'canonical/aid/scripts/grade.sh'),
                          (('.aid', 'runtime', 'scripts', 'change', 'safeguard.py'),
                           REPOSITORY / 'canonical/aid/scripts/change/safeguard.py'),
                          (('.aid', 'runtime', 'scripts', 'change', 'codex_safeguard.py'),
                           REPOSITORY / 'canonical/aid/scripts/change/codex_safeguard.py'),
                          (('.aid', 'runtime', 'scripts', 'change', 'codex_hook_config.py'),
                           REPOSITORY / 'canonical/aid/scripts/change/codex_hook_config.py')):
        parent = root
        for part in parts[:-1]:
            parent = parent / part
            unlinked_directory(parent)
        installed = parent / parts[-1]
        digest(installed)
        actual = installed.read_bytes()
        if installed.suffix == '.sh' and b'\r' in actual:
            raise ValueError('installed shell prerequisite must use LF: ' + '/'.join(parts))
        if actual.replace(b'\r\n', b'\n') != source.read_bytes().replace(b'\r\n', b'\n'):
            raise ValueError('installed AID component differs from the trial source: ' + '/'.join(parts))
    if os.path.lexists(destination):
        raise ValueError('trial skill already exists; nothing was overwritten')
    payload = {name: path.read_bytes() for name, path in FILES.items()}
    destination.mkdir()
    try:
        for folder in ('references', 'scripts'):
            (destination / folder).mkdir()
        for name, contents in payload.items():
            with (destination / name).open('xb') as stream:
                stream.write(contents)
        metadata = {'format': 1, 'files': {name: hashlib.sha256(value).hexdigest()
                                           for name, value in payload.items()}}
        with (destination / MANIFEST).open('x', encoding='utf-8') as stream:
            json.dump(metadata, stream, indent=2)
            stream.write('\n')
    except (OSError, ValueError) as exc:
        raise ValueError('partial trial installation preserved at ' + str(destination) + ': ' + str(exc)) from exc
    print('Trial installed at ' + str(destination) + '.')
    print('The skill contains a Claude hook; host hook configuration and trust settings were not changed.')


def remove(project):
    root, skills, destination = project_paths(project)
    unlinked_directory(destination)
    for folder in ('references', 'scripts'):
        unlinked_directory(destination / folder)
    expected = {destination / name for name in FILES} | {destination / MANIFEST}
    actual = set()
    for directory in (destination, destination / 'references', destination / 'scripts'):
        for path in directory.iterdir():
            if path.name in ('references', 'scripts') and path.parent == destination:
                continue
            actual.add(path)
    if actual != expected:
        raise ValueError('trial contains unexpected or missing files; nothing removed')
    manifest_file = destination / MANIFEST
    digest(manifest_file)
    metadata = json.loads(manifest_file.read_text(encoding='utf-8'))
    if (not isinstance(metadata, dict) or set(metadata) != {'format', 'files'} or metadata.get('format') != 1 or
            not isinstance(metadata.get('files'), dict) or set(metadata['files']) != set(FILES)):
        raise ValueError('invalid trial manifest; nothing removed')
    for name, expected_hash in metadata['files'].items():
        if (hashlib.sha256(FILES[name].read_bytes()).hexdigest() != expected_hash or
                digest(destination / name) != expected_hash):
            raise ValueError('trial file changed; nothing removed: ' + name)
    # Move rather than delete: an edit arriving after validation is preserved.
    aid = root / '.aid'
    unlinked_directory(aid)
    scratch = aid / '.temp'
    if not scratch.exists():
        scratch.mkdir()
    unlinked_directory(scratch)
    quarantine = Path(tempfile.mkdtemp(prefix='aid-outcome-quarantine-', dir=scratch))
    target = quarantine / 'aid-outcome'
    os.rename(destination, target)
    print('Trial files moved out of the skill directory and preserved at ' + str(target) + '.')
    print('Running sessions may retain loaded skills or hooks; hook configuration and trust were not changed.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['install', 'remove'])
    parser.add_argument('--project', required=True)
    args = parser.parse_args()
    try:
        (install if args.action == 'install' else remove)(args.project)
        return 0
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print('outcome trial: ' + str(exc), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
