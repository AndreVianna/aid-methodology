#!/usr/bin/env python3
# sync_dogfood.py -- resync the repo-root dogfood trees from the rendered profiles.
#
# Why this exists:
#   `run_generator.py` writes the five `profiles/<tool>/...` trees. It does NOT
#   write the two TRACKED dogfood trees at the repo root (`.claude/`, `.cursor/`)
#   -- this repo installs AID into itself, so those trees are copies of the
#   corresponding profile output. `tests/canonical/test-dogfood-byte-identity.sh`
#   asserts they match their profile's emission manifest byte-for-byte, so a
#   render that is not followed by a resync leaves CI red.
#
#   That step was previously undocumented and done by hand. Doing it by hand is
#   how you end up copying a file the manifest does not own.
#
# What it copies, and what it must never touch:
#   ONLY the `dst` paths listed in each profile's `emission-manifest.jsonl`. Files
#   that live in a dogfood tree WITHOUT a manifest entry are hand-authored
#   maintainer content -- `.claude/settings.json`, `.claude/output-styles/**`,
#   `.claude/skills/generate-profile/**` (this script included),
#   `.cursor/rules/**` -- and are deliberately left alone. The dogfood suite's
#   Direction-3 allowlists are the authority on which of those are legitimate.
#
#   Deletion is bounded the same way `run_generator.py` bounds its own: a path is
#   removed only if the PREVIOUS manifest listed it and the current one does not.
#   An unmanifested file can therefore never be swept, whatever its path.
#
# Usage:
#   sync_dogfood.py                Resync both trees; print a per-tree summary.
#   sync_dogfood.py --check        Report drift and exit 1 if any; write nothing.
#
# Python 3.11+ stdlib only. Zero third-party deps.

from __future__ import annotations

import json
import shutil
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[4]

# (profile dir, dst prefix the profile owns inside the repo root)
PAIRS = (("profiles/claude-code", ".claude/"), ("profiles/cursor", ".cursor/"))


def manifest_entries(profile_dir: Path, prefix: str) -> dict[str, str]:
    """Return {dst: sha256} for the manifest rows this tree owns.

    The manifest's first row is a `{"_manifest_version": N}` header with no `dst`;
    rows without `dst` are skipped rather than assumed absent.
    """
    path = profile_dir / "emission-manifest.jsonl"
    if not path.is_file():
        return {}
    out: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        row = json.loads(line)
        dst = row.get("dst")
        if dst and dst.startswith(prefix):
            out[dst] = row.get("sha256", "")
    return out


def sync(check_only: bool) -> int:
    drift = 0
    for rel_profile, prefix in PAIRS:
        profile_dir = REPO_ROOT / rel_profile
        owned = manifest_entries(profile_dir, prefix)
        if not owned:
            print(f"  {prefix:10} no manifest entries -- is {rel_profile} rendered?")
            drift += 1
            continue

        copied = identical = missing_src = 0
        for dst_rel in sorted(owned):
            src = profile_dir / dst_rel
            dst = REPO_ROOT / dst_rel
            if not src.is_file():
                print(f"  MISSING SOURCE {src.relative_to(REPO_ROOT)}")
                missing_src += 1
                continue
            if dst.is_file() and dst.read_bytes() == src.read_bytes():
                identical += 1
                continue
            if check_only:
                copied += 1
                continue
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(src, dst)
            copied += 1

        verb = "would resync" if check_only else "resynced"
        print(f"  {prefix:10} owned={len(owned):4}  {verb}={copied:4}  "
              f"identical={identical:4}" + (f"  MISSING-SRC={missing_src}" if missing_src else ""))
        drift += copied + missing_src

    if check_only:
        print("\nsync_dogfood: " + ("DRIFT -- run without --check" if drift else "clean"))
        return 1 if drift else 0
    print("\nsync_dogfood: done")
    return 0


if __name__ == "__main__":
    args = sys.argv[1:]
    if args and args != ["--check"]:
        print("usage: sync_dogfood.py [--check]", file=sys.stderr)
        sys.exit(2)
    sys.exit(sync(check_only=bool(args)))
