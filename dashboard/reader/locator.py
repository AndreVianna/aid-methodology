# dashboard/reader/locator.py
# LC-1 Locator: resolve .aid/ root, enumerate work-NNN-*/ dirs, stat manifest/KB.
#
# Responsibility: filesystem listing only. No parse, no write, no derivation.
# Read-only by construction: stat + iterdir only; no open(path, 'w') anywhere here.
#
# Python 3.11+ stdlib only. Zero third-party deps.

from __future__ import annotations

import re
from pathlib import Path
from typing import NamedTuple, Optional

# Work-folder glob pattern: exactly work-[0-9]*-* (FR12 / feature-002 LC-1)
# Matches work-NNN-{slug} directories only; excludes .temp/, .heartbeat/, etc.
_WORK_GLOB = "work-[0-9]*-*"

# Compiled pattern for the same rule (used to double-check against symlinks or files)
_WORK_RE = re.compile(r"^work-[0-9]+-")


class LocatorResult(NamedTuple):
    """Output of locate_aid_root()."""
    aid_dir: Path          # resolved .aid/ path (always set; may not exist)
    aid_exists: bool       # whether .aid/ actually exists on disk
    manifest_path: Path    # .aid/.aid-manifest.json (may not exist)
    version_path: Path     # .aid/.aid-version (may not exist; fallback for ToolInfo)
    settings_path: Path    # .aid/settings.yml
    kb_dir: Path           # .aid/knowledge/ (may not exist)
    work_dirs: list[Path]  # .aid/work-NNN-*/ directories (sorted, dirs only)
    heartbeat_dir: Path    # .aid/.heartbeat/ (stat-only; may not exist)


def locate_aid_root(repo_root: str | Path) -> LocatorResult:
    """Resolve the .aid/ tree from repo_root and enumerate work folders.

    Structurally excludes .aid/.temp/ and .aid/.heartbeat/ -- only work-NNN-*
    dirs are returned as works (the work-glob is the only filter needed; no
    special-casing of .temp or .heartbeat is required because they don't match
    the glob).

    Never throws. If .aid/ is absent, aid_exists=False and work_dirs=[].
    """
    root = Path(repo_root).resolve()
    aid_dir = root / ".aid"

    manifest_path = aid_dir / ".aid-manifest.json"
    version_path = aid_dir / ".aid-version"
    settings_path = aid_dir / "settings.yml"
    kb_dir = aid_dir / "knowledge"
    heartbeat_dir = aid_dir / ".heartbeat"

    aid_exists = aid_dir.is_dir()
    work_dirs: list[Path] = []

    if aid_exists:
        work_dirs = _enumerate_work_dirs(aid_dir)

    return LocatorResult(
        aid_dir=aid_dir,
        aid_exists=aid_exists,
        manifest_path=manifest_path,
        version_path=version_path,
        settings_path=settings_path,
        kb_dir=kb_dir,
        work_dirs=work_dirs,
        heartbeat_dir=heartbeat_dir,
    )


def _enumerate_work_dirs(aid_dir: Path) -> list[Path]:
    """Return sorted list of .aid/work-NNN-*/ directories.

    Uses the exact glob work-[0-9]*-* (FR12). Returns only entries that:
    - match the glob
    - are actual directories (not files, not symlinks to non-dirs)
    - match the _WORK_RE pattern (belt-and-suspenders: glob already filters,
      but explicit check guards against oddly-named dirs on case-insensitive FS)

    .aid/.temp/ and .aid/.heartbeat/ are structurally excluded by the glob --
    they do not start with "work-[0-9]" so they are never yielded.
    """
    try:
        candidates = list(aid_dir.glob(_WORK_GLOB))
    except OSError:
        return []

    result = []
    for p in candidates:
        if p.is_dir() and _WORK_RE.match(p.name):
            result.append(p)

    result.sort(key=lambda p: p.name)
    return result


def stat_path(path: Path) -> Optional[int]:
    """Return file size in bytes if path exists and is a regular file; else None."""
    try:
        st = path.stat()
        if path.is_file():
            return st.st_size
        return None
    except OSError:
        return None
