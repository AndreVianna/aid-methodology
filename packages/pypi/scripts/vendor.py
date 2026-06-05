#!/usr/bin/env python3
# vendor.py - Copy the 6 aid-cli source files from the repo root into the PyPI package.
#
# Run automatically as a Hatchling build hook so `python -m build` and
# `pip wheel` always ship the current source.
#
# Also callable directly:
#   python packages/pypi/scripts/vendor.py
#
# Source of truth is the repo root (three levels above packages/pypi/scripts/).
# Destination is packages/pypi/aid_installer/_vendor/{bin,lib,VERSION}
# (gitignored; generated at build time).
#
# Files copied (mirrors release.sh Step-5 aid-cli bundle):
#   bin/aid              -> aid_installer/_vendor/bin/aid
#   bin/aid.ps1          -> aid_installer/_vendor/bin/aid.ps1
#   bin/aid.cmd          -> aid_installer/_vendor/bin/aid.cmd
#   lib/aid-install-core.sh  -> aid_installer/_vendor/lib/aid-install-core.sh
#   lib/AidInstallCore.psm1  -> aid_installer/_vendor/lib/AidInstallCore.psm1
#   VERSION              -> aid_installer/_vendor/VERSION

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
    ("bin/aid",                 "bin/aid"),
    ("bin/aid.ps1",             "bin/aid.ps1"),
    ("bin/aid.cmd",             "bin/aid.cmd"),
    ("lib/aid-install-core.sh", "lib/aid-install-core.sh"),
    ("lib/AidInstallCore.psm1", "lib/AidInstallCore.psm1"),
    ("VERSION",                 "VERSION"),
]


def vendor(repo_root: Path = _REPO_ROOT, vendor_dir: Path = _VENDOR_DIR) -> bool:
    """Copy the 6 aid-cli files into vendor_dir. Returns True on full success."""
    # Ensure destination directories exist.
    (vendor_dir / "bin").mkdir(parents=True, exist_ok=True)
    (vendor_dir / "lib").mkdir(parents=True, exist_ok=True)

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
        print("vendor: done. 6 files vendored into aid_installer/_vendor/.")
    return ok


# ---------------------------------------------------------------------------
# Hatchling build hook interface
# ---------------------------------------------------------------------------
try:
    from hatchling.builders.hooks.plugin.interface import BuildHookInterface  # type: ignore[import]

    class CustomBuildHook(BuildHookInterface):
        """Hatchling hook: vendor the 6 aid-cli files before the wheel is built."""

        def initialize(self, version: str, build_data: dict) -> None:  # type: ignore[override]
            """Called by hatchling before wheel assembly."""
            # Derive repo root from the hook's root (which is packages/pypi/).
            hook_root = Path(self.root)
            repo_root = hook_root.parent.parent
            vendor_dir = hook_root / "aid_installer" / "_vendor"
            if not vendor(repo_root=repo_root, vendor_dir=vendor_dir):
                raise RuntimeError("vendor.py: failed to vendor aid-cli files; aborting build.")

except ImportError:
    # hatchling not present (e.g. running the script standalone without build deps).
    pass


# ---------------------------------------------------------------------------
# Standalone entry point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    success = vendor()
    sys.exit(0 if success else 1)
