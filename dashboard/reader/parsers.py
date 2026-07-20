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
from .derivation import derive_lifecycle, _parse_minimum_grade
from .state_schema import (
    parse_bool_yesno,
    parse_frontmatter_scalars,
    parse_header_bold_field,
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
        fm = parse_frontmatter_scalars(state_text)
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
# Level-2: STATE.md parser -- normalized path (LC-2 levels 0-3)
# ---------------------------------------------------------------------------

# Section header patterns (anchored, case-insensitive for resilience)
# Accept BOTH the new "state" names (work-004 rename) and the legacy "status" names
# (Pillar 3 / Pillar 6 coexistence: new works use "State"; old works keep "Status").
_RE_PIPELINE_STATUS    = re.compile(r"^##\s+Pipeline (?:State|Status)\s*$",    re.IGNORECASE)
_RE_TASKS_STATUS       = re.compile(r"^##\s+Tasks (?:State|Status)\s*$",       re.IGNORECASE)
_RE_CROSSPHASE_QA      = re.compile(r"^##\s+Cross-phase Q&A",        re.IGNORECASE)
_RE_TRIAGE             = re.compile(r"^##\s+Triage\s*$",             re.IGNORECASE)
_RE_FEATURES_STATUS    = re.compile(r"^##\s+Features (?:State|Status)\s*$",    re.IGNORECASE)
_RE_PLAN_DELIVERIES    = re.compile(r"^##\s+Plan\s*/\s*Deliveries\s*$", re.IGNORECASE)
_RE_LIFECYCLE_HISTORY  = re.compile(r"^##\s+Lifecycle History\s*$",  re.IGNORECASE)
_RE_SECTION            = re.compile(r"^##\s+\S")  # any ## section (to end a prior section)

# Triage field patterns
_RE_TRIAGE_PATH     = re.compile(r"^\s*-\s*\*\*Path:\*\*\s*(.+)", re.IGNORECASE)
_RE_TRIAGE_RECIPE   = re.compile(r"^\s*-\s*\*\*Recipe:\*\*\s*(.+)", re.IGNORECASE)

# Pipeline Status field patterns (each is a "- **Field:** value" line)
_RE_PS_LIFECYCLE    = re.compile(r"^\s*-\s*\*\*Lifecycle:\*\*\s*(.+)", re.IGNORECASE)
_RE_PS_PHASE        = re.compile(r"^\s*-\s*\*\*Phase:\*\*\s*(.+)",     re.IGNORECASE)
_RE_PS_SKILL        = re.compile(r"^\s*-\s*\*\*Active Skill:\*\*\s*(.+)", re.IGNORECASE)
_RE_PS_UPDATED      = re.compile(r"^\s*-\s*\*\*Updated:\*\*\s*(.+)",   re.IGNORECASE)
_RE_PS_PAUSE_REASON = re.compile(r"^\s*-\s*\*\*Pause Reason:\*\*\s*(.+)", re.IGNORECASE)
_RE_PS_BLOCK_REASON = re.compile(r"^\s*-\s*\*\*Block Reason:\*\*\s*(.+)", re.IGNORECASE)
_RE_PS_BLOCK_ART    = re.compile(r"^\s*-\s*\*\*Block Artifact:\*\*\s*(.+)", re.IGNORECASE)

# Q{N} header under Cross-phase Q&A
_RE_QN_HEADER  = re.compile(r"^###\s+(Q\d+)\s*$")
_RE_QN_STATUS  = re.compile(r"^\s*-\s*\*\*Status:\*\*\s*(.+)", re.IGNORECASE)
_RE_QN_CAT     = re.compile(r"^\s*-\s*\*\*Category:\*\*\s*(.+)", re.IGNORECASE)
_RE_QN_IMPACT  = re.compile(r"^\s*-\s*\*\*Impact:\*\*\s*(.+)", re.IGNORECASE)
_RE_QN_CONTEXT = re.compile(r"^\s*-\s*\*\*Context:\*\*\s*(.+)", re.IGNORECASE)
_RE_QN_SUGGEST = re.compile(r"^\s*-\s*\*\*Suggested:\*\*\s*(.+)", re.IGNORECASE)

# Tasks table separator row detector
_RE_TABLE_SEP  = re.compile(r"^\|[\s\-|]+\|$")
# Placeholder row
_NONE_YET      = "_none yet_"


def parse_state_md(
    text: str,
    work_id: str = "",
    work_dir: Optional[Path] = None,
) -> ParsedWork:
    """Parse a STATE.md file text into a ParsedWork.

    Single-pass line scan. Three phases in a single pass:
      - ## Pipeline Status  -> normalized WorkModel fields (source_mode=normalized)
      - ## Tasks Status     -> tasks[] (DM-5); skip _none yet_
      - ## Cross-phase Q&A  -> pending_inputs (Status: Pending only)

    When ## Pipeline Status is absent, the LC-3 fallback adapter (derive_lifecycle)
    is invoked to reconstruct lifecycle from legacy signals (SM-2 fallback path).
    source_mode=fallback is recorded for all works that use the fallback.

    work_dir is required for the fallback IMPEDIMENT scan (KI-003); if absent,
    the IMPEDIMENT check is skipped (IMPEDIMENT file detection does not fire).

    This function is pure (text-only) when work_dir is None. When work_dir is
    supplied it performs one filesystem scan for IMPEDIMENT files; no writes.

    Dual-format (work-003-state-schema task-002): the YAML frontmatter block at
    the top of the file (if any) is parsed ONCE via parse_frontmatter_scalars()
    and applied AFTER the legacy prose line-scan below -- frontmatter wins
    whenever both are present (dual-format / back-compat tolerant read). See
    _apply_pipeline_frontmatter / _apply_identity_frontmatter.
    """
    pw = ParsedWork()
    fm = parse_frontmatter_scalars(text)
    lines = text.splitlines()

    # State machine over sections
    in_pipeline_status = False
    pipeline_status_found = False
    in_tasks = False
    in_crossphase = False
    in_triage = False
    in_features = False
    in_deliveries = False
    in_lifecycle_history = False
    lifecycle_history_header_seen = False
    tasks_header_seen = False
    features_header_seen = False
    deliveries_header_seen = False

    # Q&A tracking
    current_q_id: Optional[str] = None
    current_q: dict = {}  # accumulator for current Q{N} block

    def _flush_q() -> None:
        nonlocal current_q, current_q_id
        if current_q_id and current_q.get("status", "").lower() == "pending":
            pw.pending_inputs.append(PendingInput(
                question_id=current_q_id,
                category=current_q.get("category"),
                impact=current_q.get("impact"),
                context=current_q.get("context"),
                suggested=current_q.get("suggested"),
            ))
        current_q_id = None
        current_q = {}

    def _reset_sections() -> None:
        nonlocal in_pipeline_status, in_tasks, in_crossphase
        nonlocal in_triage, in_features, in_deliveries, in_lifecycle_history
        in_pipeline_status = False
        in_tasks = False
        in_crossphase = False
        in_triage = False
        in_features = False
        in_deliveries = False
        in_lifecycle_history = False

    for line in lines:
        # Detect section boundaries (## headers)
        if _RE_PIPELINE_STATUS.match(line):
            _flush_q()
            _reset_sections()
            in_pipeline_status = True
            continue

        if _RE_TASKS_STATUS.match(line):
            _flush_q()
            _reset_sections()
            in_tasks = True
            tasks_header_seen = False
            continue

        if _RE_CROSSPHASE_QA.match(line):
            _flush_q()
            _reset_sections()
            in_crossphase = True
            continue

        if _RE_TRIAGE.match(line):
            _flush_q()
            _reset_sections()
            in_triage = True
            continue

        if _RE_FEATURES_STATUS.match(line):
            _flush_q()
            _reset_sections()
            in_features = True
            features_header_seen = False
            continue

        if _RE_PLAN_DELIVERIES.match(line):
            _flush_q()
            _reset_sections()
            in_deliveries = True
            deliveries_header_seen = False
            continue

        if _RE_LIFECYCLE_HISTORY.match(line):
            _flush_q()
            _reset_sections()
            in_lifecycle_history = True
            lifecycle_history_header_seen = False
            continue

        # Any other ## section resets active section
        if _RE_SECTION.match(line):
            _flush_q()
            _reset_sections()
            continue

        # --- Process active section ---

        if in_pipeline_status:
            _parse_pipeline_status_line(line, pw)
            pipeline_status_found = True
            continue

        if in_tasks:
            _parse_tasks_line(line, pw, tasks_header_seen)
            if line.strip().startswith("|") and not _RE_TABLE_SEP.match(line.strip()):
                tasks_header_seen = True
            continue

        if in_crossphase:
            # ### Q{N} header
            m = _RE_QN_HEADER.match(line)
            if m:
                _flush_q()
                current_q_id = m.group(1)
                current_q = {}
                continue
            if current_q_id:
                # Accept both "Status:" (legacy) and "State:" (new, Pillar 3) for Q&A state
                m2 = _RE_QN_STATUS.match(line)
                if m2:
                    current_q["status"] = m2.group(1).strip()
                    continue
                # New name "State:" -- map to same "status" key for unified flush logic
                m2 = re.match(r"^\s*-\s*\*\*State:\*\*\s*(.+)", line, re.IGNORECASE)
                if m2:
                    current_q["status"] = m2.group(1).strip()
                    continue
                m2 = _RE_QN_CAT.match(line)
                if m2:
                    current_q["category"] = m2.group(1).strip()
                    continue
                m2 = _RE_QN_IMPACT.match(line)
                if m2:
                    current_q["impact"] = m2.group(1).strip()
                    continue
                m2 = _RE_QN_CONTEXT.match(line)
                if m2:
                    current_q["context"] = m2.group(1).strip()
                    continue
                m2 = _RE_QN_SUGGEST.match(line)
                if m2:
                    current_q["suggested"] = m2.group(1).strip()
                    continue

        if in_triage:
            _parse_triage_line(line, pw)
            continue

        if in_features:
            _parse_features_line(line, pw, features_header_seen)
            if line.strip().startswith("|") and not _RE_TABLE_SEP.match(line.strip()):
                features_header_seen = True
            continue

        if in_deliveries:
            _parse_deliveries_line(line, pw, deliveries_header_seen)
            if line.strip().startswith("|") and not _RE_TABLE_SEP.match(line.strip()):
                deliveries_header_seen = True
            continue

        if in_lifecycle_history:
            _parse_lifecycle_history_line(line, pw, lifecycle_history_header_seen)
            if line.strip().startswith("|") and not _RE_TABLE_SEP.match(line.strip()):
                lifecycle_history_header_seen = True
            continue

    # Flush any trailing Q block
    _flush_q()

    # Dual-format (task-002): frontmatter-first override for the ## Pipeline State
    # scalars, applied AFTER the legacy prose scan above so frontmatter (the newer,
    # authoritative source) wins whenever both are present. A migrated STATE.md's
    # ## Pipeline State section body is enum-reference prose ONLY (no more
    # "- **Lifecycle:** ..." bullets) -- without this override, a migrated work would
    # render Lifecycle.Unknown despite pipeline_status_found=True (the section header
    # alone would still be seen). fm_lifecycle_present tracks whether the frontmatter
    # itself supplies a normalized-quality signal (used below alongside the legacy
    # pipeline_status_found flag, so a frontmatter-only fixture with no ## Pipeline
    # State section at all still resolves to Normalized).
    fm_lifecycle_present = _apply_pipeline_frontmatter(fm, pw)

    # Normalized path: if ## Pipeline Status was found (legacy prose) OR the
    # frontmatter supplied a valid `lifecycle` scalar, set source_mode=normalized.
    if pipeline_status_found or fm_lifecycle_present:
        pw.source_mode = SourceMode.Normalized
    else:
        # LC-3 FALLBACK ADAPTER (task-011, audited task-013 M6):
        # ## Pipeline Status block absent -- apply SM-2 fallback derivation from
        # legacy signals (IMPEDIMENT scan, task status rollup, Q&A pending,
        # Lifecycle History, Deploy Status).  source_mode=fallback is recorded.
        # All signals except Canceled are now LEGACY-COMPAT (live works use the
        # normalized ## Pipeline Status path). Canceled remains the legitimate path
        # since it has no automatic producer. KI-003 RESOLVED (task-013).
        _wd = work_dir if work_dir is not None else Path(".")
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
        )
        # Only update updated from fallback if not already set (normalized path may
        # have set it before the fallback; in practice the block is absent here so
        # pw.updated is always None, but guard explicitly for mixed-mode safety).
        if pw.updated is None:
            pw.updated = fallback_updated
        pw.parse_warnings.extend(extra_warnings)

    # Dual-format (task-002): pipeline-identity + newly-captured scalars.
    # Independent of the lifecycle/source_mode decision above -- these fields have
    # their own frontmatter-first / legacy-prose-fallback resolution.
    _apply_identity_frontmatter(fm, pw, text)

    return pw


# ---------------------------------------------------------------------------
# Hierarchical per-unit STATE.md parsers (work-004 Pillar 1/2/6)
#
# These parsers read the TASK-LEVEL and DELIVERY-LEVEL STATE.md files
# produced by the new uniform unit hierarchy (task-002 delivery-folder relocation --
# full-nested and lite-flat layouts; see reader.py _detect_hierarchy):
#   Full-nested: deliveries/delivery-NNN/tasks/task-NNN/STATE.md -- task mutable cells
#                deliveries/delivery-NNN/STATE.md                -- delivery lifecycle + gate + Q&A
#   Lite-flat:   tasks/task-NNN/STATE.md (directly under work_dir) -- task mutable cells
#                the work-root STATE.md's own ## Delivery Lifecycle / ## Delivery Gate /
#                ## Cross-phase Q&A sections -- the single implicit delivery's lifecycle/gate/Q&A
#
# They are ONLY called when hierarchy detection fires (_detect_hierarchy in reader.py).
# Legacy (monolithic) works continue to use parse_state_md().
# ---------------------------------------------------------------------------

# Task-level STATE.md section patterns
_RE_TASK_STATE_SECTION = re.compile(r"^##\s+Task State\s*$", re.IGNORECASE)

# Task state field patterns (- **Field:** value)
_RE_TS_STATE   = re.compile(r"^\s*-\s*\*\*State:\*\*\s*(.+)",   re.IGNORECASE)
_RE_TS_REVIEW  = re.compile(r"^\s*-\s*\*\*Review:\*\*\s*(.+)",  re.IGNORECASE)
_RE_TS_ELAPSED = re.compile(r"^\s*-\s*\*\*Elapsed:\*\*\s*(.+)", re.IGNORECASE)
_RE_TS_NOTES   = re.compile(r"^\s*-\s*\*\*Notes:\*\*\s*(.+)",   re.IGNORECASE)

# Delivery-level STATE.md section patterns
_RE_DELIVERY_LIFECYCLE_SECTION = re.compile(r"^##\s+Delivery Lifecycle\s*$", re.IGNORECASE)
_RE_DELIVERY_GATE_SECTION      = re.compile(r"^##\s+Delivery Gate\s*$",      re.IGNORECASE)
_RE_DELIVERY_CROSSPHASE_QA     = re.compile(r"^##\s+Cross-phase Q&A",        re.IGNORECASE)
_RE_DELIVERY_TASKS_STATE       = re.compile(r"^##\s+Tasks State\s*$",        re.IGNORECASE)

# Delivery lifecycle field patterns
_RE_DL_STATE        = re.compile(r"^\s*-\s*\*\*State:\*\*\s*(.+)",          re.IGNORECASE)
_RE_DL_UPDATED      = re.compile(r"^\s*-\s*\*\*Updated:\*\*\s*(.+)",        re.IGNORECASE)
_RE_DL_BLOCK_REASON = re.compile(r"^\s*-\s*\*\*Block Reason:\*\*\s*(.+)",   re.IGNORECASE)
_RE_DL_BLOCK_ART    = re.compile(r"^\s*-\s*\*\*Block Artifact:\*\*\s*(.+)", re.IGNORECASE)

# Delivery Gate field patterns
_RE_DG_REVIEWER_TIER = re.compile(r"^\s*-\s*\*\*Reviewer Tier:\*\*\s*(.+)", re.IGNORECASE)
_RE_DG_GRADE         = re.compile(r"^\s*-\s*\*\*Grade:\*\*\s*(.+)",         re.IGNORECASE)
_RE_DG_ISSUE_LIST    = re.compile(r"^\s*-\s*\*\*Issue List:\*\*\s*(.+)",    re.IGNORECASE)
_RE_DG_TIMESTAMP     = re.compile(r"^\s*-\s*\*\*Timestamp:\*\*\s*(.+)",     re.IGNORECASE)

# Valid SD-8 delivery lifecycle enum values (Pillar 1 / SD-8)
_DELIVERY_STATE_VALUES = frozenset({
    "Pending-Spec", "Specified", "Executing", "Gated", "Done", "Blocked",
})


class ParsedTaskState:
    """Parsed result for one task-level STATE.md (task-NNN/STATE.md).

    Covers: State / Review / Elapsed / Notes from ## Task State section, plus
    the feature-005 mutable `display_name` override (frontmatter-only -- no
    legacy prose bullet form; None when unset).
    Used by the hierarchical reader path only.
    """
    __slots__ = ("state", "review", "elapsed", "notes", "display_name", "parse_warnings")

    def __init__(self) -> None:
        self.state: TaskStatus = TaskStatus.Unknown
        self.review: Optional[str] = None
        self.elapsed: Optional[str] = None
        self.notes: Optional[str] = None
        self.display_name: Optional[str] = None
        self.parse_warnings: list[str] = []


class ParsedDeliveryState:
    """Parsed result for one delivery-level STATE.md (delivery-NNN/STATE.md).

    Covers:
      - delivery_state: SD-8 lifecycle enum (authored, not derived from tasks)
      - updated, block_reason, block_artifact from ## Delivery Lifecycle
      - grade, reviewer_tier, gate_timestamp from ## Delivery Gate
      - pending_inputs from ## Cross-phase Q&A (Pending entries)
      - tasks: list[TaskModel] from ## Tasks State derived table (if present inline)
    Used by the hierarchical reader path only.
    """
    __slots__ = (
        "delivery_state", "updated", "block_reason", "block_artifact",
        "gate_grade", "gate_reviewer_tier", "gate_timestamp",
        "pending_inputs", "tasks", "parse_warnings",
    )

    def __init__(self) -> None:
        self.delivery_state: Optional[str] = None
        self.updated: Optional[str] = None
        self.block_reason: Optional[str] = None
        self.block_artifact: Optional[str] = None
        self.gate_grade: Optional[str] = None
        self.gate_reviewer_tier: Optional[str] = None
        self.gate_timestamp: Optional[str] = None
        self.pending_inputs: list[PendingInput] = []
        self.tasks: list[TaskModel] = []
        self.parse_warnings: list[str] = []


def parse_task_state_md(
    text: str,
    task_id: str = "",
) -> ParsedTaskState:
    """Parse a task-level STATE.md into a ParsedTaskState.

    Reads the ## Task State section for the 4 mutable cells:
      State / Review / Elapsed / Notes

    The closed State enum values are the same as the work-level TaskStatus enum
    (Pending | In Progress | In Review | Blocked | Done | Failed | Canceled).

    Dual-format (work-003-state-schema task-002): the task-state-template.md
    frontmatter block (`state`/`review`/`elapsed`/`notes`, flat scalars) is
    read frontmatter-first; the ## Task State bullet scan below is the
    legacy-prose fallback for un-migrated files (a migrated file's ## Task
    State section body is comment-only, no bullets).

    Read-only; never throws (parse_warnings on error). Called only by the
    hierarchical reader path for a task-NNN/STATE.md file (full-nested:
    deliveries/delivery-NNN/tasks/task-NNN/STATE.md; lite-flat: tasks/task-NNN/STATE.md).
    """
    pts = ParsedTaskState()
    fm = parse_frontmatter_scalars(text)

    try:
        in_task_state = False

        for line in text.splitlines():
            # Section boundary
            if _RE_TASK_STATE_SECTION.match(line):
                in_task_state = True
                continue

            if _RE_SECTION.match(line):
                in_task_state = False
                continue

            if not in_task_state:
                continue

            m = _RE_TS_STATE.match(line)
            if m:
                raw = m.group(1).strip()
                pts.state = _parse_task_status(raw)
                continue

            m = _RE_TS_REVIEW.match(line)
            if m:
                val = m.group(1).strip()
                pts.review = None if _is_null(val) else val
                continue

            m = _RE_TS_ELAPSED.match(line)
            if m:
                val = m.group(1).strip()
                pts.elapsed = None if _is_null(val) else val
                continue

            m = _RE_TS_NOTES.match(line)
            if m:
                val = m.group(1).strip()
                pts.notes = None if _is_null(val) else val
                continue

        # Frontmatter-first override (applied after the legacy prose scan so
        # frontmatter wins whenever both are present).
        v = fm.get("state")
        if v is not None and not _is_null(v):
            pts.state = _parse_task_status(v.strip())

        v = fm.get("review")
        if v is not None:
            vv = v.strip()
            pts.review = None if _is_null(vv) else vv

        v = fm.get("elapsed")
        if v is not None:
            vv = v.strip()
            pts.elapsed = None if _is_null(vv) else vv

        v = fm.get("notes")
        if v is not None:
            vv = v.strip()
            pts.notes = None if _is_null(vv) else vv

        # feature-005 (work-017 task-008): display_name is a NEW frontmatter-only
        # key -- no legacy prose bullet form exists, so it is read only here (no
        # body-scan counterpart above, unlike state/review/elapsed/notes).
        v = fm.get("display_name")
        if v is not None:
            vv = v.strip()
            pts.display_name = None if _is_null(vv) else vv

    except Exception as exc:  # noqa: BLE001 -- never throws (NFR7)
        pts.parse_warnings.append(
            f"{task_id}: error parsing task STATE.md ({exc}); "
            f"returning best-effort task state"
        )

    return pts


def parse_delivery_state_md(
    text: str,
    delivery_id: str = "",
) -> ParsedDeliveryState:
    """Parse a delivery-level STATE.md into a ParsedDeliveryState.

    Reads:
      - ## Delivery Lifecycle: delivery_state (SD-8 enum), updated, block_reason,
        block_artifact
      - ## Delivery Gate: grade, reviewer_tier, gate_timestamp
      - ## Cross-phase Q&A: pending Q&A entries (Status: Pending only)
      - ## Tasks State: derived task rows (if present inline -- fallback table)

    The delivery_state is the INDEPENDENTLY AUTHORED SD-8 enum
    (Pending-Spec | Specified | Executing | Gated | Done | Blocked).
    It is NOT derived from the task rollup (SD-9).

    Read-only; never throws (parse_warnings on error). Called only by the
    hierarchical reader path -- for full-nested works with the delivery-level
    deliveries/delivery-NNN/STATE.md text; for lite-flat works with the work-root
    STATE.md text itself (the single implicit delivery's lifecycle/gate/Q&A are
    AUTHORED directly in the work-root file for lite works, so the same generic
    section parser applies to either text -- see reader.py _read_work_hierarchical).

    Dual-format (work-003-state-schema task-002): the delivery-state-template.md
    frontmatter block (`delivery_state`/`gate_tier`/`gate_grade`/`gate_timestamp`,
    flat scalars) is read frontmatter-first; the ## Delivery Lifecycle / ## Delivery
    Gate bullet scans below are the legacy-prose fallback for un-migrated files.
    """
    pds = ParsedDeliveryState()
    fm = parse_frontmatter_scalars(text)

    try:
        in_lifecycle = False
        in_gate = False
        in_crossphase = False
        in_tasks = False
        tasks_header_seen = False

        # Reuse one accumulator for the delivery ## Tasks State table (avoids per-line alloc)
        task_accumulator = _TaskAccumulator(pds)

        # Q&A tracking
        current_q_id: Optional[str] = None
        current_q: dict = {}

        def _flush_q() -> None:
            nonlocal current_q, current_q_id
            if current_q_id and current_q.get("state", "").lower() == "pending":
                pds.pending_inputs.append(PendingInput(
                    question_id=current_q_id,
                    category=current_q.get("category"),
                    impact=current_q.get("impact"),
                    context=current_q.get("context"),
                    suggested=current_q.get("suggested"),
                ))
            current_q_id = None
            current_q = {}

        for line in lines_iter(text):
            # Section boundaries (## headers, including ###)
            if _RE_DELIVERY_LIFECYCLE_SECTION.match(line):
                _flush_q()
                in_lifecycle = True
                in_gate = False
                in_crossphase = False
                in_tasks = False
                continue

            if _RE_DELIVERY_GATE_SECTION.match(line):
                _flush_q()
                in_lifecycle = False
                in_gate = True
                in_crossphase = False
                in_tasks = False
                continue

            if _RE_DELIVERY_CROSSPHASE_QA.match(line):
                _flush_q()
                in_lifecycle = False
                in_gate = False
                in_crossphase = True
                in_tasks = False
                continue

            if _RE_DELIVERY_TASKS_STATE.match(line):
                _flush_q()
                in_lifecycle = False
                in_gate = False
                in_crossphase = False
                in_tasks = True
                tasks_header_seen = False
                continue

            # Any other ## section resets all active sections
            if _RE_SECTION.match(line):
                _flush_q()
                in_lifecycle = False
                in_gate = False
                in_crossphase = False
                in_tasks = False
                continue

            # --- Process active section ---

            if in_lifecycle:
                m = _RE_DL_STATE.match(line)
                if m:
                    raw = m.group(1).strip()
                    # Accept valid SD-8 enum values; ignore placeholder text
                    if raw in _DELIVERY_STATE_VALUES:
                        pds.delivery_state = raw
                    elif "|" not in raw and raw:
                        # Unparseable -- warn but keep going
                        pds.parse_warnings.append(
                            f"{delivery_id}: unknown Delivery Lifecycle State '{raw}'; "
                            f"expected one of {sorted(_DELIVERY_STATE_VALUES)}"
                        )
                    continue

                m = _RE_DL_UPDATED.match(line)
                if m:
                    val = m.group(1).strip()
                    pds.updated = None if _is_null(val) else val
                    continue

                m = _RE_DL_BLOCK_REASON.match(line)
                if m:
                    val = m.group(1).strip()
                    pds.block_reason = None if _is_null(val) else val
                    continue

                m = _RE_DL_BLOCK_ART.match(line)
                if m:
                    val = m.group(1).strip()
                    pds.block_artifact = None if _is_null(val) else val
                    continue

            elif in_gate:
                m = _RE_DG_REVIEWER_TIER.match(line)
                if m and pds.gate_reviewer_tier is None:
                    val = m.group(1).strip()
                    raw_split = val.split()[0] if val else None
                    pds.gate_reviewer_tier = raw_split if raw_split and not _is_null(raw_split) else None
                    continue

                m = _RE_DG_GRADE.match(line)
                if m and pds.gate_grade is None:
                    val = m.group(1).strip()
                    raw_split = val.split()[0] if val else None
                    # Treat "Pending" placeholder as absent grade
                    if raw_split and not _is_null(raw_split) and raw_split.lower() != "pending":
                        pds.gate_grade = raw_split
                    continue

                m = _RE_DG_TIMESTAMP.match(line)
                if m and pds.gate_timestamp is None:
                    val = m.group(1).strip()
                    pds.gate_timestamp = None if _is_null(val) else val
                    continue

            elif in_crossphase:
                # ### Q{N} header
                m = _RE_QN_HEADER.match(line)
                if m:
                    _flush_q()
                    current_q_id = m.group(1)
                    current_q = {}
                    continue
                if current_q_id:
                    # Accept both "State:" (new) and "Status:" (legacy) for Q&A state
                    m2 = re.match(r"^\s*-\s*\*\*(?:State|Status):\*\*\s*(.+)", line, re.IGNORECASE)
                    if m2:
                        current_q["state"] = m2.group(1).strip()
                        continue
                    m2 = _RE_QN_CAT.match(line)
                    if m2:
                        current_q["category"] = m2.group(1).strip()
                        continue
                    m2 = _RE_QN_IMPACT.match(line)
                    if m2:
                        current_q["impact"] = m2.group(1).strip()
                        continue
                    m2 = _RE_QN_CONTEXT.match(line)
                    if m2:
                        current_q["context"] = m2.group(1).strip()
                        continue
                    m2 = _RE_QN_SUGGEST.match(line)
                    if m2:
                        current_q["suggested"] = m2.group(1).strip()
                        continue

            elif in_tasks:
                # Parse the derived task rollup table from delivery STATE.md
                _parse_tasks_line(line, task_accumulator, tasks_header_seen)
                stripped = line.strip()
                if stripped.startswith("|") and not _RE_TABLE_SEP.match(stripped):
                    tasks_header_seen = True

        # Flush any trailing Q block
        _flush_q()

        # Frontmatter-first override (applied after the legacy prose scan so
        # frontmatter wins whenever both are present).
        v = fm.get("delivery_state")
        if v is not None and not _is_null(v):
            raw = v.strip()
            if raw in _DELIVERY_STATE_VALUES:
                pds.delivery_state = raw
            else:
                pds.parse_warnings.append(
                    f"{delivery_id}: unknown frontmatter delivery_state '{raw}'; "
                    f"expected one of {sorted(_DELIVERY_STATE_VALUES)}"
                )

        v = fm.get("gate_tier")
        if v is not None and not _is_null(v):
            split = v.strip().split()
            if split:
                pds.gate_reviewer_tier = split[0]

        v = fm.get("gate_grade")
        if v is not None and not _is_null(v):
            split = v.strip().split()
            if split and split[0].lower() != "pending":
                pds.gate_grade = split[0]

        v = fm.get("gate_timestamp")
        if v is not None and not _is_null(v):
            pds.gate_timestamp = v.strip()

    except Exception as exc:  # noqa: BLE001 -- never throws (NFR7)
        pds.parse_warnings.append(
            f"{delivery_id}: error parsing delivery STATE.md ({exc}); "
            f"returning best-effort delivery state"
        )

    return pds


# ---------------------------------------------------------------------------
# feature-001 (flattened single-delivery layout): ### Tasks lifecycle parser
#
# The flat layout has no per-task STATE.md and no per-delivery STATE.md -- the
# promoted `## Delivery Lifecycle` / `## Delivery Gate` blocks (parsed above via
# parse_delivery_state_md, unchanged) plus a `### Tasks lifecycle` SUBSECTION
# live directly in the work-root STATE.md. This table REPLACES the per-task
# STATE.md's `## Task State` section, but uses a NARROWER column layout (no
# leading # / Type / Wave columns -- type comes from DETAIL.md, wave is the
# synthesized delivery-001 for every task in this layout):
#
#   | Task | State | Review | Elapsed | Notes |
#
# Called ONLY by the flat reader path (_read_work_flat in reader.py).
# ---------------------------------------------------------------------------

_RE_TASKS_LIFECYCLE_SECTION = re.compile(r"^###\s+Tasks lifecycle\s*$", re.IGNORECASE)
# Any ## or ### heading ends the ### Tasks lifecycle subsection (it is nested
# under ## Delivery Lifecycle, so a plain ## heading -- e.g. ## Delivery Gate --
# must also close it, not just another ###).
_RE_SECTION_2_OR_3 = re.compile(r"^#{2,3}\s+\S")


def parse_tasks_lifecycle_md(text: str) -> "tuple[dict[str, ParsedTaskState], list[str]]":
    """Parse the work-root STATE.md `### Tasks lifecycle` table (feature-001 flat layout).

    Columns: | Task | State | Review | Elapsed | Notes | Name |
    Name (feature-005, work-017 task-008) is the trailing col 5 (0-indexed) --
    a legacy 5-column row (pre-feature-005) yields display_name None.

    Returns (task_id_lower -> ParsedTaskState, parse_warnings). Header/separator
    rows and the `_none yet_` placeholder row are skipped. Unrecognized state
    literals map to TaskStatus.Unknown (never throws, NFR7).

    Read-only. Called only by the flat reader path.
    """
    result: dict[str, ParsedTaskState] = {}
    warnings: list[str] = []

    try:
        in_section = False
        header_seen = False

        for line in text.splitlines():
            if _RE_TASKS_LIFECYCLE_SECTION.match(line):
                in_section = True
                header_seen = False
                continue

            if in_section and _RE_SECTION_2_OR_3.match(line):
                in_section = False
                continue

            if not in_section:
                continue

            stripped = line.strip()
            if not stripped.startswith("|"):
                continue
            if _RE_TABLE_SEP.match(stripped):
                continue

            cols = [c.strip() for c in stripped.strip("|").split("|")]
            if len(cols) < 2:
                continue

            # First table row encountered is the header row (Task | State | ...)
            if not header_seen:
                header_seen = True
                continue

            if any(_NONE_YET in c for c in cols):
                continue

            def _col(idx: int) -> Optional[str]:
                if idx < len(cols):
                    v = cols[idx].strip()
                    return None if _is_null(v) else v
                return None

            task_id = _col(0) or ""
            if not task_id or task_id.lower() == "task":
                continue

            pts = ParsedTaskState()
            pts.state = _parse_task_status(_col(1) or "")
            pts.review = _col(2)
            pts.elapsed = _col(3)
            pts.notes = _col(4)
            # feature-005 (work-017 task-008): trailing Name column (col 5); a
            # legacy 5-column row (no Name column authored yet) yields
            # _col(5) is None -> display_name None -> short_name/task_id fallback.
            pts.display_name = _col(5)
            result[task_id.lower()] = pts

    except Exception as exc:  # noqa: BLE001 -- never throws (NFR7)
        warnings.append(
            f"error parsing ### Tasks lifecycle table ({exc}); returning best-effort"
        )

    return result, warnings


def lines_iter(text: str):
    """Yield lines from text (helper to avoid repeated splitlines() calls)."""
    return text.splitlines()


class _TaskAccumulator:
    """Minimal duck-type for ParsedWork accepted by _parse_tasks_line.

    Wraps a ParsedDeliveryState so we can reuse _parse_tasks_line for the
    delivery-level ## Tasks State derived table without duplicating the parser.
    """
    __slots__ = ("_pds",)

    def __init__(self, pds: ParsedDeliveryState) -> None:
        self._pds = pds

    @property
    def tasks(self) -> list[TaskModel]:
        return self._pds.tasks

    @property
    def parse_warnings(self) -> list[str]:
        return self._pds.parse_warnings


def _parse_pipeline_status_line(line: str, pw: ParsedWork) -> None:
    """Parse one line from the ## Pipeline State / ## Pipeline Status section into pw fields.

    Each line has the shape: - **Field:** value
    Unknown field lines are silently ignored (forward-compatible).
    Accepts both legacy "## Pipeline Status" and new "## Pipeline State" section names
    (Pillar 3 / Pillar 6 coexistence).
    """
    m = _RE_PS_LIFECYCLE.match(line)
    if m:
        pw.lifecycle = _parse_lifecycle(m.group(1).strip())
        return

    m = _RE_PS_PHASE.match(line)
    if m:
        pw.phase = _parse_phase(m.group(1).strip())
        return

    m = _RE_PS_SKILL.match(line)
    if m:
        val = m.group(1).strip()
        pw.active_skill = None if _is_null(val) or val == "none" else val
        return

    m = _RE_PS_UPDATED.match(line)
    if m:
        val = m.group(1).strip()
        pw.updated = None if _is_null(val) else val
        return

    m = _RE_PS_PAUSE_REASON.match(line)
    if m:
        val = m.group(1).strip()
        pw.pause_reason = None if _is_null(val) else val
        return

    m = _RE_PS_BLOCK_REASON.match(line)
    if m:
        val = m.group(1).strip()
        pw.block_reason = None if _is_null(val) else val
        return

    m = _RE_PS_BLOCK_ART.match(line)
    if m:
        val = m.group(1).strip()
        pw.block_artifact = None if _is_null(val) else val
        return


# ---------------------------------------------------------------------------
# Dual-format frontmatter overrides (work-003-state-schema task-002)
#
# Applied AFTER the legacy prose line-scan (parse_state_md), so the frontmatter
# (the newer, authoritative source) wins whenever both are present. Absent
# frontmatter keys never regress a prose-derived value to null -- each field is
# only overridden when its frontmatter key is itself present and non-null.
# ---------------------------------------------------------------------------

def _apply_pipeline_frontmatter(fm: dict, pw: ParsedWork) -> bool:
    """Frontmatter-first override for the ## Pipeline State scalar fields.

    Returns True iff the 'lifecycle' key was present with a valid (non-null)
    value -- the caller (parse_state_md) uses this alongside the legacy
    pipeline_status_found flag to decide source_mode.
    """
    lifecycle_present = False

    v = fm.get("lifecycle")
    if v is not None and not _is_null(v):
        pw.lifecycle = _parse_lifecycle(v.strip())
        lifecycle_present = True

    v = fm.get("phase")
    if v is not None and not _is_null(v):
        pw.phase = _parse_phase(v.strip())

    v = fm.get("active_skill")
    if v is not None:
        vv = v.strip()
        pw.active_skill = None if (_is_null(vv) or vv.lower() == "none") else vv

    v = fm.get("updated")
    if v is not None and not _is_null(v):
        pw.updated = v.strip()

    v = fm.get("pause_reason")
    if v is not None:
        vv = v.strip()
        pw.pause_reason = None if _is_null(vv) else vv

    v = fm.get("block_reason")
    if v is not None:
        vv = v.strip()
        pw.block_reason = None if _is_null(vv) else vv

    v = fm.get("block_artifact")
    if v is not None:
        vv = v.strip()
        pw.block_artifact = None if _is_null(vv) else vv

    return lifecycle_present


def _apply_identity_frontmatter(fm: dict, pw: ParsedWork, text: str) -> None:
    """Frontmatter-first (legacy header-blockquote fallback) for the
    pipeline-identity + newly-captured work scalars: `pipeline.path` ->
    work_path, `pipeline.initiator` -> kind, `started`, `minimum_grade`,
    `user_approved`.
    """
    # pipeline.path -> work_path (stop inferring via _detect_flat/_detect_hierarchy
    # when present; reader.py keeps those layout-detection heuristics as the
    # fallback default for un-migrated works).
    v = fm.get("pipeline.path")
    if v is not None and not _is_null(v):
        pw.work_path = v.strip().lower()

    # pipeline.initiator -> kind (display verb, shortcut-catalog.yml mapping).
    # No legacy prose equivalent exists (the old ## Triage **Recipe:** field --
    # still read into pw.recipe above -- is a distinct, older, dead-prose concept).
    v = fm.get("pipeline.initiator")
    if v is not None and not _is_null(v):
        pw.kind = resolve_kind(v.strip())

    # started (frontmatter-only; schema-note.md: the header blockquote's own
    # '**Started:**' line "was never actually parsed... the row-scrape was the
    # only working path" -- so there is no working legacy prose fallback to wire
    # here). Retires the fragile 'Work created' row-scrape for migrated works:
    # pw.created is ALSO backfilled so existing consumers (home.html work.created,
    # the JSON 'created' key) keep working unchanged.
    v = fm.get("started")
    if v is not None and not _is_null(v):
        started_val = v.strip()
        pw.started = started_val
        pw.created = started_val

    # minimum_grade: frontmatter-first; legacy fallback reuses the EXISTING
    # header-blockquote parse (derivation._parse_minimum_grade) -- its role in
    # the sub-minimum Blocked-gate derivation (derivation.py:_find_subminimum_gate)
    # is UNCHANGED; this is a separate exposure of the same value onto the model.
    v = fm.get("minimum_grade")
    if v is not None and not _is_null(v):
        pw.minimum_grade = v.strip().upper()
    else:
        legacy_grade = _parse_minimum_grade(text)
        if legacy_grade:
            pw.minimum_grade = legacy_grade

    # user_approved: frontmatter yes/no/true/false (case-insensitive) -> bool;
    # legacy header-blockquote '**User Approved:**' line as fallback. Work-level
    # approval, distinct from the KB's summary_approved (parse_kb_state).
    v = fm.get("user_approved")
    if v is not None:
        pw.user_approved = parse_bool_yesno(v)
    else:
        legacy_val = parse_header_bold_field(text, "User Approved")
        if legacy_val is not None and not _is_null(legacy_val):
            pw.user_approved = parse_bool_yesno(legacy_val)


def _parse_tasks_line(line: str, pw: ParsedWork, header_seen: bool) -> None:
    """Parse one line from the ## Tasks State / ## Tasks Status table.

    Table columns (new work-state-template.md -- work-004 rename):
        # | Task | Type | Wave | State | Review | Elapsed | Notes
    Table columns (legacy work-state-template.md -- pre-work-004):
        # | Task | Type | Wave | Status | Review | Elapsed | Notes

    Column index 4 is "State" (new) or "Status" (legacy); both parse identically
    since the reader reads by column index, not header name.

    Header row (col index 0 = "#") and separator rows are skipped.
    The _none yet_ placeholder row is skipped (DM-5).
    """
    stripped = line.strip()
    if not stripped.startswith("|"):
        return
    if _RE_TABLE_SEP.match(stripped):
        return

    cols = [c.strip() for c in stripped.strip("|").split("|")]
    if len(cols) < 2:
        return

    # Skip header row (first column is "#" or blank)
    if cols[0] in ("#", "") and not header_seen:
        return

    # Skip _none yet_ placeholder
    if any(_NONE_YET in c for c in cols):
        return

    # Column layout: # | Task | Type | Wave | Status | Review | Elapsed | Notes
    # Index:         0    1      2      3      4        5        6        7
    def _col(idx: int) -> Optional[str]:
        if idx < len(cols):
            v = cols[idx].strip()
            return None if _is_null(v) else v
        return None

    task_id = _col(1) or _col(0) or ""
    if not task_id or task_id == "#":
        return

    status_str = _col(4) or ""
    status = _parse_task_status(status_str)

    pw.tasks.append(TaskModel(
        task_id=task_id,
        type=_col(2) or "",
        wave=_col(3),
        status=status,
        review_grade=_col(5),
        elapsed=_col(6),
        notes=_col(7),
    ))


def _parse_triage_line(line: str, pw: ParsedWork) -> None:
    """Parse one line from the ## Triage section into pw fields."""
    m = _RE_TRIAGE_PATH.match(line)
    if m:
        val = m.group(1).strip()
        if not _is_null(val):
            pw.work_path = val.lower()
        return

    m = _RE_TRIAGE_RECIPE.match(line)
    if m:
        val = m.group(1).strip()
        if not _is_null(val):
            pw.recipe = val
        return


def _parse_features_line(line: str, pw: ParsedWork, header_seen: bool) -> None:
    """Parse one line from the ## Features Status table.

    Table columns: # | Feature | Spec Status | ... (at minimum # and Feature)
    """
    stripped = line.strip()
    if not stripped.startswith("|"):
        return
    if _RE_TABLE_SEP.match(stripped):
        return

    cols = [c.strip() for c in stripped.strip("|").split("|")]
    if len(cols) < 2:
        return

    # Skip header row
    if cols[0] in ("#", "") and not header_seen:
        return

    def _col(idx: int) -> Optional[str]:
        if idx < len(cols):
            v = cols[idx].strip()
            return None if _is_null(v) else v
        return None

    num_str = _col(0) or ""
    feature_name = _col(1) or ""

    if not num_str or num_str == "#" or not feature_name:
        return

    try:
        number = int(num_str)
    except ValueError:
        return

    # Readable name: strip "feature-NNN-" prefix if present
    readable = re.sub(r"^feature-\d+-", "", feature_name, flags=re.IGNORECASE).replace("-", " ").strip()
    if not readable:
        readable = feature_name

    pw.features.append(FeatureRef(number=number, name=readable))


def _parse_deliveries_line(line: str, pw: ParsedWork, header_seen: bool) -> None:
    """Parse one line from the ## Plan / Deliveries table.

    Table columns: Delivery | Status | Tasks | Notes
    """
    stripped = line.strip()
    if not stripped.startswith("|"):
        return
    if _RE_TABLE_SEP.match(stripped):
        return

    cols = [c.strip() for c in stripped.strip("|").split("|")]
    if len(cols) < 3:
        return

    # Skip header row (first column is "Delivery" or blank)
    if cols[0].lower() in ("delivery", "") and not header_seen:
        return

    def _col(idx: int) -> Optional[str]:
        if idx < len(cols):
            v = cols[idx].strip()
            return None if _is_null(v) else v
        return None

    delivery_id = _col(0) or ""
    tasks_str = _col(2) or ""
    notes_str = _col(3) or ""

    if not delivery_id or delivery_id.lower() == "delivery":
        return

    # Parse delivery number from "delivery-NNN" or "delivery-NNN ..."
    m = re.match(r"delivery-(\d+)", delivery_id, re.IGNORECASE)
    if not m:
        return
    number = int(m.group(1))

    # Parse leading integer from tasks column e.g. "13 (task-001-013)" -> 13
    task_count = 0
    tm = re.match(r"(\d+)", tasks_str)
    if tm:
        task_count = int(tm.group(1))

    # Name: use notes up to first semicolon/period, or delivery_id
    name = delivery_id
    if notes_str:
        # Split on "; " or " - " or " -- " separators to get the first clause
        short = notes_str.split(";")[0].split(" - ")[0].split(" -- ")[0].strip()
        if short:
            name = short

    pw.deliverables.append(DeliverableRef(number=number, name=name, task_count=task_count))


def _parse_lifecycle_history_line(line: str, pw: ParsedWork, header_seen: bool) -> None:
    """Parse one line from the ## Lifecycle History table for the 'created' date.

    Table columns: Date | Phase Transition / Gate | Grade | Notes  (typical shape)
    The Date column is index 0; the Phase Transition / Gate column is index 1.

    Extracts pw.created = the Date cell (first column, trimmed) of the FIRST row
    whose second column equals "Work created" (case-insensitive, trimmed).
    Once pw.created is set, subsequent rows are not re-evaluated (take first match).
    Header row and separator rows are skipped.
    """
    stripped = line.strip()
    if not stripped.startswith("|"):
        return
    if _RE_TABLE_SEP.match(stripped):
        return

    cols = [c.strip() for c in stripped.strip("|").split("|")]
    if len(cols) < 2:
        return

    # Skip header row (first column is "Date" or blank) before first data row seen
    if not header_seen:
        return

    # Already found created date; skip remaining rows
    if pw.created is not None:
        return

    date_val = cols[0].strip()
    gate_val = cols[1].strip()

    if gate_val.lower() == "work created" and date_val:
        pw.created = date_val


# ---------------------------------------------------------------------------
# Null-value helper
# ---------------------------------------------------------------------------

# Null/absent sentinels used in the work-state-template.md:
#   -   single dash (early template style)
#   --  double dash (common in task-status tables)
#   —   em-dash (Unicode U+2014, used in some fields)
_NULL_SENTINELS = frozenset(("-", "--", "—", ""))


def _is_null(val: str) -> bool:
    """Return True when the value represents an absent / not-applicable field."""
    return val in _NULL_SENTINELS


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

# Section header patterns for the forensic sections
_RE_QUICK_CHECK_FINDINGS = re.compile(r"^##\s+Quick Check Findings\s*$", re.IGNORECASE)
_RE_DELIVERY_GATES_SECTION = re.compile(r"^##\s+Delivery Gates\s*$", re.IGNORECASE)
# Task block header under ## Quick Check Findings: ### task-NNN
_RE_TASK_BLOCK_HEADER = re.compile(r"^###\s+(task-\S+)\s*$", re.IGNORECASE)
# Delivery sub-section under ## Delivery Gates: ### delivery-NNN
_RE_DELIVERY_BLOCK_HEADER = re.compile(r"^###\s+(delivery-\d+[^\s]*)\s*$", re.IGNORECASE)

# Per-task block field patterns
_RE_FINDINGS_REVIEWER_TIER = re.compile(r"^\s*-\s*\*\*Reviewer Tier:\*\*\s*(.+)", re.IGNORECASE)
_RE_FINDINGS_BULLET = re.compile(r"^\s*-\s*(\[.+?\])\s+(.*)")
# Per-delivery gate field patterns
_RE_GATE_GRADE = re.compile(r"^\s*-\s*\*\*Grade:\*\*\s*(.+)", re.IGNORECASE)
_RE_GATE_REVIEWER_TIER = re.compile(r"^\s*-\s*\*\*Reviewer Tier:\*\*\s*(.+)", re.IGNORECASE)
_RE_GATE_TIMESTAMP = re.compile(r"^\s*-\s*\*\*Timestamp:\*\*\s*(.+)", re.IGNORECASE)

# Severity normalization: only CRITICAL and HIGH; all others -> MINOR neutral
_KNOWN_SEVERITIES = frozenset({"[CRITICAL]", "[HIGH]"})

# Location pattern: {file:line} or {source-file:line} segments
_RE_LOCATION = re.compile(r"\{([^}]+:[^}]*)\}")

# Disposition tokens (verbatim from the template)
_DISPOSITION_TOKENS = ("Fixed-on-spot", "Deferred-to-gate")


def _parse_severity(tag: str) -> str:
    """Normalize a severity tag to [CRITICAL], [HIGH], or [MINOR] (neutral fallback).

    Mirrors feature-002 DM-6: lower/unknown -> [MINOR] neutral, never throws (NFR7).
    """
    normalized = tag.upper().strip()
    if normalized in ("[CRITICAL]", "[HIGH]"):
        return normalized
    return "[MINOR]"


def _parse_finding_bullet(
    bullet_text: str,
    reviewer_tier: Optional[str],
) -> Optional[Finding]:
    """Parse one **Findings:** bullet into a Finding.

    Bullet shape (DR-2):
      - [SEVERITY] description — {file:line} — Disposition

    Field separator: the canonical em-dash ' — ' (space U+2014 space); the
    legacy ASCII ' -- ' (space dash-dash space) is also accepted. Location and
    disposition are optional. Never throws (NFR7); returns None only if the
    bullet is blank.
    """
    text = bullet_text.strip()
    if not text:
        return None

    # Extract leading bracketed tag (severity)
    m = _RE_FINDINGS_BULLET.match("- " + text)
    if not m:
        # No bracketed tag -- treat whole text as description with MINOR severity
        return Finding(
            severity="[MINOR]",
            description=text,
            location=None,
            disposition=None,
            reviewer_tier=reviewer_tier,
        )

    tag = m.group(1)
    rest = m.group(2).strip()
    severity = _parse_severity(tag)

    # Split on em-dash ' — ' (canonical) or legacy ' -- ' (ASCII double-dash).
    # The canonical findings template uses U+2014 em-dash; accept both for back-compat.
    segments = re.split(r" (?:—|--) ", rest)

    description = segments[0].strip() if segments else rest

    # Extract location from any segment: {file:line}
    location: Optional[str] = None
    for seg in segments[1:]:
        lm = _RE_LOCATION.search(seg)
        if lm:
            location = lm.group(1).strip()
            break

    # Extract disposition: last segment matching a known token
    disposition: Optional[str] = None
    for seg in segments:
        stripped_seg = seg.strip()
        for token in _DISPOSITION_TOKENS:
            if stripped_seg == token or stripped_seg.startswith(token):
                disposition = token
                break
        if disposition:
            break

    return Finding(
        severity=severity,
        description=description,
        location=location,
        disposition=disposition,
        reviewer_tier=reviewer_tier,
    )


def parse_quick_check_findings(
    state_text: str,
    task_id: str,
    parse_warnings: list[str],
) -> list[Finding]:
    """DR-2: Parse ## Quick Check Findings -> ### task-NNN -> **Findings:** bullets.

    Returns a list of Finding objects for the given task_id.
    A clean task (no block or empty Findings list) -> returns [] (not an error).
    Torn/missing block -> parse_warning + best-effort (never throws, NFR7).
    """
    findings: list[Finding] = []
    in_findings_section = False
    in_task_block = False
    in_findings_list = False
    reviewer_tier: Optional[str] = None

    # Normalize task_id for comparison (case-insensitive)
    task_id_lower = task_id.lower()

    try:
        lines = state_text.splitlines()
        for line in lines:
            # Detect ## Quick Check Findings section
            if _RE_QUICK_CHECK_FINDINGS.match(line):
                in_findings_section = True
                in_task_block = False
                in_findings_list = False
                reviewer_tier = None
                continue

            if in_findings_section:
                # A ## section (not ###) ends the quick-check findings section
                if re.match(r"^##\s+\S", line) and not re.match(r"^###", line):
                    in_findings_section = False
                    in_task_block = False
                    in_findings_list = False
                    continue

                # ### task-NNN sub-section header
                tm = _RE_TASK_BLOCK_HEADER.match(line)
                if tm:
                    block_task_id = tm.group(1).lower()
                    in_task_block = (block_task_id == task_id_lower)
                    in_findings_list = False
                    reviewer_tier = None
                    continue

                if in_task_block:
                    # **Reviewer Tier:** line
                    rtm = _RE_FINDINGS_REVIEWER_TIER.match(line)
                    if rtm:
                        reviewer_tier = rtm.group(1).strip()
                        continue

                    # **Findings:** line (heading for the bullet list)
                    if re.match(r"^\s*-\s*\*\*Findings:\*\*\s*$", line, re.IGNORECASE):
                        in_findings_list = True
                        continue

                    if in_findings_list:
                        # A findings bullet: starts with '  - [' (indented bullet with bracket)
                        stripped = line.strip()
                        if stripped.startswith("- [") or stripped.startswith("-["):
                            # Parse the bullet (strip the leading '- ')
                            bullet_body = re.sub(r"^-\s*", "", stripped, count=1)
                            f = _parse_finding_bullet(bullet_body, reviewer_tier)
                            if f is not None:
                                findings.append(f)
                            continue
                        # Blank line or non-bullet: end of findings list for this task
                        if stripped and not stripped.startswith("-"):
                            in_findings_list = False

    except Exception as exc:  # noqa: BLE001 -- never throws (NFR7)
        parse_warnings.append(
            f"{task_id}: error parsing ## Quick Check Findings ({exc}); "
            f"returning best-effort findings"
        )

    return findings


def parse_delivery_gate(
    state_text: str,
    delivery_id: str,
    parse_warnings: list[str],
) -> tuple[Optional[str], Optional[str], Optional[str]]:
    """DR-3: Parse ## Delivery Gates -> ### delivery-NNN for grade/tier/timestamp.

    Returns (grade, reviewer_tier, gate_timestamp). All None if the block is absent.
    Verbatim -- never re-grades (NFR7). Never throws (torn -> parse_warning + None).

    Fallback (flat/lite works): a shortcut-produced work promotes a SINGULAR
    `## Delivery Gate` block into the work-root STATE.md instead of the derived
    plural `## Delivery Gates` -> `### delivery-NNN` rollup (see
    parse_delivery_state_md's docstring). When no plural `## Delivery Gates`
    section is present at all, the singular `## Delivery Gate` block -- if any --
    is read as delivery-001's gate. This is additive: it never fires when a
    plural section exists, so full/hierarchical works are unaffected.
    """
    grade: Optional[str] = None
    reviewer_tier: Optional[str] = None
    gate_timestamp: Optional[str] = None

    in_gates = False
    in_delivery_block = False
    found_gates_section = False

    # Normalize for comparison
    delivery_id_lower = delivery_id.lower()

    try:
        for line in state_text.splitlines():
            if _RE_DELIVERY_GATES_SECTION.match(line):
                in_gates = True
                in_delivery_block = False
                found_gates_section = True
                continue

            if in_gates:
                # A ## section (not ###) ends the delivery gates section
                if re.match(r"^##\s+\S", line) and not re.match(r"^###", line):
                    in_gates = False
                    in_delivery_block = False
                    continue

                # ### delivery-NNN sub-section header
                dm = _RE_DELIVERY_BLOCK_HEADER.match(line)
                if dm:
                    block_delivery_id = dm.group(1).lower()
                    in_delivery_block = (block_delivery_id == delivery_id_lower)
                    continue

                if in_delivery_block:
                    gm = _RE_GATE_GRADE.match(line)
                    if gm and grade is None:
                        raw = gm.group(1).strip()
                        # Grade is the first word (e.g. "A+ (cycle 2 ...)" -> "A+")
                        grade = raw.split()[0] if raw else None
                        continue

                    rtm = _RE_GATE_REVIEWER_TIER.match(line)
                    if rtm and reviewer_tier is None:
                        raw = rtm.group(1).strip()
                        # Tier is the first word (e.g. "Large (complexity score ...)" -> "Large")
                        reviewer_tier = raw.split()[0] if raw else None
                        continue

                    tsm = _RE_GATE_TIMESTAMP.match(line)
                    if tsm and gate_timestamp is None:
                        gate_timestamp = tsm.group(1).strip() or None
                        continue

                    # Once all three are found, we can stop scanning the delivery block
                    if grade and reviewer_tier and gate_timestamp:
                        break

        # Fallback: no plural ## Delivery Gates section anywhere in the text --
        # try the singular ## Delivery Gate block (flat/lite promoted layout),
        # treated as delivery-001's gate.
        if not found_gates_section and delivery_id_lower == "delivery-001":
            in_gate = False
            for line in state_text.splitlines():
                if _RE_DELIVERY_GATE_SECTION.match(line):
                    in_gate = True
                    continue

                if in_gate:
                    # Any ## section (not ###) ends the singular gate block
                    if re.match(r"^##\s+\S", line) and not re.match(r"^###", line):
                        in_gate = False
                        continue

                    gm = _RE_GATE_GRADE.match(line)
                    if gm and grade is None:
                        raw = gm.group(1).strip()
                        grade = raw.split()[0] if raw else None
                        continue

                    rtm = _RE_GATE_REVIEWER_TIER.match(line)
                    if rtm and reviewer_tier is None:
                        raw = rtm.group(1).strip()
                        reviewer_tier = raw.split()[0] if raw else None
                        continue

                    tsm = _RE_GATE_TIMESTAMP.match(line)
                    if tsm and gate_timestamp is None:
                        gate_timestamp = tsm.group(1).strip() or None
                        continue

                    if grade and reviewer_tier and gate_timestamp:
                        break

    except Exception as exc:  # noqa: BLE001 -- never throws (NFR7)
        parse_warnings.append(
            f"{delivery_id}: error parsing ## Delivery Gates ({exc}); "
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
