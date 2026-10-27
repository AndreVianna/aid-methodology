#!/usr/bin/env python3
"""Purpose: capture and compare command and JUnit results.
Usage: checks.py baseline|compare --spec commands.json --baseline baseline.json
Exit codes: 0 for an accepted result, 1 for failure or invalid evidence.
"""
import argparse
import hashlib
import json
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def allowed_inputs(spec):
    hashes = {}
    root = Path.cwd().resolve()
    for name in spec.get('allowed_untracked', []):
        path = Path(name)
        if path.is_absolute() or '..' in path.parts or not path.parts:
            raise ValueError('allowed input must be a relative file')
        cursor = root
        for part in path.parts:
            cursor = cursor / part
            if cursor.is_symlink():
                raise ValueError('allowed input may not contain symbolic links')
        if not cursor.is_file():
            raise ValueError(f'allowed input is not a file: {name}')
        hashes[path.as_posix()] = hashlib.sha256(cursor.read_bytes()).hexdigest()
    return hashes


def run_commands(spec):
    results = {}
    errors = []
    for command in spec['commands']:
        name, argv = command['name'], command['argv']
        if name in results or not argv:
            raise ValueError('command names must be unique and argv nonempty')
        report = Path(command['junit']) if command.get('junit') else None
        if report:
            report.unlink(missing_ok=True)
        try:
            proc = subprocess.run(argv, capture_output=True, text=True, errors='replace')
            print(proc.stdout, end='')
            print(proc.stderr, end='', file=sys.stderr)
            failures = {}
            count = None
            if report:
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
        except (OSError, ET.ParseError, ValueError) as exc:
            errors.append(f'{name}: {exc}')
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
        baseline = Path(args.baseline)
        inputs = allowed_inputs(spec)
        if args.mode == 'baseline':
            if baseline.exists():
                raise ValueError('baseline already exists')
            commit = subprocess.run(['git', 'rev-parse', '--verify', 'HEAD'], capture_output=True, text=True, check=True).stdout.strip()
            clean = subprocess.run(['git', 'diff', '--quiet', 'HEAD', '--'], capture_output=True)
            if clean.returncode:
                raise ValueError('starting commit has tracked changes or cannot be checked')
            untracked = subprocess.run(['git', 'ls-files', '--others', '--exclude-standard', '-z'], capture_output=True, text=True, check=True).stdout.split('\0')
            ignored = subprocess.run(['git', 'ls-files', '--others', '--ignored', '--exclude-standard', '-z'], capture_output=True, text=True, check=True).stdout.split('\0')
            root = Path.cwd().resolve()
            evidence = set(inputs)
            for name in [args.spec, args.baseline, *[item.get('junit') for item in spec['commands'] if item.get('junit')]]:
                try:
                    evidence.add(Path(name).resolve().relative_to(root).as_posix())
                except ValueError:
                    pass
            unexpected = sorted(name for name in untracked + ignored if name and Path(name).as_posix() not in evidence)
            if unexpected:
                raise ValueError('untracked baseline inputs: ' + ', '.join(unexpected))
        actual = run_commands(spec)
        if args.mode == 'baseline':
            baseline.write_text(json.dumps({'commit': commit, 'allowed_untracked': inputs, 'commands': actual}, indent=2) + '\n', encoding='utf-8')
        else:
            saved = json.loads(baseline.read_text(encoding='utf-8'))
            if not saved['commit']:
                raise ValueError('baseline has no starting commit')
            if saved['allowed_untracked'] != inputs:
                raise ValueError('declared untracked baseline inputs changed')
            old = saved['commands']
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
