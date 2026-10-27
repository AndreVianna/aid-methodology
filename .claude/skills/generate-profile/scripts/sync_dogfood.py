#!/usr/bin/env python3
# sync_dogfood.py -- resync this repo's installed AID trees from a local release staging.
#
# Why this exists:
#   This repo installs AID into itself. Its tracked install trees (`.agents/skills/`,
#   `.claude/skills/aid-*`, `.aid/runtime/`, `.claude/agents/`, `.cursor/agents/`,
#   `AGENTS.md`, `CLAUDE.md`, and the rest of the managed set recorded in
#   `.aid/.aid-manifest.json`) are the output of `aid update`, not hand-copied files.
#   Running that install path by hand is easy to get wrong, so this script runs it.
#
# What a resync does (release-faithful, offline):
#   1. `bash release.sh --stage-only --out <tmp>/stage` stages the shared payload, the
#      tool artifacts and the CLI bundle from the working tree. `--stage-only` skips the
#      clean-tree, tag, render, render-drift and network checks, and never runs the
#      generator, so this script cannot recurse into `run_generator.py`.
#   2. `bin/aid update --from-bundle <tmp>/stage --target <target>`, run with
#      `AID_HOME=<tmp>/home` and `AID_NO_UPDATE_CHECK=1`. The maintainer's registry
#      (`~/.aid`) and the network are never touched. `<target>` defaults to this repo.
#
# `--check` runs `bin/aid status --target <target>` (same AID_HOME / AID_NO_UPDATE_CHECK)
# instead and reports drift from the `Shared files` block. It writes nothing to the target.
# A target whose manifest is not yet format 3 prints a `Layout:` line instead of the
# `Shared files` block; that counts as drift, because the resync has not run yet.
#
# Usage:
#   sync_dogfood.py                       Resync this repo; print the aid update summary.
#   sync_dogfood.py --check               Report drift and exit 1 if any; write nothing.
#   sync_dogfood.py --target <dir>        Operate on <dir> instead of the repo root
#                                         (used to test the resync on a scratch copy).
#
# Exit codes: 0 done / clean; 1 drift (--check) or a failed stage / update / status;
#             2 usage error.
#
# Python 3.11+ stdlib only. Zero third-party deps.

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[4]


def _bash_path(value: str | Path) -> str:
    """Use Git Bash's drive paths on Windows; preserve ordinary POSIX paths."""
    path = str(value).replace('\\', '/')
    if path.startswith('//'):
        raise ValueError('UNC paths are not supported for dogfood resync')
    return re.sub(r'^([A-Za-z]):(?:/|$)', lambda match: '/' + match.group(1).lower() + '/', path)


def _bash_prefix() -> list[str]:
    """Select Git Bash on Windows instead of the WSL launcher."""
    if sys.platform != 'win32':
        return ['bash']
    git = shutil.which('git')
    candidate = Path(git).resolve().parent.parent / 'bin/bash.exe' if git else None
    if candidate is None or not candidate.is_file():
        raise RuntimeError('Git Bash is required for Windows dogfood resync')
    return [str(candidate), '-o', 'igncr']


def _run(cmd: list[str], env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, cwd=str(REPO_ROOT), env=env, text=True,
                          capture_output=True)


def _env(home: Path) -> dict[str, str]:
    env = dict(os.environ)
    env["AID_HOME"] = _bash_path(home)
    env["AID_NO_UPDATE_CHECK"] = "1"
    return env


def resync(target: Path, scratch: Path) -> int:
    stage = scratch / "stage"
    home = scratch / "home"
    home.mkdir()

    print(f"sync_dogfood: staging release from {REPO_ROOT} (release.sh --stage-only)")
    staged = _run([*_bash_prefix(), "release.sh", "--stage-only", "--out", _bash_path(stage)])
    sys.stdout.write(staged.stdout)
    if staged.returncode:
        sys.stderr.write(staged.stderr)
        print("sync_dogfood: staging FAILED", file=sys.stderr)
        return 1

    print(f"sync_dogfood: aid update --from-bundle -> {target}")
    updated = subprocess.run(
        [*_bash_prefix(), _bash_path(REPO_ROOT / "bin" / "aid"), "update",
         "--from-bundle", _bash_path(stage), "--target", _bash_path(target)],
        cwd=str(REPO_ROOT), env=_env(home), text=True, capture_output=True)
    sys.stdout.write(updated.stdout)
    if updated.returncode:
        sys.stderr.write(updated.stderr)
        print("sync_dogfood: aid update FAILED", file=sys.stderr)
        return 1
    print("\nsync_dogfood: done")
    return 0


def check(target: Path, scratch: Path) -> int:
    home = scratch / "home"
    home.mkdir()
    status = subprocess.run(
        [*_bash_prefix(), _bash_path(REPO_ROOT / "bin" / "aid"), "status", "--target", _bash_path(target)],
        cwd=str(REPO_ROOT), env=_env(home), text=True, capture_output=True)
    sys.stdout.write(status.stdout)
    if status.returncode:
        sys.stderr.write(status.stderr)
        print("sync_dogfood: aid status FAILED", file=sys.stderr)
        return 1

    lines = [line.strip() for line in status.stdout.splitlines()]
    if "Shared files: clean" in lines and not any(line.startswith("Layout:") for line in lines):
        print("\nsync_dogfood: clean")
        return 0
    print("\nsync_dogfood: DRIFT -- run without --check", file=sys.stderr)
    return 1


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Resync this repo's installed AID trees from a local release staging.")
    parser.add_argument("--check", action="store_true",
                        help="report drift via 'aid status' and exit 1 if any; write nothing")
    parser.add_argument("--target", metavar="DIR", default=str(REPO_ROOT),
                        help="project root to resync (default: this repo's root)")
    args = parser.parse_args(argv)

    target = Path(args.target).resolve()
    if not target.is_dir():
        print(f"sync_dogfood: --target is not a directory: {target}", file=sys.stderr)
        return 2

    scratch = Path(tempfile.mkdtemp(prefix="aid-sync-dogfood-"))
    try:
        if args.check:
            return check(target, scratch)
        return resync(target, scratch)
    finally:
        shutil.rmtree(scratch, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
