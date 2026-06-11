# dashboard/reader/derivation.py
# LC-3 Fallback Adapter + SM-2 / SM-3 lifecycle derivation.
#
# Responsibility:
#   - derive_lifecycle(work_dir, pw) -> Lifecycle (SM-2: preferred or fallback path)
#   - rollup_lifecycle(tasks, pending_inputs, has_impediment, deploy_done,
#                      cancellation_recorded) -> Lifecycle (SM-3)
#   - Fallback-only helpers that scan legacy STATE.md sections when ## Pipeline Status
#     is absent (LC-3 Fallback Adapter).
#
# TECH-DEBT TRACKING: every fallback derivation path in this module is TEMPORARY.
# Each function that reads a legacy signal is annotated with its KI reference so
# task-013 (M6 cutover) can audit and retire per-signal when feature-001 normalizes it.
#   - KI-003: IMPEDIMENT scan hard-codes the flat .aid/{work}/IMPEDIMENT-task-NNN.md path.
#   - KI-004: heartbeat is repo-level corroborating only; not used here (never a lifecycle
#             primitive).
#
# No I/O here; this module receives pre-parsed in-memory data structures (ParsedWork fields
# + the extra fallback-parsed text blobs). The filesystem is touched only by parsers.py.
# Read-only by construction. No write, no subprocess, no agent/LLM.
# Python 3.11+ stdlib only. Zero third-party deps.

from __future__ import annotations

import re
from pathlib import Path
from typing import Optional

from .models import Lifecycle, PendingInput, SourceMode, TaskModel, TaskStatus


# ---------------------------------------------------------------------------
# SM-2: derive_lifecycle -- unified preferred + fallback entry point
#
# PREFERRED path (normalized, feature-001 M1+):
#   When ## Pipeline Status block is present and contains a valid Lifecycle
#   literal, that literal is returned verbatim (source_mode=normalized).
#   This path is implemented in parsers.py (parse_state_md / _parse_pipeline_status_line).
#   derive_lifecycle() is called for the FALLBACK path only; the caller (parsers.py) decides
#   which path to use.
#
# FALLBACK path (LC-3, migration window -- task-013 retires this per-signal):
#   Apply SM-2 priority rules in order; first match wins; always returns exactly one.
# ---------------------------------------------------------------------------

def derive_lifecycle(
    *,
    work_dir: Path,
    tasks: list[TaskModel],
    pending_inputs: list[PendingInput],
    state_text: str,
    work_id: str = "",
) -> tuple[Lifecycle, SourceMode, Optional[str], Optional[str], Optional[str], Optional[str], list[str]]:
    """Apply SM-2 fallback derivation when ## Pipeline Status is absent.

    TEMPORARY (KI-003, KI-004): each branch below is a legacy signal scan that
    task-013 (M6 cutover) will retire once feature-001 fully normalizes the field.

    Returns:
        (lifecycle, source_mode, pause_reason, block_reason, block_artifact, updated,
         extra_warnings)

    Priority order (first match wins, TOTAL -- feature-002 SM-2):
      1. Canceled  -- ## Lifecycle History row matching /cancel|canceled/i (best-effort)
      2. Completed -- ## Deploy Status shipped OR all ## Plan / Deliveries Done + no open task
      3. Blocked   -- IMPEDIMENT-task-NNN.md exists (flat path, KI-003) OR any task Status=Failed
                      OR ## Delivery Gates block with Grade < minimum
      4. Paused-Awaiting-Input -- pending_inputs non-empty
         NOTE: **User Approved:** (top blockquote) is DELIBERATELY EXCLUDED from this primitive
         (SM-2 prio-4 note: it is the terminal work-completion gate, not a mid-run pause signal).
      5. Running   -- default (live work with no terminal/pause/block signal)
    """
    warnings: list[str] = []

    # ---- Prio 1: Canceled (TEMPORARY -- KI-003) ----
    # Scan ## Lifecycle History for a row whose Phase Transition / Gate column matches
    # /cancel|canceled/i.  Best-effort: if not found, fall through.
    if _has_cancellation_in_history(state_text, warnings, work_id):
        return (
            Lifecycle.Canceled,
            SourceMode.Fallback,
            None, None, None,
            _extract_latest_history_date(state_text),
            warnings,
        )

    # ---- Prio 2: Completed (TEMPORARY -- KI-003) ----
    # ## Deploy Status shipped OR all ## Plan / Deliveries rows Done with no open task.
    if _is_completed(state_text, tasks):
        return (
            Lifecycle.Completed,
            SourceMode.Fallback,
            None, None, None,
            _extract_latest_history_date(state_text),
            warnings,
        )

    # ---- Prio 3: Blocked (TEMPORARY -- KI-003) ----
    # IMPEDIMENT-task-NNN.md exists at the flat work-folder path (KI-003),
    # OR any task Status = Failed,
    # OR ## Delivery Gates block with Grade < minimum.
    block_reason, block_artifact = _find_block_signal(work_dir, tasks, state_text)
    if block_reason is not None:
        return (
            Lifecycle.Blocked,
            SourceMode.Fallback,
            None,  # pause_reason
            block_reason,
            block_artifact,
            _extract_latest_history_date(state_text),
            warnings,
        )

    # ---- Prio 4: Paused-Awaiting-Input (TEMPORARY -- KI-003) ----
    # pending_inputs non-empty (Q{N} with Status: Pending under ## Cross-phase Q&A).
    # DELIBERATELY EXCLUDES the top-blockquote **User Approved:** field (SM-2 prio-4 note):
    # that field is the terminal work-completion gate; using it would falsely mark every
    # not-yet-completed live work as Paused.
    if pending_inputs:
        q_ids = ", ".join(p.question_id for p in pending_inputs)
        pause_reason = f"Pending Q&A: {q_ids}"
        return (
            Lifecycle.PausedAwaitingInput,
            SourceMode.Fallback,
            pause_reason,
            None, None,
            _extract_latest_history_date(state_text),
            warnings,
        )

    # ---- Prio 5: Running -- total default (TEMPORARY -- KI-003) ----
    # Live work with no terminal/pause/block signal.
    # Heartbeat is corroborating only (KI-004) and never used here as a primitive.
    return (
        Lifecycle.Running,
        SourceMode.Fallback,
        None, None, None,
        _extract_latest_history_date(state_text),
        warnings,
    )


# ---------------------------------------------------------------------------
# SM-3: work-level rollup over per-task Status (FR14)
#
# Mirrors feature-001 §3 exactly so normalized and fallback agree.
# Called by derive_lifecycle (fallback path) to decide Running vs Blocked.
# The rollup is SEPARATE from (and does not replace) the per-task tasks[] list.
#
# NOTE: This function is ALSO usable standalone for testing the rollup in isolation.
# ---------------------------------------------------------------------------

def rollup_lifecycle(
    tasks: list[TaskModel],
    pending_inputs: list[PendingInput],
    has_impediment: bool,
    deploy_done: bool,
    cancellation_recorded: bool,
    all_deliveries_done: bool = False,
) -> Lifecycle:
    """SM-3: derive work-level Lifecycle from the multiset of per-task Status values.

    Matches feature-001 §3 deterministic rollup rule exactly.
    Never collapses the per-task list; this is a complementary summary.

    Priority order (first match wins):
      1. Canceled     -- user cancellation recorded in history
      2. Completed    -- deploy shipped OR all deliveries Done + no open task
      3. Blocked      -- impediment exists OR any task.status == Failed
      4. Paused       -- pending_inputs non-empty (Q&A pending)
      5. Running      -- any task In Progress/In Review, OR default (between waves)

    Heartbeat is never a primitive here (KI-004).
    **User Approved:** is deliberately excluded from Paused (SM-2 prio-4 note).
    """
    if cancellation_recorded:
        return Lifecycle.Canceled

    if deploy_done or all_deliveries_done:
        return Lifecycle.Completed

    if has_impediment or any(t.status == TaskStatus.Failed for t in tasks):
        return Lifecycle.Blocked

    if pending_inputs:
        return Lifecycle.PausedAwaitingInput

    # Running: any active task, OR default for a live work between waves.
    # "Between waves" is still Running -- FR16 has no Idle state.
    return Lifecycle.Running


# ---------------------------------------------------------------------------
# Fallback parsing helpers (LC-3 -- TEMPORARY: KI-003)
# Each function reads one legacy STATE.md signal.
# ---------------------------------------------------------------------------

# --- Prio 1: Cancellation (TEMPORARY -- KI-003) ---

_RE_HISTORY_SECTION = re.compile(r"^##\s+Lifecycle History\s*$", re.IGNORECASE)
_RE_TABLE_SEP = re.compile(r"^\|[\s\-|]+\|$")
_CANCEL_RE = re.compile(r"cancel(?:ed)?", re.IGNORECASE)


def _has_cancellation_in_history(text: str, warnings: list[str], work_id: str = "") -> bool:
    """Scan ## Lifecycle History rows for a Phase Transition / Gate column matching /cancel|canceled/i.

    Table shape (canonical/templates/work-state-template.md):
        | Date | Phase | Event | Phase Transition / Gate | Notes |

    TEMPORARY (KI-003): best-effort legacy parse; once feature-001 normalizes
    Lifecycle: Canceled in ## Pipeline Status, this scan is retired by task-013.

    Returns True if a cancellation row is found; emits a warning for ambiguous rows.
    """
    in_history = False
    header_seen = False

    for line in text.splitlines():
        if _RE_HISTORY_SECTION.match(line):
            in_history = True
            header_seen = False
            continue
        if in_history:
            if re.match(r"^##\s+", line):
                break
            stripped = line.strip()
            if not stripped.startswith("|"):
                continue
            if _RE_TABLE_SEP.match(stripped):
                continue
            cols = [c.strip() for c in stripped.strip("|").split("|")]
            if not header_seen:
                header_seen = True  # skip header row
                continue
            # Phase Transition / Gate is column index 3 (0-based: Date|Phase|Event|Gate|Notes)
            gate_col = cols[3].strip() if len(cols) > 3 else ""
            if _CANCEL_RE.search(gate_col):
                return True
            # Check all columns for ambiguous cancellation mentions
            if any(_CANCEL_RE.search(c) for c in cols):
                prefix = f"{work_id}: " if work_id else ""
                warnings.append(
                    f"{prefix}## Lifecycle History row mentions cancellation outside "
                    f"Gate column (ambiguous); check manually: {stripped}"
                )
    return False


# --- Latest history date (used as coarse updated fallback) (TEMPORARY -- KI-003) ---

_RE_DATE = re.compile(r"\b(\d{4}-\d{2}-\d{2})\b")


def _extract_latest_history_date(text: str) -> Optional[str]:
    """Return the most recent date found in ## Lifecycle History as the coarse updated fallback.

    TEMPORARY (KI-003): approximate; once feature-001 normalizes Updated in ## Pipeline Status,
    the Lifecycle History date is not needed.

    Scans the Date column (first column of each data row) in ## Lifecycle History.
    Returns the lexicographically latest date string ("YYYY-MM-DD"), or None if absent.
    """
    in_history = False
    header_seen = False
    latest: Optional[str] = None

    for line in text.splitlines():
        if _RE_HISTORY_SECTION.match(line):
            in_history = True
            header_seen = False
            continue
        if in_history:
            if re.match(r"^##\s+", line):
                break
            stripped = line.strip()
            if not stripped.startswith("|"):
                continue
            if _RE_TABLE_SEP.match(stripped):
                continue
            cols = [c.strip() for c in stripped.strip("|").split("|")]
            if not header_seen:
                header_seen = True
                continue
            # Date is the first column
            date_col = cols[0].strip() if cols else ""
            m = _RE_DATE.search(date_col)
            if m:
                d = m.group(1)
                if latest is None or d > latest:
                    latest = d
    return latest


# --- Prio 2: Completed (TEMPORARY -- KI-003) ---

_RE_DEPLOY_STATUS = re.compile(r"^##\s+Deploy Status\s*$", re.IGNORECASE)
_RE_PLAN_DELIVERIES = re.compile(r"^##\s+Plan\s*/\s*Deliveries\s*$", re.IGNORECASE)

# Shipped markers in the Deploy Status table
_SHIPPED_RE = re.compile(r"\b(shipped|deployed|done|complete[d]?)\b", re.IGNORECASE)

# Done markers in Plan / Deliveries Status column
_DELIVERY_DONE_RE = re.compile(r"^done$", re.IGNORECASE)
_DELIVERY_NOT_DONE_RE = re.compile(r"^(pending|in[\s-]progress|blocked)\b", re.IGNORECASE)


def _is_completed(text: str, tasks: list[TaskModel]) -> bool:
    """Return True if the work appears completed from legacy signals.

    TEMPORARY (KI-003): two sub-checks (either fires):
      (a) ## Deploy Status table has at least one row whose Status column contains
          a shipped/done marker.
      (b) ## Plan / Deliveries: all rows have Status=Done AND no task is open
          (no In Progress / In Review task).

    Once feature-001 normalizes Lifecycle: Completed, this scan is retired by task-013.
    """
    if _deploy_status_shipped(text):
        return True
    if _all_deliveries_done(text) and not _has_open_task(tasks):
        return True
    return False


def _deploy_status_shipped(text: str) -> bool:
    """Return True if ## Deploy Status contains a shipped/deployed row.

    TEMPORARY (KI-003). Scans the Status column (column 1) of each data row.
    """
    in_deploy = False
    header_seen = False

    for line in text.splitlines():
        if _RE_DEPLOY_STATUS.match(line):
            in_deploy = True
            header_seen = False
            continue
        if in_deploy:
            if re.match(r"^##\s+", line):
                break
            stripped = line.strip()
            if not stripped.startswith("|"):
                continue
            if _RE_TABLE_SEP.match(stripped):
                continue
            cols = [c.strip() for c in stripped.strip("|").split("|")]
            if not header_seen:
                header_seen = True
                continue
            # Status is typically column 1 (Delivery | Status | Notes)
            status_col = cols[1].strip() if len(cols) > 1 else ""
            if _SHIPPED_RE.search(status_col):
                return True
    return False


def _all_deliveries_done(text: str) -> bool:
    """Return True if ## Plan / Deliveries has at least one row AND all rows are Done.

    TEMPORARY (KI-003). Scans Status column (column 1: Delivery | Status | Tasks | Notes).
    An empty table (no rows) returns False (cannot confirm completion with no deliveries).
    """
    in_plan = False
    header_seen = False
    row_count = 0
    all_done = True

    for line in text.splitlines():
        if _RE_PLAN_DELIVERIES.match(line):
            in_plan = True
            header_seen = False
            row_count = 0
            all_done = True
            continue
        if in_plan:
            if re.match(r"^##\s+", line):
                break
            stripped = line.strip()
            if not stripped.startswith("|"):
                continue
            if _RE_TABLE_SEP.match(stripped):
                continue
            cols = [c.strip() for c in stripped.strip("|").split("|")]
            if not header_seen:
                header_seen = True
                continue
            # Skip _none yet_ placeholder
            if any("_none yet_" in c for c in cols):
                continue
            # Status column (index 1)
            status_col = cols[1].strip() if len(cols) > 1 else ""
            if not status_col:
                continue
            row_count += 1
            if not _DELIVERY_DONE_RE.match(status_col):
                all_done = False

    return in_plan and row_count > 0 and all_done


def _has_open_task(tasks: list[TaskModel]) -> bool:
    """Return True if any task has an open (in-progress/in-review) status."""
    open_statuses = {TaskStatus.InProgress, TaskStatus.InReview}
    return any(t.status in open_statuses for t in tasks)


# --- Prio 3: Blocked (TEMPORARY -- KI-003) ---

_IMPEDIMENT_RE = re.compile(r"^IMPEDIMENT-task-\w+\.md$", re.IGNORECASE)
_RE_DELIVERY_GATES = re.compile(r"^##\s+Delivery Gates\s*$", re.IGNORECASE)
_RE_GRADE_LINE = re.compile(r"\*\*Grade:\*\*\s*(\S+)", re.IGNORECASE)
_RE_MINIMUM_GRADE_LINE = re.compile(r"\*\*Minimum Grade:\*\*\s*(\S+)", re.IGNORECASE)

# Grade order for comparison (lowest to highest)
_GRADE_ORDER = ["F", "D", "C", "B", "A"]


def _find_block_signal(
    work_dir: Path,
    tasks: list[TaskModel],
    state_text: str,
) -> tuple[Optional[str], Optional[str]]:
    """Return (block_reason, block_artifact) or (None, None) if no block signal found.

    TEMPORARY (KI-003): three sub-checks (first wins in the block priority):
      (a) IMPEDIMENT-task-NNN.md exists at the flat path work_dir/IMPEDIMENT-task-NNN.md
          (de-facto producer path, state-execute.md:322; KI-003 tracks path reconciliation).
      (b) Any task has Status = Failed.
      (c) ## Delivery Gates block has a Grade that is below the per-work minimum grade
          (from the top blockquote **Minimum Grade:**).

    Once feature-001 normalizes Lifecycle: Blocked, this scan is retired by task-013.
    """
    # (a) IMPEDIMENT file -- flat path per KI-003 (not subdir; schema.md §13 is wrong)
    impediment_path = _find_impediment_file(work_dir)
    if impediment_path is not None:
        artifact = impediment_path.name
        return f"IMPEDIMENT file present: {artifact}", artifact

    # (b) Failed task
    failed_tasks = [t for t in tasks if t.status == TaskStatus.Failed]
    if failed_tasks:
        ids = ", ".join(t.task_id for t in failed_tasks)
        return f"Task(s) failed: {ids}", None

    # (c) Sub-minimum delivery gate
    gate_fail = _find_subminimum_gate(state_text)
    if gate_fail:
        return f"Delivery gate below minimum: {gate_fail}", gate_fail

    return None, None


def _find_impediment_file(work_dir: Path) -> Optional[Path]:
    """Return the first IMPEDIMENT-task-NNN.md file in work_dir, or None.

    TEMPORARY (KI-003): scans the FLAT work_dir/ path.
    The producer writes to .aid/{work}/IMPEDIMENT-task-NNN.md (state-execute.md:322).
    schemas.md §13 wrongly documents the subdir form; this reader follows the producer.
    When feature-001 KI-002 reconciles the path, update this scan in task-013.
    """
    try:
        for entry in work_dir.iterdir():
            if entry.is_file() and _IMPEDIMENT_RE.match(entry.name):
                return entry
    except OSError:
        pass
    return None


def _find_subminimum_gate(state_text: str) -> Optional[str]:
    """Return the delivery id of a ## Delivery Gates block with Grade < minimum, or None.

    TEMPORARY (KI-003): reads the top-blockquote **Minimum Grade:** + per-delivery **Grade:**.
    A Gate is sub-minimum when its Grade falls below the minimum in the grade order.

    Scans ## Delivery Gates for ### delivery-NNN sub-sections;
    reads **Grade:** lines to find a grade below the minimum.
    """
    minimum_grade = _parse_minimum_grade(state_text)

    in_gates = False
    current_delivery: Optional[str] = None

    for line in state_text.splitlines():
        if _RE_DELIVERY_GATES.match(line):
            in_gates = True
            current_delivery = None
            continue
        if in_gates:
            if re.match(r"^##\s+", line) and not re.match(r"^###\s+", line):
                break
            # Delivery sub-section header: ### delivery-NNN
            m = re.match(r"^###\s+(\S+)", line)
            if m:
                current_delivery = m.group(1)
                continue
            if current_delivery:
                gm = _RE_GRADE_LINE.search(line)
                if gm:
                    grade = gm.group(1).strip().upper()
                    if minimum_grade and _grade_below(grade, minimum_grade):
                        return current_delivery

    return None


def _parse_minimum_grade(text: str) -> Optional[str]:
    """Extract **Minimum Grade:** from the top blockquote in STATE.md.

    The top blockquote is the section before the first ## section header.
    """
    for line in text.splitlines():
        if re.match(r"^##\s+", line):
            break
        m = _RE_MINIMUM_GRADE_LINE.search(line)
        if m:
            return m.group(1).strip().upper()
    return None


def _grade_below(grade: str, minimum: str) -> bool:
    """Return True if grade is strictly below minimum in the grade order."""
    if grade not in _GRADE_ORDER or minimum not in _GRADE_ORDER:
        return False
    return _GRADE_ORDER.index(grade) < _GRADE_ORDER.index(minimum)
