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
    DeliverableRef,
    FeatureRef,
    KbBaseline,
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
        # prototype: work-overview header fields
        "work_path",
        "recipe",
        "features",
        "deliverables",
        "created",
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
                val = m.group(1)
                # PF-6: strip inline YAML comment -- drop from first unquoted '#' to EOL
                val = _strip_yaml_inline_comment(val)
                val = val.strip().strip('"').strip("'")
                return val, bytes_read

    return "", bytes_read


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


def parse_kb_baseline(settings_path: Path) -> tuple[Optional["KbBaseline"], int]:
    """Parse the kb_baseline block from .aid/settings.yml (DM-A4, task-064).

    Tolerant line-scan of the 'kb_baseline:' nested block, reusing the
    parse_project_name posture (parsers.py:148):
      - Scan for 'kb_baseline:' top-level key
      - Within that block, extract 'branch:' and 'tip_date:' scalar values
      - Absent/unparseable -> None (skip freshness, stay approved; FF-A2)

    Returns (KbBaseline or None, bytes_read).
    Never raises (NFR7). Never writes.
    """
    if not settings_path.is_file():
        return None, 0

    try:
        raw = settings_path.read_bytes()
    except OSError:
        return None, 0

    bytes_read = len(raw)
    text = raw.decode("utf-8", errors="replace")

    in_baseline = False
    branch: Optional[str] = None
    tip_date: Optional[str] = None

    for line in text.splitlines():
        stripped = line.strip()
        if stripped == "kb_baseline:" or stripped.startswith("kb_baseline: "):
            in_baseline = True
            continue
        if in_baseline:
            # Another top-level key (no leading whitespace) ends the block
            if line and not line[0].isspace() and ":" in line and not stripped.startswith("#"):
                break
            # Extract branch:
            m = re.match(r"^\s+branch:\s+(.+)", line)
            if m and branch is None:
                val = _strip_yaml_inline_comment(m.group(1)).strip().strip('"').strip("'")
                if val:
                    branch = val
                continue
            # Extract tip_date:
            m = re.match(r"^\s+tip_date:\s+(.+)", line)
            if m and tip_date is None:
                val = _strip_yaml_inline_comment(m.group(1)).strip().strip('"').strip("'")
                if val:
                    tip_date = val
                continue

    if branch is None and tip_date is None:
        return None, bytes_read

    return KbBaseline(branch=branch, tip_date=tip_date), bytes_read


def parse_kb_state(
    kb_dir: Path,
    dashboard_dir: Optional[Path] = None,
) -> tuple[Optional["KbStateRef"], int]:
    """Parse .aid/knowledge/STATE.md + README.md into a KbStateRef hook.

    If .aid/knowledge/ does not exist, returns (None, 0) -- repo never ran
    /aid-discover; render gracefully.

    dashboard_dir: if supplied, stat .aid/dashboard/kb.html for summary_present.
    The status field and kb_baseline are populated by the caller (reader.py)
    after derivation (FF-A3) and parsing (parse_kb_baseline).

    Fields populated:
      summary_approved  -- from STATE.md "**User Approved:** yes ..."
      last_summary_date -- extracted from same line (parenthesized date)
      doc_count         -- count of data rows in README.md ## Completeness table
      summary_present   -- True if dashboard_dir/kb.html exists (stat only)
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

    # Stat .aid/dashboard/kb.html for summary_present.
    summary_present = False
    if dashboard_dir is not None:
        kb_html = dashboard_dir / "kb.html"
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
        raw = path.read_bytes()
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
        raw = spec_path.read_bytes()
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
        # Read up to 4096 bytes to cover long titles; first-line-bounded parse
        raw = task_path.read_bytes()
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
        raw = plan_path.read_bytes()
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
_RE_PIPELINE_STATUS    = re.compile(r"^##\s+Pipeline Status\s*$",    re.IGNORECASE)
_RE_TASKS_STATUS       = re.compile(r"^##\s+Tasks Status\s*$",       re.IGNORECASE)
_RE_CROSSPHASE_QA      = re.compile(r"^##\s+Cross-phase Q&A",        re.IGNORECASE)
_RE_TRIAGE             = re.compile(r"^##\s+Triage\s*$",             re.IGNORECASE)
_RE_FEATURES_STATUS    = re.compile(r"^##\s+Features Status\s*$",    re.IGNORECASE)
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
    """
    pw = ParsedWork()
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

    # Normalized path: if ## Pipeline Status was found, set source_mode=normalized.
    if pipeline_status_found:
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
