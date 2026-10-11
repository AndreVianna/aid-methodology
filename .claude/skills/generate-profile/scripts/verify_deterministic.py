#!/usr/bin/env python3
# verify_deterministic.py -- agents and aid-tool.conf hard gate
#
# Purpose:
#   Verify stable re-rendering, exact output contents, frontmatter/TOML syntax,
#   canonical-token neutralization, and descriptor placement data.
#
# Usage:
#   python verify_deterministic.py --canonical-root <repo-root>
#
# Requirements: Python 3.11+; standard library only.
from __future__ import annotations

import argparse
import filecmp
import json
import re
import sys
import tempfile
import tomllib
from pathlib import Path
from typing import Any

_SCRIPT_DIR = Path(__file__).parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from aid_profile import load_profile, validate  # noqa: E402
from render import _parse_frontmatter, render_profile  # noqa: E402


def _profiles(root: Path):
    profiles = []
    for path in sorted((root / "profiles").glob("*.toml")):
        profile = load_profile(str(path))
        errors = validate(profile)
        if errors:
            raise ValueError(f"Profile {profile.name} invalid: {errors}")
        profiles.append(profile)
    return profiles


def _render(root: Path, profiles, out: Path) -> None:
    for profile in profiles:
        render_profile(root, profile, out)


def _all_files(path: Path) -> set[str]:
    return {str(file.relative_to(path)).replace("\\", "/") for file in path.rglob("*") if file.is_file()}


def _check(root: Path) -> dict[str, Any]:
    profiles = _profiles(root)
    expected_agents = len(list((root / "canonical" / "agents").glob("*/AGENT.md")))
    offenders: list[str] = []
    with tempfile.TemporaryDirectory() as first, tempfile.TemporaryDirectory() as second:
        first_path, second_path = Path(first), Path(second)
        _render(root, profiles, first_path)
        _render(root, profiles, second_path)
        for profile in profiles:
            profile_dir = first_path / profile.common_parent()
            repeated = second_path / profile.common_parent()
            if _all_files(profile_dir) != _all_files(repeated):
                offenders.append(f"[{profile.name}] rendered file sets differ")
            else:
                for rel in sorted(_all_files(profile_dir)):
                    if (profile_dir / rel).read_bytes() != (repeated / rel).read_bytes():
                        offenders.append(f"[{profile.name}] nondeterministic output: {rel}")
                        break

            expected = {"aid-tool.conf"}
            suffix = ".toml" if profile.agent_format == "toml" else ".md"
            expected.update(f"{profile.root_dir}/agents/{path.parent.name}{suffix}"
                            for path in (root / "canonical" / "agents").glob("*/AGENT.md"))
            actual = _all_files(profile_dir)
            if actual != expected:
                offenders.append(f"[{profile.name}] output set mismatch (expected {len(expected)}, got {len(actual)})")

            descriptor = (profile_dir / "aid-tool.conf").read_bytes()
            try:
                descriptor.decode("ascii")
            except UnicodeDecodeError:
                offenders.append(f"[{profile.name}] aid-tool.conf is not ASCII")
            if b"\r" in descriptor:
                offenders.append(f"[{profile.name}] aid-tool.conf has non-LF line endings")

            for agent_path in sorted((profile_dir / profile.root_dir / "agents").glob("*")):
                content = agent_path.read_text(encoding="utf-8")
                if "canonical/" in content:
                    offenders.append(f"[{profile.name}] canonical token remains in {agent_path.name}")
                if agent_path.suffix == ".md":
                    fm, _body = _parse_frontmatter(content)
                    if not fm:
                        offenders.append(f"[{profile.name}] missing or malformed frontmatter in {agent_path.name}")
                elif agent_path.suffix == ".toml":
                    try:
                        tomllib.loads(content)
                    except tomllib.TOMLDecodeError as exc:
                        offenders.append(f"[{profile.name}] invalid TOML {agent_path.name}: {exc}")

    return {"overall_passed": not offenders, "offenders": offenders[:30], "profiles": len(profiles), "agents_per_profile": expected_agents}


def run_verify(canonical_root: str | Path, report_path: str | Path | None = None) -> tuple[bool, dict[str, Any]]:
    """Run all deterministic agent/descriptor checks and optionally save a report."""
    report = _check(Path(canonical_root))
    print("VERIFY (deterministic): agents and aid-tool.conf")
    print(f"  Profiles: {report['profiles']}; agents per profile: {report['agents_per_profile']}")
    print("  " + ("PASS" if report["overall_passed"] else "FAIL"))
    for offender in report["offenders"]:
        print(f"  - {offender}")
    if report_path:
        path = Path(report_path)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return report["overall_passed"], report


def _self_test(root: Path) -> int:
    """Run the focused verifier smoke test against an isolated full render."""
    report = _check(root)
    if report["overall_passed"]:
        print("OK: deterministic verifier self-test passed")
        return 0
    for offender in report["offenders"]:
        print(f"FAIL: {offender}", file=sys.stderr)
    return 1


def main() -> int:
    parser = argparse.ArgumentParser(prog="verify_deterministic.py")
    parser.add_argument("--canonical-root", required=True, metavar="PATH")
    parser.add_argument("--report-path", default=None)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        return _self_test(Path(args.canonical_root))
    passed, _report = run_verify(args.canonical_root, args.report_path)
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
