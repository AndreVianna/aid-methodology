# dashboard/reader/locator.py
# LC-1 Locator: resolve .aid/ root, enumerate .aid/works/* dirs, stat manifest/KB.
#
# Responsibility: filesystem listing + read-only git worktree enumeration.
# No parse (beyond worktree-list output), no write, no derivation.
# Read-only by construction: stat + iterdir + read-only git worktree list;
# the git subprocess is delegated to derivation.py (the one module permitted
# to call subprocess per the existing architecture contract; see FR35).
# This module does NOT use subprocess directly.
#
# Python 3.11+ stdlib only. Zero third-party deps.

from __future__ import annotations

import re
from pathlib import Path
from typing import NamedTuple, Optional


class LocatorResult(NamedTuple):
    """Output of locate_aid_root()."""
    aid_dir: Path          # resolved .aid/ path (always set; may not exist)
    aid_exists: bool       # whether .aid/ actually exists on disk
    manifest_path: Path    # .aid/.aid-manifest.json (may not exist)
    version_path: Path     # .aid/.aid-version (may not exist; fallback for ToolInfo)
    settings_path: Path    # .aid/settings.yml
    kb_dir: Path           # .aid/knowledge/ (may not exist)
    work_dirs: list[Path]  # .aid/works/* directories (sorted, dirs only)
    heartbeat_dir: Path    # .aid/.heartbeat/ (stat-only; may not exist)


def locate_aid_root(repo_root: str | Path) -> LocatorResult:
    """Resolve the .aid/ tree from repo_root and enumerate work folders.

    Works are the direct subfolders of the .aid/works/ container. The non-work
    siblings (.temp/, .heartbeat/, knowledge/, settings.yml, .aid-manifest.json,
    ...) live BESIDE works/ under .aid/, not inside it, so enumerating
    .aid/works/* excludes them structurally -- no name-based filtering needed.

    Never throws. aid_exists reflects .aid/ itself; if .aid/ (or .aid/works/)
    is absent, work_dirs=[].
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
    """Return the sorted list of work directories under the .aid/works/ container.

    The container .aid/works/ is the discovery selector: EVERY direct subfolder
    of it is a work. The folder name is no longer a visibility filter -- a work
    is any direct subdirectory of works/, numbered (work-NNN-*) or not.
    ^work-([0-9]+)- survives only as a best-effort ordering / short-id key
    (parsed in reader._number_from_work_id); it never includes or excludes here.

    The non-work siblings (.temp/, .heartbeat/, knowledge/, settings.yml,
    .aid-manifest.json, ...) live beside works/ under .aid/, not inside it, so a
    plain "all subfolders of .aid/works/" listing excludes them structurally.

    Returns only actual directories (files / broken symlinks are skipped).
    Never throws: a missing or unreadable .aid/works/ yields [].
    """
    works_dir = aid_dir / "works"
    try:
        candidates = list(works_dir.iterdir())
    except OSError:
        return []

    result = [p for p in candidates if p.is_dir()]
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


# ---------------------------------------------------------------------------
# SD-3: Worktree enumeration (work-004 Pillar 4)
#
# The git subprocess calls (worktree list, symbolic-ref) are delegated to
# derivation.py -- the one reader module permitted to use the subprocess module
# per the existing architecture contract (FR35, SEC-A1).  This module contains
# only the pure-Python parsing and filesystem-traversal logic; it never calls
# subprocess directly.
# ---------------------------------------------------------------------------

# Regex to detect "worktree <path>" lines in --porcelain output.
_RE_WORKTREE_LINE = re.compile(r"^worktree\s+(.+)$")
# Regex to detect "branch refs/heads/<name>" lines.
_RE_BRANCH_LINE = re.compile(r"^branch\s+refs/heads/(.+)$")
# Label used for detached-HEAD worktrees (no branch line in --porcelain output).
_DETACHED_LABEL = "(detached)"


def enumerate_worktree_roots(repo_root: str | Path) -> list[tuple[str, Path]]:
    """Enumerate all persistent git worktrees for repo_root and return per-worktree roots.

    Delegates the read-only `git -C <root> worktree list --porcelain` call to
    derivation.run_worktree_list() (the fixed-argv / no-shell pattern, twin of
    _run_git_log).  The verb is hard-coded in the argv list inside derivation.py;
    no shell and no user-supplied string is ever executed.

    For each worktree, locates its .aid/ directory (worktree_path/.aid/).  The main
    worktree (first record in --porcelain output) is ALWAYS included.

    Returns a list of (branch_label, aid_dir) pairs, one per worktree.  The main
    worktree is always the first element.

    Degradation (SD-3 DD-A2): git absent / non-git / timeout / parse failure ->
    returns [(main_branch_label, main_aid_dir)] (main-root-only fallback).
    Never throws.
    """
    # Lazy import to avoid circular imports (locator -> derivation; derivation
    # imports models but NOT locator, so this direction is safe).
    from .derivation import detect_main_branch_label, run_worktree_list  # noqa: PLC0415

    root = Path(repo_root).resolve()
    main_aid = root / ".aid"
    # Main-root-only fallback (returned on any failure mode)
    main_label = detect_main_branch_label(root)
    main_fallback: list[tuple[str, Path]] = [(main_label, main_aid)]

    porcelain = run_worktree_list(root)
    if porcelain is None:
        return main_fallback

    parsed = _parse_worktree_porcelain(porcelain)
    if not parsed:
        return main_fallback

    results: list[tuple[str, Path]] = []
    for wt_path, branch_label in parsed:
        wt_aid = wt_path / ".aid"
        results.append((branch_label, wt_aid))

    if not results:
        return main_fallback

    return results


def _parse_worktree_porcelain(output: str) -> list[tuple[Path, str]]:
    """Parse `git worktree list --porcelain` output into (worktree_path, branch_label) pairs.

    The --porcelain format groups records by blank lines:
        worktree /abs/path/to/worktree
        HEAD <sha>
        branch refs/heads/<branch>    # absent for detached HEADs

    Returns list of (Path, branch_label) pairs; detached HEADs get label "(detached)".
    Returns [] on any parse failure (caller degrades to main-root-only).
    Never throws.  No subprocess calls; no I/O.
    """
    try:
        records: list[tuple[Path, str]] = []
        current_path: Optional[Path] = None
        current_branch: Optional[str] = None

        for raw_line in output.splitlines():
            line = raw_line.rstrip()

            if not line:
                # Blank line: flush the current record (if any)
                if current_path is not None:
                    label = current_branch if current_branch is not None else _DETACHED_LABEL
                    records.append((current_path, label))
                current_path = None
                current_branch = None
                continue

            wt_m = _RE_WORKTREE_LINE.match(line)
            if wt_m:
                # If we have a pending record without a trailing blank, flush it.
                if current_path is not None:
                    label = current_branch if current_branch is not None else _DETACHED_LABEL
                    records.append((current_path, label))
                    current_branch = None
                current_path = Path(wt_m.group(1).strip())
                continue

            br_m = _RE_BRANCH_LINE.match(line)
            if br_m:
                current_branch = br_m.group(1).strip()

        # Flush any trailing record (output may not end with a blank line)
        if current_path is not None:
            label = current_branch if current_branch is not None else _DETACHED_LABEL
            records.append((current_path, label))

        return records
    except Exception:  # noqa: BLE001 -- never throws
        return []
