# dashboard/reader/derivation.py
# LC-3 Fallback Adapter + SM-2 / SM-3 lifecycle derivation.
# FF-A3 KB 5-state status waterfall + FF-A2 git freshness read (task-064, feature-007).
#
# Responsibility:
#   - derive_lifecycle(work_dir, pw) -> Lifecycle (SM-2: preferred or fallback path)
#   - rollup_lifecycle(tasks, pending_inputs, has_impediment, deploy_done,
#                      cancellation_recorded) -> Lifecycle (SM-3)
#   - Fallback-only helpers that scan legacy STATE.md sections when ## Pipeline Status
#     is absent (LC-3 Fallback Adapter).
#   - derive_kb_status(kb_dir, summary_approved, summary_present, kb_baseline, repo_root)
#     -> KbStatus  (FF-A3 5-state waterfall, task-064)
#   - git_freshness_check(repo_root, kb_baseline) -> "approved" | "outdated" | "skip"
#     (FF-A2 read-only bounded git log subprocess, task-064)
#
# MIGRATION STATUS (task-013 M6 cutover audit):
#
#   NORMALIZED (producer-emitted, feature-001 M1-M6 complete):
#   - Running          -- M4: aid-interview, aid-specify, aid-plan, aid-detail,
#                        aid-execute, aid-deploy (state-idle.md) emit at phase entry.
#   - Paused-Awaiting-Input + Pause Reason -- M5: aid-specify (state-blocked.md,
#                        state-spike.md), aid-execute (state-delivery-gate.md),
#                        aid-interview (state-completion.md) emit on pause transitions.
#   - Blocked + Block Reason/Artifact -- M5: aid-execute (state-execute.md,
#                        state-review.md), aid-execute (state-delivery-gate.md)
#                        emit on impediment/failed-gate transitions.
#   - Completed        -- M6 (task-013): aid-deploy (state-done.md) emits at final
#                        work-completion transition (DONE state entry).
#
#   LEGITIMATE FALLBACK (no automatic producer by design):
#   - Canceled         -- Per feature-001 SS3 SM, Canceled is a USER ACTION only
#                        (no automatic pipeline trigger). Its ## Lifecycle History
#                        scan IS the intended derivation path, not tech-debt.
#                        No automatic producer will ever emit Lifecycle: Canceled;
#                        the fallback scan is retained as the permanent mechanism.
#
#   LEGACY-COMPAT (fallback code retained for works created before M4-M6):
#   The fallback code paths below are no longer "temporary by construction" for
#   signals that now have producers. They are retained as LEGACY-COMPAT for works
#   created before the migration (no ## Pipeline Status block present).
#   source_mode=fallback identifies these legacy works; ReadMeta.fallback_works
#   is the runtime evidence of which works still use the fallback path.
#
#   KI-003 RESOLVED (task-013): task-001 reconciled schemas.md SS13 to the flat
#   IMPEDIMENT-task-NNN.md path (the path the reader's _find_impediment_file already
#   scans). The reader's flat-scan path now matches the canonical documented path.
#   The KI-003 coupling note is closed; the flat-scan code is correct and stays.
#
#   KI-004: heartbeat is repo-level corroborating only; not used here (never a lifecycle
#           primitive). Retained as a known design choice (not tech-debt).
#
# No write / no LLM / one read-only `git log` subprocess for KB freshness (FR35).
# Python 3.11+ stdlib only. Zero third-party deps.

from __future__ import annotations

import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from .models import KbBaseline, KbStatus, Lifecycle, PendingInput, SourceMode, TaskModel, TaskStatus


# ---------------------------------------------------------------------------
# FF-A2: UTC-instant normalization helper (R12, task-064)
# ---------------------------------------------------------------------------

def _normalize_to_utc_ms(iso_str: str) -> Optional[int]:
    """Parse an ISO-8601 datetime string and return UTC milliseconds since epoch.

    Handles both Z-suffix and +/-HH:MM offset forms. Returns None if unparseable.
    Python: datetime.fromisoformat(...).astimezone(timezone.utc) (3.11 parses Z).

    This is the authoritative normalization helper for cross-runtime UTC comparison
    (FF-A2 step 4, R12). The Z-vs-+-HH:MM boundary unit case is in task-066.
    """
    if not iso_str:
        return None
    try:
        # Python 3.11+ parses Z suffix natively
        dt = datetime.fromisoformat(iso_str)
        if dt.tzinfo is None:
            # Assume UTC for naive datetimes (defensive; real data always has offset)
            dt = dt.replace(tzinfo=timezone.utc)
        dt_utc = dt.astimezone(timezone.utc)
        # Return milliseconds since epoch (matching Node Date.parse / getTime)
        epoch = datetime(1970, 1, 1, tzinfo=timezone.utc)
        return int((dt_utc - epoch).total_seconds() * 1000)
    except (ValueError, OverflowError):
        return None


# ---------------------------------------------------------------------------
# FF-A2: git freshness check (task-064, LC-A2 reader subprocess)
# ---------------------------------------------------------------------------

# Allowed git verbs: ONLY rev-parse, symbolic-ref, log (read-only)
# NEVER: fetch, pull, commit, checkout, reset, push, merge, rebase, add, rm
_GIT_ALLOWED_VERBS = frozenset({"rev-parse", "symbolic-ref", "log"})

# Degradation timeout (seconds) -- bounded read, never blocks indefinitely
_GIT_TIMEOUT_S = 2


def git_freshness_check(
    repo_root: Path,
    kb_baseline: Optional[KbBaseline],
) -> str:
    """FF-A2: Check if the repo's default branch has advanced past kb_baseline.

    Returns one of: "approved" | "outdated" | "skip".
    Every failure mode (DD-A2 7-mode degradation matrix) -> "skip" -> stay approved.

    Read-only subprocess: only rev-parse / symbolic-ref / log verbs.
    No fetch / pull / commit / checkout / reset / push / merge.
    No file written.

    argv (identical to Node reader.mjs twin):
        git -C <repo_root> log -1 --format=%cI <branch>
    """
    # Degradation mode 6: kb_baseline absent
    if kb_baseline is None:
        return "skip"

    # Resolve branch: prefer baseline.branch, else origin/HEAD basename, else main/master
    branch = _resolve_git_branch(repo_root, kb_baseline)
    if branch is None:
        return "skip"

    # Run: git -C <root> log -1 --format=%cI <branch>
    current_tip_str = _run_git_log(repo_root, branch)
    if current_tip_str is None:
        return "skip"

    # UTC normalization before compare (R12, never raw string compare)
    current_ms = _normalize_to_utc_ms(current_tip_str)
    baseline_ms = _normalize_to_utc_ms(kb_baseline.tip_date or "")
    if current_ms is None or baseline_ms is None:
        return "skip"

    return "outdated" if current_ms > baseline_ms else "approved"


def _resolve_git_branch(repo_root: Path, kb_baseline: KbBaseline) -> Optional[str]:
    """DD-A2 branch resolution: prefer baseline.branch, else origin/HEAD, else main/master."""
    # Prefer baseline.branch
    if kb_baseline.branch:
        return kb_baseline.branch

    # Try git symbolic-ref --short refs/remotes/origin/HEAD
    try:
        result = subprocess.run(
            ["git", "-C", str(repo_root), "symbolic-ref", "--short",
             "refs/remotes/origin/HEAD"],
            capture_output=True,
            text=True,
            timeout=_GIT_TIMEOUT_S,
        )
        if result.returncode == 0:
            ref = result.stdout.strip()
            if ref:
                # basename: "origin/main" -> "main"
                return ref.split("/")[-1] if "/" in ref else ref
    except (FileNotFoundError, subprocess.TimeoutExpired, OSError):
        pass

    # Fallback: first of {main, master} that exists
    for candidate in ("main", "master"):
        try:
            result = subprocess.run(
                ["git", "-C", str(repo_root), "rev-parse", "--verify",
                 f"refs/heads/{candidate}"],
                capture_output=True,
                text=True,
                timeout=_GIT_TIMEOUT_S,
            )
            if result.returncode == 0:
                return candidate
        except (FileNotFoundError, subprocess.TimeoutExpired, OSError):
            # Try the next candidate (twin of reader.mjs, which continues the loop on
            # a failed candidate rather than aborting) -- a spawn error on 'main' must
            # not prevent checking 'master'.
            continue

    return None


def _run_git_log(repo_root: Path, branch: str) -> Optional[str]:
    """Run: git -C <repo_root> log -1 --format=%cI <branch>

    Returns the raw ISO-8601 date string on success, None on every failure.
    Degradation modes: ENOENT (git absent), nonzero, empty, timeout.
    """
    try:
        result = subprocess.run(
            ["git", "-C", str(repo_root), "log", "-1", "--format=%cI", branch],
            capture_output=True,
            text=True,
            timeout=_GIT_TIMEOUT_S,
        )
        if result.returncode != 0:
            return None
        tip = result.stdout.strip()
        return tip if tip else None
    except FileNotFoundError:
        # git binary absent (ENOENT)
        return None
    except subprocess.TimeoutExpired:
        return None
    except OSError:
        return None


# ---------------------------------------------------------------------------
# FF-A3: KB 5-state status waterfall (task-064, feature-007 DM-A2)
# ---------------------------------------------------------------------------

def derive_kb_status(
    kb_dir: Path,
    summary_approved: bool,
    summary_present: bool,
    kb_baseline: Optional[KbBaseline],
    repo_root: Path,
) -> KbStatus:
    """FF-A3: Derive the FR32 5-state KB status from disk-only signals.

    Waterfall (outermost-first, DD-A3):
      1. .aid/knowledge/ absent or empty                          -> pending
      2. KB present but not yet User Approved: yes                -> generating
         (SPEC residual-#1 safe default -- applied verbatim, no design here)
      3. KB approved but kb.html absent OR summary not yet approved -> preparing
      4. freshness_check == "outdated"                            -> outdated
      5. else                                                     -> approved

    outdated is checked LAST and ONLY over approved (DD-A3).
    Never raises (NFR7).
    """
    try:
        # Step 1: .aid/knowledge/ absent or empty -> pending
        if not kb_dir.is_dir():
            return KbStatus.pending
        try:
            entries = list(kb_dir.iterdir())
        except OSError:
            entries = []
        if not entries:
            return KbStatus.pending

        # Step 2: KB present but not yet User Approved: yes -> generating
        # (SPEC residual-#1: "KB present but not yet User Approved: yes" is the safe default)
        if not summary_approved:
            return KbStatus.generating

        # Step 3: KB approved but kb.html absent OR summary not V1-approved -> preparing
        if not summary_present:
            return KbStatus.preparing

        # Step 4+5: freshness check (last, only over approved)
        freshness = git_freshness_check(repo_root, kb_baseline)
        if freshness == "outdated":
            return KbStatus.outdated

        return KbStatus.approved

    except Exception:  # noqa: BLE001 -- never raises (NFR7)
        return KbStatus.unknown


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
# FALLBACK path (LC-3, legacy-compat -- see module docstring for M6 migration status):
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

    LEGACY-COMPAT: each branch below is a legacy signal scan for works created before
    the M4-M6 producer migration (no ## Pipeline Status block present). Live works now
    use the normalized path (source_mode=normalized). These branches are retained for
    works that pre-date the migration.

    Exception: Canceled (prio-1) is the LEGITIMATE derivation path for all works,
    since Canceled is a user action with no automatic producer by design (feature-001 §3).

    Returns:
        (lifecycle, source_mode, pause_reason, block_reason, block_artifact, updated,
         extra_warnings)

    Priority order (first match wins, TOTAL -- feature-002 SM-2):
      1. Canceled  -- ## Lifecycle History row matching /cancel|canceled/i (best-effort).
                      LEGITIMATE PATH (not tech-debt): Canceled has no automatic producer.
      2. Completed -- ## Deploy Status shipped OR all ## Plan / Deliveries Done + no open task.
                      LEGACY-COMPAT: live works now emit Lifecycle: Completed via state-done.md.
      3. Blocked   -- IMPEDIMENT-task-NNN.md exists (flat path, KI-003 RESOLVED) OR any task
                      Status=Failed OR ## Delivery Gates block with Grade < minimum.
                      LEGACY-COMPAT: live works now emit Lifecycle: Blocked via M5 producers.
      4. Paused-Awaiting-Input -- pending_inputs non-empty.
                      LEGACY-COMPAT: live works now emit Lifecycle: Paused-Awaiting-Input via M5.
         NOTE: **User Approved:** (top blockquote) is DELIBERATELY EXCLUDED from this primitive
         (SM-2 prio-4 note: it is the terminal work-completion gate, not a mid-run pause signal).
      5. Running   -- default (live work with no terminal/pause/block signal).
                      LEGACY-COMPAT: live works now emit Lifecycle: Running via M4 producers.
    """
    warnings: list[str] = []

    # ---- Prio 1: Canceled (LEGITIMATE PATH -- no automatic producer by design) ----
    # Scan ## Lifecycle History for a row whose Phase Transition / Gate column matches
    # /cancel|canceled/i.  Best-effort: if not found, fall through.
    # Per feature-001 §3 SM, Canceled is a user action only; no pipeline producer will
    # ever emit Lifecycle: Canceled automatically. This scan is the permanent mechanism.
    if _has_cancellation_in_history(state_text, warnings, work_id):
        return (
            Lifecycle.Canceled,
            SourceMode.Fallback,
            None, None, None,
            _extract_latest_history_date(state_text),
            warnings,
        )

    # ---- Prio 2: Completed (LEGACY-COMPAT) ----
    # ## Deploy Status shipped OR all ## Plan / Deliveries rows Done with no open task.
    # Live works (created after M6) emit Lifecycle: Completed via state-done.md at DONE entry.
    # This branch is retained for legacy works created before the M6 migration.
    if _is_completed(state_text, tasks):
        return (
            Lifecycle.Completed,
            SourceMode.Fallback,
            None, None, None,
            _extract_latest_history_date(state_text),
            warnings,
        )

    # ---- Prio 3: Blocked (LEGACY-COMPAT) ----
    # IMPEDIMENT-task-NNN.md exists at the flat work-folder path (KI-003 RESOLVED),
    # OR any task Status = Failed,
    # OR ## Delivery Gates block with Grade < minimum.
    # Live works (created after M5) emit Lifecycle: Blocked via state-execute.md /
    # state-review.md / state-delivery-gate.md. Retained for legacy works.
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

    # ---- Prio 4: Paused-Awaiting-Input (LEGACY-COMPAT) ----
    # pending_inputs non-empty (Q{N} with Status: Pending under ## Cross-phase Q&A).
    # Live works (created after M5) emit Lifecycle: Paused-Awaiting-Input via M5 producers.
    # Retained for legacy works. DELIBERATELY EXCLUDES the top-blockquote **User Approved:**
    # field (SM-2 prio-4 note): that field is the terminal work-completion gate; using it
    # would falsely mark every not-yet-completed live work as Paused.
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

    # ---- Prio 5: Running -- total default (LEGACY-COMPAT) ----
    # Live work with no terminal/pause/block signal.
    # Live works (created after M4) emit Lifecycle: Running via M4 producers at phase entry.
    # Retained for legacy works. Heartbeat is corroborating only (KI-004, design choice).
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
# Fallback parsing helpers (LC-3)
# Each function reads one legacy STATE.md signal.
# Status per M6 audit (task-013):
#   - Canceled scan   : LEGITIMATE PATH (no automatic producer; see module docstring)
#   - All other scans : LEGACY-COMPAT (live works use normalized ## Pipeline Status)
# KI-003 RESOLVED: flat-scan path now matches canonical documented path (task-001).
# ---------------------------------------------------------------------------

# --- Prio 1: Cancellation (LEGITIMATE PATH -- no automatic producer by design) ---

_RE_HISTORY_SECTION = re.compile(r"^##\s+Lifecycle History\s*$", re.IGNORECASE)
_RE_TABLE_SEP = re.compile(r"^\|[\s\-|]+\|$")
_CANCEL_RE = re.compile(r"cancel(?:ed)?", re.IGNORECASE)


def _has_cancellation_in_history(text: str, warnings: list[str], work_id: str = "") -> bool:
    """Scan ## Lifecycle History rows for a Phase Transition / Gate column matching /cancel|canceled/i.

    Table shape (canonical/templates/work-state-template.md):
        | Date | Phase Transition / Gate | Grade | Notes |

    LEGITIMATE PATH (permanent): Canceled is a user action; no automatic pipeline producer
    will ever emit Lifecycle: Canceled. This ## Lifecycle History scan is the intended
    derivation mechanism for all works (legacy and live alike). Not retired by M6.

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
            # Phase Transition / Gate is column index 1 (0-based: Date|Gate|Grade|Notes)
            gate_col = cols[1].strip() if len(cols) > 1 else ""
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

    LEGACY-COMPAT: used only when ## Pipeline Status is absent (no Updated field).
    Live works (M4+) have authoritative Updated in ## Pipeline Status; this scan is
    retained for legacy works created before the migration.

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


# --- Prio 2: Completed (LEGACY-COMPAT) ---

_RE_DEPLOY_STATUS = re.compile(r"^##\s+Deploy Status\s*$", re.IGNORECASE)
_RE_PLAN_DELIVERIES = re.compile(r"^##\s+Plan\s*/\s*Deliveries\s*$", re.IGNORECASE)

# Shipped markers in the Deploy Status table
_SHIPPED_RE = re.compile(r"\b(shipped|deployed|done|complete[d]?)\b", re.IGNORECASE)

# Done markers in Plan / Deliveries Status column
_DELIVERY_DONE_RE = re.compile(r"^done$", re.IGNORECASE)
_DELIVERY_NOT_DONE_RE = re.compile(r"^(pending|in[\s-]progress|blocked)\b", re.IGNORECASE)


def _is_completed(text: str, tasks: list[TaskModel]) -> bool:
    """Return True if the work appears completed from legacy signals.

    LEGACY-COMPAT: two sub-checks (either fires):
      (a) ## Deploy Status table has at least one row whose Status column contains
          a shipped/done marker.
      (b) ## Plan / Deliveries: all rows have Status=Done AND no task is open
          (no In Progress / In Review task).

    Live works (created after M6) emit Lifecycle: Completed via state-done.md at DONE entry.
    This scan is retained for works created before the M6 migration.
    """
    if _deploy_status_shipped(text):
        return True
    if _all_deliveries_done(text) and not _has_open_task(tasks):
        return True
    return False


def _deploy_status_shipped(text: str) -> bool:
    """Return True if ## Deploy Status contains a shipped/deployed row.

    LEGACY-COMPAT. Scans the Status column (column 1) of each data row.
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
            # State is column 1 (Delivery | State | PR | KB Updated | Tag | Notes)
            status_col = cols[1].strip() if len(cols) > 1 else ""
            if _SHIPPED_RE.search(status_col):
                return True
    return False


def _all_deliveries_done(text: str) -> bool:
    """Return True if ## Plan / Deliveries has at least one row AND all rows are Done.

    LEGACY-COMPAT. Scans Status column (column 1: Delivery | Status | Tasks | Notes).
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


# --- Prio 3: Blocked (LEGACY-COMPAT) ---

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

    LEGACY-COMPAT: three sub-checks (first wins in the block priority):
      (a) IMPEDIMENT-task-NNN.md exists at the flat path work_dir/IMPEDIMENT-task-NNN.md
          (de-facto producer path, state-execute.md:322; KI-003 RESOLVED: this path now
          matches the canonical documented path after task-001 reconciliation).
      (b) Any task has Status = Failed.
      (c) ## Delivery Gates block has a Grade that is below the per-work minimum grade
          (from the top blockquote **Minimum Grade:**).

    Live works (created after M5) emit Lifecycle: Blocked via state-execute.md /
    state-review.md / state-delivery-gate.md. Retained for legacy works.
    """
    # (a) IMPEDIMENT file -- flat path per KI-003 RESOLVED (canonical documented path)
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

    KI-003 RESOLVED (task-013): scans the FLAT work_dir/ path.
    The producer writes to .aid/{work}/IMPEDIMENT-task-NNN.md (state-execute.md:322).
    task-001 reconciled schemas.md §13 to this flat path; the reader's scan now matches
    the canonical documented path. No update needed.
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

    LEGACY-COMPAT: reads the top-blockquote **Minimum Grade:** + per-delivery **Grade:**.
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
