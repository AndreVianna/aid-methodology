#!/usr/bin/env python3
# vendor.py - Copy the aid-cli source files from the repo root into the PyPI package.
#
# Run automatically as a Hatchling build hook so `python -m build` and
# `pip wheel` always ship the current source.
#
# Also callable directly:
#   python packages/pypi/scripts/vendor.py
#
# Source of truth is the repo root (three levels above packages/pypi/scripts/).
# Destination is packages/pypi/aid_installer/_vendor/{bin,lib,dashboard/,VERSION}
# (gitignored; generated at build time).
#
# Files copied (mirrors release.sh Step-5 aid-cli bundle):
#   bin/aid              -> aid_installer/_vendor/bin/aid
#   bin/aid.ps1          -> aid_installer/_vendor/bin/aid.ps1
#   bin/aid.cmd          -> aid_installer/_vendor/bin/aid.cmd
#   lib/aid-install-core.sh  -> aid_installer/_vendor/lib/aid-install-core.sh
#   lib/AidInstallCore.psm1  -> aid_installer/_vendor/lib/AidInstallCore.psm1
#   VERSION              -> aid_installer/_vendor/VERSION
#
# Dashboard server+reader unit: the curated file set is NOT listed here -- it is read
# from the single-source manifest dashboard/MANIFEST (shared with install.sh, install.ps1,
# packages/npm/scripts/vendor.js and release.sh; guarded by
# tests/canonical/test-dashboard-manifest.sh). MANIFEST is itself vendored, so the sdist
# carries a self-describing payload the build-from-sdist completeness check re-reads.
# This prevents a new dashboard source file from being silently omitted from the PyPI
# channel (the H1 lockstep failure mode).

from __future__ import annotations

import shutil
import sys
from pathlib import Path


# Determine repo root: packages/pypi/scripts/vendor.py is three levels below.
_SELF_DIR = Path(__file__).parent
_PKG_ROOT = _SELF_DIR.parent          # packages/pypi/
_REPO_ROOT = _PKG_ROOT.parent.parent  # repo root

_VENDOR_DIR = _PKG_ROOT / "aid_installer" / "_vendor"

# The non-dashboard aid-cli files (static). The dashboard server+reader unit is derived
# from the single-source manifest dashboard/MANIFEST -- see _dashboard_copies().
_BASE_COPIES: list[tuple[str, str]] = [
    ("bin/aid",                          "bin/aid"),
    ("bin/aid.ps1",                      "bin/aid.ps1"),
    ("bin/aid.cmd",                      "bin/aid.cmd"),
    ("lib/aid-install-core.sh",          "lib/aid-install-core.sh"),
    ("lib/AidInstallCore.psm1",          "lib/AidInstallCore.psm1"),
    ("VERSION",                          "VERSION"),
]

_DASHBOARD_MANIFEST_REL = "dashboard/MANIFEST"


def _read_dashboard_manifest(manifest_path: Path) -> list[str]:
    """Parse dashboard/MANIFEST -> dashboard-relative paths (strip #-comments + blanks)."""
    files: list[str] = []
    for line in manifest_path.read_text(encoding="utf-8").splitlines():
        line = line.split("#", 1)[0].strip()
        if line:
            files.append(line)
    return files


def _dashboard_copies(root: Path) -> list[tuple[str, str]]:
    """Dashboard server+reader unit, derived from ``root``/dashboard/MANIFEST. MANIFEST
    itself is included first so the vendored payload is self-describing (the build-from-
    sdist completeness check re-reads it from the payload)."""
    entries: list[tuple[str, str]] = [(_DASHBOARD_MANIFEST_REL, _DASHBOARD_MANIFEST_REL)]
    for rel in _read_dashboard_manifest(root / "dashboard" / "MANIFEST"):
        entries.append((f"dashboard/{rel}", f"dashboard/{rel}"))
    return entries


def vendor(repo_root: Path = _REPO_ROOT, vendor_dir: Path = _VENDOR_DIR) -> bool:
    """Copy the aid-cli files into vendor_dir. Returns True on full success."""
    # Clean slate: remove any prior payload so stray runtime artifacts (e.g. the
    # CLI's .update-check cache, or files from an older version) never ship in the wheel.
    shutil.rmtree(str(vendor_dir), ignore_errors=True)

    copies = _BASE_COPIES + _dashboard_copies(repo_root)
    ok = True
    for src_rel, dst_rel in copies:
        src = repo_root / src_rel
        dst = vendor_dir / dst_rel
        try:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(str(src), str(dst))
            print(f"vendor: copied {src_rel} -> aid_installer/_vendor/{dst_rel}")
        except OSError as exc:
            print(f"vendor: ERROR copying {src}: {exc}", file=sys.stderr)
            ok = False

    if ok:
        print(f"vendor: done. {len(copies)} files vendored into aid_installer/_vendor/.")
    return ok


# ---------------------------------------------------------------------------
# Hatchling build hook interface
# ---------------------------------------------------------------------------
try:
    from hatchling.builders.hooks.plugin.interface import BuildHookInterface  # type: ignore[import]

    class CustomBuildHook(BuildHookInterface):
        """Hatchling hook: vendor the aid-cli files before the wheel is built."""

        def initialize(self, version: str, build_data: dict) -> None:  # type: ignore[override]
            """Called by hatchling before sdist/wheel assembly.

            In the worktree (repo-root sources present) we (re)vendor from the repo root.
            When building the wheel FROM an sdist (isolated temp dir, no repo-root sources)
            we fall back to the _vendor payload bundled inside the sdist.
            """
            hook_root = Path(self.root)
            repo_root = hook_root.parent.parent
            vendor_dir = hook_root / "aid_installer" / "_vendor"
            # sources_present: check a representative subset (bin/aid + one dashboard file).
            # If the repo root is available the full file set will be vendored.
            sources_present = (repo_root / "bin" / "aid").exists() and \
                              (repo_root / "dashboard" / "index.html").exists()
            if sources_present:
                if not vendor(repo_root=repo_root, vendor_dir=vendor_dir):
                    raise RuntimeError("vendor.py: failed to vendor aid-cli files; aborting build.")
            else:
                # Building from an sdist: the payload must already be bundled. Re-derive the
                # expected file set from the vendored MANIFEST (self-describing payload) so
                # the completeness check stays in lockstep with the single source.
                payload_manifest = vendor_dir / "dashboard" / "MANIFEST"
                expected = [dst for _, dst in _BASE_COPIES]
                expected.append(_DASHBOARD_MANIFEST_REL)
                if payload_manifest.exists():
                    for rel in _read_dashboard_manifest(payload_manifest):
                        expected.append(f"dashboard/{rel}")
                missing = [dst for dst in expected if not (vendor_dir / dst).exists()]
                if missing or not payload_manifest.exists():
                    raise RuntimeError(
                        "vendor.py: aid-cli sources not found and the bundled _vendor payload is "
                        "incomplete (missing: %s). The sdist must include aid_installer/_vendor/ "
                        "with dashboard/MANIFEST." % ", ".join(missing or ["dashboard/MANIFEST"])
                    )
                # Payload already present (came in via the sdist); nothing to do.

except ImportError:
    # hatchling not present (e.g. running the script standalone without build deps).
    pass


# ---------------------------------------------------------------------------
# Standalone entry point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    success = vendor()
    sys.exit(0 if success else 1)
