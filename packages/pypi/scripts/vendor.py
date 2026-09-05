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

# The static aid-cli files. The dashboard server+reader unit and the agent chat node are
# each derived from their own single-source manifest -- see _dashboard_copies() and
# _chat_node_copies().
_BASE_COPIES: list[tuple[str, str]] = [
    ("bin/aid",                          "bin/aid"),
    ("bin/aid.ps1",                      "bin/aid.ps1"),
    ("bin/aid.cmd",                      "bin/aid.cmd"),
    ("lib/aid-install-core.sh",          "lib/aid-install-core.sh"),
    ("lib/AidInstallCore.psm1",          "lib/AidInstallCore.psm1"),
    ("VERSION",                          "VERSION"),
]

_DASHBOARD_MANIFEST_REL = "dashboard/MANIFEST"
_CHAT_NODE_MANIFEST_REL = "chat-node/MANIFEST"


def _read_component_manifest(manifest_path: Path) -> list[str]:
    """Parse a component MANIFEST -> component-relative paths (strip #-comments + blanks).

    Shared by the dashboard and the chat node: both follow the same single-source rule, and
    a second copy of this parser is the drift the manifests exist to prevent.
    """
    files: list[str] = []
    for line in manifest_path.read_text(encoding="utf-8").splitlines():
        line = line.split("#", 1)[0].strip()
        if line:
            files.append(line)
    return files


def _component_copies(root: Path, component: str, manifest_rel: str) -> list[tuple[str, str]]:
    """One component's curated unit, derived from ``root``/``component``/MANIFEST. MANIFEST
    itself is included first so the vendored payload is self-describing (the build-from-
    sdist completeness check re-reads it from the payload)."""
    entries: list[tuple[str, str]] = [(manifest_rel, manifest_rel)]
    for rel in _read_component_manifest(root / component / "MANIFEST"):
        entries.append((f"{component}/{rel}", f"{component}/{rel}"))
    return entries


def _dashboard_copies(root: Path) -> list[tuple[str, str]]:
    """Dashboard server+reader unit."""
    return _component_copies(root, "dashboard", _DASHBOARD_MANIFEST_REL)


def _chat_node_copies(root: Path) -> list[tuple[str, str]]:
    """Agent chat node. Carries no third-party dependency, so vendoring it leaves this
    package's dependency list empty, which is a requirement rather than a coincidence."""
    return _component_copies(root, "chat-node", _CHAT_NODE_MANIFEST_REL)


def vendor(repo_root: Path = _REPO_ROOT, vendor_dir: Path = _VENDOR_DIR) -> bool:
    """Copy the aid-cli files into vendor_dir. Returns True on full success."""
    # Clean slate: remove any prior payload so stray runtime artifacts (e.g. the
    # CLI's .update-check cache, or files from an older version) never ship in the wheel.
    shutil.rmtree(str(vendor_dir), ignore_errors=True)

    copies = _BASE_COPIES + _dashboard_copies(repo_root) + _chat_node_copies(repo_root)
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
                              (repo_root / "dashboard" / "index.html").exists() and \
                              (repo_root / "chat-node" / "MANIFEST").exists()
            if sources_present:
                if not vendor(repo_root=repo_root, vendor_dir=vendor_dir):
                    raise RuntimeError("vendor.py: failed to vendor aid-cli files; aborting build.")
            else:
                # Building from an sdist: the payload must already be bundled. Re-derive the
                # expected file set from the vendored MANIFEST (self-describing payload) so
                # the completeness check stays in lockstep with the single source.
                dash_manifest = vendor_dir / "dashboard" / "MANIFEST"
                node_manifest = vendor_dir / "chat-node" / "MANIFEST"
                expected = [dst for _, dst in _BASE_COPIES]
                expected.append(_DASHBOARD_MANIFEST_REL)
                expected.append(_CHAT_NODE_MANIFEST_REL)
                if dash_manifest.exists():
                    for rel in _read_component_manifest(dash_manifest):
                        expected.append(f"dashboard/{rel}")
                if node_manifest.exists():
                    for rel in _read_component_manifest(node_manifest):
                        expected.append(f"chat-node/{rel}")
                absent_manifests = [
                    rel for rel, pth in (
                        (_DASHBOARD_MANIFEST_REL, dash_manifest),
                        (_CHAT_NODE_MANIFEST_REL, node_manifest),
                    ) if not pth.exists()
                ]
                missing = [dst for dst in expected if not (vendor_dir / dst).exists()]
                if missing or absent_manifests:
                    raise RuntimeError(
                        "vendor.py: aid-cli sources not found and the bundled _vendor payload is "
                        "incomplete (missing: %s). The sdist must include aid_installer/_vendor/ "
                        "with both dashboard/MANIFEST and chat-node/MANIFEST."
                        % ", ".join(missing or absent_manifests)
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
