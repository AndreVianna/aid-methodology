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

from .models import (
    KbStateRef,
    Lifecycle,
    PendingInput,
    Phase,
    SourceMode,
    TaskModel,
    TaskStatus,
    ToolInfo,
)
from .derivation import derive_lifecycle


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


# ---------------------------------------------------------------------------
# Level-0: ToolInfo from .aid-manifest.json (+ .aid-version fallback)
# ---------------------------------------------------------------------------

def parse_tool_info(
    manifest_path: Path,
    version_path: Path,
) -> tuple[ToolInfo, int]:
    """Parse .aid/.aid-manifest.json into ToolInfo.

    Falls back to .aid/.aid-version (plain string) for aid_version if the JSON
    manifest is absent.

    Returns (ToolInfo, bytes_read).
    manifest_present=False -> all fields None, no error (DM-2).
    """
    bytes_read = 0

    # Try manifest JSON first.
    if manifest_path.is_file():
        try:
            raw = manifest_path.read_bytes()
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

    # Fallback: .aid/.aid-version (plain string with the version)
    if version_path.is_file():
        try:
            raw = version_path.read_bytes()
            bytes_read += len(raw)
            version_str = raw.decode("utf-8", errors="replace").strip()
        except OSError:
            version_str = None

        return ToolInfo(
            manifest_present=False,
            aid_version=version_str or None,
        ), bytes_read

    # No manifest, no version file.
    return ToolInfo(manifest_present=False), bytes_read


# ---------------------------------------------------------------------------
# Level-1: RepoInfo helpers
# ---------------------------------------------------------------------------

def parse_project_name(settings_path: Path) -> tuple[str, int]:
    """Extract project.name from .aid/settings.yml.

    Uses a simple line-scan for 'name:' under the 'project:' block.
    Returns (name, bytes_read). On any failure, returns ("", 0).

    This is display-only: we read only the literal name scalar, not
    grade-resolution semantics (read-setting.sh is the contract for resolution).
    """
    if not settings_path.is_file():
        return "", 0

    try:
        raw = settings_path.read_bytes()
    except OSError:
        return "", 0

    bytes_read = len(raw)
    text = raw.decode("utf-8", errors="replace")

    # Find 'project:' section then the first 'name:' line after it.
    # Simple anchored line-scan: no YAML parser needed for this one scalar.
    in_project = False
    for line in text.splitlines():
        stripped = line.strip()
        if stripped == "project:" or stripped.startswith("project: "):
            in_project = True
            continue
        if in_project:
            # Another top-level key ends the project block
            if line and line[0] not in (" ", "\t", "#", "") and ":" in line:
                key = line.split(":")[0].strip()
                if key != "name":
                    # If this is a new top-level section (no leading whitespace), stop.
                    if not line[0].isspace():
                        break
            m = re.match(r"^\s+name:\s+(.+)", line)
            if m:
                val = m.group(1).strip().strip('"').strip("'")
                return val, bytes_read

    return "", bytes_read


def parse_kb_state(kb_dir: Path) -> tuple[Optional[KbStateRef], int]:
    """Parse .aid/knowledge/STATE.md + README.md into a KbStateRef hook.

    If .aid/knowledge/ does not exist, returns (None, 0) -- repo never ran
    /aid-discover; render gracefully.

    Fields populated:
      summary_approved  -- from STATE.md "**User Approved:** yes ..."
      last_summary_date -- extracted from same line (parenthesized date)
      doc_count         -- count of data rows in README.md ## Completeness table
    """
    if not kb_dir.is_dir():
        return None, 0

    bytes_read = 0
    summary_approved = False
    last_summary_date: Optional[str] = None
    doc_count: Optional[int] = None

    # Parse STATE.md for summary approval.
    state_path = kb_dir / "STATE.md"
    if state_path.is_file():
        try:
            raw = state_path.read_bytes()
            bytes_read += len(raw)
            state_text = raw.decode("utf-8", errors="replace")
        except OSError:
            state_text = ""
        summary_approved, last_summary_date = _parse_kb_summary_approval(state_text)

    # Parse README.md for doc_count.
    readme_path = kb_dir / "README.md"
    if readme_path.is_file():
        try:
            raw = readme_path.read_bytes()
            bytes_read += len(raw)
            readme_text = raw.decode("utf-8", errors="replace")
        except OSError:
            readme_text = ""
        doc_count = _parse_kb_doc_count(readme_text)

    return KbStateRef(
        summary_approved=summary_approved,
        last_summary_date=last_summary_date,
        doc_count=doc_count,
    ), bytes_read


def _parse_kb_summary_approval(text: str) -> tuple[bool, Optional[str]]:
    """Find the Knowledge Summary Status '**User Approved:** yes' line.

    Returns (approved: bool, date: Optional[str]).
    The date is extracted from the first parenthesized group on that line if present.
    """
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
                return approved, date
    return False, None


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
# Level-2: STATE.md parser -- normalized path (LC-2 levels 0-3)
# ---------------------------------------------------------------------------

# Section header patterns (anchored, case-insensitive for resilience)
_RE_PIPELINE_STATUS = re.compile(r"^##\s+Pipeline Status\s*$", re.IGNORECASE)
_RE_TASKS_STATUS    = re.compile(r"^##\s+Tasks Status\s*$",    re.IGNORECASE)
_RE_CROSSPHASE_QA   = re.compile(r"^##\s+Cross-phase Q&A",     re.IGNORECASE)
_RE_SECTION         = re.compile(r"^##\s+\S")  # any ## section (to end a prior section)

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
    """
    pw = ParsedWork()
    lines = text.splitlines()

    # State machine over sections
    in_pipeline_status = False
    pipeline_status_found = False
    in_tasks = False
    in_crossphase = False
    tasks_header_seen = False

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

    for line in lines:
        # Detect section boundaries (## headers)
        if _RE_PIPELINE_STATUS.match(line):
            _flush_q()
            in_pipeline_status = True
            in_tasks = False
            in_crossphase = False
            continue

        if _RE_TASKS_STATUS.match(line):
            _flush_q()
            in_tasks = True
            in_pipeline_status = False
            in_crossphase = False
            tasks_header_seen = False
            continue

        if _RE_CROSSPHASE_QA.match(line):
            _flush_q()
            in_crossphase = True
            in_pipeline_status = False
            in_tasks = False
            continue

        # Any other ## section resets active section
        if _RE_SECTION.match(line):
            _flush_q()
            in_pipeline_status = False
            in_tasks = False
            in_crossphase = False
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
                m2 = _RE_QN_STATUS.match(line)
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

    # Flush any trailing Q block
    _flush_q()

    # Normalized path: if ## Pipeline Status was found, set source_mode=normalized.
    if pipeline_status_found:
        pw.source_mode = SourceMode.Normalized
    else:
        # LC-3 FALLBACK ADAPTER (task-011):
        # ## Pipeline Status block absent -- apply SM-2 fallback derivation from
        # legacy signals (IMPEDIMENT scan, task status rollup, Q&A pending,
        # Lifecycle History, Deploy Status).  source_mode=fallback is recorded.
        # Each fallback path is TEMPORARY (KI-003/KI-004); task-013 retires them
        # per-signal as feature-001 normalizes the corresponding field.
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

    return pw


def _parse_pipeline_status_line(line: str, pw: ParsedWork) -> None:
    """Parse one line from the ## Pipeline Status section into pw fields.

    Each line has the shape: - **Field:** value
    Unknown field lines are silently ignored (forward-compatible).
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


def _parse_tasks_line(line: str, pw: ParsedWork, header_seen: bool) -> None:
    """Parse one line from the ## Tasks Status table.

    Table columns (work-state-template.md):
        # | Task | Type | Wave | Status | Review | Elapsed | Notes

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

# Phase mapping
_PHASE_MAP: dict[str, Phase] = {
    "Interview": Phase.Interview,
    "Specify": Phase.Specify,
    "Plan": Phase.Plan,
    "Detail": Phase.Detail,
    "Execute": Phase.Execute,
    "Deploy": Phase.Deploy,
    "Monitor": Phase.Monitor,
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
