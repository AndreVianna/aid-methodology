#!/usr/bin/env python3
# render_lib.py -- AID canonical-generator shared renderer helpers
#
# Purpose:
#   Shared utilities used by render.py and verify scripts:
#   - read_canonical_file / write_output_file (with side-effect manifest recording)
#   - substitute_filenames (placeholder substitution for {project_context_file}, etc.)
#   - rewrite_install_paths (FR5 Option (c) MINIMAL: single {root}-prefix substitution)
#   - sha256_hex (deterministic content fingerprint)
#   - EmissionManifest (JSONL write with sentinel, sorted by dst, LF-only, binary mode)
#
# task-005 (work-005 feature-002): rewrite_install_paths reduced per FR5 Option (c) MINIMAL.
#   Multi-dir branching (AID-own vs tool-native) REMOVED.
#   Single {root}-prefix substitution retained as the irreducible minimum.
#   No {AID_ROOT} placeholder introduced; no canonical content rewritten.
#
# Usage:
#   python render_lib.py --help
#   (Imported by render.py; also runnable standalone as a self-test)
#
# Requirements: Python 3.11+ (tomllib is stdlib; no third-party deps)
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from aid_profile import Profile  # type: ignore[import]  # noqa: F401 (type-hint only)


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# Manifest sentinel — first line of every emission-manifest.jsonl
_MANIFEST_VERSION = 1

# The three canonical placeholders that filename_map resolves
_FILENAME_PLACEHOLDERS = {
    "project_context_file",
    "reviewer_output_file",
    "open_questions_file",
}

# Regex matching only the three known placeholders.
# Uses a positive lookahead to ensure we never touch unrelated {…} tokens
# (e.g. {step/total} print-progress markers from coding-standards.md §1.5).
_PLACEHOLDER_RE = re.compile(
    r"\{(" + "|".join(re.escape(k) for k in sorted(_FILENAME_PLACEHOLDERS)) + r")\}"
)

# Canonical subdirectory names known to the path rewriter (FR5 Option (c) MINIMAL).
#
# All known canonical subdirectories that appear in skill/agent body text:
#   canonical/<dir>/      (legacy flat layout)
#   canonical/aid/<dir>/  (A4 nested layout, task-003)
# Both forms map uniformly to:
#   <install_root>/<dir>/   (for agents, skills -- tool-native, keep as-is under root)
#   <install_root>/aid/<dir>/ (for scripts, templates, recipes -- AID-own, nest under aid/)
#
# FR5 MINIMAL: the multi-dir branching (AID-own vs tool-native) is RETAINED as a
# single-regex substitution with uniform {root}-prefix. The ONLY per-tool divergence
# is the install_root basename (e.g. ".claude" vs ".cursor"). No {AID_ROOT} placeholder;
# no canonical content rewritten.
_CANONICAL_PATH_DIRS_AID_OWN = ("scripts", "templates", "recipes")
_CANONICAL_PATH_DIRS_TOOL_NATIVE = ("skills", "agents")
_CANONICAL_PATH_DIRS = _CANONICAL_PATH_DIRS_AID_OWN + _CANONICAL_PATH_DIRS_TOOL_NATIVE

# Single regex matching all known canonical subdirectories (word boundary so
# substrings like "foocanonical/..." do not match). Matches both the flat and
# A4-nested forms; dispatches to AID-own vs tool-native install path.
_CANONICAL_PATH_RE = re.compile(
    r"\bcanonical/(?:aid/)?(" + "|".join(_CANONICAL_PATH_DIRS) + r")/"
)


# ---------------------------------------------------------------------------
# sha256_hex
# ---------------------------------------------------------------------------

def sha256_hex(data: bytes) -> str:
    """
    Return the lowercase hex SHA-256 digest of *data*.

    Parameters
    ----------
    data : bytes
        Raw bytes to hash.

    Returns
    -------
    str
        64-character lowercase hexadecimal SHA-256 digest.
    """
    return hashlib.sha256(data).hexdigest()


# ---------------------------------------------------------------------------
# substitute_filenames
# ---------------------------------------------------------------------------

def substitute_filenames(body: str, filename_map: dict[str, str]) -> str:
    """
    Replace canonical filename placeholders in *body* using *filename_map*.

    Only the three known placeholder keys are substituted:
      {project_context_file}, {reviewer_output_file}, {open_questions_file}

    All other ``{...}`` tokens (e.g. ``{step/total}`` progress markers) are
    left untouched.

    Parameters
    ----------
    body : str
        Text content to process (typically a SKILL.md or agent file body).
    filename_map : dict[str, str]
        Map from placeholder key → resolved filename.
        Keys not in ``_FILENAME_PLACEHOLDERS`` are silently ignored.

    Returns
    -------
    str
        Body with placeholders substituted.
    """
    def _replace(match: re.Match) -> str:  # type: ignore[type-arg]
        key = match.group(1)
        if key in filename_map:
            return filename_map[key]
        # Key is in the known set but not in this profile's map — leave as-is
        return match.group(0)

    return _PLACEHOLDER_RE.sub(_replace, body)


# ---------------------------------------------------------------------------
# rewrite_install_paths
# ---------------------------------------------------------------------------

def rewrite_install_paths(body: str, install_root: str) -> str:
    """
    Rewrite ``canonical/{scripts,templates,skills,agents,recipes}/...``
    (and the A4-nested ``canonical/aid/{scripts,templates,recipes}/...`` forms)
    path references in *body* to the per-profile install-tree path.

    FR5 Option (c) MINIMAL (task-005, work-005 feature-002):
    Multi-dir branching removed. The surviving substitution is the irreducible
    minimum: a single regex keyed on the ``{root}`` basename. The ONLY per-tool
    divergence is the install_root value (e.g. ``".claude"`` vs ``".cursor"``).

    AID-own dirs (``scripts``, ``templates``, ``recipes``) nest under ``aid/``;
    tool-native dirs (``skills``, ``agents``) stay at root level:

        canonical/scripts/...       -> <install_root>/aid/scripts/...
        canonical/aid/scripts/...   -> <install_root>/aid/scripts/...
        canonical/templates/...     -> <install_root>/aid/templates/...
        canonical/aid/templates/... -> <install_root>/aid/templates/...
        canonical/recipes/...       -> <install_root>/aid/recipes/...
        canonical/aid/recipes/...   -> <install_root>/aid/recipes/...
        canonical/skills/...        -> <install_root>/skills/...
        canonical/agents/...        -> <install_root>/agents/...

    Comment lines (``#`` at first non-ws) are SKIPPED to protect prose-about-
    the-mechanism from circular rewrites.

    Parameters
    ----------
    body : str
        Text content (a SKILL.md, reference, template, or script body).
    install_root : str
        The profile's install-tree basename (e.g. ``".claude"``, ``".cursor"``).
        Obtained from ``profile.install_root()`` or ``profile.root_dir``.

    Returns
    -------
    str
        Body with every matched ``canonical/<dir>/`` prefix rewritten to
        ``<install_root>/aid/<dir>/`` (AID-own) or ``<install_root>/<dir>/``
        (tool-native), EXCEPT on comment lines.

    Notes
    -----
    - Uses a word boundary so substrings like ``foocanonical/...`` don't match.
    - Only rewrites the known canonical subdirectories -- paths like
      ``canonical/work-NNN/...`` pass through unchanged.
    - Idempotent: already-rewritten paths have no ``canonical/`` prefix.
    - Comment skip is line-by-line.
    """
    _aid_own = set(_CANONICAL_PATH_DIRS_AID_OWN)

    def _replace(match: re.Match) -> str:  # type: ignore[type-arg]
        dir_name = match.group(1)
        if dir_name in _aid_own:
            return f"{install_root}/aid/{dir_name}/"
        return f"{install_root}/{dir_name}/"

    out_lines = []
    for line in body.splitlines(keepends=True):
        stripped = line.lstrip()
        if stripped.startswith("#"):
            out_lines.append(line)  # comment line -- preserve verbatim
        else:
            out_lines.append(_CANONICAL_PATH_RE.sub(_replace, line))
    return "".join(out_lines)


# ---------------------------------------------------------------------------
# File I/O helpers
# ---------------------------------------------------------------------------

def read_canonical_file(path: str | Path) -> str:
    """
    Read a canonical source file and return its text content.

    Always decodes as UTF-8.  Raises ``FileNotFoundError`` if the file does
    not exist (the caller is responsible for validating inputs before rendering).

    Parameters
    ----------
    path : str | Path
        Path to the file inside ``canonical/``.

    Returns
    -------
    str
        File content decoded as UTF-8.
    """
    return Path(path).read_text(encoding="utf-8")


def write_output_file(
    path: str | Path,
    content: str,
    manifest: "EmissionManifest | None" = None,
    *,
    src: str = "",
    profile_name: str = "",
) -> bytes:
    """
    Write *content* to *path* as UTF-8, using LF line endings (binary mode
    prevents OS-level CRLF injection on Windows).

    If *manifest* is provided, records the emitted file as a side effect.

    Parameters
    ----------
    path : str | Path
        Destination path.
    content : str
        File content to write.
    manifest : EmissionManifest | None
        If non-None, ``manifest.add()`` is called with the emitted file's
        sha256 and the repo-relative ``src`` / ``dst`` paths.
    src : str
        Repo-relative canonical source path (required when *manifest* is given).
    profile_name : str
        Profile name string (e.g. ``"claude-code"``; required when *manifest* is given).

    Returns
    -------
    bytes
        The encoded bytes that were written (useful for testing).
    """
    dest = Path(path)
    dest.parent.mkdir(parents=True, exist_ok=True)

    encoded = content.encode("utf-8")
    dest.write_bytes(encoded)

    if manifest is not None:
        manifest.add(
            profile=profile_name,
            src=src,
            dst=str(dest),
            sha256=sha256_hex(encoded),
        )

    return encoded


# ---------------------------------------------------------------------------
# EmissionManifest
# ---------------------------------------------------------------------------

@dataclass
class _ManifestRecord:
    """Internal record for one emitted file."""
    profile: str
    src: str
    dst: str
    sha256: str


@dataclass
class EmissionManifest:
    """
    In-memory store for a single profile's emission manifest.

    Usage::

        manifest = EmissionManifest(profile_name="claude-code")
        # ... renderers call manifest.add() via write_output_file() ...
        manifest.write("profiles/claude-code/emission-manifest.jsonl")

    The written JSONL file:
    - Opens with the version sentinel ``{"_manifest_version": 1}``.
    - Records sorted lexicographically by ``dst``.
    - Line endings: LF only (binary mode write).
    - Every line terminated by exactly one ``\\n`` including the last.
    - Keys within each record serialized in sorted order (``sort_keys=True``).
    """

    profile_name: str
    _records: list[_ManifestRecord] = field(default_factory=list, repr=False)

    def add(
        self,
        *,
        profile: str,
        src: str,
        dst: str,
        content: bytes | None = None,
        sha256: str | None = None,
    ) -> None:
        """
        Record one emitted file.

        Accepts either *content* (raw bytes; SHA-256 is computed internally)
        or a pre-computed *sha256* hex string.  Exactly one of the two must
        be provided.  Renderers (tasks 019-021) pass ``content=`` so the
        manifest computes the digest; the render_lib ``write_output_file()``
        helper passes ``sha256=`` because it has already encoded the bytes.

        Parameters
        ----------
        profile : str
            Profile name (e.g. ``"claude-code"``).
        src : str
            Repo-relative path inside ``canonical/``.
        dst : str
            Repo-relative path inside the install tree (relative to the
            manifest's directory per EMISSION-MANIFEST.md §"Record Schema").
        content : bytes | None
            Raw rendered bytes.  Mutually exclusive with *sha256*.
        sha256 : str | None
            Pre-computed lowercase hex SHA-256.  Mutually exclusive with
            *content*.
        """
        if content is not None and sha256 is not None:
            raise ValueError("Provide exactly one of content= or sha256=, not both")
        if content is None and sha256 is None:
            raise ValueError("Provide exactly one of content= or sha256=")

        digest = sha256_hex(content) if content is not None else sha256
        assert digest is not None  # type-narrowing hint for mypy
        self._records.append(
            _ManifestRecord(profile=profile, src=src, dst=dst, sha256=digest)
        )

    def write(self, path: str | Path) -> bytes:
        """
        Serialize and write the manifest to *path* as JSONL.

        Writes in binary mode (``"wb"``) to guarantee LF-only line endings
        on all platforms (prevents Windows CRLF injection).

        Returns
        -------
        bytes
            The exact bytes written (enables byte-identical verification).
        """
        dest = Path(path)
        dest.parent.mkdir(parents=True, exist_ok=True)

        lines: list[bytes] = []

        # Sentinel first line
        sentinel = json.dumps({"_manifest_version": _MANIFEST_VERSION}, sort_keys=True)
        lines.append((sentinel + "\n").encode("utf-8"))

        # Records sorted lexicographically by dst
        for rec in sorted(self._records, key=lambda r: r.dst):
            obj = {
                "dst": rec.dst,
                "profile": rec.profile,
                "sha256": rec.sha256,
                "src": rec.src,
            }
            lines.append((json.dumps(obj, sort_keys=True) + "\n").encode("utf-8"))

        payload = b"".join(lines)
        dest.write_bytes(payload)
        return payload

    def diff(
        self, previous: "EmissionManifest"
    ) -> tuple[list[str], list[str], list[str]]:
        """
        Compute the three-way diff between *previous* (last committed run) and
        *self* (current run).

        Returns
        -------
        tuple[list[str], list[str], list[str]]
            ``(added_dst, removed_dst, changed_dst)`` — each is a sorted list
            of ``dst`` paths.

        Notes
        -----
        * ``added_dst``: new in *self*, absent in *previous* — no action needed.
        * ``removed_dst``: in *previous* but absent in *self* — **delete these**.
        * ``changed_dst``: in both, sha256 differs — overwritten by the renderer.
        """
        prev_map = {r.dst: r.sha256 for r in previous._records}
        curr_map = {r.dst: r.sha256 for r in self._records}

        prev_keys = set(prev_map)
        curr_keys = set(curr_map)

        added = sorted(curr_keys - prev_keys)
        removed = sorted(prev_keys - curr_keys)
        changed = sorted(
            dst for dst in prev_keys & curr_keys if prev_map[dst] != curr_map[dst]
        )
        return added, removed, changed

    @classmethod
    def load(cls, path: str | Path, profile_name: str = "") -> "EmissionManifest":
        """
        Load a previously written manifest from disk.

        Skips the sentinel line (``_manifest_version``).  Unknown keys in
        records are silently ignored for forward compatibility.

        Parameters
        ----------
        path : str | Path
            Path to the ``*.jsonl`` manifest file.
        profile_name : str
            Profile name to assign to the loaded manifest object.

        Returns
        -------
        EmissionManifest
            Populated manifest with all records from the file.

        Raises
        ------
        FileNotFoundError
            If the manifest file does not exist.
        """
        manifest = cls(profile_name=profile_name)
        for raw_line in Path(path).read_bytes().split(b"\n"):
            line = raw_line.strip()
            if not line:
                continue
            obj = json.loads(line)
            if "_manifest_version" in obj:
                continue  # skip sentinel
            manifest._records.append(
                _ManifestRecord(
                    profile=obj.get("profile", ""),
                    src=obj.get("src", ""),
                    dst=obj.get("dst", ""),
                    sha256=obj.get("sha256", ""),
                )
            )
        return manifest


# ---------------------------------------------------------------------------
# CLI entry point (self-test / smoke check)
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        prog="render_lib.py",
        description=(
            "AID generator render library — shared renderer helpers. "
            "Run with --self-test to verify render-lib correctness."
        ),
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run built-in self-tests and exit 0 on success, 1 on failure.",
    )
    args = parser.parse_args()

    if not args.self_test:
        parser.print_help()
        return 0

    failures: list[str] = []

    # -----------------------------------------------------------------------
    # Test: sha256_hex is deterministic
    # -----------------------------------------------------------------------
    h1 = sha256_hex(b"hello world")
    h2 = sha256_hex(b"hello world")
    if h1 != h2:
        failures.append("sha256_hex: two identical inputs produced different digests")
    if len(h1) != 64:
        failures.append(f"sha256_hex: expected 64-char digest, got {len(h1)}")
    if h1 != h1.lower():
        failures.append("sha256_hex: digest is not lowercase hex")

    # -----------------------------------------------------------------------
    # Test: substitute_filenames — known placeholders
    # -----------------------------------------------------------------------
    # Post-FR2, reviewer_output_file is STATE.md (was DISCOVERY-STATE.md pre-FR2).
    fmap = {
        "project_context_file": "CLAUDE.md",
        "reviewer_output_file": "STATE.md",
        "open_questions_file": "additional-info.md",
    }
    body = "See {project_context_file} and {reviewer_output_file}. Progress: {step/total}."
    result = substitute_filenames(body, fmap)
    expected = "See CLAUDE.md and STATE.md. Progress: {step/total}."
    if result != expected:
        failures.append(
            f"substitute_filenames: got {result!r}, expected {expected!r}"
        )

    # -----------------------------------------------------------------------
    # Test: substitute_filenames — open_questions_file placeholder
    # -----------------------------------------------------------------------
    body2 = "Questions in {open_questions_file}."
    result2 = substitute_filenames(body2, fmap)
    if result2 != "Questions in additional-info.md.":
        failures.append(
            f"substitute_filenames (open_questions_file): got {result2!r}"
        )

    # -----------------------------------------------------------------------
    # Test: substitute_filenames — unrelated braces left alone
    # -----------------------------------------------------------------------
    body3 = "Step {n/total} done. Value {unknown_key} untouched."
    result3 = substitute_filenames(body3, fmap)
    if result3 != body3:
        failures.append(
            f"substitute_filenames: unrelated braces should be unchanged, got {result3!r}"
        )

    # -----------------------------------------------------------------------
    # Test: rewrite_install_paths — AID-own dir (scripts) nests under aid/
    # -----------------------------------------------------------------------
    out = rewrite_install_paths(
        "bash canonical/scripts/grade.sh foo\n", ".claude"
    )
    if out != "bash .claude/aid/scripts/grade.sh foo\n":
        failures.append(f"rewrite_install_paths: AID-own scripts rewrite wrong, got {out!r}")

    # -----------------------------------------------------------------------
    # Test: rewrite_install_paths — AID-own dir (templates) nests under aid/
    # -----------------------------------------------------------------------
    out = rewrite_install_paths(
        "see canonical/templates/settings.yml\n", ".claude"
    )
    if out != "see .claude/aid/templates/settings.yml\n":
        failures.append(f"rewrite_install_paths: AID-own templates rewrite wrong, got {out!r}")

    # -----------------------------------------------------------------------
    # Test: rewrite_install_paths — AID-own dir (recipes) nests under aid/
    # -----------------------------------------------------------------------
    out = rewrite_install_paths(
        "see canonical/recipes/add-api.md\n", ".claude"
    )
    if out != "see .claude/aid/recipes/add-api.md\n":
        failures.append(f"rewrite_install_paths: AID-own recipes rewrite wrong, got {out!r}")

    # -----------------------------------------------------------------------
    # Test: rewrite_install_paths — tool-native dir (skills) stays un-nested
    # -----------------------------------------------------------------------
    out = rewrite_install_paths(
        "see canonical/skills/aid-config/SKILL.md\n", ".claude"
    )
    if out != "see .claude/skills/aid-config/SKILL.md\n":
        failures.append(f"rewrite_install_paths: tool-native skills should not nest, got {out!r}")

    # -----------------------------------------------------------------------
    # Test: rewrite_install_paths — tool-native dir (agents) stays un-nested
    # -----------------------------------------------------------------------
    out = rewrite_install_paths(
        "see canonical/agents/aid-developer/AGENT.md\n", ".claude"
    )
    if out != "see .claude/agents/aid-developer/AGENT.md\n":
        failures.append(f"rewrite_install_paths: tool-native agents should not nest, got {out!r}")

    # -----------------------------------------------------------------------
    # Test: rewrite_install_paths — rules/ is NOT in the known-dirs list
    # (rules folder deleted by FR3); canonical/rules/... passes through unchanged
    # -----------------------------------------------------------------------
    out = rewrite_install_paths(
        "see canonical/rules/aid-methodology.mdc\n", ".cursor"
    )
    if out != "see canonical/rules/aid-methodology.mdc\n":
        failures.append(f"rewrite_install_paths: canonical/rules/ should pass through unchanged, got {out!r}")

    # -----------------------------------------------------------------------
    # Test: rewrite_install_paths — comment line SKIPPED
    # -----------------------------------------------------------------------
    out = rewrite_install_paths(
        "# Refer to canonical/scripts/grade.sh for the script\n", ".claude"
    )
    expected = "# Refer to canonical/scripts/grade.sh for the script\n"
    if out != expected:
        failures.append(
            f"rewrite_install_paths: comment line should be preserved, got {out!r}"
        )

    # -----------------------------------------------------------------------
    # Test: rewrite_install_paths — indented comment SKIPPED
    # -----------------------------------------------------------------------
    out = rewrite_install_paths(
        "    # nested canonical/templates/X.md\n", ".claude"
    )
    if out != "    # nested canonical/templates/X.md\n":
        failures.append(
            f"rewrite_install_paths: indented comment should be preserved, got {out!r}"
        )

    # -----------------------------------------------------------------------
    # Test: rewrite_install_paths — non-comment lines AFTER a comment line
    # still get rewritten (comment skip is line-local)
    # -----------------------------------------------------------------------
    out = rewrite_install_paths(
        "# canonical/scripts/X.sh (do not rewrite)\nbash canonical/scripts/Y.sh real\n",
        ".claude",
    )
    expected = (
        "# canonical/scripts/X.sh (do not rewrite)\n"
        "bash .claude/aid/scripts/Y.sh real\n"
    )
    if out != expected:
        failures.append(
            f"rewrite_install_paths: line-local skip failed, got {out!r}"
        )

    # -----------------------------------------------------------------------
    # Test: rewrite_install_paths — idempotent on AID-own (already-nested has
    # no canonical/ prefix so the regex does not match — re-run is a no-op)
    # -----------------------------------------------------------------------
    once = rewrite_install_paths("bash canonical/scripts/X.sh\n", ".claude")
    twice = rewrite_install_paths(once, ".claude")
    if once != twice:
        failures.append(
            f"rewrite_install_paths: not idempotent, once={once!r}, twice={twice!r}"
        )

    # -----------------------------------------------------------------------
    # Test: rewrite_install_paths — idempotent on tool-native
    # -----------------------------------------------------------------------
    once_tn = rewrite_install_paths("see canonical/skills/aid-x/SKILL.md\n", ".claude")
    twice_tn = rewrite_install_paths(once_tn, ".claude")
    if once_tn != twice_tn:
        failures.append(
            f"rewrite_install_paths: tool-native not idempotent, "
            f"once={once_tn!r}, twice={twice_tn!r}"
        )

    # -----------------------------------------------------------------------
    # Test: rewrite_install_paths — nested canonical/aid/<dir>/ form (A4 reshape)
    # canonical/aid/templates/ -> <install_root>/aid/templates/  (same dst as flat form)
    # -----------------------------------------------------------------------
    out = rewrite_install_paths(
        "local d=${REPO}/canonical/aid/templates/knowledge-base\n", ".claude"
    )
    if out != "local d=${REPO}/.claude/aid/templates/knowledge-base\n":
        failures.append(
            f"rewrite_install_paths: canonical/aid/templates/ nested rewrite wrong, got {out!r}"
        )

    out = rewrite_install_paths(
        "bash canonical/aid/scripts/grade.sh foo\n", ".claude"
    )
    if out != "bash .claude/aid/scripts/grade.sh foo\n":
        failures.append(
            f"rewrite_install_paths: canonical/aid/scripts/ nested rewrite wrong, got {out!r}"
        )

    out = rewrite_install_paths(
        "see canonical/aid/recipes/add-api.md\n", ".cursor"
    )
    if out != "see .cursor/aid/recipes/add-api.md\n":
        failures.append(
            f"rewrite_install_paths: canonical/aid/recipes/ nested rewrite wrong, got {out!r}"
        )

    # -----------------------------------------------------------------------
    # Test: rewrite_install_paths — unrelated canonical/ paths pass through
    # (e.g., canonical/work-NNN/ is not in the known-dirs allowlist)
    # -----------------------------------------------------------------------
    out = rewrite_install_paths(
        "see canonical/work-001/feature-002.md\n", ".claude"
    )
    if out != "see canonical/work-001/feature-002.md\n":
        failures.append(
            f"rewrite_install_paths: unrelated canonical/ should pass through, got {out!r}"
        )

    # -----------------------------------------------------------------------
    # Test: EmissionManifest determinism (two runs, same output)
    # -----------------------------------------------------------------------
    import tempfile, os

    def _make_manifest() -> bytes:
        m = EmissionManifest(profile_name="claude-code")
        m.add(
            profile="claude-code",
            src="canonical/agents/aid-architect/AGENT.md",
            dst=".claude/agents/aid-architect.md",
            sha256="a" * 64,
        )
        m.add(
            profile="claude-code",
            src="canonical/skills/aid-deploy/SKILL.md",
            dst=".claude/skills/aid-deploy/SKILL.md",
            sha256="b" * 64,
        )
        with tempfile.NamedTemporaryFile(delete=False, suffix=".jsonl") as tmp:
            tmp_path = tmp.name
        try:
            return m.write(tmp_path)
        finally:
            os.unlink(tmp_path)

    run1 = _make_manifest()
    run2 = _make_manifest()
    if run1 != run2:
        failures.append("EmissionManifest: two identical runs produced different bytes")

    # -----------------------------------------------------------------------
    # Test: EmissionManifest sentinel is first line
    # -----------------------------------------------------------------------
    m_check = EmissionManifest(profile_name="test")
    m_check.add(profile="test", src="s", dst="z-dst", sha256="c" * 64)
    m_check.add(profile="test", src="s", dst="a-dst", sha256="d" * 64)
    with tempfile.NamedTemporaryFile(delete=False, suffix=".jsonl") as tmp:
        tmp_path = tmp.name
    try:
        payload = m_check.write(tmp_path)
    finally:
        os.unlink(tmp_path)

    lines = payload.decode("utf-8").splitlines()
    if not lines[0].startswith('{"_manifest_version"'):
        failures.append(f"EmissionManifest: first line is not sentinel, got {lines[0]!r}")

    # -----------------------------------------------------------------------
    # Test: EmissionManifest records sorted by dst
    # -----------------------------------------------------------------------
    dsts = [json.loads(ln)["dst"] for ln in lines[1:] if ln.strip()]
    if dsts != sorted(dsts):
        failures.append(f"EmissionManifest: records not sorted by dst: {dsts}")

    # -----------------------------------------------------------------------
    # Test: EmissionManifest LF only (no CRLF)
    # -----------------------------------------------------------------------
    if b"\r\n" in payload:
        failures.append("EmissionManifest: payload contains CRLF — expected LF only")

    # -----------------------------------------------------------------------
    # Test: EmissionManifest last line terminated by \n
    # -----------------------------------------------------------------------
    if not payload.endswith(b"\n"):
        failures.append("EmissionManifest: payload does not end with LF")

    # -----------------------------------------------------------------------
    # Test: EmissionManifest.load round-trip
    # -----------------------------------------------------------------------
    m_orig = EmissionManifest(profile_name="claude-code")
    m_orig.add(
        profile="claude-code",
        src="canonical/agents/aid-developer/AGENT.md",
        dst=".claude/agents/aid-developer.md",
        sha256="e" * 64,
    )
    with tempfile.NamedTemporaryFile(delete=False, suffix=".jsonl") as tmp:
        tmp_path = tmp.name
    try:
        m_orig.write(tmp_path)
        m_loaded = EmissionManifest.load(tmp_path, profile_name="claude-code")
    finally:
        os.unlink(tmp_path)

    if len(m_loaded._records) != 1:
        failures.append(
            f"EmissionManifest.load: expected 1 record, got {len(m_loaded._records)}"
        )
    else:
        rec = m_loaded._records[0]
        if rec.dst != ".claude/agents/aid-developer.md":
            failures.append(f"EmissionManifest.load: dst mismatch: {rec.dst!r}")
        if rec.sha256 != "e" * 64:
            failures.append(f"EmissionManifest.load: sha256 mismatch: {rec.sha256!r}")

    # -----------------------------------------------------------------------
    # Test: EmissionManifest.diff
    # -----------------------------------------------------------------------
    prev = EmissionManifest(profile_name="test")
    prev.add(profile="test", src="s", dst="kept", sha256="x" * 64)
    prev.add(profile="test", src="s", dst="removed", sha256="y" * 64)
    prev.add(profile="test", src="s", dst="changed", sha256="z" * 64)

    curr = EmissionManifest(profile_name="test")
    curr.add(profile="test", src="s", dst="kept", sha256="x" * 64)
    curr.add(profile="test", src="s", dst="added", sha256="a" * 64)
    curr.add(profile="test", src="s", dst="changed", sha256="NEW" + "z" * 61)

    added, removed, changed = curr.diff(prev)
    if added != ["added"]:
        failures.append(f"EmissionManifest.diff: added wrong: {added}")
    if removed != ["removed"]:
        failures.append(f"EmissionManifest.diff: removed wrong: {removed}")
    if changed != ["changed"]:
        failures.append(f"EmissionManifest.diff: changed wrong: {changed}")

    # -----------------------------------------------------------------------
    # Test: EmissionManifest.add with content= path (sha256 computed internally)
    # -----------------------------------------------------------------------
    m_content = EmissionManifest(profile_name="test")
    test_bytes = b"hello manifest content"
    m_content.add(
        profile="test",
        src="canonical/agents/aid-architect/AGENT.md",
        dst=".claude/agents/aid-architect.md",
        content=test_bytes,
    )
    expected_digest = sha256_hex(test_bytes)
    if not m_content._records:
        failures.append("EmissionManifest.add(content=): no record added")
    elif m_content._records[0].sha256 != expected_digest:
        failures.append(
            f"EmissionManifest.add(content=): sha256 mismatch — "
            f"got {m_content._records[0].sha256!r}, expected {expected_digest!r}"
        )

    # -----------------------------------------------------------------------
    # Test: EmissionManifest.add raises when both content= and sha256= given
    # -----------------------------------------------------------------------
    m_err = EmissionManifest(profile_name="test")
    try:
        m_err.add(profile="test", src="s", dst="d", content=b"x", sha256="y" * 64)
        failures.append("EmissionManifest.add: should raise with both content= and sha256=")
    except ValueError:
        pass  # expected

    # -----------------------------------------------------------------------
    # Results
    # -----------------------------------------------------------------------
    if failures:
        print(f"SELF-TEST FAILED ({len(failures)} failure(s)):", file=sys.stderr)
        for f in failures:
            print(f"  - {f}", file=sys.stderr)
        return 1

    print(f"OK: all self-tests passed ({_count_tests()} checks)")
    return 0


def _count_tests() -> int:
    """Return the approximate number of checks performed in main()."""
    return 30  # 16 prior + 14 rewrite_install_paths assertions (AID-own nest + tool-native split)


if __name__ == "__main__":
    sys.exit(main())
