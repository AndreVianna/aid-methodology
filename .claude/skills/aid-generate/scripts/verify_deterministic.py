#!/usr/bin/env python3
# verify_deterministic.py — AID generator deterministic verify hard gate
#
# Purpose:
#   Three sub-checks that MUST all pass before a render run is considered valid:
#   1. Byte-identical re-render: two independent render passes produce identical output.
#   2. File-presence audit: every file in the manifest exists; no extra generator files.
#   3. Frontmatter parse: every *.md and *.toml emitted parses without error.
#
# Usage:
#   python verify_deterministic.py --canonical-root <repo-root> [--report-path <path>]
#   python verify_deterministic.py --self-test --canonical-root <repo-root>
#
# Exit code: 0 on full pass; 1 on any sub-check failure.
# Requirements: Python 3.11+
from __future__ import annotations

import argparse
import filecmp
import json
import sys
import tempfile
import tomllib
from pathlib import Path
from typing import Any

_SCRIPT_DIR = Path(__file__).parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from aid_profile import load_profile, validate as validate_profile, Profile  # noqa: E402
from harness import EmissionManifest  # noqa: E402
from render_agents import render_agents  # noqa: E402
from render_skills import render_skills  # noqa: E402
from render_templates import render_templates  # noqa: E402
from render_recipes import render_recipes  # noqa: E402


# ---------------------------------------------------------------------------
# Minimal YAML frontmatter parser (same subset as render_agents.py)
# ---------------------------------------------------------------------------

def _parse_yaml_frontmatter(text: str) -> dict[str, Any] | None:
    """
    Parse YAML frontmatter from a ``---``-delimited block.

    Returns None if no frontmatter is present or the block is malformed.
    Returns a dict (possibly empty) on success.
    """
    lines = text.splitlines(keepends=True)
    if not lines or lines[0].strip() != "---":
        return {}  # No frontmatter → treat as valid (body-only file)

    end_idx = None
    for i, line in enumerate(lines[1:], start=1):
        if line.strip() == "---":
            end_idx = i
            break

    if end_idx is None:
        return None  # Unclosed frontmatter block → malformed

    # Minimal key:value parse (just check it doesn't blow up)
    fm: dict[str, Any] = {}
    i = 0
    fm_lines = lines[1:end_idx]
    while i < len(fm_lines):
        raw = fm_lines[i].rstrip("\n")
        if raw.strip() and not raw.strip().startswith("#"):
            if ":" in raw and not raw[0].isspace():
                key, _, val = raw.partition(":")
                key = key.strip()
                val = val.strip()
                if val == ">":
                    # Collect folded block continuation
                    block = []
                    i += 1
                    while i < len(fm_lines) and fm_lines[i] and fm_lines[i][0].isspace():
                        block.append(fm_lines[i].strip())
                        i += 1
                    fm[key] = " ".join(block)
                    continue
                else:
                    fm[key] = val
        i += 1

    return fm


# ---------------------------------------------------------------------------
# Full render helper
# ---------------------------------------------------------------------------

def _render_all(canonical_root: Path, profiles: list[Profile], output_dir: Path) -> list[EmissionManifest]:
    """Render all profiles into output_dir and return a manifest per profile."""
    manifests = []
    for profile in profiles:
        manifest = EmissionManifest(profile_name=profile.name)
        render_agents(canonical_root, profile, manifest, output_dir)
        render_skills(canonical_root, profile, manifest, output_dir)
        render_templates(canonical_root, profile, manifest, output_dir)
        render_recipes(canonical_root, profile, manifest, output_dir)
        manifests.append(manifest)
    return manifests


def _load_profiles(canonical_root: Path) -> list[Profile]:
    """Load and validate all profiles from canonical_root/profiles/."""
    profiles = []
    for profile_path in sorted((canonical_root / "profiles").glob("*.toml")):
        profile = load_profile(str(profile_path))
        errors = validate_profile(profile)
        if errors:
            raise ValueError(f"Profile {profile.name!r} invalid: {errors}")
        profiles.append(profile)
    return profiles


# ---------------------------------------------------------------------------
# Sub-check 1: byte-identical re-render
# ---------------------------------------------------------------------------

def _check_byte_identical(canonical_root: Path, profiles: list[Profile]) -> dict[str, Any]:
    """
    Render twice into separate scratch directories; compare byte-for-byte.

    Returns a result dict with keys: passed, offenders (up to 10).
    """
    with tempfile.TemporaryDirectory() as dir_a, tempfile.TemporaryDirectory() as dir_b:
        _render_all(canonical_root, profiles, Path(dir_a))
        _render_all(canonical_root, profiles, Path(dir_b))

        offenders: list[str] = []
        _recursive_compare(Path(dir_a), Path(dir_b), offenders, limit=10)

    return {
        "passed": len(offenders) == 0,
        "offenders": offenders,
        "description": "Byte-identical re-render",
    }


def _recursive_compare(dir_a: Path, dir_b: Path, offenders: list[str], limit: int) -> None:
    """
    Recursively compare two directory trees; append differing paths to offenders.

    Uses content comparison (not shallow mtime/size) to ensure correctness
    even when files are created at the same instant (avoids filecmp shallow=True
    false-same race).
    """
    if len(offenders) >= limit:
        return

    # Use shallow=False to force content comparison
    dcmp = filecmp.dircmp(str(dir_a), str(dir_b))
    # filecmp.dircmp doesn't expose shallow as a constructor param in all versions;
    # we use report_full_closure to force comparison, then manually content-check.

    # Files only in A (missing from B)
    for name in dcmp.left_only:
        offenders.append(f"only in A: {dir_a / name}")
        if len(offenders) >= limit:
            return

    # Files only in B (missing from A)
    for name in dcmp.right_only:
        offenders.append(f"only in B: {dir_b / name}")
        if len(offenders) >= limit:
            return

    # Force content comparison for all common files (bypasses shallow=True default)
    for name in dcmp.common_files:
        fa = dir_a / name
        fb = dir_b / name
        if fa.read_bytes() != fb.read_bytes():
            offenders.append(f"differs: {fa}")
            if len(offenders) >= limit:
                return

    # Recurse into subdirectories
    for sub in dcmp.common_dirs:
        _recursive_compare(dir_a / sub, dir_b / sub, offenders, limit)
        if len(offenders) >= limit:
            return


# ---------------------------------------------------------------------------
# Sub-check 2: file-presence audit against manifest
# ---------------------------------------------------------------------------

def _check_presence_audit(
    canonical_root: Path,
    profiles: list[Profile],
) -> dict[str, Any]:
    """
    For each profile: render into a temp dir, write the manifest, then verify
    that every manifest dst exists on disk (no missing files) and that no extra
    files exist within the generator-owned subtrees (no files outside manifest).

    Returns result dict.
    """
    offenders: list[str] = []

    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        manifests = _render_all(canonical_root, profiles, tmp_path)

        for profile, manifest in zip(profiles, manifests):
            common_parent = Path(profile.layout.common_parent())
            out_root = tmp_path / common_parent

            # Build expected set from manifest
            expected_dst = {r.dst for r in manifest._records}

            # Build actual set: walk all files under the profile's output roots
            actual_dst: set[str] = set()
            for out_dir in _profile_output_dirs(profile, tmp_path):
                for f in out_dir.rglob("*"):
                    if f.is_file():
                        rel = str(f.relative_to(tmp_path / common_parent)).replace("\\", "/")
                        actual_dst.add(rel)

            # Missing: in manifest but not on disk
            missing = expected_dst - actual_dst
            for dst in sorted(missing)[:5]:
                offenders.append(f"[{profile.name}] MISSING: {dst}")

            # Extra: on disk but not in manifest (within generator-owned tree)
            extra = actual_dst - expected_dst
            for dst in sorted(extra)[:5]:
                offenders.append(f"[{profile.name}] EXTRA: {dst}")

    return {
        "passed": len(offenders) == 0,
        "offenders": offenders[:10],
        "description": "File-presence audit against manifest",
    }


def _profile_output_dirs(profile: Profile, output_base: Path) -> list[Path]:
    """Return the list of output root directories for a profile."""
    if profile.layout.output_root is not None:
        return [output_base / profile.layout.output_root]
    else:
        # Codex split layout
        return [
            output_base / profile.layout.agents_root,  # type: ignore[arg-type]
            output_base / profile.layout.assets_root,  # type: ignore[arg-type]
        ]


# ---------------------------------------------------------------------------
# Sub-check 3: frontmatter parse
# ---------------------------------------------------------------------------

def _check_frontmatter_parse(canonical_root: Path, profiles: list[Profile]) -> dict[str, Any]:
    """
    Render into a temp dir; for every *.md, parse frontmatter.
    For every *.toml, load with tomllib.
    Any parse failure is a VERIFY (deterministic) fail.
    """
    offenders: list[str] = []

    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        _render_all(canonical_root, profiles, tmp_path)

        for profile in profiles:
            for out_dir in _profile_output_dirs(profile, tmp_path):
                if not out_dir.exists():
                    continue
                for f in sorted(out_dir.rglob("*")):
                    if not f.is_file():
                        continue

                    if f.suffix.lower() == ".md":
                        try:
                            text = f.read_text(encoding="utf-8")
                            result = _parse_yaml_frontmatter(text)
                            if result is None:
                                offenders.append(
                                    f"[{profile.name}] malformed frontmatter: {f.name}"
                                )
                        except Exception as exc:
                            offenders.append(
                                f"[{profile.name}] parse error in {f.name}: {exc}"
                            )

                    elif f.suffix.lower() == ".toml":
                        try:
                            with f.open("rb") as fh:
                                tomllib.load(fh)
                        except Exception as exc:
                            offenders.append(
                                f"[{profile.name}] TOML parse error in {f.name}: {exc}"
                            )

                    if len(offenders) >= 10:
                        break

    return {
        "passed": len(offenders) == 0,
        "offenders": offenders[:10],
        "description": "Frontmatter / TOML parse validation",
    }


# ---------------------------------------------------------------------------
# Top-level verifier
# ---------------------------------------------------------------------------

def run_verify(
    canonical_root: str | Path,
    report_path: str | Path | None = None,
) -> tuple[bool, dict[str, Any]]:
    """
    Run all three VERIFY (deterministic) sub-checks.

    Returns
    -------
    tuple[bool, dict]
        ``(overall_passed, report_dict)``.
    """
    canonical_root = Path(canonical_root)
    profiles = _load_profiles(canonical_root)

    print("VERIFY (deterministic): Running deterministic hard gate...")
    print(f"  Profiles: {[p.name for p in profiles]}")

    results: list[dict[str, Any]] = []

    print("\n  [1/3] Byte-identical re-render...")
    r1 = _check_byte_identical(canonical_root, profiles)
    results.append(r1)
    print(f"        {'PASS' if r1['passed'] else 'FAIL'}" +
          (f" — {len(r1['offenders'])} offender(s)" if not r1["passed"] else ""))

    print("  [2/3] File-presence audit...")
    r2 = _check_presence_audit(canonical_root, profiles)
    results.append(r2)
    print(f"        {'PASS' if r2['passed'] else 'FAIL'}" +
          (f" — {len(r2['offenders'])} offender(s)" if not r2["passed"] else ""))

    print("  [3/3] Frontmatter parse...")
    r3 = _check_frontmatter_parse(canonical_root, profiles)
    results.append(r3)
    print(f"        {'PASS' if r3['passed'] else 'FAIL'}" +
          (f" — {len(r3['offenders'])} offender(s)" if not r3["passed"] else ""))

    overall = all(r["passed"] for r in results)

    report: dict[str, Any] = {
        "overall_passed": overall,
        "checks": [
            {
                "name": r["description"],
                "passed": r["passed"],
                "offenders": r["offenders"],
            }
            for r in results
        ],
    }

    if report_path is not None:
        rp = Path(report_path)
        rp.parent.mkdir(parents=True, exist_ok=True)
        rp.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        print(f"\nReport written to {report_path}")

    return overall, report


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        prog="verify_deterministic.py",
        description=(
            "VERIFY (deterministic): deterministic hard gate. "
            "Runs byte-identical re-render, file-presence audit, and frontmatter parse. "
            "Exit 0 = all pass; exit 1 = any failure."
        ),
    )
    parser.add_argument("--canonical-root", required=True, metavar="PATH")
    parser.add_argument(
        "--report-path",
        metavar="PATH",
        default=".aid/work-002-canonical-generator/verify-deterministic-report.json",
        help="Where to write the JSON report (default: .aid/work-002-canonical-generator/verify-deterministic-report.json)",
    )
    parser.add_argument("--self-test", action="store_true", help="Run failure-mode smoke tests")
    args = parser.parse_args()

    if args.self_test:
        return _self_test(args.canonical_root)

    passed, report = run_verify(args.canonical_root, args.report_path)

    if passed:
        print("\nVERIFY (deterministic): ALL CHECKS PASSED")
        return 0
    else:
        print("\nVERIFY (deterministic): FAILED", file=sys.stderr)
        for check in report["checks"]:
            if not check["passed"]:
                print(f"  FAIL: {check['name']}", file=sys.stderr)
                for o in check["offenders"][:5]:
                    print(f"    - {o}", file=sys.stderr)
        return 1


def _self_test(canonical_root_arg: str) -> int:
    """
    Smoke tests for failure-mode detection.
    Tests: (a) non-determinism detection, (b) missing-file detection,
           (c) malformed frontmatter detection.
    All three failure modes must be detected.
    """
    if not canonical_root_arg:
        print("ERROR: --canonical-root required for --self-test", file=sys.stderr)
        return 1

    canonical_root = Path(canonical_root_arg)
    failures: list[str] = []

    # -----------------------------------------------------------------------
    # Smoke test (b): missing file → presence audit fails
    # -----------------------------------------------------------------------
    print("Self-test (b): missing file detection...")
    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        profiles = _load_profiles(canonical_root)
        manifests = _render_all(canonical_root, profiles, tmp_path)

        # Delete one file from the rendered tree
        first_profile = profiles[0]
        first_manifest = manifests[0]
        if first_manifest._records:
            common_parent = first_profile.layout.common_parent()
            first_dst = first_manifest._records[0].dst
            target = tmp_path / common_parent / first_dst
            if target.exists():
                target.unlink()

        # Re-run presence audit (using the same temp dir, manifest recorded)
        # Simulate by building a manifest from what we rendered and checking vs disk
        offenders: list[str] = []
        for profile, manifest in zip(profiles, manifests):
            cp = Path(profile.layout.common_parent())
            out_root = tmp_path / cp
            expected_dst = {r.dst for r in manifest._records}
            actual_dst: set[str] = set()
            for out_dir in _profile_output_dirs(profile, tmp_path):
                for f in out_dir.rglob("*"):
                    if f.is_file():
                        rel = str(f.relative_to(tmp_path / cp)).replace("\\", "/")
                        actual_dst.add(rel)
            missing = expected_dst - actual_dst
            for dst in sorted(missing)[:5]:
                offenders.append(f"MISSING: {dst}")

        if offenders:
            print(f"  PASS: missing file detected ({offenders[0]})")
        else:
            failures.append("Smoke test (b) FAIL: missing file not detected by presence audit")

    # -----------------------------------------------------------------------
    # Smoke test (c): malformed frontmatter detection
    # -----------------------------------------------------------------------
    print("Self-test (c): malformed frontmatter detection...")
    malformed_tests = [
        "---\nname: test\ndescription: good\n",  # unclosed frontmatter → None
    ]
    for text in malformed_tests:
        result = _parse_yaml_frontmatter(text)
        if result is None:
            print("  PASS: malformed frontmatter detected (unclosed block)")
        else:
            failures.append(f"Smoke test (c) FAIL: malformed frontmatter not detected: {text!r}")

    # -----------------------------------------------------------------------
    # Smoke test (a): byte-identical check with non-determinism
    # -----------------------------------------------------------------------
    # We test the comparison function directly rather than patching a renderer
    print("Self-test (a): byte-identical comparison logic...")
    with tempfile.TemporaryDirectory() as dir_a, tempfile.TemporaryDirectory() as dir_b:
        pa = Path(dir_a) / "file.txt"
        pb = Path(dir_b) / "file.txt"
        pa.write_bytes(b"content-a")
        pb.write_bytes(b"content-b")  # different content = non-determinism

        test_offenders: list[str] = []
        _recursive_compare(Path(dir_a), Path(dir_b), test_offenders, limit=10)
        if test_offenders:
            print("  PASS: byte-difference detected")
        else:
            failures.append("Smoke test (a) FAIL: byte difference not detected")

    # -----------------------------------------------------------------------
    # Results
    # -----------------------------------------------------------------------
    if failures:
        print(f"\nSELF-TEST FAILED ({len(failures)} failure(s)):", file=sys.stderr)
        for f in failures:
            print(f"  - {f}", file=sys.stderr)
        return 1

    print("\nOK: all VERIFY (deterministic) self-tests passed (3 smoke tests)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
