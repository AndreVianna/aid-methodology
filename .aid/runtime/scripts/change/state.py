#!/usr/bin/env python3
"""Purpose: write a compact work state atomically.
Usage: state.py --file state.json --data '{"goal":"..."}'
Exit codes: 0 on success, 1 for invalid data or write failure.
"""
import argparse
import json
import os
import sys
import tempfile
import re
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path


def init_direct(work_arg, goal):
    # The caller owns the newly allocated directory exclusively during setup.
    # The final link prevents overwriting a state created by another initializer.
    if not goal or not goal.strip() or '\n' in goal or '\r' in goal:
        raise ValueError('a nonempty single-line goal is required')
    root = Path.cwd().resolve()
    works = root / '.aid' / 'works'
    work = Path(work_arg).absolute()
    if (not re.fullmatch(r'work-[0-9]+-[a-zA-Z0-9][a-zA-Z0-9_-]*', work.name)
            or work.parent != works or not work.is_dir()
            or work.is_symlink() or works.is_symlink() or works.parent.is_symlink()
            or work.resolve().parent != works.resolve()):
        raise ValueError('work must be an allocated, unlinked project work directory')
    target = work / 'STATE.yml'
    if os.path.lexists(target):
        raise ValueError('work state already exists')
    if any(work.iterdir()):
        raise ValueError('direct work must start in an empty allocated directory')
    runtime = Path(__file__).resolve().parents[2]
    template = runtime / 'templates/direct-state-template.yml'
    reader = runtime / 'scripts/config/read-setting.sh'
    writer = runtime / 'scripts/execute/writeback-state.sh'
    if not all(p.is_file() for p in (template, reader, writer)):
        raise ValueError('direct template, settings reader, and writer are required')
    bash = None
    child_env = dict(os.environ)
    if os.name == 'nt':
        git = shutil.which('git')
        if git:
            git_root = Path(git).resolve().parent.parent
            candidate = git_root / 'bin' / 'bash.exe'
            if candidate.is_file():
                bash = str(candidate)
                child_env['PATH'] = os.pathsep.join((str(git_root / 'bin'), str(git_root / 'usr/bin'), child_env.get('PATH', '')))
    bash = bash or shutil.which('bash')
    if not bash:
        raise ValueError('bash is required')
    grade = subprocess.run([bash, str(reader.relative_to(root)).replace('\\', '/'),
                            '--skill', 'change', '--key', 'minimum_grade', '--default', 'A'],
                           cwd=root, env=child_env, check=True, capture_output=True, text=True).stdout.strip()
    with tempfile.TemporaryDirectory(prefix='.aid-direct-init-', dir=work) as tmp:
        stage = Path(tmp)
        state = stage / 'STATE.yml'
        shutil.copyfile(template, state)
        relative_stage = stage.relative_to(root).as_posix()
        env = dict(child_env, AID_STATE_FILE=f'{relative_stage}/STATE.yml',
                   AID_WORK_DIR=relative_stage, TMPDIR=relative_stage)
        now = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
        fields = [('Direct Goal', goal), ('Minimum Grade', grade), ('Started', now), ('Updated', now)]
        for field, value in fields:
            subprocess.run([bash, str(writer.relative_to(root)).replace('\\', '/'),
                            '--pipeline', '--field', field, '--value', value],
                           cwd=root, env=env, check=True, capture_output=True, text=True)
        os.link(state, target)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--file')
    parser.add_argument('--data')
    parser.add_argument('--init-work-dir')
    parser.add_argument('--goal')
    args = parser.parse_args()
    temp = None
    try:
        if args.init_work_dir:
            if args.file is not None or args.data is not None:
                raise ValueError('initialization cannot be combined with JSON output')
            init_direct(args.init_work_dir, args.goal)
            return 0
        if args.file is None or args.data is None or args.goal is not None:
            raise ValueError('provide --file and --data, or --init-work-dir and --goal')
        data = json.loads(args.data)
        if not isinstance(data, dict):
            raise ValueError('state must be an object')
        path = Path(args.file)
        with tempfile.NamedTemporaryFile('w', encoding='utf-8', dir=path.parent, delete=False) as out:
            temp = out.name
            json.dump(data, out, ensure_ascii=False, indent=2)
            out.write('\n')
        os.replace(temp, path)
        return 0
    except (OSError, ValueError, subprocess.SubprocessError) as exc:
        print(f'state: {exc}', file=sys.stderr)
        return 1
    finally:
        if temp and os.path.exists(temp):
            os.unlink(temp)


if __name__ == '__main__':
    sys.exit(main())
