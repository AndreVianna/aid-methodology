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
# NFR2 (read-only): no write, no append, no lock, no subprocess, no agent/LLM.
# NFR7 (no-LLM):    all derivation is deterministic code; no inference, no model call.
# NFR4 (overhead):  single bounded pass; ReadMeta.bytes_read records total bytes read.
#
# Python 3.11+ stdlib only. Zero third-party deps.

from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path
from typing import Optional, Union

from .locator import locate_aid_root
from .models import (
    Lifecycle,
    ReadMeta,
    RepoInfo,
    RepoModel,
    SourceMode,
    TaskModel,
    ToolInfo,
    WorkModel,
)
from .parsers import (
    ParsedWork,
    parse_execution_graph,
    parse_kb_state,
    parse_project_name,
    parse_requirements_md,
    parse_spec_md,
    parse_state_md,
    parse_task_short_name,
    parse_tool_info,
)


def read_repo(aid_root: Union[str, Path]) -> RepoModel:
    """Read AID state for the repo at aid_root and return a normalized RepoModel.

    Single pure, idempotent filesystem pass. No writes, no locks, no subprocess,
    no agent/LLM (NFR2/NFR7).

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
        return RepoModel(
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

    # Step 2: LEVEL-0 -- ToolInfo (LC-2)
    tool_info, br = parse_tool_info(loc.manifest_path, loc.version_path)
    bytes_read += br

    # Step 3: LEVEL-1 -- RepoInfo + KbStateRef (LC-2)
    project_name, br = parse_project_name(loc.settings_path)
    bytes_read += br
    if not project_name:
        project_name = root.name  # fallback: folder basename (SPEC DM-7 note)

    kb_state, br = parse_kb_state(loc.kb_dir)
    bytes_read += br

    repo_info = RepoInfo(
        project_name=project_name,
        aid_dir=str(loc.aid_dir),
        kb_state=kb_state,
    )

    # Step 4: ENUMERATE -- work folders already enumerated by LC-1 locator
    # Steps 5a-5g: PER WORK -- parse STATE.md; build WorkModel list
    works: list[WorkModel] = []
    fallback_works: list[str] = []

    for work_dir in loc.work_dirs:
        work_id = work_dir.name
        work_model, work_warnings, work_bytes = _read_work(work_dir, work_id)
        works.append(work_model)
        parse_warnings.extend(work_warnings)
        bytes_read += work_bytes
        if work_model.source_mode != SourceMode.Normalized:
            fallback_works.append(work_id)

    # Step 6: ASSEMBLE
    return RepoModel(
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


def _read_work(
    work_dir: Path, work_id: str
) -> tuple[WorkModel, list[str], int]:
    """Read and parse a single work folder's STATE.md.

    Steps 5a-5g of the Feature Flow, per-work.

    Returns (WorkModel, parse_warnings, bytes_read).
    Never raises: any exception yields a parse_warning + best-effort WorkModel.
    """
    state_path = work_dir / "STATE.md"
    parse_warnings: list[str] = []
    bytes_read = 0

    # Step 5a: read STATE.md once into memory (single file read)
    if not state_path.is_file():
        parse_warnings.append(
            f"{work_id}: STATE.md not found; returning minimal WorkModel."
        )
        return _minimal_work_model(work_id, parse_warnings), parse_warnings, 0

    try:
        raw = state_path.read_bytes()
        bytes_read = len(raw)
        text = raw.decode("utf-8", errors="replace")
    except OSError as exc:
        parse_warnings.append(
            f"{work_id}: STATE.md read error ({exc}); returning minimal WorkModel."
        )
        return _minimal_work_model(work_id, parse_warnings), parse_warnings, 0

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

    return work_model, parse_warnings, bytes_read


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
