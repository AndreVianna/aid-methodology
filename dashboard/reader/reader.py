# dashboard/reader/reader.py
# Public entry point: read_repo(aid_root) -> RepoModel
#
# Feature-002 Feature Flow (step numbers match the SPEC.md):
#   1. RESOLVE    verify aid_root/.aid exists; absent -> empty RepoModel + parse_warning
#   2. LEVEL-0    parse .aid/.aid-manifest.json (+ .aid/.aid-version)    -> ToolInfo
#   3. LEVEL-1    parse .aid/settings.yml + stat .aid/knowledge/          -> RepoInfo
#   4. ENUMERATE  glob .aid/work-NNN-*/ (dirs only; FR12)                -> work_id list
#   5. PER WORK   read STATE.md once; parse normalized block + tasks + Q&A -> WorkModel list
#   6. ASSEMBLE   RepoModel{tool, repo, works, read=ReadMeta}             -> return
#
# This module is the ONLY place that performs filesystem I/O for the whole pass.
# LC-1 Locator is in locator.py; LC-2 Parsers are in parsers.py.
#
# No write / no LLM / one read-only `git log` subprocess for KB freshness (FR35).
# NFR7 (no-LLM):    all derivation is deterministic code; no inference, no model call.
# NFR4 (overhead):  single bounded pass; ReadMeta.bytes_read records total bytes read.
#
# Python 3.11+ stdlib only. Zero third-party deps.

from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path
from typing import Optional, Union

from .derivation import derive_kb_status
from .locator import locate_aid_root
from .models import (
    DeferredIssue,
    Finding,
    Lifecycle,
    LogAvailability,
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
    parse_tool_info,
)


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

    # Step 4: ENUMERATE -- work folders already enumerated by LC-1 locator
    # Steps 5a-5g: PER WORK -- parse STATE.md; build WorkModel list
    works: list[WorkModel] = []
    fallback_works: list[str] = []
    # Build per-work STATE.md cache as a by-product of the always-on pass.
    # DR-1/DD-3/NFR4: read_repo_detail reuses these bytes; zero extra disk I/O.
    state_text_cache: dict[str, tuple[str, str]] = {}

    for work_dir in loc.work_dirs:
        work_id = work_dir.name
        work_model, work_warnings, work_bytes, state_text, state_label = _read_work(
            work_dir, work_id
        )
        works.append(work_model)
        parse_warnings.extend(work_warnings)
        bytes_read += work_bytes
        state_text_cache[work_id] = (state_text, state_label)
        if work_model.source_mode != SourceMode.Normalized:
            fallback_works.append(work_id)

    # Step 6: ASSEMBLE
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

    Returns (WorkModel, parse_warnings, bytes_read, state_text, state_label).
    state_text is the decoded STATE.md content (empty string on error/absent).
    state_label is the relative path label for raw_state (e.g. '.aid/work-001/STATE.md').
    Never raises: any exception yields a parse_warning + best-effort WorkModel.
    """
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
