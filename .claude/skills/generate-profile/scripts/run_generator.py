#!/usr/bin/env python3
"""Wipe and fully regenerate each agents-only profile, then verify and resync dogfood."""
from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from aid_profile import load_profile, validate  # noqa: E402
from render import render_profile  # noqa: E402
from verify_advisory import run_advisory  # noqa: E402
from verify_deterministic import run_verify  # noqa: E402


def main() -> int:
    """Regenerate all profiles from clean output directories."""
    repo = Path(".")
    profiles_dir = repo / "profiles"
    total = 0
    for profile_path in sorted(profiles_dir.glob("*.toml")):
        profile = load_profile(str(profile_path))
        errors = validate(profile)
        if errors:
            print(f"ERROR: {profile.name}: {errors}", file=sys.stderr)
            return 1
        output = repo / profile.common_parent()
        if output.exists():
            shutil.rmtree(output)
        output.mkdir(parents=True)
        print(f"\n[RENDER] {profile.name} (clean profile wipe)...")
        emitted = render_profile(repo, profile, repo)
        total += len(emitted)
        print(f"  Emitted: {len(emitted)} files")

    print(f"\nTotal: {total} files emitted")
    print("\nRunning VERIFY (deterministic)...")
    passed, _report = run_verify(repo)
    if not passed:
        print("VERIFY (deterministic) FAILED", file=sys.stderr)
        return 1
    print("VERIFY (deterministic): PASS")

    report = run_advisory(repo)
    print(f"VERIFY (advisory): checked={report['checked_count']} warnings={report['warning_count']}")

    # Task-027 will repoint this dogfood sync after the profile manifest retirement.
    print("\nResyncing dogfood trees (.claude/ and .cursor/)...")
    sync = Path(__file__).resolve().parent / "sync_dogfood.py"
    result = subprocess.run([sys.executable, str(sync)], cwd=str(repo), text=True, capture_output=True)
    sys.stdout.write(result.stdout)
    if result.returncode:
        sys.stderr.write(result.stderr)
        print("DOGFOOD RESYNC FAILED", file=sys.stderr)
        return 1
    print("\nDone. Profile trees regenerated and dogfood trees resynced.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
