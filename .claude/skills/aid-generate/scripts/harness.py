#!/usr/bin/env python3
# harness.py — AID canonical-generator shared renderer helpers
#
# Purpose:
#   Shared utilities used by every renderer (tasks 019-021):
#   - read_canonical_file / write_output_file (with side-effect manifest recording)
#   - substitute_filenames (placeholder substitution for {project_context_file}, etc.)
#   - sha256_hex (deterministic content fingerprint)
#   - EmissionManifest (JSONL write with sentinel, sorted by dst, LF-only, binary mode)
#
# Usage:
#   python harness.py --help
#   (Imported by renderers; also runnable standalone as a self-test)
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

# Regex matching canonical/* path references that must be rewritten to the
# install-tree path during render (F1 fix). Uses a word boundary so substrings
# like "foocanonical/..." don't match; constrains the second segment to the
# known canonical subdirectories so unrelated paths (e.g., "canonical/work-NNN")
# pass through untouched.
_CANONICAL_PATH_DIRS = ("scripts", "templates", "skills", "agents", "rules", "recipes")
_CANONICAL_PATH_RE = re.compile(
    r"\bcanonical/(" + "|".join(_CANONICAL_PATH_DIRS) + r")/"
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
# rewrite_install_paths (F1 fix)
# ---------------------------------------------------------------------------

def rewrite_install_paths(body: str, install_root: str) -> str:
    """
    Rewrite ``canonical/{scripts,templates,skills,agents,rules,recipes}/...``
    path references in *body* to the per-profile install-tree path.

    Adopters install the bundle under ``.claude/`` / ``.agents/`` / ``.cursor/``;
    skill bodies that hard-code ``canonical/scripts/...`` would fail to resolve
    in adopter projects. This rewriter runs during render so each profile's
    output contains install-rooted paths instead.

    Comment lines (lines whose first non-whitespace character is ``#``) are
    SKIPPED. This protects prose-about-the-mechanism (e.g.,
    ``generated-files.txt`` PATH CONVENTION header) from circular rewrites:
    a comment that describes the renderer's behavior using literal
    ``canonical/scripts/...`` strings would otherwise become circular
    nonsense in the profile (``.claude/scripts/... → .claude/scripts/...``).
    Shell, YAML, and .txt files use ``#`` as their comment character;
    markdown headings start with ``#`` too but rarely contain literal
    canonical/ path references — so the same rule is safe across formats.

    Non-comment lines (everything not starting with ``#`` after leading
    whitespace) still receive normal rewriting — the skip rule is line-local
    and does not change behavior for the surrounding code lines.

    Parameters
    ----------
    body : str
        Text content (typically a SKILL.md, reference, template, or script body).
    install_root : str
        The profile's install-tree basename (e.g., ``.claude``, ``.agents``,
        ``.cursor``). Obtained from ``profile.layout.install_root()``.

    Returns
    -------
    str
        Body with every matched canonical/<dir>/ prefix rewritten to
        <install_root>/<dir>/, EXCEPT on comment lines (`#` at first non-ws).

    Notes
    -----
    - Uses a word boundary so substrings like ``foocanonical/...`` don't match.
    - Only rewrites the 6 known canonical subdirectories — paths like
      ``canonical/work-NNN/...`` or ``canonical/scratch/`` pass through.
    - Idempotent: rewriting already-rewritten text is a no-op.
    - Comment skip is line-by-line; multi-line constructs not detected.
    """
    out_lines = []
    for line in body.splitlines(keepends=True):
        stripped = line.lstrip()
        if stripped.startswith("#"):
            out_lines.append(line)  # comment line — preserve verbatim
        else:
            out_lines.append(_CANONICAL_PATH_RE.sub(install_root + r"/\1/", line))
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
        manifest computes the digest; the harness ``write_output_file()``
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
        prog="harness.py",
        description=(
            "AID generator harness — shared renderer helpers. "
            "Run with --self-test to verify harness correctness."
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
    # Test: rewrite_install_paths — basic rewrite on a non-comment line
    # -----------------------------------------------------------------------
    out = rewrite_install_paths(
        "bash canonical/scripts/grade.sh foo\n", ".claude"
    )
    if out != "bash .claude/scripts/grade.sh foo\n":
        failures.append(f"rewrite_install_paths: basic rewrite wrong, got {out!r}")

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
        "bash .claude/scripts/Y.sh real\n"
    )
    if out != expected:
        failures.append(
            f"rewrite_install_paths: line-local skip failed, got {out!r}"
        )

    # -----------------------------------------------------------------------
    # Test: rewrite_install_paths — idempotent (rewrite of rewritten is no-op)
    # -----------------------------------------------------------------------
    once = rewrite_install_paths("bash canonical/scripts/X.sh\n", ".claude")
    twice = rewrite_install_paths(once, ".claude")
    if once != twice:
        failures.append(
            f"rewrite_install_paths: not idempotent, once={once!r}, twice={twice!r}"
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
            src="canonical/agents/architect/AGENT.md",
            dst=".claude/agents/architect.md",
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
        src="canonical/agents/developer/AGENT.md",
        dst=".claude/agents/developer.md",
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
        if rec.dst != ".claude/agents/developer.md":
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
        src="canonical/agents/architect/AGENT.md",
        dst=".claude/agents/architect.md",
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
    return 22  # 16 prior + 6 rewrite_install_paths assertions (round-5 Item 6)


if __name__ == "__main__":
    sys.exit(main())
