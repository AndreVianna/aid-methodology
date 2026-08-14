# dashboard/reader/parsers.py
# LC-2 Parsers: per-source structural parse for the AID state reader.
#
# Responsibility: parse file bytes into typed model fields.
# No derivation, no write, no I/O side-effects.
# Every rule is a single anchored grep / line-scan expressible in either runtime
# (Python or Node) with zero third-party deps.
#
# Read-only by construction: all open() calls are read-only (mode 'r' / 'rb').
# No open(..., 'w'), no open(..., 'a'), no lock primitive exists here.
#
# Python 3.11+ stdlib only. Zero third-party deps.

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Optional

from .io_bounds import read_bytes_bounded
from .models import (
    ConnectorRef,
    DeliverableRef,
    DeferredIssue,
    DocFreshness,
    FeatureRef,
    Finding,
    KbBaseline,
    KbStateRef,
    Lifecycle,
    LogAvailability,
    PendingInput,
    Phase,
    RawStateRef,
    SourceMode,
    TaskDetail,
    TaskLedger,
    TaskModel,
    TaskStatus,
    ToolInfo,
)
from .derivation import derive_lifecycle
from .state_schema import (
    parse_bool_yesno,
    parse_header_bold_field,
    parse_state_document,
    resolve_kind,
)


# ---------------------------------------------------------------------------
# Parse result containers (plain dicts/values; models assembled in reader.py)
# ---------------------------------------------------------------------------

class ParsedWork:
    """Intermediate parse result for a single work folder's STATE.md.

    Fields match WorkModel fields. Assembled into a WorkModel by reader.py.
    """
    __slots__ = (
        "lifecycle",
        "phase",
        "active_skill",
        "updated",
        "pause_reason",
        "block_reason",
        "block_artifact",
        "tasks",
        "pending_inputs",
        "source_mode",
        "parse_warnings",
        "bytes_read",
        # prototype: work-overview header fields
        "work_path",
        "recipe",
        "features",
        "deliverables",
        "created",
        # work-003-state-schema task-002: dual-format frontmatter read, new fields
        "kind",
        "started",
        "minimum_grade",
        "user_approved",
    )

    def __init__(self) -> None:
        self.lifecycle: Lifecycle = Lifecycle.Unknown
        self.phase: Optional[Phase] = None
        self.active_skill: Optional[str] = None
        self.updated: Optional[str] = None
        self.pause_reason: Optional[str] = None
        self.block_reason: Optional[str] = None
        self.block_artifact: Optional[str] = None
        self.tasks: list[TaskModel] = []
        self.pending_inputs: list[PendingInput] = []
        self.source_mode: SourceMode = SourceMode.Fallback
        self.parse_warnings: list[str] = []
        self.bytes_read: int = 0
        # prototype: work-overview header fields
        self.work_path: Optional[str] = None
        self.recipe: Optional[str] = None
        self.features: list[FeatureRef] = []
        self.deliverables: list[DeliverableRef] = []
        self.created: Optional[str] = None
        # work-003-state-schema task-002: dual-format frontmatter read, new fields
        self.kind: Optional[str] = None
        self.started: Optional[str] = None
        self.minimum_grade: Optional[str] = None
        self.user_approved: Optional[bool] = None


# ---------------------------------------------------------------------------
# Level-0: ToolInfo from .aid-manifest.json
# ---------------------------------------------------------------------------

def parse_tool_info(
    manifest_path: Path,
) -> tuple[ToolInfo, int]:
    """Parse .aid/.aid-manifest.json into ToolInfo.

    Returns (ToolInfo, bytes_read).
    manifest_present=False -> all fields None, no error (DM-2). The retired
    .aid/.aid-version marker is no longer consulted; a tool-less project (no
    manifest) records its AID version in settings.yml instead, surfaced by the
    home-grid reader.
    """
    bytes_read = 0

    if manifest_path.is_file():
        try:
            raw = read_bytes_bounded(manifest_path)
            bytes_read += len(raw)
            data = json.loads(raw.decode("utf-8", errors="replace"))
        except (OSError, json.JSONDecodeError, ValueError):
            return ToolInfo(manifest_present=False), bytes_read

        aid_version = data.get("aid_version")
        installed_at = data.get("installed_at")
        tools_dict = data.get("tools", {})
        tools_installed = list(tools_dict.keys()) if isinstance(tools_dict, dict) else []

        return ToolInfo(
            manifest_present=True,
            aid_version=str(aid_version) if aid_version is not None else None,
            installed_at=str(installed_at) if installed_at is not None else None,
            tools_installed=tools_installed,
        ), bytes_read

    # No manifest.
    return ToolInfo(manifest_present=False), bytes_read


# ---------------------------------------------------------------------------
# Level-1: RepoInfo helpers
# ---------------------------------------------------------------------------

def parse_project_settings(settings_path: Path) -> tuple[str, Optional[str], int]:
    """Extract project.name and project.description from .aid/settings.yml.

    Both scalars live in the SAME 'project:' block, so this is one shared
    line-scan (feature-002, work-017 task-005) -- the combined pass
    `parse_project_name` used to run alone before this field was added.
    Returns (name, description, bytes_read). On any failure, returns ("", None, 0).

    This is display-only: we read only the literal scalars, not
    grade-resolution semantics (read-setting.sh is the contract for resolution).
    """
    if not settings_path.is_file():
        return "", None, 0

    try:
        raw = read_bytes_bounded(settings_path)
    except OSError:
        return "", None, 0

    bytes_read = len(raw)
    text = raw.decode("utf-8", errors="replace")

    # Find 'project:' section then the 'name:'/'description:' lines within it.
    # Simple anchored line-scan: no YAML parser needed for these scalars.
    in_project = False
    name: Optional[str] = None
    description: Optional[str] = None
    for line in text.splitlines():
        stripped = line.strip()
        if stripped == "project:" or stripped.startswith("project: "):
            in_project = True
            continue
        if in_project:
            # Another top-level key ends the project block
            if line and line[0] not in (" ", "\t", "#", "") and ":" in line:
                key = line.split(":")[0].strip()
                if key not in ("name", "description"):
                    # If this is a new top-level section (no leading whitespace), stop.
                    if not line[0].isspace():
                        break
            m = re.match(r"^\s+name:\s+(.+)", line)
            if m and name is None:
                # PF-6: strip inline YAML comment -- drop from first unquoted '#' to EOL
                val = _strip_yaml_inline_comment(m.group(1))
                name = val.strip().strip('"').strip("'")
                continue
            m = re.match(r"^\s+description:\s+(.+)", line)
            if m and description is None:
                val = _strip_yaml_inline_comment(m.group(1))
                description = val.strip().strip('"').strip("'")
                continue

    # Flat-schema fallback: name/description at the top level (the project:
    # wrapper is removed in the flat schema). A migrated project has them at
    # column 0; a legacy project has them nested (found above).
    if name is None:
        name = _parse_toplevel_scalar(text, "name")
    if description is None:
        description = _parse_toplevel_scalar(text, "description")

    return (name if name is not None else ""), description, bytes_read


def parse_project_name(settings_path: Path) -> tuple[str, int]:
    """Extract project.name from .aid/settings.yml.

    Thin wrapper over `parse_project_settings` (kept for existing
    callers/tests that only need the name). Returns (name, bytes_read).
    On any failure, returns ("", 0).

    This is display-only: we read only the literal name scalar, not
    grade-resolution semantics (read-setting.sh is the contract for resolution).
    """
    name, _description, bytes_read = parse_project_settings(settings_path)
    return name, bytes_read


def parse_minimum_grade(settings_path: Path) -> tuple[Optional[str], int]:
    """Extract the GLOBAL review.minimum_grade from .aid/settings.yml.

    Its own 'review:'-section line-scan -- structurally SEPARATE from the
    'project:' block. In a real settings.yml the 'tools:' section sits
    between 'project:' and 'review:', so `parse_project_settings`'s
    break-on-next-top-level-key logic exits the loop at 'tools:' and never
    reaches 'review:'; reusing that scan is impossible, hence the dedicated pass.

    Returns (grade, bytes_read). Absent/unreadable -> (None, bytes_read or 0).

    Read literally as a display scalar -- no resolution (read-setting.sh
    remains the resolution contract, same posture as parse_project_name).
    """
    if not settings_path.is_file():
        return None, 0

    try:
        raw = read_bytes_bounded(settings_path)
    except OSError:
        return None, 0

    bytes_read = len(raw)
    text = raw.decode("utf-8", errors="replace")

    in_review = False
    grade: Optional[str] = None
    for line in text.splitlines():
        stripped = line.strip()
        if stripped == "review:" or stripped.startswith("review: "):
            in_review = True
            continue
        if in_review:
            # Another top-level key ends the review block
            if line and line[0] not in (" ", "\t", "#", "") and ":" in line:
                key = line.split(":")[0].strip()
                if key != "minimum_grade":
                    if not line[0].isspace():
                        break
            m = re.match(r"^\s+minimum_grade:\s+(.+)", line)
            if m and grade is None:
                val = _strip_yaml_inline_comment(m.group(1))
                val = val.strip().strip('"').strip("'")
                if val:
                    grade = val
                continue

    # Flat-schema fallback: top-level minimum_grade (review: wrapper removed).
    if grade is None:
        grade = _parse_toplevel_scalar(text, "minimum_grade")

    return grade, bytes_read


def _parse_toplevel_scalar(text: str, key: str) -> Optional[str]:
    """Read a column-0 ``key: value`` scalar (the flat settings schema, where
    name/description/type/minimum_grade live at the top level). Returns the
    stripped value, or None if absent / empty / an inline list / block-marker."""
    pat = re.compile(r"^" + re.escape(key) + r":\s*(.*)$")
    for line in text.splitlines():
        m = pat.match(line)
        if m:
            val = _strip_yaml_inline_comment(m.group(1)).strip().strip('"').strip("'")
            if val.startswith("[") and val.endswith("]"):
                return None
            return val or None
    return None


def _strip_yaml_inline_comment(scalar: str) -> str:
    """Strip an inline YAML comment from a scalar value (PF-6).

    Drops everything from the first '#' that is NOT inside a quoted string
    to end-of-line. Handles single- and double-quoted values.

    Examples:
      'AID  # set during /aid-config INIT'  ->  'AID'
      '"Foo Bar" # comment'                 ->  '"Foo Bar"'
      'plain'                               ->  'plain'
    """
    s = scalar
    # If the value starts with a quote, find the closing quote first
    if s and s[0] in ('"', "'"):
        quote = s[0]
        end = s.find(quote, 1)
        if end != -1:
            # Everything after the closing quote is potentially a comment
            after = s[end + 1:].lstrip()
            if after.startswith("#"):
                s = s[:end + 1]
        return s
    # Unquoted: first '#' (possibly preceded by space) is the comment
    idx = s.find("#")
    if idx != -1:
        s = s[:idx]
    return s


def _scan_block_pair(
    text: str, block_key: str, key1: str, key2: str
) -> tuple[Optional[str], Optional[str], bool]:
    """Tolerant line-scan for a top-level ``block_key`` (e.g. 'knowledge:')
    block, extracting the ``key1`` and ``key2`` scalar values found inside it.

    Returns (key1_value, key2_value, block_found).
    """
    in_block = False
    found = False
    val1: Optional[str] = None
    val2: Optional[str] = None
    key1_re = re.compile(r"^\s+" + re.escape(key1) + r"\s+(.+)")
    key2_re = re.compile(r"^\s+" + re.escape(key2) + r"\s+(.+)")

    for line in text.splitlines():
        stripped = line.strip()
        if stripped == block_key or stripped.startswith(block_key + " "):
            in_block = True
            found = True
            continue
        if in_block:
            # Another top-level key (no leading whitespace) ends the block
            if line and not line[0].isspace() and ":" in line and not stripped.startswith("#"):
                break
            m = key1_re.match(line)
            if m and val1 is None:
                val = _strip_yaml_inline_comment(m.group(1)).strip().strip('"').strip("'")
                if val:
                    val1 = val
                continue
            m = key2_re.match(line)
            if m and val2 is None:
                val = _strip_yaml_inline_comment(m.group(1)).strip().strip('"').strip("'")
                if val:
                    val2 = val
                continue

    return val1, val2, found


def parse_kb_baseline(settings_path: Path) -> tuple[Optional["KbBaseline"], int]:
    """Parse the KB baseline from .aid/settings.yml (DM-A4, task-064).

    Tolerant line-scan, reusing the parse_project_name posture (parsers.py:148):
      - Scan for the 'knowledge:' top-level key
      - Within that block, extract 'source:' (-> branch) and 'last_update:'
        (-> tip_date) scalar values
      - When 'knowledge:' is absent, fall back to the legacy 'kb_baseline:'
        block ('branch:' / 'tip_date:' scalars) for pre-migration settings.yml
      - Absent/unparseable -> None (skip freshness, stay approved; FF-A2)

    Returns (KbBaseline or None, bytes_read). The returned struct keeps the
    same branch/tip_date field names regardless of which schema it was read
    from, so downstream freshness logic is unchanged.
    Never raises (NFR7). Never writes.
    """
    if not settings_path.is_file():
        return None, 0

    try:
        raw = read_bytes_bounded(settings_path)
    except OSError:
        return None, 0

    bytes_read = len(raw)
    text = raw.decode("utf-8", errors="replace")

    branch, tip_date, knowledge_found = _scan_block_pair(
        text, "knowledge:", "source:", "last_update:"
    )
    if not knowledge_found:
        branch, tip_date, _ = _scan_block_pair(
            text, "kb_baseline:", "branch:", "tip_date:"
        )

    if branch is None and tip_date is None:
        return None, bytes_read

    return KbBaseline(branch=branch, tip_date=tip_date), bytes_read


def parse_kb_state(
    kb_dir: Path,
) -> tuple[Optional["KbStateRef"], int]:
    """Parse .aid/knowledge/STATE.md + README.md into a KbStateRef hook.

    If .aid/knowledge/ does not exist, returns (None, 0) -- repo never ran
    /aid-discover; render gracefully.

    summary_present is stat'd from kb_dir/kb.html: the generated KB summary now
    lives beside its KB source in .aid/knowledge/ (the .aid/dashboard/ folder was
    eliminated -- home.html is served by the CLI, kb.html moved here).
    The status field and kb_baseline are populated by the caller (reader.py)
    after derivation (FF-A3) and parsing (parse_kb_baseline).

    Fields populated:
      summary_approved  -- frontmatter `summary_approved` (task-002, dual-format),
                            else the legacy "**User Approved:** yes ..." bold line
      last_summary_date -- frontmatter `last_summary`, else the parenthesized date
                            on the legacy bold line
      doc_count         -- count of data rows in README.md ## Completeness table
      summary_present   -- True if kb_dir/kb.html exists (stat only)
      source_mode       -- Normalized (frontmatter) | Fallback (legacy prose or
                            nothing present) -- extends SourceMode onto the KB
                            path (task-002 gate criteria #3)
      kb_status/kb_grade/last_kb_review -- newly-captured discovery scalars:
                            frontmatter-first, legacy header-blockquote fallback
    """
    if not kb_dir.is_dir():
        return None, 0

    bytes_read = 0
    summary_approved = False
    last_summary_date: Optional[str] = None
    doc_count: Optional[int] = None
    source_mode = SourceMode.Fallback
    kb_status_val: Optional[str] = None
    kb_grade_val: Optional[str] = None
    last_kb_review_val: Optional[str] = None

    # Parse STATE.md for summary approval.
    state_path = kb_dir / "STATE.md"
    if state_path.is_file():
        try:
            raw = read_bytes_bounded(state_path)
            bytes_read += len(raw)
            state_text = raw.decode("utf-8", errors="replace")
        except OSError:
            state_text = ""
        # .aid/knowledge/STATE.md is OUT OF SCOPE for this work (SPEC.md § D-6):
        # it stays markdown-with-frontmatter. This is the ONE caller in the
        # package that opts INTO the legacy fenced-frontmatter scan
        # (allow_frontmatter_fence=True) -- every state-file reader leaves it
        # at the strict default. Dispatch on the CALLER, not on the document's
        # own leading bytes: a state file that happens to open with '---' must
        # still be rejected by the strict engine as a second document, not
        # silently routed to this looser grammar. With the caller opting in
        # AND this file always opening with '---', behavior here is identical
        # to the pre-refactor parse_frontmatter_scalars call -- the (always-
        # empty, for this path) warnings are discarded, matching the original
        # contract (that scan never emitted a parse_warning).
        fm, _kb_fm_warnings = parse_state_document(
            state_text, file_label="knowledge/STATE.md", allow_frontmatter_fence=True
        )
        summary_approved, last_summary_date, source_mode = _parse_kb_summary_approval(
            state_text, fm
        )

        # Newly-captured discovery-status scalars (task-002): frontmatter-first,
        # legacy header-blockquote fallback (never parsed by any reader before
        # this task -- schema-note.md classifies these "Newly captured").
        v = fm.get("kb_status")
        if v is not None and not _is_null(v):
            kb_status_val = v.strip()
        else:
            legacy = parse_header_bold_field(state_text, "Status")
            if legacy is not None and not _is_null(legacy):
                kb_status_val = legacy

        v = fm.get("kb_grade")
        if v is not None and not _is_null(v):
            kb_grade_val = v.strip()
        else:
            legacy = parse_header_bold_field(state_text, "Current Grade")
            if legacy is not None and not _is_null(legacy):
                kb_grade_val = legacy

        v = fm.get("last_kb_review")
        if v is not None and not _is_null(v):
            last_kb_review_val = v.strip()
        else:
            legacy = parse_header_bold_field(state_text, "Last KB Review")
            if legacy is not None and not _is_null(legacy):
                last_kb_review_val = legacy

    # Parse README.md for doc_count.
    readme_path = kb_dir / "README.md"
    if readme_path.is_file():
        try:
            raw = read_bytes_bounded(readme_path)
            bytes_read += len(raw)
            readme_text = raw.decode("utf-8", errors="replace")
        except OSError:
            readme_text = ""
        doc_count = _parse_kb_doc_count(readme_text)

    # Stat kb_dir/kb.html for summary_present (kb.html now lives beside its KB
    # source in .aid/knowledge/, not in the eliminated .aid/dashboard/ folder).
    summary_present = False
    kb_html = kb_dir / "kb.html"
    try:
        summary_present = kb_html.is_file()
    except OSError:
        summary_present = False

    return KbStateRef(
        summary_approved=summary_approved,
        last_summary_date=last_summary_date,
        doc_count=doc_count,
        summary_present=summary_present,
        # status and kb_baseline are set by reader.py after derivation
        source_mode=source_mode,
        kb_status=kb_status_val,
        kb_grade=kb_grade_val,
        last_kb_review=last_kb_review_val,
    ), bytes_read


def _parse_kb_summary_approval(
    text: str, fm: Optional[dict] = None
) -> tuple[bool, Optional[str], SourceMode]:
    """Find the KB summary approval + last-run date (frontmatter-first).

    Returns (approved: bool, date: Optional[str], source_mode: SourceMode).

    Frontmatter-first (task-002): if `summary_approved` is present in the
    already-parsed frontmatter dict `fm`, that scalar (yes/no/true/false,
    case-insensitive) is authoritative and `last_summary` supplies the date;
    source_mode=Normalized.

    Legacy-prose fallback (UNCHANGED behavior): scans the
    '## Knowledge Summary Status' section for a '**User Approved:** yes ...'
    BOLD LINE (not a table row -- the historical misparse this whole work
    exists to fix; the ad hoc bold line IS what state-generate.md/
    state-approval.md actually write below the table, so this scan remains the
    real legacy-compat path for un-migrated files); source_mode=Fallback.
    """
    if fm is not None:
        fm_approved = fm.get("summary_approved")
        if fm_approved is not None:
            approved = bool(parse_bool_yesno(fm_approved))
            fm_last = fm.get("last_summary")
            date: Optional[str] = None
            if fm_last is not None and not _is_null(fm_last):
                date = fm_last.strip()
            return approved, date, SourceMode.Normalized

    # Look for the section ## Knowledge Summary Status then **User Approved:**
    in_summary_status = False
    for line in text.splitlines():
        if re.match(r"^##\s+Knowledge Summary Status", line):
            in_summary_status = True
            continue
        if in_summary_status:
            # Stop at the next section header
            if re.match(r"^##\s+", line):
                break
            m = re.match(r"\*\*User Approved:\*\*\s+(.+)", line.strip())
            if m:
                val = m.group(1).strip()
                approved = val.lower().startswith("yes")
                date_m = re.search(r"\((\d{4}-\d{2}-\d{2})", val)
                date = date_m.group(1) if date_m else None
                return approved, date, SourceMode.Fallback
    return False, None, SourceMode.Fallback


def _parse_kb_doc_count(text: str) -> Optional[int]:
    """Count data rows under ## Completeness table in README.md.

    A data row is a Markdown table row that:
    - starts with '|' and contains at least 2 columns
    - is not the header row (does not contain '---')
    - is not a blank/separator row
    """
    in_completeness = False
    count = 0
    header_seen = False

    for line in text.splitlines():
        if re.match(r"^##\s+Completeness", line):
            in_completeness = True
            header_seen = False
            count = 0
            continue
        if in_completeness:
            if re.match(r"^##\s+", line):
                break
            if not line.strip().startswith("|"):
                continue
            if "---" in line:
                header_seen = True  # separator row; skip
                continue
            if not header_seen:
                header_seen = True  # first non-separator table line = header
                continue
            # Data row
            cols = [c.strip() for c in line.strip().strip("|").split("|")]
            if len(cols) >= 2 and cols[0]:
                count += 1

    return count if in_completeness else None


# ---------------------------------------------------------------------------
# f007 / task-042: per-doc frontmatter scan (sources: + approved_at_commit:)
# ---------------------------------------------------------------------------

_RE_FM_FENCE = re.compile(r"^---\s*$")
_RE_URL = re.compile(r"^[a-z][a-z0-9+.\-]*://")


def parse_doc_frontmatter(path: Path) -> tuple[Optional[str], list[str], bool]:
    """Tolerant sources:/approved_at_commit: frontmatter scan for one KB doc.

    Reads only the YAML frontmatter block (between the first pair of '---' lines).
    Identical algorithm to the bash fm_scalar/fm_list/fm_sources_present helpers in
    kb-freshness-check.sh; mirrors the Node twin in reader.mjs (byte-parity).

    Returns:
        (approved_at_commit, sources_list, sources_field_present)

    approved_at_commit:
        the trimmed scalar value, or None if absent/empty.
    sources_list:
        items from the sources: YAML list (inline or block); empty list if field
        is absent, sources: [], or the value is not a list.
    sources_field_present:
        True if the sources: key was present (even as sources: []), False if absent.
        Used to distinguish "sources: []" (-> current) from "no sources: field" (-> current too,
        but noted separately for debugging; both map to current per the SPEC).

    Never raises (NFR7). Handles:
      - No frontmatter (no leading ---) -> (None, [], False)
      - Inline list: sources: [a, b]
      - Block list:  sources:\n  - a\n  - b
      - Empty list:  sources: []  -> (approval, [], True)
    """
    if not path.is_file():
        return None, [], False

    try:
        raw = read_bytes_bounded(path)
        text = raw.decode("utf-8", errors="replace")
    except OSError:
        return None, [], False

    approved_at_commit: Optional[str] = None
    sources_list: list[str] = []
    sources_field_present: bool = False

    in_fm = False
    fm_entered = False
    in_sources_block = False

    for line in text.splitlines():
        if _RE_FM_FENCE.match(line):
            if not fm_entered:
                # Opening fence
                in_fm = True
                fm_entered = True
                continue
            else:
                # Closing fence
                break

        if not in_fm:
            # No opening fence yet -- not in frontmatter (or no frontmatter)
            break

        # Inside frontmatter block
        stripped = line.rstrip()

        if in_sources_block:
            # Continuation of a block-style sources: list
            m_item = re.match(r"^[ \t]+-[ \t]*(.*)", stripped)
            if m_item:
                item = m_item.group(1).strip().strip('"').strip("'")
                if item:
                    sources_list.append(item)
                continue
            else:
                # Any non-item line ends the block
                in_sources_block = False
                # Fall through to check this line for other fields

        # approved_at_commit: scalar
        m_aac = re.match(r"^approved_at_commit:\s*(.*)", stripped)
        if m_aac:
            val = m_aac.group(1).strip().strip('"').strip("'")
            approved_at_commit = val if val else None
            continue

        # sources: field
        m_src = re.match(r"^sources:\s*(.*)", stripped)
        if m_src:
            sources_field_present = True
            rest = m_src.group(1).strip()
            if rest == "[]":
                # Explicit empty inline list: sources: []
                # sources_field_present already set; list stays []
                continue
            if not rest:
                # Bare 'sources:' with nothing after -- block list follows
                in_sources_block = True
                continue
            if rest.startswith("["):
                # Inline list: [a, b, c]
                inner = rest.lstrip("[").rstrip("]").strip()
                if inner:
                    for item in inner.split(","):
                        item = item.strip().strip('"').strip("'")
                        if item:
                            sources_list.append(item)
                continue
            # Block list: next indented lines are items
            in_sources_block = True
            continue

    return approved_at_commit, sources_list, sources_field_present


def is_url_source(entry: str) -> bool:
    """Return True if entry matches a URL scheme (^[a-z][a-z0-9+.-]*://).

    Identical to kb-freshness-check.sh is_url() and the Node twin isUrlSource().
    """
    return bool(_RE_URL.match(entry))


# ---------------------------------------------------------------------------
# feature-007-connectors-list (work-017 task-019): connectors registry parser
# ---------------------------------------------------------------------------

# The six connector-descriptor frontmatter scalars (feature-001's frozen
# schema) -- the SAME fields build-connectors-index.sh's ef() and
# connector-registry.sh's read_field address.
_CONNECTOR_FM_FIELDS = (
    "name", "connection_type", "endpoint", "auth_method", "secret_reference", "summary",
)


def _parse_connector_frontmatter_scalars(text: str) -> dict[str, str]:
    """Extract the six connector-descriptor frontmatter scalars from the FIRST
    frontmatter block only.

    Same semantics as connector-registry.sh's read_field() / build-connectors-
    index.sh's ef(): a single-line 'field: value' scalar, with ONE pair of
    surrounding quotes stripped, first occurrence wins. A body-level
    thematic-break '---' is never re-entered as frontmatter -- the scan stops
    the instant the frontmatter block closes (mirrors ef()'s
    "if (i > 1 && !in_fm) return ''" early-exit: nothing found before the
    close is nothing found, full stop).

    A field absent from the frontmatter (or a wholly frontmatter-less file)
    is simply absent from the returned dict. Never raises (NFR7); no I/O
    (pure text -> dict, mirrors parse_doc_frontmatter's own boundary).
    """
    result: dict[str, str] = {}
    in_fm = False
    fm_entered = False

    for line in text.splitlines():
        if _RE_FM_FENCE.match(line):
            if not fm_entered:
                # Opening fence
                in_fm = True
                fm_entered = True
                continue
            else:
                # Closing fence -- stop scanning entirely (never re-enter
                # frontmatter for a body-level thematic break).
                break

        if not in_fm:
            # No opening fence yet -- not in frontmatter (or no frontmatter at all)
            break

        for fld in _CONNECTOR_FM_FIELDS:
            if fld in result:
                continue  # first occurrence wins
            prefix = fld + ":"
            if line.startswith(prefix):
                val = line[len(prefix):].strip()
                if len(val) >= 1 and val[0] in "\"'":
                    val = val[1:]
                if len(val) >= 1 and val[-1] in "\"'":
                    val = val[:-1]
                result[fld] = val

    return result


def parse_connectors(connectors_dir: Path) -> "tuple[list[ConnectorRef], int]":
    """Enumerate <aid_dir>/connectors/*.md into a stem-sorted list[ConnectorRef].

    Uses the EXACT filter connector-registry.sh's `list` op uses
    (connector-registry.sh lines 151-154): `*.md` files directly under
    connectors_dir, excluding `INDEX.md` and dotfiles, sorted by stem. A
    missing connectors_dir -> [] (non-error; mirrors the script's own
    missing-root behavior).

    Per descriptor, extracts the six frontmatter scalars (name,
    connection_type, endpoint, auth_method, secret_reference, summary) via
    _parse_connector_frontmatter_scalars(). `name` defaults to the
    descriptor's own stem when absent (Data Model "human name; defaults to
    <stem>" -- the same default build-connectors-index.sh's ef()+fallback
    applies for its INDEX.md Connector column). `connection_type` is a raw,
    possibly-empty scalar (a required str field; the reader adds no enum).
    endpoint/auth_method/secret_reference/summary are None when absent from
    the descriptor.

    Never reads/serializes the secret VALUE or the `.secrets/` directory
    contents -- descriptor frontmatter only. Returns (refs, bytes_read).
    Never raises (NFR7).
    """
    if not connectors_dir.is_dir():
        return [], 0

    try:
        candidates = [
            p for p in connectors_dir.iterdir()
            if p.is_file() and p.name.endswith(".md")
            and p.name != "INDEX.md" and not p.name.startswith(".")
        ]
    except OSError:
        return [], 0

    candidates.sort(key=lambda p: p.stem)

    bytes_read = 0
    refs: list[ConnectorRef] = []
    for path in candidates:
        stem = path.stem
        try:
            raw = read_bytes_bounded(path)
            bytes_read += len(raw)
            text = raw.decode("utf-8", errors="replace")
        except OSError:
            text = ""

        fm = _parse_connector_frontmatter_scalars(text)
        name = fm.get("name") or stem
        connection_type = fm.get("connection_type", "")
        endpoint = fm.get("endpoint") or None
        auth_method = fm.get("auth_method") or None
        secret_reference = fm.get("secret_reference") or None
        summary = fm.get("summary") or None

        refs.append(ConnectorRef(
            stem=stem,
            name=name,
            connection_type=connection_type,
            endpoint=endpoint,
            auth_method=auth_method,
            secret_reference=secret_reference,
            summary=summary,
        ))

    return refs, bytes_read


# ---------------------------------------------------------------------------
# feature-010-external-sources-list (work-017 task-021): external-sources
# registry wrapper -- NO new frontmatter parser. A thin wrapper over the
# existing byte-parity-tested parse_doc_frontmatter() (line 586).
# ---------------------------------------------------------------------------

def parse_external_sources(kb_dir: Path) -> list[str]:
    """Return the deduped, order-preserved `sources:` entries of
    `<kb_dir>/external-sources.md`, with the discovery placeholder `(none)`
    filtered out.

    A thin wrapper -- NOT a new parser -- over the existing
    parse_doc_frontmatter(): takes its `sources_list`, drops the literal
    `(none)` placeholder entry, dedupes while preserving first-seen order, and
    returns the result. An absent/frontmatter-less file -> parse_doc_frontmatter
    already returns `[]` for sources_list, so this wrapper returns `[]` too
    (NFR-never-raises; no separate absent-file branch needed here).

    Reader-parity note (feature-010 SPEC): parse_doc_frontmatter's block-list
    continuation only matches CONTIGUOUS leading-whitespace "-" item lines --
    a comment or blank line between `sources:` and its items ends the block
    (and it does not strip a trailing inline `# comment` from a block item).
    The write-external-source.sh writer (task-020) normalizes the block to
    contiguous `  - <item>` lines directly under `sources:`, with no inline
    comment, so every dashboard-managed entry is reader-visible here (AC2).
    """
    _, sources_list, _ = parse_doc_frontmatter(kb_dir / "external-sources.md")
    seen: set[str] = set()
    result: list[str] = []
    for item in sources_list:
        if item == "(none)":
            continue
        if item in seen:
            continue
        seen.add(item)
        result.append(item)
    return result


# ---------------------------------------------------------------------------
# Prototype: REQUIREMENTS.md parser (work-overview header, delivery-002)
# ---------------------------------------------------------------------------

def parse_requirements_md(path: Path) -> tuple[Optional[str], Optional[str], Optional[str], int]:
    """Parse REQUIREMENTS.md for identity block fields.

    Returns (title, description, objective, bytes_read).
    All fields are None when the file is absent or the pattern is not found.
    Never raises (NFR7).

    Parses:
      - **Name:** value      -> title
      - **Description:** val -> description
      - ## 1. Objective (or ## Objective) body -> objective (until next ## heading)

    PF-2: lines matching ^>\\s*_.*_\\s*$ (status blockquote footer) are dropped
    from the Objective body so > _Status: ..._ never appears in objective.
    """
    if not path.is_file():
        return None, None, None, 0

    try:
        raw = read_bytes_bounded(path)
        bytes_read = len(raw)
        text = raw.decode("utf-8", errors="replace")
    except OSError:
        return None, None, None, 0

    title: Optional[str] = None
    description: Optional[str] = None
    objective: Optional[str] = None

    _re_name = re.compile(r"^\s*-\s*\*\*Name:\*\*\s*(.+)", re.IGNORECASE)
    _re_desc = re.compile(r"^\s*-\s*\*\*Description:\*\*\s*(.+)", re.IGNORECASE)
    _re_obj_hdr = re.compile(r"^##\s+(?:\d+\.\s+)?Objective\s*$", re.IGNORECASE)
    _re_section = re.compile(r"^##\s+\S")
    # PF-2: status blockquote footer shape: > _..._  (wholly italic blockquote)
    _re_status_blockquote = re.compile(r"^>\s*_.*_\s*$")

    lines = text.splitlines()
    in_objective = False
    obj_lines: list[str] = []

    # Template seed placeholder: treat *(pending)* as absent (PF-7)
    _PENDING_PLACEHOLDER = "*(pending)*"

    for line in lines:
        if in_objective:
            if _re_section.match(line):
                in_objective = False
            else:
                # PF-2: skip status blockquote lines (> _Status: ..._)
                if not _re_status_blockquote.match(line.strip() if line.strip() else line):
                    obj_lines.append(line)
            continue

        m = _re_name.match(line)
        if m and title is None:
            val = m.group(1).strip()
            title = None if val == _PENDING_PLACEHOLDER else val
            continue

        m = _re_desc.match(line)
        if m and description is None:
            val = m.group(1).strip()
            description = None if val == _PENDING_PLACEHOLDER else val
            continue

        if _re_obj_hdr.match(line):
            in_objective = True
            obj_lines = []
            continue

    if obj_lines:
        # Strip leading/trailing blank lines from the captured block
        raw_obj = "\n".join(obj_lines).strip()
        if raw_obj:
            objective = raw_obj

    return title, description, objective, bytes_read


# ---------------------------------------------------------------------------
# PF-8: SPEC.md parser (Lite-path identity fallback source)
# ---------------------------------------------------------------------------

def parse_spec_md(spec_path: Path) -> tuple[Optional[str], Optional[str], Optional[str], int]:
    """Parse work-root SPEC.md for identity fields (PF-8 Lite-path fallback).

    Returns (title, description, h1_title, bytes_read).
    - title: value from '- **Name:**' line (None if absent or *(pending)*)
    - description: value from '- **Description:**' line (None if absent or *(pending)*)
    - h1_title: text after the first '# ' line (None if absent)
    - bytes_read: number of bytes read

    Reuses the same _re_name/_re_desc regexes as parse_requirements_md and the
    *(pending)* null sentinel (PF-7). Never raises (NFR7).
    """
    if not spec_path.is_file():
        return None, None, None, 0

    try:
        raw = read_bytes_bounded(spec_path)
        bytes_read = len(raw)
        text = raw.decode("utf-8", errors="replace")
    except OSError:
        return None, None, None, 0

    _re_name = re.compile(r"^\s*-\s*\*\*Name:\*\*\s*(.+)", re.IGNORECASE)
    _re_desc = re.compile(r"^\s*-\s*\*\*Description:\*\*\s*(.+)", re.IGNORECASE)
    _re_h1 = re.compile(r"^#\s+(.+)$")

    # Template seed placeholder: treat *(pending)* as absent (PF-7)
    _PENDING_PLACEHOLDER = "*(pending)*"

    title: Optional[str] = None
    description: Optional[str] = None
    h1_title: Optional[str] = None

    for line in text.splitlines():
        if h1_title is None:
            m = _re_h1.match(line)
            if m:
                h1_title = m.group(1).strip()
                continue

        m = _re_name.match(line)
        if m and title is None:
            val = m.group(1).strip()
            title = None if val == _PENDING_PLACEHOLDER else val
            continue

        m = _re_desc.match(line)
        if m and description is None:
            val = m.group(1).strip()
            description = None if val == _PENDING_PLACEHOLDER else val
            continue

        # Stop scanning after we have all three fields
        if title is not None and description is not None and h1_title is not None:
            break

    return title, description, h1_title, bytes_read


# ---------------------------------------------------------------------------
# PF-3: Task short-name from tasks/task-NNN.md first line
# ---------------------------------------------------------------------------

def parse_task_short_name(task_path: Path) -> tuple[Optional[str], int]:
    """Parse the short-name from the first non-blank line of a task file.

    Reads only the first ~256 bytes (first-line-bounded read).
    Returns (short_name, bytes_read).
    short_name is None when absent or unparseable (PF-7 graceful).
    Never raises (NFR7).

    Parse rule (PF-3): ^#\\s+task-0*\\d+\\s*:\\s*(.+)$  (case-insensitive)
    Strips trailing period from the captured title.
    """
    if not task_path.is_file():
        return None, 0

    try:
        # Bounded read (5 MB cap; see io_bounds.py) covers long titles fine
        raw = read_bytes_bounded(task_path)
        bytes_read = len(raw)
        text = raw.decode("utf-8", errors="replace")
    except OSError:
        return None, 0

    _re_title = re.compile(r"^#\s+task-0*\d+\s*:\s*(.+)$", re.IGNORECASE)

    for line in text.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        m = _re_title.match(stripped)
        if m:
            title = m.group(1).strip().rstrip(".")
            return title if title else None, bytes_read
        # First non-blank line didn't match the pattern -> no short_name
        break

    return None, bytes_read


# ---------------------------------------------------------------------------
# PF-5: Execution graph from PLAN.md (wave-map + legacy prose fallback)
# ---------------------------------------------------------------------------

def parse_execution_graph(plan_path: Path) -> tuple[dict, int]:
    """Parse PLAN.md for wave-map blocks (PF-5a) with prose fallback (PF-5b).

    Returns (task_lane_map, bytes_read) where:
      task_lane_map: dict mapping task_id -> lane (int or None)

    Note: delivery comes from STATE Wave column (PF-5c); this function only
    derives the lane number within a delivery.

    PF-5a (normalized): scans for ```wave-map fences; reads delivery: NNN +
    wave N: task-001, ... lines.
    PF-5b (prose fallback): when no wave-map found for a delivery section,
    parses - Wave N: lines (including sub-bullets) to extract task ids and
    their lane numbers.

    Never raises (NFR7). Returns ({}, 0) when PLAN.md absent.
    """
    if not plan_path.is_file():
        return {}, 0

    try:
        raw = read_bytes_bounded(plan_path)
        bytes_read = len(raw)
        text = raw.decode("utf-8", errors="replace")
    except OSError:
        return {}, 0

    task_lane_map: dict[str, int] = {}

    lines = text.splitlines()

    # --- PF-5a: scan for wave-map fenced blocks ---
    _re_wavemap_open = re.compile(r"^```wave-map\s*$")
    _re_wavemap_close = re.compile(r"^```\s*$")
    _re_delivery_line = re.compile(r"^delivery:\s*(\d+)\s*$")
    _re_wave_line = re.compile(r"^wave\s+(\d+)\s*:\s*(.+)$", re.IGNORECASE)
    _re_task_id = re.compile(r"\btask-\d+\b", re.IGNORECASE)

    # Wave-map blocks found: set of delivery numbers that have a wave-map
    wavemap_deliveries: set[int] = set()

    i = 0
    n = len(lines)
    while i < n:
        line = lines[i]
        if _re_wavemap_open.match(line.strip()):
            # Read block until closing fence
            i += 1
            block_delivery: Optional[int] = None
            while i < n:
                bline = lines[i].strip()
                if _re_wavemap_close.match(bline):
                    i += 1
                    break
                dm = _re_delivery_line.match(bline)
                if dm:
                    block_delivery = int(dm.group(1))
                    if block_delivery is not None:
                        wavemap_deliveries.add(block_delivery)
                    i += 1
                    continue
                wm = _re_wave_line.match(bline)
                if wm:
                    lane = int(wm.group(1))
                    tasks_str = wm.group(2)
                    for tid_match in _re_task_id.finditer(tasks_str):
                        tid = tid_match.group(0).lower()
                        task_lane_map[tid] = lane
                    i += 1
                    continue
                i += 1
        else:
            i += 1

    # --- PF-5b: prose fallback for delivery sections with no wave-map ---
    # Parse - Wave N: lines and collect sub-bullets
    _re_delivery_section = re.compile(
        r"^###\s+delivery-(\d+)\s+execution\s+graph", re.IGNORECASE
    )
    _re_wave_prose = re.compile(r"^(\s*)-\s*Wave\s+(\d+)\b", re.IGNORECASE)

    current_delivery: Optional[int] = None
    current_wave: Optional[int] = None
    wave_indent: Optional[int] = None  # indent level of the - Wave N: bullet
    # Track tasks already placed by wave-map (don't overwrite with prose)
    wavemap_task_ids: set[str] = set(task_lane_map.keys())

    for line in lines:
        # Detect delivery section header (for tracking current delivery context)
        dm = _re_delivery_section.match(line)
        if dm:
            current_delivery = int(dm.group(1))
            current_wave = None
            wave_indent = None
            continue

        # Only run prose fallback for deliveries WITHOUT a wave-map
        if current_delivery is None or current_delivery in wavemap_deliveries:
            current_wave = None
            wave_indent = None
            continue

        # Detect Wave N: prose heading
        wm = _re_wave_prose.match(line)
        if wm:
            current_wave = int(wm.group(2))
            wave_indent = len(wm.group(1))  # indent of the "- Wave N" line
            # Collect task ids from the heading line itself
            for tid_match in _re_task_id.finditer(line):
                tid = tid_match.group(0).lower()
                if tid not in wavemap_task_ids:
                    task_lane_map[tid] = current_wave
            continue

        # Collect task ids from sub-bullets (more-indented than the Wave heading)
        if current_wave is not None and wave_indent is not None:
            line_indent = len(line) - len(line.lstrip())
            # Sub-bullet must be more-indented than the wave heading
            if line_indent > wave_indent and line.strip():
                # Stop on a new Wave heading at the same or shallower indent (handled above)
                # Collect task ids from this sub-bullet
                for tid_match in _re_task_id.finditer(line):
                    tid = tid_match.group(0).lower()
                    if tid not in wavemap_task_ids:
                        task_lane_map[tid] = current_wave
            elif line.strip() == "":
                # Blank line: maintain current wave for following sub-bullets
                pass
            elif line_indent <= wave_indent and line.strip():
                # Dedented non-blank line ends the current wave's sub-bullets
                current_wave = None
                wave_indent = None

    return task_lane_map, bytes_read


# ---------------------------------------------------------------------------
# Level-2: STATE.yml parser -- structured document read (work-009-refactor
# task-003). The legacy section-header regexes and the section state machine
# that used to scan '## Pipeline State' / '## Tasks State' / '## Cross-phase
# Q&A' / '## Triage' / '## Features State' / '## Plan / Deliveries' /
# '## Lifecycle History' prose are GONE: parse_state_document already turned
# the whole file into a nested dict, so parse_state_md below is now
# parse-document-then-map-keys, not a markdown scanner.
# ---------------------------------------------------------------------------

# Tasks table separator row detector -- still needed by parse_deferred_issues
# (delivery-NNN-issues.md stays a markdown table; out of scope for this task).
_RE_TABLE_SEP  = re.compile(r"^\|[\s\-|]+\|$")
# Placeholder row
_NONE_YET      = "_none yet_"


def parse_state_md(
    text: str,
    work_id: str = "",
    work_dir: Optional[Path] = None,
) -> ParsedWork:
    """Parse a work-root STATE.yml document into a ParsedWork.

    Parse-document-then-map-keys (work-009-refactor task-003): the whole file
    is parsed ONCE by parse_state_document (§ D-3 subset engine) into a
    nested dict; `_apply_pipeline_frontmatter` / `_apply_identity_frontmatter`
    then map that dict's keys onto `pw` -- together they ARE the whole of
    this function now (no more markdown section state machine).

    Three things this function still does, beyond the two _apply_* mappers:
      - falls back to derive_lifecycle() (LC-3, UNCHANGED) when the document
        carries no `lifecycle` key at all (an absent/empty/truncated file);
      - reads `lifecycle_history` for the work's `created` date (the first
        entry whose `event` is "Work created", newest-last per the template);
      - reads `qa` for pending_inputs (flattened-Lite-only AUTHORED Cross-phase
        Q&A; DERIVED on the full path, where no `qa` key is present at all).

    work_dir is required for the fallback IMPEDIMENT scan (KI-003, unchanged
    derive_lifecycle behavior); if absent, the IMPEDIMENT check is skipped.

    This function is pure (text-only) when work_dir is None. When work_dir is
    supplied it performs one filesystem scan for IMPEDIMENT files; no writes.
    """
    pw = ParsedWork()
    label = f"{work_id}/STATE.yml" if work_id else "STATE.yml"
    data, warnings = parse_state_document(text, file_label=label)
    pw.parse_warnings.extend(warnings)

    # § D-3 subset engine already turned the document into a dict; map its
    # keys onto pw. `lifecycle_present` mirrors the old `pipeline_status_found
    # or fm_lifecycle_present` decision -- there is no more legacy prose
    # section, so a `lifecycle` key's presence IS the normalized signal.
    lifecycle_present = _apply_pipeline_frontmatter(data, pw)

    # `lifecycle_history` (AUTHORED) is read once here -- before the fallback
    # branch below -- so its ALREADY-parsed sequence can supply the coarse-
    # `updated` fallback value without a second file read or raw-text re-scan
    # (SP-10; KI-004, work-009-refactor task-021). Reused again further down
    # for pw.created.
    lifecycle_history = data.get("lifecycle_history")

    if lifecycle_present:
        pw.source_mode = SourceMode.Normalized
    else:
        # LC-3 FALLBACK ADAPTER (task-011, audited task-013 M6; derivation.py's
        # own body is out of this task's edit surface beyond threading this one
        # value): no `lifecycle` key at all -- absent/empty/truncated document.
        # derive_lifecycle scans legacy markdown signals (IMPEDIMENT files, task
        # rollup, Q&A, Deploy Status); against a YAML document it finds none of
        # those and returns Unknown/Fallback -- a safe no-op that still
        # satisfies "best-effort model, never raises" (SP-9). The coarse-
        # `updated` slot, though, is computed from the STRUCTURED
        # lifecycle_history sequence (twin of reader.mjs's
        # computeLatestHistoryDate()), not re-derived per branch inside
        # derive_lifecycle -- see _compute_latest_history_date's docstring.
        _wd = work_dir if work_dir is not None else Path(".")
        latest_history_date = _compute_latest_history_date(lifecycle_history)
        (
            pw.lifecycle,
            pw.source_mode,
            pw.pause_reason,
            pw.block_reason,
            pw.block_artifact,
            fallback_updated,
            extra_warnings,
        ) = derive_lifecycle(
            work_dir=_wd,
            tasks=pw.tasks,
            pending_inputs=pw.pending_inputs,
            state_text=text,
            work_id=work_id,
            latest_history_date=latest_history_date,
        )
        if pw.updated is None:
            pw.updated = fallback_updated
        pw.parse_warnings.extend(extra_warnings)

    _apply_identity_frontmatter(data, pw)

    # `lifecycle_history` (AUTHORED) -> pw.created: the first entry (append-
    # only, newest LAST per the template) whose `event` is "Work created".
    if isinstance(lifecycle_history, list):
        for entry in lifecycle_history:
            if not isinstance(entry, dict):
                continue
            event = entry.get("event")
            if isinstance(event, str) and event.strip().lower() == "work created":
                date_val = entry.get("date")
                if isinstance(date_val, str) and not _is_null(date_val):
                    pw.created = date_val
                break

    # `qa` (flattened-Lite-only AUTHORED Cross-phase Q&A; absent/DERIVED on
    # the full path, where reader.py's hierarchical assembly unions per-
    # delivery Q&A instead) -> pending_inputs, Pending entries only.
    qa_list = data.get("qa")
    if isinstance(qa_list, list):
        for entry in qa_list:
            if not isinstance(entry, dict):
                continue
            state_val = entry.get("state")
            if isinstance(state_val, str) and state_val.strip().lower() == "pending":
                pw.pending_inputs.append(PendingInput(
                    question_id=_qa_question_id(entry.get("id")),
                    category=_none_if_null(entry.get("category")),
                    impact=_none_if_null(entry.get("impact")),
                    context=_none_if_null(entry.get("context")),
                    suggested=_none_if_null(entry.get("suggested")),
                ))

    return pw


# ---------------------------------------------------------------------------
# Hierarchical per-unit STATE.yml parsers (work-004 Pillar 1/2/6; structured
# document read since work-009-refactor task-003)
#
# These parsers read the TASK-LEVEL and DELIVERY-LEVEL STATE.yml files
# produced by the uniform unit hierarchy (full-nested and lite-flat layouts;
# see reader.py _detect_hierarchy):
#   Full-nested: deliveries/delivery-NNN/tasks/task-NNN/STATE.yml -- task cells
#                deliveries/delivery-NNN/STATE.yml -- delivery lifecycle + gate + Q&A
#   Lite-flat:   the work-root STATE.yml's own `tasks_lifecycle` mapping (task
#                cells) and `delivery_lifecycle` / `delivery_gate` / `qa` keys
#                (the single implicit delivery's lifecycle/gate/Q&A)
#
# They are ONLY called when hierarchy detection fires (_detect_hierarchy in
# reader.py). Legacy (monolithic pre-conversion) works never reach these --
# a work directory holding a STATE.md with no sibling STATE.yml is diagnosed
# by reader.py's legacy detection instead (SP-9), not parsed here.
# ---------------------------------------------------------------------------

# Valid SD-8 delivery lifecycle enum values (Pillar 1 / SD-8)
_DELIVERY_STATE_VALUES = frozenset({
    "Pending-Spec", "Specified", "Executing", "Gated", "Done", "Blocked",
})


class ParsedTaskState:
    """Parsed result for one task-level STATE.yml (task-NNN/STATE.yml).

    Covers: state / review / elapsed / notes / display_name (top-level
    scalars), plus the AUTHORED `quick_check` (reviewer_tier + findings) and
    `dispatch_log` structures that exist only at this level (§ D-4 note).
    Used by the hierarchical reader path only.
    """
    __slots__ = (
        "state", "review", "elapsed", "notes", "display_name",
        "quick_check_reviewer_tier", "quick_check_findings", "dispatch_log",
        "parse_warnings",
    )

    def __init__(self) -> None:
        self.state: TaskStatus = TaskStatus.Unknown
        self.review: Optional[str] = None
        self.elapsed: Optional[str] = None
        self.notes: Optional[str] = None
        self.display_name: Optional[str] = None
        self.quick_check_reviewer_tier: Optional[str] = None
        self.quick_check_findings: list["Finding"] = []
        self.dispatch_log: list[dict] = []
        self.parse_warnings: list[str] = []


class ParsedDeliveryState:
    """Parsed result for one delivery-level STATE.yml (delivery-NNN/STATE.yml).

    Covers:
      - delivery_state: SD-8 lifecycle enum (authored, not derived from tasks)
      - updated, block_reason, block_artifact from `delivery_lifecycle`
      - delivery_gate_issue_list from `delivery_gate.issue_list`
      - pending_inputs from `qa` (Pending entries)
      - tasks: [] always (the derived Tasks State rollup is never authored in
        this file; kept only so the reader.py call sites that read `pds.tasks`
        need no change -- always empty, exactly the pre-existing behavior for
        a current-shape file, § L-12)
    Used by the hierarchical reader path only.
    """
    __slots__ = (
        "delivery_state", "updated", "block_reason", "block_artifact",
        "gate_grade", "gate_reviewer_tier", "gate_timestamp",
        "delivery_gate_issue_list", "pending_inputs", "tasks", "parse_warnings",
    )

    def __init__(self) -> None:
        self.delivery_state: Optional[str] = None
        self.updated: Optional[str] = None
        self.block_reason: Optional[str] = None
        self.block_artifact: Optional[str] = None
        self.gate_grade: Optional[str] = None
        self.gate_reviewer_tier: Optional[str] = None
        self.gate_timestamp: Optional[str] = None
        self.delivery_gate_issue_list: list[str] = []
        self.pending_inputs: list[PendingInput] = []
        self.tasks: list[TaskModel] = []
        self.parse_warnings: list[str] = []


def parse_task_state_md(
    text: str,
    task_id: str = "",
) -> ParsedTaskState:
    """Parse a task-level STATE.yml into a ParsedTaskState.

    Structured read (work-009-refactor task-003; no prose fallback -- a
    legacy STATE.md this task belongs to is diagnosed at the work level
    before this function is ever reached, SP-9): the whole document is
    parsed once by parse_state_document, then every top-level scalar and the
    `quick_check` / `dispatch_log` structures are read directly by key.

    The closed State enum values are the same as the work-level TaskStatus enum
    (Pending | In Progress | In Review | Blocked | Done | Failed | Canceled).

    Read-only; never throws (parse_warnings on error). Called only by the
    hierarchical reader path for a task-NNN/STATE.yml file (full-nested:
    deliveries/delivery-NNN/tasks/task-NNN/STATE.yml).
    """
    pts = ParsedTaskState()

    try:
        label = f"{task_id}/STATE.yml" if task_id else "STATE.yml"
        data, warnings = parse_state_document(text, file_label=label)
        pts.parse_warnings.extend(warnings)

        v = data.get("state")
        if isinstance(v, str) and not _is_null(v):
            pts.state = _parse_task_status(v.strip())

        v = data.get("review")
        if isinstance(v, str):
            pts.review = None if _is_null(v) else v

        v = data.get("elapsed")
        if isinstance(v, str):
            pts.elapsed = None if _is_null(v) else v

        v = data.get("notes")
        if isinstance(v, str):
            pts.notes = None if _is_null(v) else v

        v = data.get("display_name")
        if isinstance(v, str):
            pts.display_name = None if _is_null(v) else v

        quick_check = data.get("quick_check")
        if isinstance(quick_check, dict):
            tier = quick_check.get("reviewer_tier")
            if isinstance(tier, str) and not _is_null(tier):
                pts.quick_check_reviewer_tier = tier
            raw_findings = quick_check.get("findings")
            if isinstance(raw_findings, list):
                for f in raw_findings:
                    if not isinstance(f, dict):
                        continue
                    severity_raw = f.get("severity")
                    pts.quick_check_findings.append(Finding(
                        severity=_parse_severity(severity_raw if isinstance(severity_raw, str) else ""),
                        description=(f.get("description") or "").strip() if isinstance(f.get("description"), str) else "",
                        location=_none_if_null(f.get("source")),
                        disposition=_none_if_null(f.get("disposition")),
                        reviewer_tier=pts.quick_check_reviewer_tier,
                    ))

        dispatch_log = data.get("dispatch_log")
        if isinstance(dispatch_log, list):
            pts.dispatch_log = [d for d in dispatch_log if isinstance(d, dict)]

    except Exception as exc:  # noqa: BLE001 -- never throws (NFR7)
        pts.parse_warnings.append(
            f"{task_id}: error parsing task STATE.yml ({exc}); "
            f"returning best-effort task state"
        )

    return pts


def parse_delivery_state_md(
    text: str,
    delivery_id: str = "",
) -> ParsedDeliveryState:
    """Parse a delivery-level STATE.yml into a ParsedDeliveryState.

    Structured read (work-009-refactor task-003; no prose fallback): the
    whole document is parsed once by parse_state_document, then:
      - `delivery_state` (top-level scalar, SD-8 enum)
      - `gate_tier` / `gate_grade` / `gate_timestamp` (top-level scalars)
      - `delivery_lifecycle.updated` / `.block_reason` / `.block_artifact`
      - `delivery_gate.issue_list`
      - `qa` -> pending_inputs (Pending entries only)

    The delivery_state is the INDEPENDENTLY AUTHORED SD-8 enum
    (Pending-Spec | Specified | Executing | Gated | Done | Blocked). It is
    NOT derived from the task rollup (SD-9); `pds.tasks` stays [] always (the
    derived Tasks State rollup is never authored in this file -- reader.py
    assembles it from the per-task hierarchy, not from this parser).

    Read-only; never throws (parse_warnings on error). Called only by the
    hierarchical reader path -- for full-nested works with the delivery-level
    deliveries/delivery-NNN/STATE.yml text; for lite-flat works with the
    work-root STATE.yml text itself (the single implicit delivery's
    lifecycle/gate/Q&A are AUTHORED directly in the work-root file for lite
    works, so the same structured read applies to either text -- see
    reader.py _read_work_hierarchical / _read_work_flat).
    """
    pds = ParsedDeliveryState()

    try:
        label = f"{delivery_id}/STATE.yml" if delivery_id else "STATE.yml"
        data, warnings = parse_state_document(text, file_label=label)
        pds.parse_warnings.extend(warnings)

        v = data.get("delivery_state")
        if isinstance(v, str) and not _is_null(v):
            raw = v.strip()
            if raw in _DELIVERY_STATE_VALUES:
                pds.delivery_state = raw
            else:
                pds.parse_warnings.append(
                    f"{delivery_id}: unknown delivery_state '{raw}'; "
                    f"expected one of {sorted(_DELIVERY_STATE_VALUES)}"
                )

        v = data.get("gate_tier")
        if isinstance(v, str) and not _is_null(v):
            split = v.strip().split()
            if split:
                pds.gate_reviewer_tier = split[0]

        v = data.get("gate_grade")
        if isinstance(v, str) and not _is_null(v):
            split = v.strip().split()
            # Treat "Pending" placeholder as absent grade (pre-existing rule).
            if split and split[0].lower() != "pending":
                pds.gate_grade = split[0]

        v = data.get("gate_timestamp")
        if isinstance(v, str) and not _is_null(v):
            pds.gate_timestamp = v.strip()

        delivery_lifecycle = data.get("delivery_lifecycle")
        if isinstance(delivery_lifecycle, dict):
            v = delivery_lifecycle.get("updated")
            if isinstance(v, str):
                pds.updated = None if _is_null(v) else v
            v = delivery_lifecycle.get("block_reason")
            if isinstance(v, str):
                pds.block_reason = None if _is_null(v) else v
            v = delivery_lifecycle.get("block_artifact")
            if isinstance(v, str):
                pds.block_artifact = None if _is_null(v) else v

        delivery_gate = data.get("delivery_gate")
        if isinstance(delivery_gate, dict):
            issue_list = delivery_gate.get("issue_list")
            if isinstance(issue_list, list):
                pds.delivery_gate_issue_list = [i for i in issue_list if isinstance(i, str)]

        qa_list = data.get("qa")
        if isinstance(qa_list, list):
            for entry in qa_list:
                if not isinstance(entry, dict):
                    continue
                state_val = entry.get("state")
                if isinstance(state_val, str) and state_val.strip().lower() == "pending":
                    pds.pending_inputs.append(PendingInput(
                        question_id=_qa_question_id(entry.get("id")),
                        category=_none_if_null(entry.get("category")),
                        impact=_none_if_null(entry.get("impact")),
                        context=_none_if_null(entry.get("context")),
                        suggested=_none_if_null(entry.get("suggested")),
                    ))

    except Exception as exc:  # noqa: BLE001 -- never throws (NFR7)
        pds.parse_warnings.append(
            f"{delivery_id}: error parsing delivery STATE.yml ({exc}); "
            f"returning best-effort delivery state"
        )

    return pds


# ---------------------------------------------------------------------------
# feature-001 (flattened single-delivery layout): `tasks_lifecycle` mapping read
#
# The flat layout has no per-task STATE.yml and no per-delivery STATE.yml --
# the promoted `delivery_lifecycle` / `delivery_gate` keys (read above via
# parse_delivery_state_md, unchanged) plus a `tasks_lifecycle` mapping
# (keyed by task-NNN, § D-3 shape S3) live directly in the work-root
# STATE.yml. This mapping REPLACES the per-task STATE.yml's top-level
# scalars for the flattened path.
#
# Called ONLY by the flat reader path (_read_work_flat in reader.py). The
# ParsedTaskState return shape is UNCHANGED so reader.py:1132 (now the
# _read_work_flat call site) needs no change.
# ---------------------------------------------------------------------------

def parse_tasks_lifecycle_md(text: str) -> "tuple[dict[str, ParsedTaskState], list[str]]":
    """Parse the work-root STATE.yml `tasks_lifecycle` mapping (flat layout).

    Each entry: task-NNN: {state, review, elapsed, notes, display_name}.

    Returns (task_id_lower -> ParsedTaskState, parse_warnings). Unrecognized
    state literals map to TaskStatus.Unknown (never throws, NFR7).

    Read-only. Called only by the flat reader path.
    """
    result: dict[str, ParsedTaskState] = {}
    warnings: list[str] = []

    try:
        data, doc_warnings = parse_state_document(text, file_label="STATE.yml")
        warnings.extend(doc_warnings)

        tasks_lifecycle = data.get("tasks_lifecycle")
        if isinstance(tasks_lifecycle, dict):
            for task_id, fields in tasks_lifecycle.items():
                if not isinstance(fields, dict):
                    continue

                def _field(name: str) -> Optional[str]:
                    v = fields.get(name)
                    if isinstance(v, str):
                        return None if _is_null(v) else v
                    return None

                pts = ParsedTaskState()
                pts.state = _parse_task_status(_field("state") or "")
                pts.review = _field("review")
                pts.elapsed = _field("elapsed")
                pts.notes = _field("notes")
                pts.display_name = _field("display_name")
                result[str(task_id).lower()] = pts

    except Exception as exc:  # noqa: BLE001 -- never throws (NFR7)
        warnings.append(
            f"error parsing 'tasks_lifecycle' mapping ({exc}); returning best-effort"
        )

    return result, warnings


# ---------------------------------------------------------------------------
# Structured document -> ParsedWork mapping (work-009-refactor task-003)
#
# Applied AFTER the legacy prose line-scan (parse_state_md), so the frontmatter
# (the newer, authoritative source) wins whenever both are present. Absent
# frontmatter keys never regress a prose-derived value to null -- each field is
# only overridden when its frontmatter key is itself present and non-null.
# ---------------------------------------------------------------------------

def _apply_pipeline_frontmatter(data: dict, pw: ParsedWork) -> bool:
    """Map the document's top-level pipeline-state scalar keys onto pw.

    Returns True iff the 'lifecycle' key was present with a valid (non-null)
    value -- the caller (parse_state_md) uses this to decide source_mode
    (Normalized iff present; Fallback -- via derive_lifecycle -- otherwise).
    """
    lifecycle_present = False

    v = data.get("lifecycle")
    if isinstance(v, str) and not _is_null(v):
        pw.lifecycle = _parse_lifecycle(v.strip())
        lifecycle_present = True

    v = data.get("phase")
    if isinstance(v, str) and not _is_null(v):
        pw.phase = _parse_phase(v.strip())

    v = data.get("active_skill")
    if isinstance(v, str):
        vv = v.strip()
        pw.active_skill = None if (_is_null(vv) or vv.lower() == "none") else vv

    v = data.get("updated")
    if isinstance(v, str) and not _is_null(v):
        pw.updated = v.strip()

    v = data.get("pause_reason")
    if isinstance(v, str):
        vv = v.strip()
        pw.pause_reason = None if _is_null(vv) else vv

    v = data.get("block_reason")
    if isinstance(v, str):
        vv = v.strip()
        pw.block_reason = None if _is_null(vv) else vv

    v = data.get("block_artifact")
    if isinstance(v, str):
        vv = v.strip()
        pw.block_artifact = None if _is_null(vv) else vv

    return lifecycle_present


def _apply_identity_frontmatter(data: dict, pw: ParsedWork) -> None:
    """Map the document's pipeline-identity + captured-scalar keys onto pw:
    `pipeline.path` -> work_path, `pipeline.initiator` -> kind, `started`,
    `minimum_grade`, `user_approved`. No legacy header-blockquote fallback
    remains -- a legacy STATE.md is diagnosed at the work level (SP-9)
    before this function is ever reached.
    """
    pipeline = data.get("pipeline")
    if isinstance(pipeline, dict):
        v = pipeline.get("path")
        if isinstance(v, str) and not _is_null(v):
            pw.work_path = v.strip().lower()

        v = pipeline.get("initiator")
        if isinstance(v, str) and not _is_null(v):
            pw.kind = resolve_kind(v.strip())

    # started (top-level scalar). pw.created is ALSO backfilled from it so
    # existing consumers (home.html work.created, the JSON 'created' key)
    # keep working unchanged -- `lifecycle_history`'s "Work created" entry
    # (read by the caller, parse_state_md) overrides this when present.
    v = data.get("started")
    if isinstance(v, str) and not _is_null(v):
        started_val = v.strip()
        pw.started = started_val
        pw.created = started_val

    v = data.get("minimum_grade")
    if isinstance(v, str) and not _is_null(v):
        pw.minimum_grade = v.strip().upper()

    # user_approved: 'yes'/'no'/'true'/'false' (case-insensitive) -> bool.
    # Work-level approval, distinct from the KB's summary_approved
    # (parse_kb_state, a different file entirely).
    v = data.get("user_approved")
    if isinstance(v, str):
        pw.user_approved = parse_bool_yesno(v)


# ---------------------------------------------------------------------------
# Null-value helper
# ---------------------------------------------------------------------------

# Null/absent sentinels used in the STATE.yml templates:
#   -   single dash (early template style)
#   --  double dash (common in task-status tables)
#   —   em-dash (Unicode U+2014, used in some fields)
_NULL_SENTINELS = frozenset(("-", "--", "—", ""))


def _none_if_null(val: object) -> Optional[str]:
    """Return None for a null-sentinel-or-non-string value, else the string."""
    if not isinstance(val, str):
        return None
    return None if _is_null(val) else val


def _qa_question_id(raw_id: object) -> str:
    """Format a `qa[].id` value as the historical 'Q{N}' display form.

    The § D-4 `qa` schema's `id` field is a bare number (or, defensively, an
    already-'Q'-prefixed token from a hand-edited file); PendingInput.question_id
    keeps the pre-refactor 'Q1'/'Q2' convention (models.py, unchanged) so every
    existing consumer (home.html, derivation.py's pause-reason Q-id list, the
    reconcile dedup key) keeps working unchanged.
    """
    if raw_id is None:
        return ""
    s = str(raw_id).strip()
    if not s:
        return ""
    if s[0].lower() == "q":
        return s
    return f"Q{s}"


def _is_null(val: str) -> bool:
    """Return True when the value represents an absent / not-applicable field."""
    return val in _NULL_SENTINELS


def _compute_latest_history_date(lifecycle_history: object) -> Optional[str]:
    """max(lifecycle_history[].date) over the ALREADY-parsed sequence (KI-004,
    work-009-refactor task-021). Twin of reader.mjs's computeLatestHistoryDate().

    Supplies derive_lifecycle's coarse-`updated` fallback slot. No second file read
    and no raw-text re-scan (SP-10): the sequence is already in hand at the call
    site (parse_state_md). Skips entries that are not dicts, `date` values that are
    not strings, and null-sentinel `date` values (`--` etc.) -- none of those may win
    the comparison. Returns None if lifecycle_history is not a list or yields no
    usable date.
    """
    if not isinstance(lifecycle_history, list):
        return None
    latest: Optional[str] = None
    for entry in lifecycle_history:
        if not isinstance(entry, dict):
            continue
        date_val = entry.get("date")
        if isinstance(date_val, str) and not _is_null(date_val):
            d = date_val.strip()
            if d and (latest is None or d > latest):
                latest = d
    return latest


# ---------------------------------------------------------------------------
# Enum parsing helpers
# ---------------------------------------------------------------------------

# Mapping from on-disk literal -> Lifecycle enum member (verbatim, SM-2)
_LIFECYCLE_MAP: dict[str, Lifecycle] = {
    "Running": Lifecycle.Running,
    "Paused-Awaiting-Input": Lifecycle.PausedAwaitingInput,
    "Blocked": Lifecycle.Blocked,
    "Completed": Lifecycle.Completed,
    "Canceled": Lifecycle.Canceled,
}

# Phase mapping (faithful numbered pipeline; ends at Execute).
_PHASE_MAP: dict[str, Phase] = {
    "Describe": Phase.Describe,
    "Define": Phase.Define,
    "Specify": Phase.Specify,
    "Plan": Phase.Plan,
    "Detail": Phase.Detail,
    "Execute": Phase.Execute,
}

# TaskStatus mapping (feature-001 M3 closed enum)
_TASK_STATUS_MAP: dict[str, TaskStatus] = {
    "Pending": TaskStatus.Pending,
    "In Progress": TaskStatus.InProgress,
    "In Review": TaskStatus.InReview,
    "Blocked": TaskStatus.Blocked,
    "Done": TaskStatus.Done,
    "Failed": TaskStatus.Failed,
    "Canceled": TaskStatus.Canceled,
}


def _parse_lifecycle(raw: str) -> Lifecycle:
    """Return the Lifecycle enum for a raw string literal (verbatim, SM-2 preferred path).

    Unknown -> Lifecycle.Unknown (reader-only sentinel; DM-6).
    """
    return _LIFECYCLE_MAP.get(raw, Lifecycle.Unknown)


def _parse_phase(raw: str) -> Phase:
    """Return the Phase enum for a raw string literal.

    Unknown -> Phase.Unknown (reader-only sentinel; DM-6).
    """
    return _PHASE_MAP.get(raw, Phase.Unknown)


def _parse_task_status(raw: str) -> TaskStatus:
    """Return the TaskStatus enum for a raw string literal.

    Unknown -> TaskStatus.Unknown (reader-only sentinel; DM-6).
    """
    return _TASK_STATUS_MAP.get(raw, TaskStatus.Unknown)


# ---------------------------------------------------------------------------
# LC-TR: TaskDetail sub-parsers (feature-008, task-069)
# Detail-only: these run ONLY when detail_task_ids is supplied to read_repo_detail().
# The always-on read_repo() path does NOT call any function below.
# No write / no LLM / no subprocess (NFR2/NFR7).
# ---------------------------------------------------------------------------

# Severity normalization: only CRITICAL and HIGH; all others -> MINOR neutral
_KNOWN_SEVERITIES = frozenset({"[CRITICAL]", "[HIGH]"})


def _parse_severity(tag: str) -> str:
    """Normalize a severity tag to [CRITICAL], [HIGH], or [MINOR] (neutral fallback).

    Accepts either the bracketed legacy-bullet form ('[HIGH]') or the bare
    § D-4 structured-field form ('HIGH', the on-disk `quick_check.findings[].
    severity` value -- no brackets, per the task-state-template.yml comment
    "severity: CRITICAL | HIGH"). Mirrors feature-002 DM-6: lower/unknown ->
    [MINOR] neutral, never throws (NFR7).
    """
    normalized = tag.upper().strip()
    if not normalized.startswith("["):
        normalized = f"[{normalized}]"
    if normalized in ("[CRITICAL]", "[HIGH]"):
        return normalized
    return "[MINOR]"


def parse_quick_check_findings(
    state_text: str,
    task_id: str,
    parse_warnings: list[str],
) -> list[Finding]:
    """DR-2: Read `quick_check.findings` for the given task_id.

    Retargeted to keys (work-009-refactor task-003, § D-4 note): `quick_check`
    exists ONLY in a per-task STATE.yml (`deliveries/delivery-NNN/tasks/
    task-NNN/STATE.yml`), never in the work-root file `state_text` is always
    called with here (`reader.py:716`, via the always-on pass's state-text
    cache -- DR-1/NFR4, no re-read). So `data.get('quick_check')` is always
    absent for a current-shape work and this still returns [] -- pre-existing
    staleness preserved, not repaired (§ L-12).

    Returns a list of Finding objects for the given task_id.
    A clean task (no block or empty findings list) -> returns [] (not an error).
    Torn/missing document -> parse_warning + best-effort (never throws, NFR7).
    """
    findings: list[Finding] = []

    try:
        data, doc_warnings = parse_state_document(
            state_text, file_label=f"{task_id}/STATE.yml"
        )
        parse_warnings.extend(doc_warnings)

        quick_check = data.get("quick_check")
        if isinstance(quick_check, dict):
            reviewer_tier_raw = quick_check.get("reviewer_tier")
            reviewer_tier = (
                reviewer_tier_raw if isinstance(reviewer_tier_raw, str) else None
            )
            raw_findings = quick_check.get("findings")
            if isinstance(raw_findings, list):
                for f in raw_findings:
                    if not isinstance(f, dict):
                        continue
                    severity_raw = f.get("severity")
                    description_raw = f.get("description")
                    findings.append(Finding(
                        severity=_parse_severity(severity_raw if isinstance(severity_raw, str) else ""),
                        description=description_raw.strip() if isinstance(description_raw, str) else "",
                        location=_none_if_null(f.get("source")),
                        disposition=_none_if_null(f.get("disposition")),
                        reviewer_tier=reviewer_tier,
                    ))

    except Exception as exc:  # noqa: BLE001 -- never throws (NFR7)
        parse_warnings.append(
            f"{task_id}: error parsing 'quick_check' ({exc}); "
            f"returning best-effort findings"
        )

    return findings


def parse_delivery_gate(
    state_text: str,
    delivery_id: str,
    parse_warnings: list[str],
) -> tuple[Optional[str], Optional[str], Optional[str]]:
    """DR-3: Read `delivery_gate` (+ top-level `gate_grade`/`gate_tier`/
    `gate_timestamp`) for grade/tier/timestamp.

    Retargeted to keys (work-009-refactor task-003). `state_text` here is
    always the work-root document (`reader.py:733`, via the state-text cache
    -- DR-1/NFR4, no re-read); `delivery_gate` only ever carries `issue_list`
    (§ D-4), so `delivery_gate.grade`/`.reviewer_tier`/`.gate_timestamp` are
    always absent, and this still returns (None, None, None) for a current-
    shape work -- pre-existing staleness preserved, not repaired (§ L-12).

    Returns (grade, reviewer_tier, gate_timestamp). All None if absent.
    Verbatim -- never re-grades (NFR7). Never throws (torn -> parse_warning + None).
    """
    grade: Optional[str] = None
    reviewer_tier: Optional[str] = None
    gate_timestamp: Optional[str] = None

    try:
        data, doc_warnings = parse_state_document(
            state_text, file_label=f"{delivery_id}/STATE.yml"
        )
        parse_warnings.extend(doc_warnings)

        gate = data.get("delivery_gate")
        if isinstance(gate, dict):
            v = gate.get("grade")
            if isinstance(v, str) and v.strip():
                grade = v.strip().split()[0]
            v = gate.get("reviewer_tier")
            if isinstance(v, str) and v.strip():
                reviewer_tier = v.strip().split()[0]
            v = gate.get("gate_timestamp")
            if isinstance(v, str) and v.strip():
                gate_timestamp = v.strip()

    except Exception as exc:  # noqa: BLE001 -- never throws (NFR7)
        parse_warnings.append(
            f"{delivery_id}: error parsing 'delivery_gate' ({exc}); "
            f"returning best-effort gate fields"
        )

    return grade, reviewer_tier, gate_timestamp


def parse_deferred_issues(
    issues_path: Path,
    task_id: str,
    parse_warnings: list[str],
) -> list[DeferredIssue]:
    """DR-4: Parse delivery-NNN-issues.md and filter rows to Source task == task_id.

    File schema (schemas.md §12): 4-col markdown table
      Source task | Severity | Description | Status

    Returns list[DeferredIssue] filtered to this task. Absent file -> [] (not an error).
    Torn/malformed -> parse_warning + best-effort rows. Never throws (NFR7).
    """
    if not issues_path.is_file():
        return []

    try:
        raw = read_bytes_bounded(issues_path)
        text = raw.decode("utf-8", errors="replace")
    except OSError as exc:
        parse_warnings.append(
            f"{task_id}: could not read {issues_path.name} ({exc}); "
            f"deferred_issues will be empty"
        )
        return []

    deferred: list[DeferredIssue] = []
    header_seen = False

    try:
        for line in text.splitlines():
            stripped = line.strip()
            if not stripped.startswith("|"):
                continue
            if _RE_TABLE_SEP.match(stripped):
                header_seen = True
                continue
            cols = [c.strip() for c in stripped.strip("|").split("|")]
            if len(cols) < 4:
                continue
            # Skip header row (first column is 'Source task' or similar)
            if not header_seen:
                header_seen = True
                continue

            source_task = cols[0].strip()
            severity = cols[1].strip()
            description = cols[2].strip()
            status = cols[3].strip()

            # Filter to this task_id (case-insensitive comparison)
            if source_task.lower() == task_id.lower():
                deferred.append(DeferredIssue(
                    source_task=source_task,
                    severity=severity if severity else "[HIGH]",
                    description=description,
                    status=status if status else "Open",
                ))

    except Exception as exc:  # noqa: BLE001 -- never throws (NFR7)
        parse_warnings.append(
            f"{task_id}: error parsing {issues_path.name} ({exc}); "
            f"returning best-effort deferred issues"
        )

    return deferred


def parse_log_availability(aid_dir: Path) -> LogAvailability:
    """DR-5: Stat log/heartbeat paths for honest DM-4 log inventory.

    task_logs:          always 'none' (AID persists no per-task execution log, DM-4)
    server_log_present: stat .aid/.temp/dashboard.log (expected-false on Windows)
    heartbeat_present:  stat .aid/.heartbeat/ (liveness signal, corroborating-only, KI-004)

    Never throws (NFR7). No file is read (stat only). No write.
    """
    server_log_path = aid_dir / ".temp" / "dashboard.log"
    heartbeat_dir = aid_dir / ".heartbeat"

    server_log_present = False
    heartbeat_present = False

    try:
        server_log_present = server_log_path.is_file()
    except OSError:
        server_log_present = False

    try:
        heartbeat_present = heartbeat_dir.is_dir()
    except OSError:
        heartbeat_present = False

    return LogAvailability(
        task_logs="none",
        server_log_present=server_log_present,
        heartbeat_present=heartbeat_present,
    )
