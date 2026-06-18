# dashboard/reader/reader.py
# Public entry point: read_repo(aid_root) -> RepoModel
#
# Feature-002 Feature Flow (step numbers match the SPEC.md):
#   1. RESOLVE    verify aid_root/.aid exists; absent -> empty RepoModel + parse_warning
#   2. LEVEL-0    parse .aid/.aid-manifest.json (+ .aid/.aid-version)    -> ToolInfo
#   3. LEVEL-1    parse .aid/settings.yml + stat .aid/knowledge/          -> RepoInfo
#   4. ENUMERATE  glob .aid/work-NNN-*/ (dirs only; FR12)                -> work_id list
#   5. PER WORK   read STATE.md once; parse normalized block + tasks + Q&A -> WorkModel list
#   6. RECONCILE  merge same-work_id roots (work-004 Pillar 5 / SD-2)    -> deduplicated list
#   7. ASSEMBLE   RepoModel{tool, repo, works, read=ReadMeta}             -> return
#
# This module is the ONLY place that performs filesystem I/O for the whole pass.
# LC-1 Locator is in locator.py; LC-2 Parsers are in parsers.py.
#
# No write / no LLM / one read-only `git log` subprocess for KB freshness (FR35).
# NFR7 (no-LLM):    all derivation is deterministic code; no inference, no model call.
# NFR4 (overhead):  single bounded pass; ReadMeta.bytes_read records total bytes read.
#
# Python 3.11+ stdlib only. Zero third-party deps.
#
# work-004 Pillar 5 -- same-work reconcile (SD-2, task-011):
#   SD2_RANK     -- authoritative SD-2 state advancement ordering (most advanced = lowest rank int).
#                   Encoded ONCE here; the Node twin (task-012) must mirror this exact ordered list.
#                   Order: Done(0) > Canceled(1) > In Review(2) > In Progress(3) >
#                          Blocked(4) > Failed(5) > Pending(6) > Unknown(7)
#   _reconcile_same_work() -- merges N same-work_id WorkModels into one (no winner):
#                   * per task: most-advanced State by SD2_RANK
#                   * work-level Pipeline State: newest Updated; tie -> branch-label sort, main first
#                   * derived views (tasks, pending_inputs, deliverables, features): union

from __future__ import annotations

import re as _re_mod
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional, Union

from .derivation import derive_kb_status
from .locator import enumerate_worktree_roots, locate_aid_root
from .models import (
    DeferredIssue,
    DeliverableRef,
    Finding,
    Lifecycle,
    LogAvailability,
    PendingInput,
    RawStateRef,
    ReadMeta,
    RepoInfo,
    RepoModel,
    SourceMode,
    TaskDetail,
    TaskLedger,
    TaskModel,
    ToolInfo,
    WorkModel,
)
from .parsers import (
    ParsedWork,
    parse_deferred_issues,
    parse_delivery_gate,
    parse_delivery_state_md,
    parse_execution_graph,
    parse_kb_baseline,
    parse_kb_state,
    parse_log_availability,
    parse_project_name,
    parse_quick_check_findings,
    parse_requirements_md,
    parse_spec_md,
    parse_state_md,
    parse_task_short_name,
    parse_task_state_md,
    parse_tool_info,
)


# ---------------------------------------------------------------------------
# work-004 Pillar 5 / SD-2: State advancement ordering (LOCKED)
#
# Authoritative ordered list (most-advanced first, index = rank int):
#   Done(0) > Canceled(1) > In Review(2) > In Progress(3) >
#   Blocked(4) > Failed(5) > Pending(6) > Unknown(7)
#
# Rationale (from SPEC.md SD-2):
#   Done/Canceled are terminal-resolved (highest rank).
#   In Review is past In Progress (review is a later pipeline stage).
#   Blocked outranks Failed: blocked = recoverable-in-place + needs attention;
#   Failed = completed-but-rejected attempt (parallel branch may have superseded it).
#   Both Blocked and Failed outrank Pending (work was attempted; more informative).
#   Unknown is the reader-only sentinel and is ranked last.
#
# The Node twin (task-012) MUST mirror this exact ordering verbatim.
# ---------------------------------------------------------------------------
SD2_RANK: dict[str, int] = {
    "Done":        0,
    "Canceled":    1,
    "In Review":   2,
    "In Progress": 3,
    "Blocked":     4,
    "Failed":      5,
    "Pending":     6,
    "Unknown":     7,
}

# Sentinel rank for any state string not in SD2_RANK (treat as least advanced)
_SD2_RANK_DEFAULT = 7


def _sd2_rank(state: "TaskStatus") -> int:
    """Return the SD-2 rank for a TaskStatus (lower = more advanced).

    Uses the .value string so the comparison is independent of the enum wrapper.
    Unknown and unrecognized values return _SD2_RANK_DEFAULT (least advanced).
    Never throws.
    """
    try:
        return SD2_RANK.get(state.value, _SD2_RANK_DEFAULT)
    except Exception:  # noqa: BLE001
        return _SD2_RANK_DEFAULT


# ---------------------------------------------------------------------------
# work-004 Pillar 5: Same-work reconcile (no winner) -- task-011
# ---------------------------------------------------------------------------

def _reconcile_same_work(
    copies: list[tuple["WorkModel", str, str]],
) -> tuple["WorkModel", str, str]:
    """Merge N WorkModel copies for the same work_id into one reconciled model.

    Args:
        copies: list of (WorkModel, state_text, state_label) tuples,
                one per worktree/main root that contains this work_id.
                The list MUST be non-empty (caller guarantees this).

    Returns:
        (reconciled_WorkModel, winning_state_text, winning_state_label)

    Reconcile rules (Pillar 5 / SD-2):
      1. Per-task State: most-advanced by SD2_RANK (lower rank wins).
      2. Work-level Pipeline State (updated, lifecycle, phase, active_skill,
         pause_reason, block_reason, block_artifact): copy with the newest
         `updated` timestamp.  On a tie (equal or both None): break by
         branch_label lexical sort, "main" sorts first (before any other label).
      3. Derived views (tasks, pending_inputs, deliverables, features): UNION
         of all copies' contributions (dedup task_ids by SD-2 in step 1).
      4. Identity fields (work_id, name, number, title, description, objective,
         work_path, recipe): taken from the Pipeline-State winner (step 2)
         because those fields come from work-level files (REQUIREMENTS/SPEC),
         which are identical across all copies of the same work_id.
      5. source_mode: if any copy is Normalized -> Normalized; else Fallback.

    Merge is DETERMINISTIC and ORDER-INDEPENDENT:
      - Step 1 is a per-task max() by rank -> independent of input order.
      - Step 2 uses a total-order key that never produces a tie: the primary
        key (ISO-8601 updated) is string-comparable; ties are broken by a
        stable secondary key (branch_label sort, "main" first).
      - Steps 3-5 are commutative set/union operations.

    Read-only. Never throws.
    """
    if len(copies) == 1:
        # Trivial case: nothing to merge
        return copies[0]

    # ------------------------------------------------------------------
    # Step 1: union tasks, picking the most-advanced state per task_id
    # ------------------------------------------------------------------
    # Map task_id (lower-cased for robustness) -> best TaskModel seen so far
    best_task: dict[str, TaskModel] = {}
    for wm, _, _ in copies:
        for task in wm.tasks:
            tid = task.task_id.lower()
            if tid not in best_task:
                best_task[tid] = task
            else:
                current_rank = _sd2_rank(best_task[tid].status)
                candidate_rank = _sd2_rank(task.status)
                if candidate_rank < current_rank:
                    best_task[tid] = task
    # Preserve the original case order from the first copy that introduced each task
    # (stable across shuffles because best_task is keyed by lower-case, but we emit
    # the TaskModel objects which carry their own task_id).
    # Sort deterministically: by task_id string so order is input-order-independent.
    merged_tasks: list[TaskModel] = sorted(
        best_task.values(),
        key=lambda t: t.task_id.lower(),
    )

    # ------------------------------------------------------------------
    # Step 2: pick the Pipeline-State winner by newest `updated` timestamp.
    # Tie-break: branch_label lexical sort, "main" sorting first.
    #
    # Sort ascending by a key where "better" (newer timestamp, main branch) maps
    # to a SMALLER value, so sorted()[0] is the winner.
    #
    # Key structure: (tier, inv_updated, secondary)
    #   tier=0 if timestamp is present, tier=1 if absent (present wins over absent).
    #   inv_updated: char-complement of the ISO-8601 string so that a LARGER
    #     (newer) timestamp maps to a SMALLER key (ascending sort picks newest first).
    #     ISO-8601 characters are ASCII (digits, 'T', 'Z', '-', ':'); guard against
    #     corrupt non-ASCII by clamping ord(c) to [0, 0x7F] before complement.
    #   secondary: (0, "") for "main", else (1, label) for lexical sort.
    # ------------------------------------------------------------------
    def _pipeline_winner_key(entry: tuple[WorkModel, str, str]) -> tuple:
        wm = entry[0]
        updated = wm.updated or ""
        label = wm.branch_label or ""
        secondary = (0, "") if label == "main" else (1, label)
        if updated:
            inv_updated = "".join(
                chr(0x7F - min(ord(c), 0x7F)) for c in updated
            )
            return (0, inv_updated, secondary)
        else:
            return (1, "", secondary)

    sorted_copies = sorted(copies, key=_pipeline_winner_key)
    winner_wm, winner_text, winner_label = sorted_copies[0]

    # ------------------------------------------------------------------
    # Step 3: union pending_inputs (all copies contribute)
    # ------------------------------------------------------------------
    seen_qids: set[str] = set()
    merged_pending: list[PendingInput] = []
    for wm, _, _ in copies:
        for pi in wm.pending_inputs:
            if pi.question_id not in seen_qids:
                seen_qids.add(pi.question_id)
                merged_pending.append(pi)

    # ------------------------------------------------------------------
    # Step 3b: union deliverables (by delivery number; winner's entry wins
    # on duplicate numbers since the winner's Pipeline State is authoritative)
    # ------------------------------------------------------------------
    seen_del: set[int] = set()
    merged_deliverables: list[DeliverableRef] = []
    # Winner's deliverables first (authoritative on duplicates)
    for dr in winner_wm.deliverables:
        if dr.number not in seen_del:
            seen_del.add(dr.number)
            merged_deliverables.append(dr)
    for wm, _, _ in copies:
        if wm is winner_wm:
            continue
        for dr in wm.deliverables:
            if dr.number not in seen_del:
                seen_del.add(dr.number)
                merged_deliverables.append(dr)
    merged_deliverables.sort(key=lambda d: d.number)

    # ------------------------------------------------------------------
    # Step 3c: union features (by feature number; winner first)
    # ------------------------------------------------------------------
    seen_feat: set[int] = set()
    merged_features = []
    for fr in winner_wm.features:
        if fr.number not in seen_feat:
            seen_feat.add(fr.number)
            merged_features.append(fr)
    for wm, _, _ in copies:
        if wm is winner_wm:
            continue
        for fr in wm.features:
            if fr.number not in seen_feat:
                seen_feat.add(fr.number)
                merged_features.append(fr)

    # ------------------------------------------------------------------
    # Step 4 + 5: build the reconciled WorkModel from the winner's fields,
    # replacing tasks/pending_inputs/deliverables/features with merged views.
    # source_mode: Normalized if any copy is Normalized.
    # ------------------------------------------------------------------
    merged_source_mode = winner_wm.source_mode
    for wm, _, _ in copies:
        if wm.source_mode == SourceMode.Normalized:
            merged_source_mode = SourceMode.Normalized
            break

    reconciled = WorkModel(
        work_id=winner_wm.work_id,
        name=winner_wm.name,
        lifecycle=winner_wm.lifecycle,
        phase=winner_wm.phase,
        active_skill=winner_wm.active_skill,
        updated=winner_wm.updated,
        created=winner_wm.created,
        pause_reason=winner_wm.pause_reason,
        block_reason=winner_wm.block_reason,
        block_artifact=winner_wm.block_artifact,
        tasks=merged_tasks,
        pending_inputs=merged_pending,
        source_mode=merged_source_mode,
        number=winner_wm.number,
        title=winner_wm.title,
        description=winner_wm.description,
        objective=winner_wm.objective,
        work_path=winner_wm.work_path,
        recipe=winner_wm.recipe,
        features=merged_features,
        deliverables=merged_deliverables,
        # branch_label: None on a reconciled model (multiple branches contributed);
        # provenance is retained on each TaskModel via its wave/delivery field.
        branch_label=None,
    )
    return reconciled, winner_text, winner_label


def read_repo(aid_root: Union[str, Path]) -> RepoModel:
    """Read AID state for the repo at aid_root and return a normalized RepoModel.

    Single pure, idempotent filesystem pass.
    No write / no LLM / one read-only git log subprocess for KB freshness (FR35).

    Edge cases:
    - Absent .aid/       -> empty RepoModel with a parse_warning (SPEC AC1).
    - Zero work folders  -> works=[] with valid tool/repo/read fields (SPEC AC1).
    - Malformed STATE.md -> parse_warning + best-effort WorkModel; never aborts (SPEC).

    Args:
        aid_root: The repo root directory that contains the .aid/ subdirectory.
                  May be the repo root (which contains .aid/) or .aid/ itself --
                  both are accepted for convenience.

    Returns:
        RepoModel with tool, repo, works, and read (ReadMeta) fields populated.
    """
    model, _ = _read_repo_full(aid_root)
    return model


def _read_repo_full(
    aid_root: Union[str, Path],
) -> "tuple[RepoModel, dict[str, tuple[str, str]]]":
    """Run the full always-on repo read pass and return both the model and a
    per-work STATE.md text cache built as a by-product (zero extra I/O).

    Returns:
        (RepoModel, state_text_cache)
        where state_text_cache maps work_id -> (decoded_text, label_str).
        The cache is used by read_repo_detail to satisfy DR-1/DD-3/NFR4
        (raw_state reuses bytes already read; no re-read of STATE.md).
    """
    read_at = datetime.now(timezone.utc).isoformat(timespec="seconds")
    parse_warnings: list[str] = []
    bytes_read = 0

    # Normalize aid_root: accept either the repo root or a path ending in ".aid"
    root = Path(aid_root).resolve()
    if root.name == ".aid":
        root = root.parent

    # Step 1: RESOLVE -- locate .aid/ and enumerate work folders (LC-1)
    loc = locate_aid_root(root)

    if not loc.aid_exists:
        parse_warnings.append(
            f"No .aid/ directory found at {root}; returning empty model."
        )
        empty_model = RepoModel(
            tool=ToolInfo(manifest_present=False),
            repo=RepoInfo(
                project_name=root.name,
                aid_dir=str(loc.aid_dir),
                kb_state=None,
            ),
            works=[],
            read=ReadMeta(
                read_at=read_at,
                work_count=0,
                fallback_works=[],
                parse_warnings=parse_warnings,
                bytes_read=0,
            ),
        )
        return empty_model, {}

    # Step 2: LEVEL-0 -- ToolInfo (LC-2)
    tool_info, br = parse_tool_info(loc.manifest_path, loc.version_path)
    bytes_read += br

    # Step 3: LEVEL-1 -- RepoInfo + KbStateRef (LC-2)
    project_name, br = parse_project_name(loc.settings_path)
    bytes_read += br
    if not project_name:
        project_name = root.name  # fallback: folder basename (SPEC DM-7 note)

    # task-064: parse kb_baseline from settings.yml (DM-A4)
    dashboard_dir = loc.aid_dir / "dashboard"
    kb_baseline, br = parse_kb_baseline(loc.settings_path)
    bytes_read += br

    # task-064: parse kb_state with summary_present (stat of .aid/dashboard/kb.html)
    kb_state, br = parse_kb_state(loc.kb_dir, dashboard_dir=dashboard_dir)
    bytes_read += br

    # task-064: derive 5-state KB status (FF-A3 waterfall) and attach fields
    if kb_state is not None:
        from .models import KbStatus as _KbStatus  # avoid circular at module level
        kb_status = derive_kb_status(
            kb_dir=loc.kb_dir,
            summary_approved=kb_state.summary_approved,
            summary_present=kb_state.summary_present,
            kb_baseline=kb_baseline,
            repo_root=root,
        )
        kb_state.status = kb_status
        kb_state.kb_baseline = kb_baseline

    repo_info = RepoInfo(
        project_name=project_name,
        aid_dir=str(loc.aid_dir),
        kb_state=kb_state,
    )

    # Step 4: ENUMERATE -- worktrees + work folders (work-004 Pillar 4 / SD-3)
    # enumerate_worktree_roots returns [(branch_label, aid_dir), ...] with the main
    # root always first.  Degrades to main-root-only on any git failure (never throws).
    # For each (branch_label, aid_dir) root, locate_aid_root enumerates work-NNN-*/
    # dirs under that aid_dir.  Each resulting WorkModel is tagged with branch_label.
    # Cross-root merge of same work_id is task-011; duplicates are fine here.
    worktree_roots = enumerate_worktree_roots(root)

    # Steps 5a-5g: PER WORK -- parse STATE.md; build WorkModel list (pre-reconcile).
    # After enumeration across all worktree roots, Step 6 reconciles same-work_id copies
    # (work-004 Pillar 5 / SD-2 / task-011).
    #
    # Intermediate accumulator: maps work_id -> [(WorkModel, state_text, state_label), ...]
    # so that every copy of a work that appears on multiple roots is gathered before
    # _reconcile_same_work() collapses them into one model.
    work_copies: dict[str, list[tuple[WorkModel, str, str]]] = {}

    for branch_label, wt_aid_dir in worktree_roots:
        # Resolve the worktree's repo root from the aid_dir (aid_dir is <root>/.aid)
        wt_root = wt_aid_dir.parent
        wt_loc = locate_aid_root(wt_root)

        if not wt_loc.aid_exists:
            # Worktree has no .aid/ -- skip (no work to enumerate there)
            continue

        for work_dir in wt_loc.work_dirs:
            work_id = work_dir.name
            work_model, work_warnings, work_bytes, state_text, state_label = _read_work(
                work_dir, work_id
            )
            # Tag the work model with the branch that owns this worktree
            work_model.branch_label = branch_label
            parse_warnings.extend(work_warnings)
            bytes_read += work_bytes
            if work_id not in work_copies:
                work_copies[work_id] = []
            work_copies[work_id].append((work_model, state_text, state_label))

    # If worktree enumeration yielded NO results (all worktrees had no .aid/), fall
    # back to the main root so a bare repo without worktrees still renders correctly.
    if not work_copies and loc.aid_exists:
        for work_dir in loc.work_dirs:
            work_id = work_dir.name
            work_model, work_warnings, work_bytes, state_text, state_label = _read_work(
                work_dir, work_id
            )
            work_model.branch_label = None  # indeterminate; worktree list gave no data
            parse_warnings.extend(work_warnings)
            bytes_read += work_bytes
            work_copies[work_id] = [(work_model, state_text, state_label)]

    # Step 6: RECONCILE -- for each work_id, merge all copies (Pillar 5 / task-011).
    # Single-copy works pass through _reconcile_same_work unchanged (trivial case).
    # Outcome: one WorkModel per work_id, plus the state_text/label from the
    # Pipeline-State winner (newest Updated) for use by read_repo_detail.
    works: list[WorkModel] = []
    fallback_works: list[str] = []
    # DR-1/DD-3/NFR4: read_repo_detail reuses STATE.md text already read this pass;
    # cache key is bare work_id (the detail caller uses work_id, not branch_label/work_id).
    # After reconcile, the cache holds the text from the Pipeline-State winner
    # (newest Updated across all worktree copies of that work_id).
    # For a work that exists only on one root the cache trivially holds that root's text.
    state_text_cache: dict[str, tuple[str, str]] = {}

    for work_id, copies in work_copies.items():
        reconciled_wm, winning_text, winning_label = _reconcile_same_work(copies)
        works.append(reconciled_wm)
        state_text_cache[work_id] = (winning_text, winning_label)
        if reconciled_wm.source_mode != SourceMode.Normalized:
            fallback_works.append(work_id)

    # Step 7: ASSEMBLE
    repo_model = RepoModel(
        tool=tool_info,
        repo=repo_info,
        works=works,
        read=ReadMeta(
            read_at=read_at,
            work_count=len(works),
            fallback_works=fallback_works,
            parse_warnings=parse_warnings,
            bytes_read=bytes_read,
        ),
    )
    return repo_model, state_text_cache


def read_repo_detail(
    aid_root: Union[str, Path],
    detail_task_ids: Optional[list[str]] = None,
) -> tuple[RepoModel, dict[str, TaskDetail]]:
    """Read AID state and populate TaskDetail for each requested task_id.

    LC-TR (feature-008, task-069): the detail sub-parser runs ONLY when
    detail_task_ids is non-empty. The always-on read_repo() path is UNCHANGED.

    detail_task_ids: list of composite 'work_id/task_id' strings.
                     None or empty -> identical to read_repo() (no TaskDetail).

    Returns (RepoModel, details) where:
      details: dict keyed 'work_id/task_id' -> TaskDetail, sorted ascending.
               Empty dict when detail_task_ids is None/empty (NFR4, DD-1).

    Read-only / no-LLM / no subprocess (NFR2/NFR7).
    Torn read -> parse_warnings + best-effort TaskDetail; never throws.
    """
    # Step 1: run the full always-on read pass; get STATE.md cache as by-product.
    # DR-1/DD-3/NFR4: reuse bytes already read; zero extra disk I/O for raw_state.
    repo_model, state_text_cache = _read_repo_full(aid_root)

    # Step 2: if no detail requested, return immediately (NFR4, DD-1)
    if not detail_task_ids:
        return repo_model, {}

    # Step 3: LC-TR DETAIL-EXTEND -- only for requested task_ids
    root = Path(aid_root).resolve()
    if root.name == ".aid":
        root = root.parent
    aid_dir = root / ".aid"

    # Build an index of WorkModel by work_id for quick lookup
    work_index: dict[str, WorkModel] = {w.work_id: w for w in repo_model.works}

    details: dict[str, TaskDetail] = {}
    extra_warnings: list[str] = []

    for composite_key in detail_task_ids:
        # composite_key = 'work_id/task_id'
        if "/" not in composite_key:
            extra_warnings.append(
                f"detail_task_ids: invalid key '{composite_key}' "
                f"(expected 'work_id/task_id'); skipping"
            )
            continue

        slash_idx = composite_key.index("/")
        work_id = composite_key[:slash_idx]
        task_id = composite_key[slash_idx + 1:]

        if not work_id or not task_id:
            extra_warnings.append(
                f"detail_task_ids: empty work_id or task_id in '{composite_key}'; skipping"
            )
            continue

        task_warnings: list[str] = []

        # DR-1: get STATE.md text from the always-on pass cache (no disk re-read).
        # If work_id was not enumerated in the always-on pass (detail for a non-enumerated
        # work), use empty text and add a warning -- never re-read from disk (NFR4).
        state_path_label: str = f".aid/{work_id}/STATE.md"
        if work_id in state_text_cache:
            state_text, state_path_label = state_text_cache[work_id]
        else:
            task_warnings.append(
                f"{work_id}/{task_id}: work not found in always-on pass; "
                f"STATE.md unavailable; raw_state will be empty"
            )
            state_text = ""

        raw_state = RawStateRef(
            text=state_text,
            byte_len=len(state_text.encode("utf-8")),
            path=state_path_label,
        )

        # DR-2: parse ## Quick Check Findings -> ### task-NNN -> **Findings:** bullets
        findings = parse_quick_check_findings(state_text, task_id, task_warnings)

        # DR-3: resolve the task's delivery from the work model
        delivery_id: Optional[str] = None
        work_model = work_index.get(work_id)
        if work_model is not None:
            for task in work_model.tasks:
                if task.task_id.lower() == task_id.lower():
                    if task.delivery is not None:
                        delivery_id = f"delivery-{task.delivery:03d}"
                    break

        # DR-3: parse ## Delivery Gates -> ### delivery-NNN for grade/tier/ts
        gate_grade: Optional[str] = None
        gate_reviewer_tier: Optional[str] = None
        gate_timestamp: Optional[str] = None
        if delivery_id is not None and state_text:
            gate_grade, gate_reviewer_tier, gate_timestamp = parse_delivery_gate(
                state_text, delivery_id, task_warnings
            )

        # DR-4: read .aid/{work}/delivery-NNN-issues.md; filter to Source task == task_id
        deferred_issues: list[DeferredIssue] = []
        if delivery_id is not None:
            issues_path = aid_dir / work_id / f"{delivery_id}-issues.md"
            deferred_issues = parse_deferred_issues(issues_path, task_id, task_warnings)

        ledger = TaskLedger(
            delivery_id=delivery_id,
            grade=gate_grade,
            reviewer_tier=gate_reviewer_tier,
            gate_timestamp=gate_timestamp,
            deferred_issues=deferred_issues,
        )

        # DR-5: stat .aid/.temp/dashboard.log + .aid/.heartbeat/
        logs = parse_log_availability(aid_dir)

        task_detail = TaskDetail(
            task_id=task_id,
            findings=findings,
            ledger=ledger,
            raw_state=raw_state,
            logs=logs,
        )

        details[composite_key] = task_detail
        extra_warnings.extend(task_warnings)

    # Append any LC-TR warnings to the model's parse_warnings (best-effort)
    if extra_warnings:
        repo_model.read.parse_warnings.extend(extra_warnings)

    # Sort details ascending by composite key (parity requirement, DM-2 key-order)
    sorted_details = dict(sorted(details.items()))

    return repo_model, sorted_details


def _read_work(
    work_dir: Path, work_id: str
) -> "tuple[WorkModel, list[str], int, str, str]":
    """Read and parse a single work folder's STATE.md.

    Steps 5a-5g of the Feature Flow, per-work.

    Pillar 6 (presence-based detection): if any delivery-NNN/tasks/task-NNN/STATE.md
    exists, routes to _read_work_hierarchical. Otherwise falls back to the legacy
    monolithic parse (reader.py:363-377 behavior preserved).

    Returns (WorkModel, parse_warnings, bytes_read, state_text, state_label).
    state_text is the decoded work-level STATE.md content (empty string on error/absent).
    state_label is the relative path label for raw_state (e.g. '.aid/work-001/STATE.md').
    Never raises: any exception yields a parse_warning + best-effort WorkModel.
    """
    # Pillar 6: hierarchy detection (per-work, presence-based)
    if _detect_hierarchy(work_dir):
        return _read_work_hierarchical(work_dir, work_id)

    # --- Legacy monolithic path (preserved behavior) ---
    state_path = work_dir / "STATE.md"
    state_label = f".aid/{work_id}/STATE.md"
    parse_warnings: list[str] = []
    bytes_read = 0

    # Step 5a: read STATE.md once into memory (single file read)
    if not state_path.is_file():
        parse_warnings.append(
            f"{work_id}: STATE.md not found; returning minimal WorkModel."
        )
        return _minimal_work_model(work_id, parse_warnings), parse_warnings, 0, "", state_label

    try:
        raw = state_path.read_bytes()
        bytes_read = len(raw)
        text = raw.decode("utf-8", errors="replace")
    except OSError as exc:
        parse_warnings.append(
            f"{work_id}: STATE.md read error ({exc}); returning minimal WorkModel."
        )
        return _minimal_work_model(work_id, parse_warnings), parse_warnings, 0, "", state_label

    # Steps 5b-5d: parse normalized block, tasks, pending Q&A (LC-2)
    # work_dir is passed for the LC-3 fallback IMPEDIMENT scan (KI-003).
    pw: ParsedWork = parse_state_md(text, work_id=work_id, work_dir=work_dir)
    parse_warnings.extend(pw.parse_warnings)

    # Extract display name from work_id slug (strip leading "work-NNN-")
    name = _slug_from_work_id(work_id)

    # Prototype: parse work number from folder prefix (work-NNN-...)
    work_number = _number_from_work_id(work_id)

    # Prototype: parse REQUIREMENTS.md for identity fields
    req_path = work_dir / "REQUIREMENTS.md"
    req_title, req_description, req_objective, req_bytes = parse_requirements_md(req_path)
    bytes_read += req_bytes

    # PF-8: SPEC.md fallback source for Lite-path works (no REQUIREMENTS.md)
    # Resolution order: REQUIREMENTS.md Name -> SPEC.md Name -> SPEC.md H1 -> de-slug
    # Resolution order: REQUIREMENTS.md Description -> SPEC.md Description -> null
    if req_title is None or req_description is None:
        spec_path = work_dir / "SPEC.md"
        spec_title, spec_description, spec_h1, spec_bytes = parse_spec_md(spec_path)
        bytes_read += spec_bytes
        if req_title is None:
            # Prefer SPEC.md Name over H1; de-slug is the final fallback (set by 'name')
            if spec_title is not None:
                req_title = spec_title
            elif spec_h1 is not None:
                req_title = spec_h1
        if req_description is None and spec_description is not None:
            req_description = spec_description

    # PF-5: parse PLAN.md execution graph to derive lane per task_id
    plan_path = work_dir / "PLAN.md"
    task_lane_map, plan_bytes = parse_execution_graph(plan_path)
    bytes_read += plan_bytes

    # PF-3 + PF-5c: enrich each TaskModel with short_name, delivery, lane
    tasks_dir = work_dir / "tasks"
    enriched_tasks = []
    import re as _re
    _re_delivery = _re.compile(r"^delivery-(\d+)$", _re.IGNORECASE)
    for task in pw.tasks:
        # PF-5c: delivery from STATE Wave column ("delivery-NNN")
        delivery: Optional[int] = None
        if task.wave:
            dm = _re_delivery.match(task.wave.strip())
            if dm:
                delivery = int(dm.group(1))

        # PF-5a/5b: lane from PLAN.md wave-map / prose
        lane: Optional[int] = task_lane_map.get(task.task_id.lower())

        # PF-3: short_name from tasks/task-NNN.md first line
        short_name: Optional[str] = None
        task_file = tasks_dir / f"{task.task_id}.md"
        if task_file.is_file():
            sn, sn_bytes = parse_task_short_name(task_file)
            bytes_read += sn_bytes
            short_name = sn

        enriched_tasks.append(TaskModel(
            task_id=task.task_id,
            type=task.type,
            wave=task.wave,
            status=task.status,
            review_grade=task.review_grade,
            elapsed=task.elapsed,
            notes=task.notes,
            short_name=short_name,
            delivery=delivery,
            lane=lane,
        ))

    # Step 5e: set source_mode; step 5f: lifecycle already set by parsers
    # Step 5g: set updated, pause/block fields
    work_model = WorkModel(
        work_id=work_id,
        name=name,
        lifecycle=pw.lifecycle,
        phase=pw.phase,
        active_skill=pw.active_skill,
        updated=pw.updated,
        created=pw.created,
        pause_reason=pw.pause_reason,
        block_reason=pw.block_reason,
        block_artifact=pw.block_artifact,
        tasks=enriched_tasks,
        pending_inputs=pw.pending_inputs,
        source_mode=pw.source_mode,
        number=work_number,
        title=req_title,
        description=req_description,
        objective=req_objective,
        work_path=pw.work_path,
        recipe=pw.recipe,
        features=pw.features,
        deliverables=pw.deliverables,
    )

    return work_model, parse_warnings, bytes_read, text, state_label


# ---------------------------------------------------------------------------
# Hierarchy detection + hierarchical work model assembly (work-004 Pillar 6)
# ---------------------------------------------------------------------------

_RE_DELIVERY_DIR = _re_mod.compile(r"^delivery-(\d+)$", _re_mod.IGNORECASE)
_RE_TASK_DIR     = _re_mod.compile(r"^(task-\d+)$",     _re_mod.IGNORECASE)


def _detect_hierarchy(work_dir: Path) -> bool:
    """Return True if this work has the new per-unit STATE.md hierarchy.

    Detection rule (Pillar 6): if ANY delivery-NNN/tasks/task-NNN/STATE.md file exists
    under work_dir, the work is hierarchical. Otherwise fall back to monolithic parse.

    Presence-based, per-work: a repo with mixed-vintage works renders all of them.
    Never throws.
    """
    try:
        for entry in work_dir.iterdir():
            if not (entry.is_dir() and _RE_DELIVERY_DIR.match(entry.name)):
                continue
            tasks_dir = entry / "tasks"
            if not tasks_dir.is_dir():
                continue
            try:
                for task_entry in tasks_dir.iterdir():
                    if task_entry.is_dir() and _RE_TASK_DIR.match(task_entry.name):
                        task_state = task_entry / "STATE.md"
                        if task_state.is_file():
                            return True
            except OSError:
                continue
    except OSError:
        pass
    return False


def _read_work_hierarchical(
    work_dir: Path,
    work_id: str,
) -> "tuple[WorkModel, list[str], int, str, str]":
    """Assemble a WorkModel from the per-unit STATE.md hierarchy.

    Reads:
      - work_dir/STATE.md                 -- work-level lifecycle/triage/history
      - work_dir/delivery-NNN/STATE.md    -- delivery lifecycle (SD-8) + gate + Q&A
      - work_dir/delivery-NNN/tasks/task-NNN/STATE.md -- per-task mutable cells
      - work_dir/delivery-NNN/SPEC.md     -- task listing (for short_name / type)
      - work_dir/delivery-NNN/tasks/task-NNN/SPEC.md -- task short name

    Union views assembled:
      - tasks[]: one TaskModel per task, state from per-task STATE.md
      - deliverables[]: one DeliverableRef per delivery, delivery_state from delivery STATE.md
      - pending_inputs: union of all delivery Cross-phase Q&A (Pending entries)

    Work-level lifecycle (Pipeline State/Status block) is read from work STATE.md if present;
    otherwise legacy fallback fires (same as monolithic path).

    Returns (WorkModel, parse_warnings, bytes_read, state_text, state_label).
    state_text is the work-level STATE.md text (for raw_state reuse by read_repo_detail).
    Never raises.
    """
    state_path = work_dir / "STATE.md"
    state_label = f".aid/{work_id}/STATE.md"
    parse_warnings: list[str] = []
    bytes_read = 0

    # Read work-level STATE.md (for Pipeline State / Lifecycle History / Triage)
    if not state_path.is_file():
        parse_warnings.append(
            f"{work_id}: STATE.md not found (hierarchical mode); "
            f"work-level lifecycle will be Unknown."
        )
        work_text = ""
    else:
        try:
            raw = state_path.read_bytes()
            bytes_read += len(raw)
            work_text = raw.decode("utf-8", errors="replace")
        except OSError as exc:
            parse_warnings.append(
                f"{work_id}: STATE.md read error ({exc}); "
                f"work-level lifecycle will be Unknown."
            )
            work_text = ""

    # Parse work-level STATE.md for pipeline/lifecycle/triage fields
    # (reuses the existing parse_state_md -- the tasks[] from this parse are IGNORED
    # in hierarchical mode; the per-unit task STATE.md files are authoritative)
    pw: ParsedWork = parse_state_md(work_text, work_id=work_id, work_dir=work_dir)
    parse_warnings.extend(pw.parse_warnings)

    # Extract display name and number from work_id
    name = _slug_from_work_id(work_id)
    work_number = _number_from_work_id(work_id)

    # Parse REQUIREMENTS.md / SPEC.md for identity fields (same as monolithic path)
    req_path = work_dir / "REQUIREMENTS.md"
    req_title, req_description, req_objective, req_bytes = parse_requirements_md(req_path)
    bytes_read += req_bytes

    if req_title is None or req_description is None:
        spec_path = work_dir / "SPEC.md"
        spec_title, spec_description, spec_h1, spec_bytes = parse_spec_md(spec_path)
        bytes_read += spec_bytes
        if req_title is None:
            if spec_title is not None:
                req_title = spec_title
            elif spec_h1 is not None:
                req_title = spec_h1
        if req_description is None and spec_description is not None:
            req_description = spec_description

    # Parse PLAN.md for lane assignments
    plan_path = work_dir / "PLAN.md"
    task_lane_map, plan_bytes = parse_execution_graph(plan_path)
    bytes_read += plan_bytes

    # -----------------------------------------------------------------------
    # Enumerate deliveries and their tasks from the hierarchy
    # -----------------------------------------------------------------------
    all_tasks: list[TaskModel] = []
    all_deliverables: list[DeliverableRef] = []
    all_pending_inputs: list[PendingInput] = []

    # Enumerate delivery-NNN/ subdirectories
    try:
        delivery_dirs = sorted(
            [
                d for d in work_dir.iterdir()
                if d.is_dir() and _RE_DELIVERY_DIR.match(d.name)
            ],
            key=lambda d: d.name,
        )
    except OSError as exc:
        parse_warnings.append(
            f"{work_id}: could not enumerate delivery dirs ({exc}); "
            f"tasks will be empty."
        )
        delivery_dirs = []

    for delivery_dir in delivery_dirs:
        delivery_id = delivery_dir.name
        # Parse delivery number from "delivery-NNN"
        dm = _RE_DELIVERY_DIR.match(delivery_id)
        delivery_number = int(dm.group(1)) if dm else 0

        # ---- Read delivery-level STATE.md ----
        delivery_state_path = delivery_dir / "STATE.md"
        delivery_state_text = ""
        if delivery_state_path.is_file():
            try:
                raw = delivery_state_path.read_bytes()
                bytes_read += len(raw)
                delivery_state_text = raw.decode("utf-8", errors="replace")
            except OSError as exc:
                parse_warnings.append(
                    f"{work_id}/{delivery_id}: STATE.md read error ({exc}); "
                    f"delivery lifecycle will be unknown."
                )

        pds = parse_delivery_state_md(delivery_state_text, delivery_id=delivery_id)
        parse_warnings.extend(pds.parse_warnings)

        # Accumulate pending Q&A from this delivery's Cross-phase Q&A
        all_pending_inputs.extend(pds.pending_inputs)

        # ---- Enumerate tasks under this delivery ----
        tasks_dir = delivery_dir / "tasks"
        delivery_task_count = 0

        try:
            task_dirs = sorted(
                [
                    t for t in tasks_dir.iterdir()
                    if t.is_dir() and _RE_TASK_DIR.match(t.name)
                ]
                if tasks_dir.is_dir() else [],
                key=lambda t: t.name,
            )
        except OSError as exc:
            parse_warnings.append(
                f"{work_id}/{delivery_id}: could not enumerate task dirs ({exc})."
            )
            task_dirs = []

        for task_dir in task_dirs:
            task_id_str = task_dir.name
            delivery_task_count += 1

            # Read task-level STATE.md
            task_state_path = task_dir / "STATE.md"
            task_state_text = ""
            if task_state_path.is_file():
                try:
                    raw = task_state_path.read_bytes()
                    bytes_read += len(raw)
                    task_state_text = raw.decode("utf-8", errors="replace")
                except OSError as exc:
                    parse_warnings.append(
                        f"{work_id}/{delivery_id}/{task_id_str}: STATE.md read error "
                        f"({exc}); task state will be Unknown."
                    )

            pts = parse_task_state_md(task_state_text, task_id=task_id_str)
            parse_warnings.extend(pts.parse_warnings)

            # Read task SPEC.md for short_name and type
            task_spec_path = task_dir / "SPEC.md"
            short_name: Optional[str] = None
            task_type: str = ""
            if task_spec_path.is_file():
                try:
                    raw = task_spec_path.read_bytes()
                    bytes_read += len(raw)
                    spec_text = raw.decode("utf-8", errors="replace")
                    short_name = _parse_task_spec_short_name(spec_text)
                    task_type = _parse_task_spec_type(spec_text)
                except OSError:
                    pass

            # Lane from PLAN.md wave-map
            lane: Optional[int] = task_lane_map.get(task_id_str.lower())

            all_tasks.append(TaskModel(
                task_id=task_id_str,
                type=task_type,
                wave=delivery_id,          # wave = delivery-NNN in hierarchical works
                status=pts.state,
                review_grade=pts.review,
                elapsed=pts.elapsed,
                notes=pts.notes,
                short_name=short_name,
                delivery=delivery_number,
                lane=lane,
            ))

        # ---- Build DeliverableRef for this delivery ----
        # Use the delivery SPEC.md title as the name, falling back to delivery_id
        delivery_spec_path = delivery_dir / "SPEC.md"
        delivery_name = delivery_id
        if delivery_spec_path.is_file():
            try:
                raw = delivery_spec_path.read_bytes()
                bytes_read += len(raw)
                spec_text = raw.decode("utf-8", errors="replace")
                spec_name = _parse_delivery_spec_title(spec_text)
                if spec_name:
                    delivery_name = spec_name
            except OSError:
                pass

        all_deliverables.append(DeliverableRef(
            number=delivery_number,
            name=delivery_name,
            task_count=delivery_task_count,
            delivery_state=pds.delivery_state,
        ))

    # -----------------------------------------------------------------------
    # Work-level pending_inputs: union of work-level Q&A + per-delivery Q&A
    # (work-level Q&A is already in pw.pending_inputs from parse_state_md)
    # -----------------------------------------------------------------------
    union_pending_inputs = list(pw.pending_inputs) + all_pending_inputs

    # Assemble WorkModel (hierarchical path)
    work_model = WorkModel(
        work_id=work_id,
        name=name,
        lifecycle=pw.lifecycle,
        phase=pw.phase,
        active_skill=pw.active_skill,
        updated=pw.updated,
        created=pw.created,
        pause_reason=pw.pause_reason,
        block_reason=pw.block_reason,
        block_artifact=pw.block_artifact,
        tasks=all_tasks,
        pending_inputs=union_pending_inputs,
        source_mode=pw.source_mode,
        number=work_number,
        title=req_title,
        description=req_description,
        objective=req_objective,
        work_path=pw.work_path,
        recipe=pw.recipe,
        features=pw.features,
        deliverables=all_deliverables,
    )

    return work_model, parse_warnings, bytes_read, work_text, state_label


def _parse_task_spec_short_name(spec_text: str) -> Optional[str]:
    """Extract the short name from a task-level SPEC.md.

    Reads the H1 heading: '# task-NNN: {Title}'
    Returns the title portion, or None if absent.
    Never raises.
    """
    try:
        import re
        _re = re.compile(r"^#\s+task-\d+\s*:\s*(.+)$", re.IGNORECASE)
        for line in spec_text.splitlines():
            stripped = line.strip()
            if not stripped:
                continue
            m = _re.match(stripped)
            if m:
                title = m.group(1).strip().rstrip(".")
                return title if title else None
            break  # first non-blank line didn't match
    except Exception:  # noqa: BLE001
        pass
    return None


def _parse_task_spec_type(spec_text: str) -> str:
    """Extract the task type from a task-level SPEC.md.

    Reads '**Type:** VALUE' line.
    Returns the type string (e.g. 'IMPLEMENT'), or '' if absent.
    Never raises.
    """
    try:
        import re
        _re = re.compile(r"^\*\*Type:\*\*\s*(.+)", re.IGNORECASE)
        for line in spec_text.splitlines():
            m = _re.match(line.strip())
            if m:
                return m.group(1).strip().split()[0]  # first word only
    except Exception:  # noqa: BLE001
        pass
    return ""


def _parse_delivery_spec_title(spec_text: str) -> Optional[str]:
    """Extract the delivery title from a delivery-level SPEC.md.

    Reads the H1 heading: '# Delivery SPEC -- delivery-NNN: {Title}'
    or a shorter form: '# delivery-NNN: {Title}'
    Returns the title portion, or None if absent / no title after colon.
    Never raises.
    """
    try:
        import re
        for line in spec_text.splitlines():
            stripped = line.strip()
            if not stripped.startswith("#"):
                continue
            # Match 'Delivery SPEC -- delivery-NNN: Title' or '# delivery-NNN: Title'
            m = re.match(r"^#+\s+.*delivery-\d+\s*:\s*(.+)$", stripped, re.IGNORECASE)
            if m:
                title = m.group(1).strip()
                # Reject template placeholders
                if title and not title.startswith("{"):
                    return title
            break  # only check the first heading line
    except Exception:  # noqa: BLE001
        pass
    return None


def _minimal_work_model(work_id: str, _warnings: list[str]) -> WorkModel:
    """Return a minimal WorkModel for a work folder with no parseable STATE.md."""
    return WorkModel(
        work_id=work_id,
        name=_slug_from_work_id(work_id),
        lifecycle=Lifecycle.Unknown,
        source_mode=SourceMode.Fallback,
        number=_number_from_work_id(work_id),
        title=None,
        description=None,
        objective=None,
        created=None,
        work_path=None,
        recipe=None,
        features=[],
        deliverables=[],
    )


def _slug_from_work_id(work_id: str) -> str:
    """Extract the display slug from a work_id like 'work-001-aid-dashboard'.

    Returns 'aid-dashboard' (strips leading 'work-NNN-').
    Falls back to the full work_id if it doesn't match the expected pattern.
    """
    import re
    m = re.match(r"^work-\d+-(.+)$", work_id)
    return m.group(1) if m else work_id


def _number_from_work_id(work_id: str) -> Optional[int]:
    """Extract the integer prefix from a work_id like 'work-001-slug'.

    Returns 1 for 'work-001-...', None if the pattern does not match.
    """
    import re
    m = re.match(r"^work-(\d+)-", work_id)
    if m:
        try:
            return int(m.group(1))
        except ValueError:
            pass
    return None
