#!/usr/bin/env python3
"""Purpose: capture and compare command and JUnit results.
Usage: checks.py baseline|compare --spec commands.json --baseline baseline.json
Exit codes: 0 for an accepted result, 1 for failure or invalid evidence.
"""
import argparse
import hashlib
import json
import os
import re
import stat
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path


def relative_input(name):
    """Require one normalized, project-relative declaration."""
    if not isinstance(name, str) or not name or '\\' in name:
        raise ValueError('declared path must be a normalized relative path')
    path = Path(name)
    if path.is_absolute() or '..' in path.parts or not path.parts or path.as_posix() != name:
        raise ValueError('declared path must be a normalized relative path')
    return path


def unlinked_path(root, name):
    path = relative_input(name)
    cursor = root
    for part in path.parts:
        cursor = cursor / part
        try:
            info = cursor.lstat()
        except FileNotFoundError:
            continue
        if (stat.S_ISLNK(info.st_mode) or
                getattr(info, 'st_file_attributes', 0) & getattr(stat, 'FILE_ATTRIBUTE_REPARSE_POINT', 0) or
                (hasattr(cursor, 'is_junction') and cursor.is_junction())):
            raise ValueError(f'declared path may not contain links: {name}')
    return cursor


def sha256_file(path):
    before = path.lstat()
    if not stat.S_ISREG(before.st_mode):
        raise ValueError(f'input must be an unlinked regular file: {path}')
    digest = hashlib.sha256()
    flags = os.O_RDONLY | getattr(os, 'O_BINARY', 0) | getattr(os, 'O_NOFOLLOW', 0)
    descriptor = os.open(str(path), flags)
    with os.fdopen(descriptor, 'rb') as stream:
        opened = os.fstat(stream.fileno())
        # Windows can report different creation-time precision through fstat and lstat.
        def identity(item):
            fields = (item.st_dev, item.st_ino, item.st_mode, item.st_size, item.st_mtime_ns)
            return fields if os.name == 'nt' else fields + (item.st_ctime_ns,)
        if not stat.S_ISREG(opened.st_mode) or identity(before) != identity(opened):
            raise ValueError(f'input changed while opening: {path}')
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
        if identity(opened) != identity(os.fstat(stream.fileno())) or identity(opened) != identity(path.lstat()):
            raise ValueError(f'input changed while hashing: {path}')
    return digest.hexdigest()


def work_state_inputs(spec):
    """Record explicitly declared mutable work-state files without hiding other files."""
    names = spec.get('work_states', [])
    if not isinstance(names, list) or len(names) > 1:
        raise ValueError('work_states must name at most one active work state')
    root = Path.cwd().resolve()
    result = {}
    for name in names:
        path = relative_input(name)
        if (len(path.parts) != 4 or path.parts[:2] != ('.aid', 'works') or
                not re.fullmatch(r'work-[0-9]+-[a-zA-Z0-9][a-zA-Z0-9_-]*', path.parts[2]) or
                path.parts[3] != 'STATE.yml'):
            raise ValueError('work state must be an exact allocated work STATE.yml')
        file = unlinked_path(root, name)
        if not file.is_file() or not stat.S_ISREG(file.lstat().st_mode):
            raise ValueError(f'work state must be a regular file: {name}')
        if file.lstat().st_nlink > 1:
            raise ValueError(f'work state must not be hard-linked: {name}')
        state_env, work_env = os.environ.get('AID_STATE_FILE'), os.environ.get('AID_WORK_DIR')
        if (not state_env or not work_env or
                Path(os.path.abspath(state_env)) != file or
                Path(os.path.abspath(work_env)) != file.parent):
            raise ValueError('work state must match AID_STATE_FILE and AID_WORK_DIR')
        result[name] = sha256_file(file)
    return result


def dependency_tree_digest(root):
    """Hash every file, directory and contained link without following directory links."""
    digest = hashlib.sha256()
    directory_edges = {}

    def field(value):
        value = os.fsencode(value)
        digest.update(len(value).to_bytes(8, 'big'))
        digest.update(value)

    def visit(directory):
        directory_edges.setdefault(directory, set())
        with os.scandir(directory) as entries:
            for entry in sorted(entries, key=lambda item: os.fsencode(item.name)):
                path = Path(entry.path)
                info = entry.stat(follow_symlinks=False)
                field(path.relative_to(root).as_posix())
                field(str(stat.S_IMODE(info.st_mode)))
                if stat.S_ISLNK(info.st_mode):
                    field('link')
                    field(os.readlink(path))
                    try:
                        resolved = path.resolve(strict=True)
                        resolved.relative_to(root)
                    except (OSError, RuntimeError, ValueError) as exc:
                        raise ValueError(f'dependency link escapes or is invalid: {path}') from exc
                    if resolved == path.parent or resolved in path.parent.parents:
                        raise ValueError(f'dependency link forms a directory cycle: {path}')
                    if resolved.is_dir():
                        directory_edges[directory].add(resolved)
                elif stat.S_ISDIR(info.st_mode):
                    if ((hasattr(path, 'is_junction') and path.is_junction()) or
                            getattr(info, 'st_file_attributes', 0) & getattr(stat, 'FILE_ATTRIBUTE_REPARSE_POINT', 0)):
                        raise ValueError(f'dependency junction is unsupported: {path}')
                    field('directory')
                    directory_edges[directory].add(path)
                    visit(path)
                elif stat.S_ISREG(info.st_mode):
                    field('file')
                    field(sha256_file(path))
                else:
                    raise ValueError(f'unsupported dependency entry: {path}')
    field(str(stat.S_IMODE(root.stat().st_mode)))
    visit(root)
    visiting, visited = set(), set()
    def check_cycles(directory):
        if directory in visiting:
            raise ValueError(f'dependency link forms a directory cycle: {directory}')
        if directory in visited:
            return
        visiting.add(directory)
        for child in directory_edges.get(directory, ()):
            check_cycles(child)
        visiting.remove(directory)
        visited.add(directory)
    check_cycles(root)
    return digest.hexdigest()


def dependency_inputs(spec):
    """Bind an explicitly declared directory link to its target, bytes and tracked lockfile."""
    declarations = spec.get('dependency_links', [])
    if not isinstance(declarations, list):
        raise ValueError('dependency_links must be a list')
    root = Path.cwd().resolve()
    result = {}
    for item in declarations:
        if not isinstance(item, dict) or set(item) != {'path', 'target', 'lockfile'}:
            raise ValueError('dependency link requires path, target and lockfile')
        name, target, lock = item['path'], item['target'], item['lockfile']
        path = relative_input(name)
        if name in result:
            raise ValueError(f'duplicate dependency link: {name}')
        parent = unlinked_path(root, path.parent.as_posix()) if len(path.parts) > 1 else root
        link = parent / path.name
        if not link.is_symlink() or (hasattr(link, 'is_junction') and link.is_junction()):
            raise ValueError(f'dependency must be an explicit symbolic link: {name}')
        if not isinstance(target, str) or not Path(target).is_absolute():
            raise ValueError('dependency target must be an absolute path')
        try:
            actual = link.resolve(strict=True)
            declared = Path(target).resolve(strict=True)
        except (OSError, RuntimeError) as exc:
            raise ValueError(f'dependency target is invalid: {name}') from exc
        if actual != declared or not actual.is_dir():
            raise ValueError(f'dependency target does not match: {name}')
        if actual == root or actual in root.parents:
            raise ValueError('dependency target may not contain the project root')
        git_dirs = []
        for flag in ('--absolute-git-dir', '--git-common-dir'):
            value = subprocess.run(['git', 'rev-parse', flag], capture_output=True, text=True, check=True).stdout.strip()
            git_dirs.append((root / value).resolve())
        if any(actual == directory or directory in actual.parents or actual in directory.parents
               for directory in git_dirs):
            raise ValueError('dependency target may not be Git metadata')
        lock_path = unlinked_path(root, lock)
        if not lock_path.is_file() or not stat.S_ISREG(lock_path.lstat().st_mode):
            raise ValueError(f'dependency lockfile must be a regular file: {lock}')
        tracked = subprocess.run(['git', '--literal-pathspecs', 'ls-files', '--error-unmatch', '--', lock],
                                 capture_output=True, text=True)
        if tracked.returncode:
            raise ValueError(f'dependency lockfile must be tracked: {lock}')
        result[name] = {'target': target, 'resolved_target': str(actual), 'link_text': os.readlink(link),
                        'lockfile': lock, 'lock_sha256': sha256_file(lock_path),
                        'tree_sha256': dependency_tree_digest(actual)}
    return result


def protected_evidence_paths(spec, spec_file, baseline_file, receipt_file, inputs, states, dependencies):
    """Reject report paths that could overwrite declared inputs or evidence."""
    root = Path.cwd().resolve()
    protected = [root / name for name in list(inputs) + list(states)]
    for name, item in dependencies.items():
        protected.extend((root / name, root / item['lockfile'], Path(item['resolved_target'])))
    evidence = [Path(spec_file), Path(baseline_file)]
    if receipt_file is not None:
        evidence.append(receipt_file)
    evidence.extend(Path(item['junit']) for item in spec['commands'] if item.get('junit'))
    resolved = [path.resolve() for path in evidence]
    if len(set(resolved)) != len(resolved):
        raise ValueError('spec, baseline and JUnit reports must not overlap')
    for item in resolved:
        for path in protected:
            candidate = path.resolve()
            if item == candidate or item in candidate.parents or candidate in item.parents:
                raise ValueError('spec, baseline or JUnit report overlaps a declared input')
    inputs_resolved = [((root / name).resolve(), 'input') for name in list(inputs) + list(states)]
    for name, item in dependencies.items():
        inputs_resolved.extend(((root / name, 'link'), ((root / item['lockfile']).resolve(), 'lock')))
    for index, (item, kind) in enumerate(inputs_resolved):
        for other, other_kind in inputs_resolved[index + 1:]:
            if item == other and kind == other_kind == 'lock':
                continue
            if item == other or item in other.parents or other in item.parents:
                raise ValueError('declared inputs overlap')


def unexpected_inputs(spec, spec_file, baseline_file, inputs, states, dependencies):
    """Keep all unrelated untracked and ignored files visible at baseline."""
    untracked = subprocess.run(['git', 'ls-files', '--others', '--exclude-standard', '-z'],
                               capture_output=True, text=True, check=True).stdout.split('\0')
    ignored = subprocess.run(['git', 'ls-files', '--others', '--ignored', '--exclude-standard', '-z'],
                             capture_output=True, text=True, check=True).stdout.split('\0')
    root = Path.cwd().resolve()
    evidence = set(inputs) | set(states) | set(dependencies)
    for name in [spec_file, baseline_file, *[item.get('junit') for item in spec['commands'] if item.get('junit')]]:
        try:
            evidence.add(Path(name).resolve().relative_to(root).as_posix())
        except ValueError:
            pass
    return sorted(name for name in untracked + ignored if name and Path(name).as_posix() not in evidence)


def require_clean_tracked(states):
    for args in (['--cached'], []):
        diff = subprocess.run(['git', 'diff', '--name-only', '--no-renames', '-z', *args, '--'],
                              capture_output=True, text=True, check=True)
        changes = {name for name in diff.stdout.split('\0') if name}
        if changes - set(states):
            raise ValueError('starting commit has tracked changes outside the declared work state')


def checkout_revision():
    return subprocess.run(['git', 'rev-parse', '--verify', 'HEAD'],
                          capture_output=True, text=True, check=True).stdout.strip()


def report_path(name):
    """Reject tracked files, Git metadata and linked report paths before writes."""
    root = Path.cwd().resolve()
    path = relative_input(name)
    if '.git' in path.parts:
        raise ValueError('JUnit report cannot be Git metadata')
    target = unlinked_path(root, name)
    tracked = subprocess.run(['git', '--literal-pathspecs', 'ls-files', '--error-unmatch', '--', name], capture_output=True)
    if tracked.returncode == 0:
        raise ValueError(f'JUnit report cannot be a tracked file: {name}')
    if tracked.returncode != 1:
        raise ValueError(f'cannot check JUnit report tracking: {name}')
    if target.exists():
        info = target.lstat()
        if not stat.S_ISREG(info.st_mode) or info.st_nlink > 1:
            raise ValueError(f'JUnit report must be an unlinked regular file: {name}')
    return target


def report_identity(path):
    digest = sha256_file(path)
    info = path.lstat()
    if not stat.S_ISREG(info.st_mode) or info.st_nlink > 1:
        raise ValueError(f'JUnit report must be an unlinked regular file: {path}')
    return {'sha256': digest, 'device': info.st_dev, 'inode': info.st_ino,
            'mode': info.st_mode, 'size': info.st_size, 'mtime_ns': info.st_mtime_ns}


def receipt_path_for(baseline):
    root = Path.cwd().resolve()
    path = Path(os.path.abspath(str(baseline) + '.reports.json'))
    try:
        name = path.relative_to(root).as_posix()
    except ValueError as exc:
        raise ValueError('baseline receipt must be inside the project') from exc
    if '.git' in Path(name).parts:
        raise ValueError('baseline receipt cannot be Git metadata')
    path = unlinked_path(root, name)
    tracked = subprocess.run(['git', '--literal-pathspecs', 'ls-files', '--error-unmatch', '--', name], capture_output=True)
    if tracked.returncode == 0:
        raise ValueError('baseline receipt cannot overwrite a tracked file')
    if tracked.returncode != 1:
        raise ValueError('cannot check baseline receipt tracking')
    return path


def write_receipt(path, data, expected_identity=None):
    """Create a receipt exclusively, or replace only the receipt we previously read."""
    content = json.dumps(data, indent=2) + '\n'
    if expected_identity is None:
        with path.open('x', encoding='utf-8') as stream:
            stream.write(content)
    else:
        if path.is_symlink() or report_identity(path) != expected_identity:
            raise ValueError('baseline receipt changed while checks ran')
        temp = None
        try:
            with tempfile.NamedTemporaryFile('w', encoding='utf-8', dir=path.parent, delete=False) as stream:
                temp = Path(stream.name)
                stream.write(content)
            if path.is_symlink() or report_identity(path) != expected_identity:
                raise ValueError('baseline receipt changed while checks ran')
            os.replace(temp, path)
            temp = None
        finally:
            if temp is not None:
                temp.unlink(missing_ok=True)
    return report_identity(path)


def verify_report_ownership(spec, receipts):
    for command in spec['commands']:
        name = command.get('junit')
        if not name:
            continue
        path = report_path(name)
        if path.exists() and receipts.get(name) != report_identity(path):
            raise ValueError(f'JUnit report is not an unchanged helper-owned output: {name}')


def allowed_inputs(spec):
    hashes = {}
    root = Path.cwd().resolve()
    for name in spec.get('allowed_untracked', []):
        path = Path(name)
        if path.is_absolute() or '..' in path.parts or not path.parts:
            raise ValueError('allowed input must be a relative file')
        cursor = unlinked_path(root, path.as_posix())
        if not cursor.is_file():
            raise ValueError(f'allowed input is not a file: {name}')
        hashes[path.as_posix()] = sha256_file(cursor)
    return hashes


def run_commands(spec, receipts, persist_receipt=None):
    results = {}
    errors = []
    for command in spec['commands']:
        name, argv = command['name'], command['argv']
        if name in results or not argv:
            raise ValueError('command names must be unique and argv nonempty')
        report_name = command.get('junit')
        report = report_path(report_name) if report_name else None
        if report:
            if report.exists():
                expected = receipts.get(report_name)
                if expected != report_identity(report):
                    raise ValueError(f'JUnit report is not an unchanged helper-owned output: {report_name}')
                receipts.pop(report_name)
                if persist_receipt is not None:
                    persist_receipt()
                if report_identity(report) != expected:
                    raise ValueError(f'JUnit report changed before cleanup: {report_name}')
                report.unlink()
        try:
            proc = subprocess.run(argv, capture_output=True, text=True, errors='replace')
            print(proc.stdout, end='')
            print(proc.stderr, end='', file=sys.stderr)
            failures = {}
            count = None
            if report:
                report = report_path(report_name)
                root = ET.parse(report).getroot()
                cases = [case for case in root.findall('.//testcase') if case.find('skipped') is None]
                count = len(cases)
                if not count:
                    raise ValueError('no test cases in report')
                for case in cases:
                    key = case.get('classname', '') + '::' + case.get('name', '')
                    for failure in list(case):
                        if failure.tag in ('failure', 'error'):
                            if key in failures:
                                raise ValueError('duplicate failure identity: ' + key)
                            failures[key] = (failure.get('message', '') + '\n' + (failure.text or '')).strip()
                if bool(proc.returncode) != bool(failures):
                    raise ValueError('command status does not match JUnit failures')
            elif proc.returncode:
                failures['command'] = (proc.stdout + proc.stderr).strip() or f'exit {proc.returncode}'
            results[name] = {'count': count, 'failures': failures, 'argv': argv, 'junit': command.get('junit')}
            if report:
                receipts[report_name] = report_identity(report)
        except (OSError, ET.ParseError, ValueError) as exc:
            errors.append(f'{name}: {exc}')
        else:
            if report and persist_receipt is not None:
                persist_receipt()
    if errors:
        raise ValueError('; '.join(errors))
    if not results:
        raise ValueError('no commands')
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=['baseline', 'compare'])
    parser.add_argument('--spec', required=True)
    parser.add_argument('--baseline', required=True)
    args = parser.parse_args()
    try:
        spec = json.loads(Path(args.spec).read_text(encoding='utf-8'))
        spec_hash = sha256_file(Path(args.spec))
        baseline = Path(args.baseline)
        inputs = allowed_inputs(spec)
        states = work_state_inputs(spec)
        dependencies = dependency_inputs(spec)
        has_reports = any(item.get('junit') for item in spec['commands'])
        receipt_path = receipt_path_for(baseline) if has_reports else None
        protected_evidence_paths(spec, args.spec, args.baseline, receipt_path, inputs, states, dependencies)
        receipts = {}
        receipt_identity = [None]
        receipt = None
        baseline_hash = None
        if args.mode == 'baseline':
            if baseline.exists() or baseline.is_symlink():
                raise ValueError('baseline already exists')
            if receipt_path is not None and (receipt_path.exists() or receipt_path.is_symlink()):
                raise ValueError('baseline receipt already exists')
            commit = checkout_revision()
            require_clean_tracked(states)
            unexpected = unexpected_inputs(spec, args.spec, args.baseline, inputs, states, dependencies)
            if unexpected:
                raise ValueError('untracked baseline inputs: ' + ', '.join(unexpected))
        else:
            saved = json.loads(baseline.read_text(encoding='utf-8'))
            baseline_hash = sha256_file(baseline)
            if not saved['commit']:
                raise ValueError('baseline has no starting commit')
            if checkout_revision() != saved['commit']:
                raise ValueError('checkout revision differs from the baseline')
            if saved['allowed_untracked'] != inputs:
                raise ValueError('declared untracked baseline inputs changed')
            if set(saved.get('work_states', {})) != set(states):
                raise ValueError('declared work states changed')
            if saved.get('dependency_links', {}) != dependencies:
                raise ValueError('declared dependency links changed')
            old = saved['commands']
            if set(old) != {item['name'] for item in spec['commands']}:
                raise ValueError('command set changed')
            for item in spec['commands']:
                previous = old[item['name']]
                if (previous['argv'], previous['junit']) != (item['argv'], item.get('junit')):
                    raise ValueError(f"{item['name']}: command changed")
            if receipt_path is not None and receipt_path.exists():
                if receipt_path.lstat().st_nlink > 1:
                    raise ValueError('baseline receipt must not be hard-linked')
                receipt_identity[0] = report_identity(receipt_path)
                receipt = json.loads(receipt_path.read_text(encoding='utf-8'))
                if (not isinstance(receipt, dict) or set(receipt) != {'baseline_sha256', 'reports'} or
                        receipt['baseline_sha256'] != sha256_file(baseline) or
                        not isinstance(receipt['reports'], dict)):
                    raise ValueError('invalid or mismatched baseline receipt')
                receipts = receipt['reports']
                expected_names = {item['junit'] for item in spec['commands'] if item.get('junit')}
                if not set(receipts).issubset(expected_names):
                    raise ValueError('baseline receipt contains unexpected reports')
        verify_report_ownership(spec, receipts)
        if args.mode == 'compare' and receipt_path is not None and receipt is None:
            receipt = {'baseline_sha256': sha256_file(baseline), 'reports': receipts}
            receipt_identity[0] = write_receipt(receipt_path, receipt)

        def persist_receipt():
            if receipt_path_for(baseline) != receipt_path:
                raise ValueError('baseline receipt path changed while checks ran')
            receipt_identity[0] = write_receipt(receipt_path, receipt, receipt_identity[0])

        actual = run_commands(spec, receipts, persist_receipt if receipt is not None else None)
        if checkout_revision() != (commit if args.mode == 'baseline' else saved['commit']):
            raise ValueError('checkout revision changed while checks ran')
        if allowed_inputs(spec) != inputs or dependency_inputs(spec) != dependencies:
            raise ValueError('declared stable inputs changed while checks ran')
        if sha256_file(Path(args.spec)) != spec_hash:
            raise ValueError('check specification changed while checks ran')
        if baseline_hash is not None and sha256_file(baseline) != baseline_hash:
            raise ValueError('baseline changed while checks ran')
        final_states = work_state_inputs(spec)
        if set(final_states) != set(states):
            raise ValueError('declared work states changed while checks ran')
        for name, value in final_states.items():
            print(f'Work state: {name} sha256={value}')
        if args.mode == 'baseline':
            require_clean_tracked(final_states)
            unexpected = unexpected_inputs(spec, args.spec, args.baseline, inputs, final_states, dependencies)
            if unexpected:
                raise ValueError('untracked baseline inputs: ' + ', '.join(unexpected))
            with baseline.open('x', encoding='utf-8') as stream:
                stream.write(json.dumps({'commit': commit, 'allowed_untracked': inputs, 'work_states': states,
                                         'dependency_links': dependencies, 'commands': actual}, indent=2) + '\n')
            if receipt_path is not None:
                write_receipt(receipt_path, {'baseline_sha256': sha256_file(baseline), 'reports': receipts})
        else:
            if set(old) != set(actual):
                raise ValueError('command set changed')
            problems = []
            for name, result in actual.items():
                previous = old[name]
                if (result['argv'], result['junit']) != (previous['argv'], previous['junit']):
                    problems.append(f'{name}: command changed')
                if previous['count'] is not None and (result['count'] is None or result['count'] < previous['count']):
                    problems.append(f'{name}: fewer tests')
                for key, value in previous['failures'].items():
                    print(f'Pre-existing failure: {name} {key}: {value}')
                for key, value in result['failures'].items():
                    if previous['failures'].get(key) != value:
                        problems.append(f'{name}: new or changed failure {key}: {value}')
            if problems:
                raise ValueError('; '.join(problems))
        return 0
    except (OSError, ValueError, KeyError, TypeError, subprocess.CalledProcessError) as exc:
        print(f'checks: {exc}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
