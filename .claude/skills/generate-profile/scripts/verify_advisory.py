#!/usr/bin/env python3
# verify_advisory.py — AID generator advisory verify conformance layer
#
# Purpose:
#   Non-blocking advisory check. For each vendor URL in external-sources.md:
#   - If URL is "⚠️ Pending fetch" or unreachable → skip with warning (skipped_count++)
#   - If URL is reachable AND previously fetched → run conformance stub (warns only)
#   Always exits 0 (advisory layer, never gates the run).
#
# Usage:
#   python verify_advisory.py --canonical-root <repo-root> [--report-path <path>]
#   python verify_advisory.py --self-test --canonical-root <repo-root>
#
# Requirements: Python 3.11+
from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.request
import urllib.error
from pathlib import Path
from typing import Any

_SCRIPT_DIR = Path(__file__).parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))


# ---------------------------------------------------------------------------
# external-sources.md parser
# ---------------------------------------------------------------------------

def _parse_external_sources(sources_path: Path) -> list[dict[str, str]]:
    """
    Parse the registered sources table from external-sources.md.

    Returns a list of dicts with keys: num, source, type, url, scope, accessible.
    Only rows whose 'type' is 'web' are returned.
    """
    text = sources_path.read_text(encoding="utf-8")
    # Find the table section
    entries: list[dict[str, str]] = []

    for line in text.splitlines():
        # Match table data rows: | num | source | type | url | scope | accessible |
        if not line.strip().startswith("|"):
            continue
        parts = [p.strip() for p in line.strip().strip("|").split("|")]
        if len(parts) < 6:
            continue
        num, source, kind, url, scope, accessible = parts[:6]

        # Skip header and separator rows
        if not num.isdigit():
            continue
        if kind.lower() != "web":
            continue

        entries.append({
            "num": num,
            "source": source,
            "type": kind,
            "url": url,
            "scope": scope,
            "accessible": accessible,
        })

    return entries


# ---------------------------------------------------------------------------
# Reachability check
# ---------------------------------------------------------------------------

def _is_pending_fetch(accessible: str) -> bool:
    """Return True if the 'accessible' field indicates this URL has not been fetched."""
    return "Pending fetch" in accessible or "⚠️" in accessible


def _check_url_reachable(url: str, timeout: int = 5) -> tuple[bool, str]:
    """
    Attempt a HEAD request to the URL.

    Returns (reachable: bool, reason: str).
    file:// URLs are handled specially (checked for local file existence).
    """
    if url.startswith("file://"):
        # Local file URL — check file existence
        local_path = Path(url[7:])
        if local_path.exists():
            return True, "local file exists"
        return False, f"local file not found: {local_path}"

    try:
        req = urllib.request.Request(url, method="HEAD")
        req.add_header("User-Agent", "AID-verify-advisory/1.0")
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return True, f"HTTP {resp.status}"
    except urllib.error.HTTPError as exc:
        if exc.code < 500:
            # 4xx still means the server is reachable
            return True, f"HTTP {exc.code} (client error but server reachable)"
        return False, f"HTTP {exc.code}"
    except Exception as exc:
        return False, str(exc)


# ---------------------------------------------------------------------------
# Conformance check stub
# ---------------------------------------------------------------------------

def _run_conformance_stub(
    source: dict[str, str],
    canonical_root: Path,
) -> list[str]:
    """
    Conformance review stub.

    This is invoked when a URL is reachable and previously fetched.
    The full conformance review (agent dispatch + detailed doc comparison) is
    a future enhancement — this stub emits a warning to surface in the report.

    Returns a list of warning strings.
    """
    return [
        f"Conformance stub: no automated review implemented yet for {source['source']!r}. "
        f"Manual review recommended against {source['url']}"
    ]


# ---------------------------------------------------------------------------
# Top-level advisor
# ---------------------------------------------------------------------------

def run_advisory(
    canonical_root: str | Path,
    report_path: str | Path | None = None,
    timeout: int = 5,
) -> dict[str, Any]:
    """
    Run the VERIFY (advisory) advisory conformance layer.

    Always returns a report dict (never raises for network errors).
    """
    canonical_root = Path(canonical_root)
    sources_md = canonical_root / ".aid" / "knowledge" / "external-sources.md"

    print("VERIFY (advisory): Running advisory conformance layer...")

    # Load URL list
    try:
        entries = _parse_external_sources(sources_md)
    except FileNotFoundError:
        entries = []
        print(f"  WARNING: {sources_md} not found — skipping all URL checks")

    print(f"  Found {len(entries)} web source(s) to check")

    results: list[dict[str, Any]] = []
    skipped_count = 0
    checked_count = 0
    warning_count = 0

    for entry in entries:
        url = entry["url"]
        source_name = entry["source"]
        accessible = entry["accessible"]

        result: dict[str, Any] = {
            "num": entry["num"],
            "source": source_name,
            "url": url,
            "status": "skipped",
            "warnings": [],
        }

        if _is_pending_fetch(accessible):
            result["status"] = "skipped"
            result["skip_reason"] = "marked as pending fetch in external-sources.md"
            skipped_count += 1
            print(f"  [{entry['num']}] SKIP: {source_name} (pending fetch)")
        else:
            # Check reachability
            reachable, reason = _check_url_reachable(url, timeout=timeout)
            if not reachable:
                result["status"] = "skipped"
                result["skip_reason"] = f"unreachable: {reason}"
                skipped_count += 1
                print(f"  [{entry['num']}] SKIP: {source_name} — {reason}")
            else:
                # Reachable + previously fetched → run conformance stub
                warnings = _run_conformance_stub(entry, canonical_root)
                result["status"] = "checked"
                result["warnings"] = warnings
                checked_count += 1
                warning_count += len(warnings)
                print(f"  [{entry['num']}] CHECK: {source_name} — {len(warnings)} warning(s)")

        results.append(result)

    report: dict[str, Any] = {
        "skipped_count": skipped_count,
        "checked_count": checked_count,
        "warning_count": warning_count,
        "total_urls": len(entries),
        "results": results,
        "note": (
            f"VERIFY (advisory) is advisory only — never blocks the run. "
            f"{skipped_count} URL(s) skipped (pending fetch or unreachable). "
            f"Once external-sources.md URLs are fetched, conformance checks will activate."
        ),
    }

    if report_path is not None:
        rp = Path(report_path)
        rp.parent.mkdir(parents=True, exist_ok=True)
        rp.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        print(f"\nReport written to {report_path}")

    return report


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        prog="verify_advisory.py",
        description=(
            "VERIFY (advisory): advisory conformance layer. "
            "Non-blocking — always exits 0. "
            "Skips URLs marked as pending fetch; runs conformance stub for fetched URLs."
        ),
    )
    parser.add_argument("--canonical-root", required=True, metavar="PATH")
    parser.add_argument(
        "--report-path",
        metavar="PATH",
        default=".aid/work-002-canonical-generator/verify-advisory-report.json",
        help="Where to write the JSON report",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=5,
        metavar="SECONDS",
        help="HTTP request timeout in seconds (default: 5)",
    )
    parser.add_argument("--self-test", action="store_true", help="Run self-tests")
    args = parser.parse_args()

    if args.self_test:
        return _self_test(args.canonical_root)

    report = run_advisory(args.canonical_root, args.report_path, timeout=args.timeout)

    print(f"\nVERIFY (advisory): skipped={report['skipped_count']} checked={report['checked_count']} "
          f"warnings={report['warning_count']}")
    print("VERIFY (advisory): DONE (advisory layer — result is informational only)")
    return 0  # Always 0


def _self_test(canonical_root_arg: str) -> int:
    """
    Self-tests:
    1. With all 8 URLs pending fetch → skipped_count == 8, checked_count == 0.
    2. With a file:// URL that exists → checked_count == 1, conformance stub warns.
    """
    failures: list[str] = []

    # Test 1: all pending → all skipped (hermetic fixture, not the live external-sources.md)
    print("Self-test 1: all URLs pending -- skipped_count == 8...")
    import tempfile
    with tempfile.TemporaryDirectory() as _td:
        _src = Path(_td) / ".aid" / "knowledge"
        _src.mkdir(parents=True)
        _rows = "\n".join(
            f"| {i} | Source {i} | web | https://example.com/{i} | global | ⚠️ Pending fetch |"
            for i in range(1, 9)
        )
        (_src / "external-sources.md").write_text(
            "# External Sources\n\n"
            "| # | Source | Type | URL | Scope | Accessible |\n"
            "|---|---|---|---|---|---|\n"
            f"{_rows}\n",
            encoding="utf-8",
        )
        report = run_advisory(str(_td))
    if report["skipped_count"] != 8:
        failures.append(
            f"Test 1 FAIL: expected skipped_count=8, got {report['skipped_count']}"
        )
    if report["checked_count"] != 0:
        failures.append(
            f"Test 1 FAIL: expected checked_count=0, got {report['checked_count']}"
        )
    if report["skipped_count"] == 8 and report["checked_count"] == 0:
        print(f"  PASS: skipped_count={report['skipped_count']}, checked_count={report['checked_count']}")

    # Test 2: synthetic reachable URL (file://) → checked path runs
    print("Self-test 2: file:// URL -- conformance stub invoked...")
    import tempfile, os

    with tempfile.NamedTemporaryFile(mode="w", suffix=".html", delete=False) as f:
        f.write("<html><body>fixture</body></html>")
        fixture_path = f.name

    try:
        fixture_url = "file://" + fixture_path.replace("\\", "/")
        synthetic_entries = [
            {
                "num": "99",
                "source": "Test Fixture",
                "type": "web",
                "url": fixture_url,
                "scope": "test",
                "accessible": "accessible (fixture)",
            }
        ]

        # Directly invoke the check path
        results_for_test: list[dict[str, Any]] = []
        for entry in synthetic_entries:
            reachable, reason = _check_url_reachable(entry["url"])
            if reachable:
                warnings = _run_conformance_stub(entry, Path(canonical_root_arg))
                results_for_test.append({"status": "checked", "warnings": warnings})
            else:
                results_for_test.append({"status": "skipped", "reason": reason})

        checked = [r for r in results_for_test if r["status"] == "checked"]
        if not checked:
            failures.append("Test 2 FAIL: file:// URL not reached — reachability check failed")
        else:
            stub_warns = checked[0].get("warnings", [])
            if stub_warns:
                print(f"  PASS: conformance stub invoked, {len(stub_warns)} warning(s)")
            else:
                failures.append("Test 2 FAIL: conformance stub did not emit any warnings")
    finally:
        os.unlink(fixture_path)

    # Results
    if failures:
        print(f"\nSELF-TEST FAILED ({len(failures)} failure(s)):", file=sys.stderr)
        for f in failures:
            print(f"  - {f}", file=sys.stderr)
        return 1

    print("\nOK: all VERIFY (advisory) self-tests passed")
    return 0  # Advisory: always 0 even in self-test context


if __name__ == "__main__":
    sys.exit(main())
