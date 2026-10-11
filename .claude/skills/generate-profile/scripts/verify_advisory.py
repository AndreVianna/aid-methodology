#!/usr/bin/env python3
# verify_advisory.py -- supplemental agents/descriptor review
#
# Purpose:
#   Report advisory observations for profile agents and aid-tool.conf without
#   introducing a second blocking validator.
#
# Usage:
#   python verify_advisory.py --canonical-root <repo-root>
#
# Requirements: Python 3.11+; standard library only.
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

_SCRIPT_DIR = Path(__file__).parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from aid_profile import load_profile, validate  # noqa: E402


def run_advisory(canonical_root: str | Path, report_path: str | Path | None = None) -> dict[str, Any]:
    """Summarize profile agent and descriptor outputs; always advisory."""
    root = Path(canonical_root)
    profiles = []
    for path in sorted((root / "profiles").glob("*.toml")):
        profile = load_profile(str(path))
        errors = validate(profile)
        profiles.append({
            "tool": profile.name,
            "descriptor": f"profiles/{profile.name}/aid-tool.conf",
            "valid_profile": not errors,
            "validation_errors": errors,
            "agent_source_count": len(list((root / "canonical" / "agents").glob("*/AGENT.md"))),
        })
    report: dict[str, Any] = {
        "profiles": profiles,
        "checked_count": len(profiles),
        "warning_count": sum(bool(item["validation_errors"]) for item in profiles),
        "note": "Advisory scope is canonical agents and per-profile aid-tool.conf.",
    }
    if report_path:
        path = Path(report_path)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return report


def main() -> int:
    parser = argparse.ArgumentParser(prog="verify_advisory.py")
    parser.add_argument("--canonical-root", required=True, metavar="PATH")
    parser.add_argument("--report-path", default=None)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    report = run_advisory(args.canonical_root, args.report_path)
    if args.self_test:
        if report["checked_count"] != len(list((Path(args.canonical_root) / "profiles").glob("*.toml"))):
            print("FAIL: advisory report did not cover every profile", file=sys.stderr)
            return 1
        if report["warning_count"]:
            print("FAIL: advisory report found invalid profile configuration", file=sys.stderr)
            return 1
        print("OK: advisory self-test passed")
        return 0
    print(f"VERIFY (advisory): checked={report['checked_count']} warnings={report['warning_count']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
