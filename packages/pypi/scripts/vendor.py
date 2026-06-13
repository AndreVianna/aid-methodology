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
# Dashboard server+reader unit (12 files, curated -- excludes tests/ __pycache__ *.pyc README):
#   dashboard/home.html             -> aid_installer/_vendor/dashboard/home.html
#   dashboard/index.html            -> aid_installer/_vendor/dashboard/index.html
#   dashboard/reader/__init__.py    -> aid_installer/_vendor/dashboard/reader/__init__.py
#   dashboard/reader/reader.py      -> aid_installer/_vendor/dashboard/reader/reader.py
#   dashboard/reader/models.py      -> aid_installer/_vendor/dashboard/reader/models.py
#   dashboard/reader/parsers.py     -> aid_installer/_vendor/dashboard/reader/parsers.py
#   dashboard/reader/derivation.py  -> aid_installer/_vendor/dashboard/reader/derivation.py
#   dashboard/reader/locator.py     -> aid_installer/_vendor/dashboard/reader/locator.py
#   dashboard/server/server.py      -> aid_installer/_vendor/dashboard/server/server.py
#   dashboard/server/server.mjs     -> aid_installer/_vendor/dashboard/server/server.mjs
#   dashboard/server/reader.mjs     -> aid_installer/_vendor/dashboard/server/reader.mjs
#   dashboard/server/__init__.py    -> aid_installer/_vendor/dashboard/server/__init__.py

from __future__ import annotations

import shutil
import sys
from pathlib import Path


# Determine repo root: packages/pypi/scripts/vendor.py is three levels below.
_SELF_DIR = Path(__file__).parent
_PKG_ROOT = _SELF_DIR.parent          # packages/pypi/
_REPO_ROOT = _PKG_ROOT.parent.parent  # repo root

_VENDOR_DIR = _PKG_ROOT / "aid_installer" / "_vendor"

COPIES: list[tuple[str, str]] = [
    ("bin/aid",                          "bin/aid"),
    ("bin/aid.ps1",                      "bin/aid.ps1"),
    ("bin/aid.cmd",                      "bin/aid.cmd"),
    ("lib/aid-install-core.sh",          "lib/aid-install-core.sh"),
    ("lib/AidInstallCore.psm1",          "lib/AidInstallCore.psm1"),
    ("VERSION",                          "VERSION"),
    # Dashboard server+reader unit (12 files, curated).
    ("dashboard/home.html",              "dashboard/home.html"),
    ("dashboard/index.html",             "dashboard/index.html"),
    ("dashboard/reader/__init__.py",     "dashboard/reader/__init__.py"),
    ("dashboard/reader/reader.py",       "dashboard/reader/reader.py"),
    ("dashboard/reader/models.py",       "dashboard/reader/models.py"),
    ("dashboard/reader/parsers.py",      "dashboard/reader/parsers.py"),
    ("dashboard/reader/derivation.py",   "dashboard/reader/derivation.py"),
    ("dashboard/reader/locator.py",      "dashboard/reader/locator.py"),
    ("dashboard/server/server.py",       "dashboard/server/server.py"),
    ("dashboard/server/server.mjs",      "dashboard/server/server.mjs"),
    ("dashboard/server/reader.mjs",      "dashboard/server/reader.mjs"),
    ("dashboard/server/__init__.py",     "dashboard/server/__init__.py"),
]


def vendor(repo_root: Path = _REPO_ROOT, vendor_dir: Path = _VENDOR_DIR) -> bool:
    """Copy the aid-cli files into vendor_dir. Returns True on full success."""
    # Clean slate: remove any prior payload so stray runtime artifacts (e.g. the
    # CLI's .update-check cache, or files from an older version) never ship in the wheel.
    shutil.rmtree(str(vendor_dir), ignore_errors=True)
    (vendor_dir / "bin").mkdir(parents=True, exist_ok=True)
    (vendor_dir / "lib").mkdir(parents=True, exist_ok=True)
    (vendor_dir / "dashboard" / "reader").mkdir(parents=True, exist_ok=True)
    (vendor_dir / "dashboard" / "server").mkdir(parents=True, exist_ok=True)

    ok = True
    for src_rel, dst_rel in COPIES:
        src = repo_root / src_rel
        dst = vendor_dir / dst_rel
        try:
            shutil.copy2(str(src), str(dst))
            print(f"vendor: copied {src_rel} -> aid_installer/_vendor/{dst_rel}")
        except OSError as exc:
            print(f"vendor: ERROR copying {src}: {exc}", file=sys.stderr)
            ok = False

    if ok:
        print("vendor: done. 18 files vendored into aid_installer/_vendor/.")
    return ok


# ---------------------------------------------------------------------------
# Hatchling build hook interface
# ---------------------------------------------------------------------------
try:
    from hatchling.builders.hooks.plugin.interface import BuildHookInterface  # type: ignore[import]

    class CustomBuildHook(BuildHookInterface):
        """Hatchling hook: vendor the 6 aid-cli files before the wheel is built."""

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
            # If the repo root is available the full COPIES list will be vendored.
            sources_present = (repo_root / "bin" / "aid").exists() and \
                              (repo_root / "dashboard" / "index.html").exists()
            if sources_present:
                if not vendor(repo_root=repo_root, vendor_dir=vendor_dir):
                    raise RuntimeError("vendor.py: failed to vendor aid-cli files; aborting build.")
            else:
                # Building from an sdist: the payload must already be bundled.
                missing = [dst for _, dst in COPIES if not (vendor_dir / dst).exists()]
                if missing:
                    raise RuntimeError(
                        "vendor.py: aid-cli sources not found and the bundled _vendor payload is "
                        "incomplete (missing: %s). The sdist must include aid_installer/_vendor/."
                        % ", ".join(missing)
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
