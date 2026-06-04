#!/usr/bin/env python3
# test_manifest_safety.py — EmissionManifest safety-boundary tests
#
# Purpose:
#   Validates the two safety-boundary invariants of the emission manifest:
#   1. User-created files inside an install tree that are NOT in any prior manifest
#      are never touched by the generator's deletion pass.
#   2. Removing a file from canonical/ and re-running causes the corresponding
#      install-tree file to be deleted (it was in the prior manifest; the current
#      run's manifest will not contain it → it appears in removed_dst).
#
# Usage:
#   python test_manifest_safety.py --self-test
#
# Requirements: Python 3.11+
from __future__ import annotations

import argparse
import os
import sys
import tempfile
from pathlib import Path

# ---------------------------------------------------------------------------
# Add script directory to sys.path so render_lib / aid_profile can be imported
# directly (maintainer-tooling; no package install needed)
# ---------------------------------------------------------------------------
_SCRIPT_DIR = Path(__file__).parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from render_lib import EmissionManifest, sha256_hex  # noqa: E402


# ---------------------------------------------------------------------------
# Safety-boundary simulation helpers
# ---------------------------------------------------------------------------

def _simulate_deletion_pass(
    install_root: Path,
    prev_manifest: EmissionManifest,
    curr_manifest: EmissionManifest,
) -> list[str]:
    """
    Simulate the generator's pure-mirror deletion pass.

    Deletes files in ``removed_dst`` (files that were in the previous manifest
    but are absent from the current run's manifest).  Prunes empty parent
    directories within *install_root*.

    Returns
    -------
    list[str]
        List of paths that were deleted (relative to install_root).
    """
    _added, removed, _changed = curr_manifest.diff(prev_manifest)
    deleted: list[str] = []

    for rel_dst in removed:
        target = install_root / rel_dst
        if target.exists():
            target.unlink()
            deleted.append(rel_dst)
            # Prune empty parent directories (but not install_root itself)
            parent = target.parent
            while parent != install_root and parent.exists():
                try:
                    parent.rmdir()  # only succeeds if empty
                    parent = parent.parent
                except OSError:
                    break  # not empty — stop

    return deleted


# ---------------------------------------------------------------------------
# Safety boundary test 1:
#   A user-created file inside the install tree that is NOT in any prior manifest
#   must NOT be deleted by the deletion pass.
# ---------------------------------------------------------------------------

def test_user_file_untouched() -> list[str]:
    """
    Safety boundary test 1: user file not in manifest → not deleted.

    Scenario:
    - Prior manifest records one generator-owned file.
    - Current manifest records the same file (no change → removed_dst is empty).
    - A user-created file exists inside the install tree.
    - After the deletion pass, the user file must still exist.
    """
    failures: list[str] = []

    with tempfile.TemporaryDirectory() as tmpdir:
        install_root = Path(tmpdir)

        # Create the generator-owned file (in both manifests)
        gen_file = install_root / ".claude" / "agents" / "aid-architect.md"
        gen_file.parent.mkdir(parents=True, exist_ok=True)
        gen_bytes = b"# aid-architect agent\n"
        gen_file.write_bytes(gen_bytes)

        # Create the user-owned file (NOT in any manifest)
        user_file = install_root / ".claude" / "USER-NOTES.md"
        user_file.write_bytes(b"# my notes\n")

        # Build previous and current manifests (identical → no removals)
        prev = EmissionManifest(profile_name="claude-code")
        prev.add(
            profile="claude-code",
            src="canonical/agents/aid-architect/AGENT.md",
            dst=".claude/agents/aid-architect.md",
            content=gen_bytes,
        )

        curr = EmissionManifest(profile_name="claude-code")
        curr.add(
            profile="claude-code",
            src="canonical/agents/aid-architect/AGENT.md",
            dst=".claude/agents/aid-architect.md",
            content=gen_bytes,
        )

        deleted = _simulate_deletion_pass(install_root, prev, curr)

        if not user_file.exists():
            failures.append(
                "Safety test 1 FAILED: user-created file was deleted by the deletion pass"
            )
        if deleted:
            failures.append(
                f"Safety test 1 FAILED: deletion pass removed files it should not have: {deleted}"
            )

    return failures


# ---------------------------------------------------------------------------
# Safety boundary test 2:
#   Removing a canonical/ source file cascades to deletion of the corresponding
#   install-tree file (it was in the prior manifest; absent from the current run).
# ---------------------------------------------------------------------------

def test_canonical_removal_cascades() -> list[str]:
    """
    Safety boundary test 2: canonical source removed → install-tree file deleted.

    Scenario:
    - Prior manifest records two generator-owned files (aid-architect.md and aid-developer.md).
    - Current run only emits aid-architect.md (aid-developer.md was removed from canonical/).
    - After the deletion pass, aid-developer.md in the install tree is deleted.
    - aid-architect.md is untouched.
    """
    failures: list[str] = []

    with tempfile.TemporaryDirectory() as tmpdir:
        install_root = Path(tmpdir)

        # Create both generator-owned files in the install tree
        arch_bytes = b"# aid-architect agent\n"
        dev_bytes = b"# aid-developer agent\n"

        arch_file = install_root / ".claude" / "agents" / "aid-architect.md"
        dev_file = install_root / ".claude" / "agents" / "aid-developer.md"
        arch_file.parent.mkdir(parents=True, exist_ok=True)
        arch_file.write_bytes(arch_bytes)
        dev_file.write_bytes(dev_bytes)

        # Prior manifest: both files were emitted
        prev = EmissionManifest(profile_name="claude-code")
        prev.add(
            profile="claude-code",
            src="canonical/agents/aid-architect/AGENT.md",
            dst=".claude/agents/aid-architect.md",
            content=arch_bytes,
        )
        prev.add(
            profile="claude-code",
            src="canonical/agents/aid-developer/AGENT.md",
            dst=".claude/agents/aid-developer.md",
            content=dev_bytes,
        )

        # Current manifest: only aid-architect.md (aid-developer.md removed from canonical/)
        curr = EmissionManifest(profile_name="claude-code")
        curr.add(
            profile="claude-code",
            src="canonical/agents/aid-architect/AGENT.md",
            dst=".claude/agents/aid-architect.md",
            content=arch_bytes,
        )

        deleted = _simulate_deletion_pass(install_root, prev, curr)

        if dev_file.exists():
            failures.append(
                "Safety test 2 FAILED: install-tree file for removed canonical source still exists"
            )
        if ".claude/agents/aid-developer.md" not in deleted:
            failures.append(
                f"Safety test 2 FAILED: deletion pass did not delete aid-developer.md; deleted: {deleted}"
            )
        if not arch_file.exists():
            failures.append(
                "Safety test 2 FAILED: aid-architect.md was deleted but should have been kept"
            )

    return failures


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        prog="test_manifest_safety.py",
        description=(
            "EmissionManifest safety-boundary tests. "
            "Verifies that the deletion pass never touches user-created files "
            "and correctly cascades canonical removals to install-tree deletions."
        ),
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run the safety-boundary tests and exit 0 on success, 1 on failure.",
    )
    args = parser.parse_args()

    if not args.self_test:
        parser.print_help()
        return 0

    all_failures: list[str] = []

    print("Running safety-boundary test 1: user-created file must not be deleted...")
    all_failures.extend(test_user_file_untouched())

    print("Running safety-boundary test 2: canonical removal cascades to install-tree deletion...")
    all_failures.extend(test_canonical_removal_cascades())

    if all_failures:
        print(f"\nSAFETY-BOUNDARY TESTS FAILED ({len(all_failures)} failure(s)):", file=sys.stderr)
        for f in all_failures:
            print(f"  - {f}", file=sys.stderr)
        return 1

    print("\nOK: all safety-boundary tests passed (2 tests)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
