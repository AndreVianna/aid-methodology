"""
test_task011_golden_master.py -- task-011 (work-009-refactor delivery-001):
cross-format, cross-runtime characterization suite -- AC-2 oracle in its
GOLDEN-MASTER form (SPEC.md SS SP-8, SS L-9), NOT a live four-way comparison.

Three legs, and which BUILD reads which tree is part of the specification
(SPEC.md SS SP-8):

  (a) RECORD THE BASELINE. The legacy-markdown fixture tree (the CURRENT-SHAPE
      dual-format STATE.md: a YAML frontmatter fence carrying the machine
      scalars, plus a markdown body carrying the AUTHORED prose sections --
      exactly the shape `bin/aid`'s `_aid_sc_convert_file` expects as input,
      and exactly what this repo's OWN pre-task-010 work folders still look
      like, e.g. `.aid/works/work-009-refactor/STATE.md` at authoring time)
      is read by the PRE-refactor `dashboard/reader` (Python) and
      `dashboard/server/reader.mjs` (Node). This is an AUTHORING-TIME step,
      performed ONCE (see `_authoring_capture_notes` below and the task's own
      report) by materializing the pre-refactor revision
      (`git show 21bf9636:dashboard/reader/...` -- the commit immediately
      before task-003/task-004 touched either reader) into a scratch
      checkout. The two payloads were recorded equal on every field below
      with no `parse_warning`, and that payload is committed here as the
      golden baseline fixture (`fixtures/task011_golden/*.json`) -- a test
      fixture, not a work-folder artifact (`CLAUDE.md SS Tracking discipline`).
      THE COMMITTED SUITE DOES NOT RE-RUN THIS STEP: it reads the committed
      JSON only. No `git ` invocation and no `subprocess` call naming git
      appears below (grep-verifiable) -- CI clones shallowly.

  (b) COMPARE THE CONVERSION. The SAME legacy-markdown fixture tree is
      converted by the REAL task-008 converter (`bin/aid __migrate-repo`,
      invoked via an isolated `AID_HOME`/`HOME`, exactly
      `tests/canonical/test-aid-migrate.sh`'s own `run_migrate` isolation
      idiom) and the result is read by the POST-refactor Python
      (`dashboard.reader.read_repo`/`read_repo_detail`) and Node
      (`reader.mjs`'s `readRepo`/`readRepoDetail`) twins. Both payloads must
      equal the committed golden baseline on every field enumerated in Scope,
      with no `parse_warning` from either. Both layouts: flat (the
      `test_flattened_layout_parity.py` shape) and full/hierarchical (the
      `test_task014_fixtures.py` shape), including the per-delivery and
      per-task file levels.

  (c) LEGACY READ DEGRADES IDENTICALLY. The UNCONVERTED legacy tree is read
      by both POST-refactor twins; both must return the minimal-model
      degradation plus the SAME `parse_warning` naming the file and the
      migration command (SP-9, AC-5) -- asserted as the REQUIRED outcome,
      not tolerated as a shortfall of (b).

KI-004 (known-issues.md): the coarse-`updated` fallback only diverges under
THREE simultaneous conditions -- no `lifecycle` key, no `updated` key, AND a
populated `lifecycle_history`. `TestKI004ThreeConditionCase` below builds a
fixture in EXACTLY that shape (a bare monolithic legacy work whose frontmatter
omits `lifecycle`/`updated` entirely) and asserts both post-refactor twins
derive the SAME coarse date from `max(lifecycle_history[].date)`, so this
suite would have caught KI-004 had it existed before task-021's fix.

Do NOT edit: the readers (`dashboard/reader/*.py`, `dashboard/server/reader.mjs`)
or the converter (`bin/aid`'s `_aid_sc_*` functions) are OUT of this task's
edit surface (task-011 Scope). A leg failing because a reader/converter is
wrong (not this suite's fixture/expectation) is a FINDING to report, not a
defect to silently paper over here.

Python 3.11+ stdlib only. No third-party deps. No network. No git history
read at run time (grep this file for 'git ' or 'subprocess' + 'git' to
verify -- the ONLY subprocess targets are `bash <repo>/bin/aid` for the real
converter and `node` for the real Node twin).
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from collections import Counter
from pathlib import Path
from typing import Optional

_REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(_REPO_ROOT))

from dashboard.reader import read_repo, read_repo_detail  # noqa: E402
from dashboard.reader.models import SourceMode  # noqa: E402

_FIXTURES_DIR = Path(__file__).resolve().parent / "fixtures" / "task011_golden"
_READER_MJS = _REPO_ROOT / "dashboard" / "server" / "reader.mjs"
_BIN_AID = _REPO_ROOT / "bin" / "aid"


def _resolve_bash() -> str:
    """Resolve a REAL POSIX-shell `bash` to invoke `bin/aid` with.

    On Windows, a bare `"bash"` argv token can resolve (via `CreateProcess`'s
    own search order, which differs from `shutil.which`) to the WSL
    launcher stub at `C:\\Windows\\System32\\bash.exe` instead of Git for
    Windows' real MSYS bash -- and the WSL stub runs `bash` inside its OWN
    Linux root filesystem, where this repo's Windows path is not mounted
    (`ls: cannot access '/c/...': No such file or directory`, exit 2 --
    confirmed empirically while authoring this suite). Prefer an explicit
    Git-for-Windows bash.exe path when one exists; fall back to the bare
    `"bash"` token everywhere else (a real POSIX host has no such ambiguity).
    """
    if os.name == "nt":
        for candidate in (
            "C:/Program Files/Git/bin/bash.exe",
            "C:/Program Files/Git/usr/bin/bash.exe",
        ):
            if Path(candidate).is_file():
                return candidate
    return "bash"


_BASH = _resolve_bash()


def _node_available() -> bool:
    try:
        subprocess.run(["node", "--version"], capture_output=True, check=True, timeout=5)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        return False


# ---------------------------------------------------------------------------
# Repo scaffold (manifest + settings.yml) -- mirrors the existing precedent
# suites (test_flattened_layout_parity.py / test_task014_fixtures.py).
# ---------------------------------------------------------------------------

def make_repo(tmp: Path) -> tuple[Path, Path]:
    """Return (repo_root, aid_dir) with a minimal manifest + settings.yml.

    era-a marker (`settings.yml` present) so `bin/aid __migrate-repo` treats
    the fixture repo as a real candidate (leg b needs the REAL converter to
    run its STEP 5 state-conversion; the settings-repair steps 1-4 it also
    runs are harmless side effects on this throwaway fixture, isolated by
    the AID_HOME/HOME env pin in `run_migrate_converter` below).
    """
    root = tmp
    aid = root / ".aid"
    aid.mkdir(parents=True, exist_ok=True)
    manifest = {
        "manifest_version": 1,
        "aid_version": "1.0.0",
        "installed_at": "2026-01-01T00:00:00Z",
        "tools": {"claude-code": {}},
    }
    (aid / ".aid-manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
    (aid / "settings.yml").write_text("project:\n  name: TestRepo\n", encoding="utf-8")
    return root, aid


# ---------------------------------------------------------------------------
# Legacy CURRENT-SHAPE dual-format markdown builders.
#
# Shape verified against TWO independent sources: (1) `bin/aid`'s
# `_aid_sc_convert_*` family (the REAL converter this suite's leg (b) runs),
# which requires a `---`-fenced YAML frontmatter block followed by a
# markdown body scanned for specific `##`/`###` headings; (2) this repo's
# OWN pre-task-010 work folder (`.aid/works/work-009-refactor/STATE.md`,
# read for its SHAPE ONLY -- never as fixture CONTENT, per C-6/Scope: no
# work folder's contents are an input to this suite).
# ---------------------------------------------------------------------------

def _fm_line(key: str, value: str) -> str:
    return f"{key}: {value}"


def flat_work_frontmatter(
    *,
    lifecycle: Optional[str] = "Running",
    phase: Optional[str] = "Execute",
    active_skill: Optional[str] = "aid-execute",
    updated: Optional[str] = "2026-06-01T09:00:00Z",
    delivery_state: Optional[str] = "Executing",
    gate_tier: Optional[str] = "Small",
    gate_grade: Optional[str] = "A",
    gate_timestamp: Optional[str] = "2026-06-01T10:00:00Z",
) -> str:
    """Frontmatter fence for a FLAT (lite) legacy work's work-root STATE.md."""
    lines = ["---", "pipeline:", "  path: lite", "  initiator: aid-refactor"]
    if lifecycle is not None:
        lines.append(_fm_line("lifecycle", lifecycle))
    if phase is not None:
        lines.append(_fm_line("phase", phase))
    if active_skill is not None:
        lines.append(_fm_line("active_skill", active_skill))
    if updated is not None:
        lines.append(_fm_line("updated", f"'{updated}'"))
    lines.append("pause_reason: --")
    lines.append("block_reason: --")
    lines.append("block_artifact: --")
    if delivery_state is not None:
        lines.append(_fm_line("delivery_state", delivery_state))
    if gate_tier is not None:
        lines.append(_fm_line("gate_tier", gate_tier))
    if gate_grade is not None:
        lines.append(_fm_line("gate_grade", gate_grade))
    if gate_timestamp is not None:
        lines.append(_fm_line("gate_timestamp", f"'{gate_timestamp}'"))
    lines.append("---")
    return "\n".join(lines) + "\n"


def _lifecycle_history_table(rows: list[tuple[str, str, str, str]]) -> str:
    """rows: list of (date, event, grade, notes)."""
    out = [
        "## Lifecycle History",
        "",
        "| Date | Phase Transition / Gate | Grade | Notes |",
        "|------|------------------------|-------|-------|",
    ]
    for date, event, grade, notes in rows:
        out.append(f"| {date} | {event} | {grade} | {notes} |")
    out.append("")
    return "\n".join(out)


def build_flat_legacy_work(
    aid: Path,
    work_id: str,
    tasks: list[dict],
    *,
    history_rows: Optional[list[tuple[str, str, str, str]]] = None,
    qa_entries: Optional[list[tuple[str, str, str, str]]] = None,  # (id, state, category, context)
    frontmatter_kwargs: Optional[dict] = None,
    delivery_title: str = "Flat Golden Delivery",
) -> Path:
    """Build a CURRENT-SHAPE dual-format flat (lite) legacy work.

    tasks: [{id, type, title, state, review, elapsed, notes, display_name}, ...]
    """
    work_dir = aid / "works" / work_id
    work_dir.mkdir(parents=True, exist_ok=True)

    (work_dir / "REQUIREMENTS.md").write_text(
        "# Requirements -- Flat Golden Work\n\n"
        "- **Name:** Flat Golden Work\n"
        "- **Description:** task-011 golden-master flat fixture.\n\n"
        "## 1. Objective\n\nProve the golden-master oracle end to end.\n",
        encoding="utf-8",
    )
    (work_dir / "SPEC.md").write_text("# Flat Golden Feature\n\n## Description\n\nN/A.\n", encoding="utf-8")
    (work_dir / "PLAN.md").write_text(
        "# Plan -- Flat Golden Work\n\n## Deliverables\n\n"
        "- **Delivery:** delivery-001 -- Flat Golden Delivery\n\n"
        "## Execution Graph\n\n### Task Dependencies\n\n| Task | Depends On |\n|------|------------|\n",
        encoding="utf-8",
    )
    (work_dir / "BLUEPRINT.md").write_text(
        f"# Delivery BLUEPRINT -- delivery-001: {delivery_title}\n\n"
        "## Objective\n\nDeliver the golden-master flat fixture.\n\n"
        "## Gate Criteria\n\n- [ ] All tests pass\n",
        encoding="utf-8",
    )

    tasks_dir = work_dir / "tasks"
    for task in tasks:
        tid = task["id"]
        tdir = tasks_dir / tid
        tdir.mkdir(parents=True, exist_ok=True)
        (tdir / "DETAIL.md").write_text(
            f"# {tid}: {task.get('title', f'{tid} title')}\n\n"
            f"**Type:** {task.get('type', 'IMPLEMENT')}\n\n"
            f"**Source:** {work_id} -> delivery-001\n\n"
            "**Depends on:** --\n\n**Scope:**\n- fixture scope\n\n"
            "**Acceptance Criteria:**\n- [ ] x\n",
            encoding="utf-8",
        )

    fm_kwargs = dict(frontmatter_kwargs or {})
    fm = flat_work_frontmatter(**fm_kwargs)

    body_parts = [fm, "", "# Work State -- " + work_id, ""]
    body_parts.append(_lifecycle_history_table(history_rows or []))
    body_parts.append("")
    body_parts.append("## Delivery Lifecycle")
    body_parts.append("")
    body_parts.append("- **Updated:** 2026-06-01T09:00:00Z")
    body_parts.append("- **Block Reason:** --")
    body_parts.append("- **Block Artifact:** --")
    body_parts.append("")
    body_parts.append("### Tasks lifecycle")
    body_parts.append("")
    body_parts.append("| Task | State | Review | Elapsed | Notes | Name |")
    body_parts.append("|------|-------|--------|---------|-------|------|")
    for task in tasks:
        body_parts.append(
            f"| {task['id']} | {task.get('state', 'Pending')} | {task.get('review', '--')} | "
            f"{task.get('elapsed', '--')} | {task.get('notes', '--')} | {task.get('display_name', '--')} |"
        )
    body_parts.append("")
    body_parts.append("## Delivery Gate")
    body_parts.append("")
    body_parts.append("- **Issue List:** none")
    body_parts.append("")
    if qa_entries:
        body_parts.append("## Cross-phase Q&A")
        body_parts.append("")
        for qid, state, category, context in qa_entries:
            body_parts.append(f"### {qid}")
            body_parts.append("")
            body_parts.append(f"- **Category:** {category}")
            body_parts.append("- **Impact:** Medium")
            body_parts.append(f"- **State:** {state}")
            body_parts.append(f"- **Context:** {context}")
            body_parts.append("")

    (work_dir / "STATE.md").write_text("\n".join(body_parts), encoding="utf-8")
    return work_dir


def delivery_frontmatter(
    *,
    delivery_state: str = "Executing",
    gate_tier: str = "Small",
    gate_grade: str = "Pending",
    gate_timestamp: str = "--",
) -> str:
    return "\n".join([
        "---",
        _fm_line("delivery_state", delivery_state),
        _fm_line("gate_tier", gate_tier),
        _fm_line("gate_grade", gate_grade),
        _fm_line("gate_timestamp", gate_timestamp if gate_timestamp == "--" else f"'{gate_timestamp}'"),
        "---",
    ]) + "\n"


def task_frontmatter(
    *,
    state: str = "Pending",
    review: str = "--",
    elapsed: str = "--",
    notes: str = "--",
    display_name: str = "--",
) -> str:
    return "\n".join([
        "---",
        _fm_line("state", state),
        _fm_line("review", review),
        _fm_line("elapsed", elapsed),
        _fm_line("notes", notes),
        _fm_line("display_name", display_name),
        "---",
    ]) + "\n"


def build_hierarchical_legacy_work(
    aid: Path,
    work_id: str,
    deliveries: list[dict],
    *,
    history_rows: Optional[list[tuple[str, str, str, str]]] = None,
    work_lifecycle: str = "Running",
    work_phase: str = "Execute",
    work_active_skill: str = "aid-execute",
    work_updated: str = "2026-06-10T09:00:00Z",
) -> Path:
    """Build a CURRENT-SHAPE dual-format hierarchical (full) legacy work.

    deliveries: [{id, title, state, gate_tier, gate_grade, gate_timestamp,
                  qa: [(id, state, category, context), ...],
                  tasks: [{id, type, title, state, review, elapsed, notes, display_name}]}]
    """
    work_dir = aid / "works" / work_id
    work_dir.mkdir(parents=True, exist_ok=True)

    (work_dir / "REQUIREMENTS.md").write_text(
        "# Requirements -- Hierarchical Golden Work\n\n"
        "- **Name:** Hierarchical Golden Work\n"
        "- **Description:** task-011 golden-master hierarchical fixture.\n\n"
        "## 1. Objective\n\nProve the golden-master oracle across delivery/task files.\n",
        encoding="utf-8",
    )

    work_fm = "\n".join([
        "---",
        _fm_line("lifecycle", work_lifecycle),
        _fm_line("phase", work_phase),
        _fm_line("active_skill", work_active_skill),
        _fm_line("updated", f"'{work_updated}'"),
        "pause_reason: --",
        "block_reason: --",
        "block_artifact: --",
        "---",
    ]) + "\n"
    work_body = [work_fm, "", "# Work State -- " + work_id, ""]
    work_body.append(_lifecycle_history_table(history_rows or []))
    (work_dir / "STATE.md").write_text("\n".join(work_body), encoding="utf-8")

    for deliv in deliveries:
        did = deliv["id"]
        ddir = work_dir / "deliveries" / did
        (ddir / "tasks").mkdir(parents=True, exist_ok=True)

        (ddir / "BLUEPRINT.md").write_text(
            f"# Delivery BLUEPRINT -- {did}: {deliv.get('title', f'{did} scope')}\n\n"
            "Delivery scope and gate criteria.\n",
            encoding="utf-8",
        )

        d_fm = delivery_frontmatter(
            delivery_state=deliv.get("state", "Executing"),
            gate_tier=deliv.get("gate_tier", "Small"),
            gate_grade=deliv.get("gate_grade", "Pending"),
            gate_timestamp=deliv.get("gate_timestamp", "--"),
        )
        d_body = [d_fm, "", f"# Delivery State -- {did}", ""]
        d_body.append("## Delivery Lifecycle")
        d_body.append("")
        d_body.append("- **Updated:** 2026-06-10T09:00:00Z")
        d_body.append("- **Block Reason:** --")
        d_body.append("- **Block Artifact:** --")
        d_body.append("")
        d_body.append("## Delivery Gate")
        d_body.append("")
        d_body.append("- **Issue List:** none")
        d_body.append("")
        qa = deliv.get("qa") or []
        if qa:
            d_body.append("## Cross-phase Q&A")
            d_body.append("")
            for qid, state, category, context in qa:
                d_body.append(f"### {qid}")
                d_body.append("")
                d_body.append(f"- **Category:** {category}")
                d_body.append("- **Impact:** Medium")
                d_body.append(f"- **State:** {state}")
                d_body.append(f"- **Context:** {context}")
                d_body.append("")
        (ddir / "STATE.md").write_text("\n".join(d_body), encoding="utf-8")

        for task in deliv.get("tasks", []):
            tid = task["id"]
            tdir = ddir / "tasks" / tid
            tdir.mkdir(parents=True, exist_ok=True)
            (tdir / "DETAIL.md").write_text(
                f"# {tid}: {task.get('title', f'{tid} title')}\n\n"
                f"**Type:** {task.get('type', 'IMPLEMENT')}\n\nBody of the task spec.\n",
                encoding="utf-8",
            )
            t_fm = task_frontmatter(
                state=task.get("state", "Pending"),
                review=task.get("review", "--"),
                elapsed=task.get("elapsed", "--"),
                notes=task.get("notes", "--"),
                display_name=task.get("display_name", "--"),
            )
            (tdir / "STATE.md").write_text(t_fm + "\n# Task State\n", encoding="utf-8")

    return work_dir


def build_ki004_legacy_work(
    aid: Path,
    work_id: str,
    history_rows: list[tuple[str, str, str, str]],
) -> Path:
    """KI-004 three-condition case: a bare monolithic legacy work whose
    frontmatter carries NEITHER `lifecycle` NOR `updated` (only the
    unrelated pause/block scalars), with a POPULATED `## Lifecycle History`
    table -- the exact shape that triggers the coarse-`updated` fallback and
    that KI-004 records as the divergence trigger (known-issues.md KI-004).
    """
    work_dir = aid / "works" / work_id
    work_dir.mkdir(parents=True, exist_ok=True)
    fm = "\n".join([
        "---",
        "pause_reason: --",
        "block_reason: --",
        "block_artifact: --",
        "---",
    ]) + "\n"
    body = [fm, "", "# Work State -- " + work_id, ""]
    body.append(_lifecycle_history_table(history_rows))
    (work_dir / "STATE.md").write_text("\n".join(body), encoding="utf-8")
    return work_dir


# ---------------------------------------------------------------------------
# Payload extraction (shared shape between the authoring-time OLD-reader
# capture and this suite's NEW-reader runtime reads -- kept as one function
# so leg (a)'s baseline and leg (b)'s comparison can never drift on WHICH
# fields are compared).
# ---------------------------------------------------------------------------

def _enum_value(v):
    return v.value if hasattr(v, "value") else v


def derived_counts(tasks) -> dict:
    """Recomputed FRESH from tasks[] every call -- proves no rollup is
    persisted by the conversion (SP-3, C-8): the SAME function applied to
    the golden-baseline task list and to a live-read task list must agree.
    """
    statuses = [_enum_value(t.status if hasattr(t, "status") else t["status"]) for t in tasks]
    counts = Counter(statuses)
    total = len(tasks)
    done = counts.get("Done", 0)
    pct = round(100.0 * done / total, 2) if total else 0.0
    return {"total": total, "by_status": dict(sorted(counts.items())), "done_pct": pct}


def without_node_unexposed_fields(payload: dict) -> dict:
    """Drop the ONE field Node's public `readRepo()`/`readRepoDetail()` never
    exposes on a `DeliverableRef`, in EITHER era: `delivery_state`.

    Verified by inspection of BOTH `reader.mjs` (current) and the extracted
    pre-refactor `reader_OLD.mjs`: `_buildDeliverableRef` strips it with an
    explicit comment -- "Python server.py _ser_deliverable_ref omits it for
    parity. Both runtimes emit the same key set until server.py is updated
    to serialize it." -- present, byte-for-byte, in both revisions. This is
    a PRE-EXISTING Node-side API-shape asymmetry between `dashboard/server/
    reader.mjs` (which conflates "raw model" and "server-response shape" in
    one file) and `dashboard/reader/reader.py` (whose `read_repo()` returns
    the true raw dataclass, with server-response stripping happening later,
    in the separate `dashboard/server/server.py`) -- NOT a task-011/task-004
    regression, and NOT something this suite's Do-Not-edit-the-readers
    constraint permits fixing here. `delivery_state` is still asserted via
    the PYTHON leg (`test_python_matches_golden_baseline`); this helper is
    applied ONLY when comparing a NODE-derived payload against a Python-
    shaped one (the golden baseline, or another Python read)."""
    out = json.loads(json.dumps(payload))  # deep copy
    for d in out.get("deliverables", []):
        d.pop("delivery_state", None)
    return out


def extract_work_payload(w, ledger=None) -> dict:
    """Extract the Scope-enumerated field set from one WorkModel (Python
    dataclass instance -- works identically against the OLD and NEW
    `dashboard.reader.models.WorkModel`, whose relevant fields are byte-
    identical dataclasses per SPEC.md D-1)."""
    deliverables = sorted(
        (
            {
                "number": d.number,
                "name": d.name,
                "task_count": d.task_count,
                "delivery_state": d.delivery_state,
            }
            for d in w.deliverables
        ),
        key=lambda x: x["number"],
    )
    tasks = sorted(
        (
            {
                "task_id": t.task_id,
                "type": t.type,
                "wave": t.wave,
                "status": _enum_value(t.status),
                "review_grade": t.review_grade,
                "elapsed": t.elapsed,
                "notes": t.notes,
                "short_name": t.short_name,
                "delivery": t.delivery,
                "display_name": t.display_name,
            }
            for t in w.tasks
        ),
        key=lambda x: x["task_id"],
    )
    pending_inputs = sorted(
        (
            {
                "question_id": p.question_id,
                "category": p.category,
                "impact": p.impact,
                "context": p.context,
                "suggested": p.suggested,
            }
            for p in w.pending_inputs
        ),
        key=lambda x: x["question_id"],
    )
    return {
        "lifecycle": _enum_value(w.lifecycle),
        "phase": _enum_value(w.phase) if w.phase is not None else None,
        "active_skill": w.active_skill,
        "updated": w.updated,
        "created": w.created,
        "source_mode": _enum_value(w.source_mode),
        "deliverables": deliverables,
        "tasks": tasks,
        "pending_inputs": pending_inputs,
        "counts": derived_counts(w.tasks),
        "gate": (
            {
                "grade": ledger.grade,
                "reviewer_tier": ledger.reviewer_tier,
                "gate_timestamp": ledger.gate_timestamp,
            }
            if ledger is not None
            else None
        ),
    }


def read_payload_python(root: Path, work_id: str, gate_task_id: Optional[str] = None) -> tuple[dict, list[str]]:
    """Read `root` with the (POST-refactor, this repo's) Python twin and
    extract `work_id`'s payload. Returns (payload, parse_warnings)."""
    if gate_task_id:
        model, details = read_repo_detail(root, detail_task_ids=[f"{work_id}/{gate_task_id}"])
        ledger = details.get(f"{work_id}/{gate_task_id}")
        ledger = ledger.ledger if ledger is not None else None
    else:
        model = read_repo(root)
        ledger = None
    work = next((w for w in model.works if w.work_id == work_id), None)
    if work is None:
        return {}, list(model.read.parse_warnings)
    return extract_work_payload(work, ledger), list(model.read.parse_warnings)


# ---------------------------------------------------------------------------
# Node (POST-refactor reader.mjs) extraction -- one generic script, driven
# by JSON args, mirroring the existing precedent suites' subprocess idiom.
# ---------------------------------------------------------------------------

_NODE_SCRIPT_TEMPLATE = """
import {{ readRepo, readRepoDetail }} from {reader_uri};
const root = {root};
const workId = {work_id};
const gateTaskId = {gate_task_id};
let model, ledger = null;
if (gateTaskId) {{
  const r = readRepoDetail(root, [workId + "/" + gateTaskId]);
  model = r.model;
  const d = r.details[workId + "/" + gateTaskId];
  ledger = d ? d.ledger : null;
}} else {{
  model = readRepo(root);
}}
const w = (model.works || []).find(x => x.work_id === workId);
function payload(w) {{
  if (!w) return null;
  // delivery_state deliberately NOT read here: readRepo()'s _buildDeliverableRef
  // strips it (pre-existing, documented server.py-parity omission -- see
  // without_node_unexposed_fields() on the Python side of this suite).
  const deliverables = (w.deliverables || []).map(d => ({{
    number: d.number, name: d.name, task_count: d.task_count,
  }})).sort((a, b) => a.number - b.number);
  const tasks = (w.tasks || []).map(t => ({{
    task_id: t.task_id, type: t.type, wave: t.wave, status: t.status,
    review_grade: t.review_grade, elapsed: t.elapsed, notes: t.notes,
    short_name: t.short_name, delivery: t.delivery, display_name: t.display_name,
  }})).sort((a, b) => a.task_id < b.task_id ? -1 : a.task_id > b.task_id ? 1 : 0);
  const pending_inputs = (w.pending_inputs || []).map(p => ({{
    question_id: p.question_id, category: p.category, impact: p.impact,
    context: p.context, suggested: p.suggested,
  }})).sort((a, b) => a.question_id < b.question_id ? -1 : a.question_id > b.question_id ? 1 : 0);
  const statusCounts = {{}};
  for (const t of tasks) {{ statusCounts[t.status] = (statusCounts[t.status] || 0) + 1; }}
  const total = tasks.length;
  const done = statusCounts["Done"] || 0;
  const donePct = total ? Math.round((100.0 * done / total) * 100) / 100 : 0.0;
  return {{
    lifecycle: w.lifecycle, phase: w.phase, active_skill: w.active_skill,
    updated: w.updated, created: w.created, source_mode: w.source_mode,
    deliverables: deliverables, tasks: tasks, pending_inputs: pending_inputs,
    counts: {{ total: total, by_status: statusCounts, done_pct: donePct }},
    gate: ledger ? {{ grade: ledger.grade, reviewer_tier: ledger.reviewer_tier, gate_timestamp: ledger.gate_timestamp }} : null,
  }};
}}
process.stdout.write(JSON.stringify({{
  payload: payload(w),
  parse_warnings: (model.read && model.read.parse_warnings) || [],
}}) + "\\n");
"""


def read_payload_node(root: Path, work_id: str, gate_task_id: Optional[str] = None) -> tuple[dict, list[str]]:
    script = _NODE_SCRIPT_TEMPLATE.format(
        reader_uri=repr(_READER_MJS.as_uri()),
        root=json.dumps(str(root)),
        work_id=json.dumps(work_id),
        gate_task_id=json.dumps(gate_task_id),
    )
    pinned_home = Path(tempfile.mkdtemp())
    try:
        result = subprocess.run(
            ["node", "--input-type=module"],
            input=script,
            capture_output=True,
            text=True,
            timeout=20,
            env={**os.environ, "HOME": str(pinned_home)},
        )
        if result.returncode != 0:
            raise RuntimeError(f"Node script error: {result.stderr[:2000]}")
        data = json.loads(result.stdout.strip())
        return data.get("payload") or {}, data.get("parse_warnings") or []
    finally:
        shutil.rmtree(pinned_home, ignore_errors=True)


# ---------------------------------------------------------------------------
# The REAL task-008 converter (`bin/aid __migrate-repo`), run in an isolated
# environment -- the SAME isolation idiom as
# `tests/canonical/test-aid-migrate.sh`'s `run_migrate` helper (AID_HOME +
# HOME pinned to throwaway dirs; AID_NO_UPDATE_CHECK=1). Uses THIS repo's
# own `bin/aid` (which self-locates AID_CODE_HOME as its own parent,
# already holding lib/aid-install-core.sh + VERSION) rather than staging a
# copy -- no NEW isolation surface, same net effect.
# ---------------------------------------------------------------------------

def _posix(p: Path) -> str:
    """POSIX-slash form of an absolute Windows path for passing as a bash
    argv token -- Git Bash's argv parsing treats a raw backslash as an
    escape character, so `C:\\Projects\\...\\bin\\aid` arrives mangled
    (e.g. `C:ProjectsAID...binaid`). `Path.as_posix()` sidesteps this; a
    POSIX host's paths already use forward slashes, so this is a no-op there."""
    return p.as_posix()


def run_migrate_converter(repo_root: Path) -> tuple[int, str]:
    state_home = Path(tempfile.mkdtemp())
    fake_home = Path(tempfile.mkdtemp())
    try:
        result = subprocess.run(
            [_BASH, _posix(_BIN_AID), "__migrate-repo", _posix(repo_root)],
            capture_output=True,
            text=True,
            timeout=30,
            env={
                **os.environ,
                "AID_HOME": str(state_home),
                "HOME": str(fake_home),
                "AID_NO_UPDATE_CHECK": "1",
            },
        )
        return result.returncode, result.stdout + result.stderr
    finally:
        shutil.rmtree(state_home, ignore_errors=True)
        shutil.rmtree(fake_home, ignore_errors=True)


def _bash_available() -> bool:
    try:
        subprocess.run([_BASH, "--version"], capture_output=True, check=True, timeout=5)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        return False


# `_aid_sc_convert_file`'s frontmatter-fence detector reads the file line by
# line via `while IFS= read -r _l || [[ -n "$_l" ]]; do _SC_LINES+=("${_l%$'\r'}");
# done` -- stripping a CRLF file's trailing CR before comparing the first
# line to the literal string `---`. A specific local Cygwin-packaged bash
# build (verified empirically while authoring this suite: GNU bash
# 5.3.9(1)-release, x86_64-pc-cygwin -- found identically at BOTH
# `C:\Program Files\Git\bin\bash.exe` and `...\usr\bin\bash.exe` on this
# machine) has a genuine array-append parameter-expansion bug: `ARR+=("${x%
# $'\r'}")` silently fails to strip the CR (confirmed in isolation -- a
# plain `y="${x%$'\r'}"` or an indexed `ARR[0]=...` assignment strips it
# correctly; ONLY the `+=()` append form with an inline ANSI-C-quoted
# removal pattern in the SAME word is affected). That makes EVERY legacy
# CRLF fixture (real ones included) look like it has "no frontmatter fence"
# to THIS bash -- a LOCAL environment defect, not a `bin/aid` bug and not a
# task-011 fixture bug (LF-only fixtures are unaffected, but this repo's
# real dual-format work-tree STATE.md files are CRLF on Windows). Probed
# ONCE per bash resolved, so a genuinely fixed/different bash (CI's, most
# likely) exercises the real converter instead of skipping.
_CRLF_PROBE_SCRIPT = r"""
tmpf="$1"
_SC_LINES=()
_l=""
while IFS= read -r _l || [[ -n "$_l" ]]; do
    _SC_LINES+=("${_l%$'\r'}")
done < "$tmpf"
if [[ "${_SC_LINES[0]}" == "---" ]]; then echo OK; else echo BAD; fi
"""


def _bash_crlf_strip_ok() -> bool:
    probe = Path(tempfile.mkdtemp()) / "probe.txt"
    probe.write_bytes(b"---\r\nkey: value\r\n")
    try:
        result = subprocess.run(
            [_BASH, "-c", _CRLF_PROBE_SCRIPT, "_", _posix(probe)],
            capture_output=True, text=True, timeout=10,
        )
        return result.stdout.strip() == "OK"
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired, OSError):
        return False
    finally:
        shutil.rmtree(probe.parent, ignore_errors=True)


# ---------------------------------------------------------------------------
# Golden baseline loader
# ---------------------------------------------------------------------------

def load_golden(name: str) -> dict:
    path = _FIXTURES_DIR / f"{name}.json"
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


_REQUIRED_BASELINE_KEYS = {
    "lifecycle", "phase", "active_skill", "updated", "created", "source_mode",
    "deliverables", "tasks", "pending_inputs", "counts", "gate",
}


# ===========================================================================
# Leg (a): the golden baseline exists as a committed fixture payload,
# produced (authoring-time, see module docstring) by the pre-refactor
# readers, equal on every field with no parse_warning (AC-1/AC-2a, SP-8a).
# ===========================================================================

class TestGoldenBaselineRecorded(unittest.TestCase):
    """AC-2(a)/SP-8(a): the golden baseline is a committed fixture, not a
    live re-derivation. This class proves the committed artifact itself is
    well-formed and carries every Scope-enumerated field -- it does NOT
    re-invoke the pre-refactor readers (that was the one-time authoring
    step; see the module docstring and this task's own report for the
    equal/no-parse_warning evidence recorded at authoring time)."""

    def test_flat_baseline_exists_and_well_formed(self):
        """AC-2(a): flat_golden.json exists, parses, and has every Scope field."""
        data = load_golden("flat_golden")
        self.assertEqual(set(data.keys()), _REQUIRED_BASELINE_KEYS)
        self.assertEqual(data["lifecycle"], "Running")
        self.assertGreaterEqual(len(data["tasks"]), 2)

    def test_hierarchical_baseline_exists_and_well_formed(self):
        """AC-2(a): hierarchical_golden.json exists, parses, and has every Scope field."""
        data = load_golden("hierarchical_golden")
        self.assertEqual(set(data.keys()), _REQUIRED_BASELINE_KEYS)
        self.assertGreaterEqual(len(data["deliverables"]), 2)

    def test_ki004_baseline_exists_and_well_formed(self):
        """AC-2(a)/KI-004: ki004_golden.json exists and records the coarse-
        updated fallback value the pre-refactor reader derived from
        ## Lifecycle History for the three-condition fixture."""
        data = load_golden("ki004_golden")
        self.assertEqual(set(data.keys()), _REQUIRED_BASELINE_KEYS)
        self.assertIsNotNone(data["updated"], "KI-004 fixture must have a derived coarse updated")

    def test_legacy_read_no_parse_warning_recorded(self):
        """AC-2(a)/SP-8(a): the recorded baseline metadata confirms the
        pre-refactor leg (a) read raised no parse_warning on either twin
        (recorded at authoring time; see the sibling _meta.json)."""
        meta_path = _FIXTURES_DIR / "_authoring_meta.json"
        self.assertTrue(meta_path.is_file(), "authoring metadata must be committed")
        meta = json.loads(meta_path.read_text(encoding="utf-8"))
        for work_key in ("flat_golden", "hierarchical_golden", "ki004_golden"):
            entry = meta[work_key]
            self.assertEqual(entry["old_python_warnings"], [],
                              f"{work_key}: pre-refactor Python must raise no parse_warning")
            self.assertEqual(entry["old_node_warnings"], [],
                              f"{work_key}: pre-refactor Node must raise no parse_warning")
            self.assertTrue(entry["old_python_equals_old_node"],
                             f"{work_key}: pre-refactor Python/Node payloads must be equal")


# ===========================================================================
# Leg (b): flat layout -- post-refactor twins' reads of the CONVERTED tree
# equal the committed golden baseline (SP-8b, AC-2b).
# ===========================================================================

class TestFlatConversionParity(unittest.TestCase):
    """SP-8(b): flat fixture, converted by the REAL task-008 converter,
    read by both post-refactor twins, compared against the committed golden
    baseline on every Scope field."""

    WORK_ID = "work-101-flat-golden"
    GATE_TASK_ID = "task-001"

    def setUp(self):
        if not _bash_available():
            self.skipTest("bash not available")
        if not _bash_crlf_strip_ok():
            self.skipTest(
                "local bash has the CRLF array-append parameter-expansion bug "
                "(see _bash_crlf_strip_ok's docstring) -- cannot exercise the "
                "real converter on this host; a correctly-behaving bash "
                "(e.g. CI) will run this test for real"
            )
        self._tmpdir = tempfile.mkdtemp()
        self.tmp = Path(self._tmpdir)
        self.root, self.aid = make_repo(self.tmp)
        build_flat_legacy_work(
            self.aid,
            self.WORK_ID,
            tasks=[
                {"id": "task-001", "type": "IMPLEMENT", "title": "First flat task",
                 "state": "Done", "review": "A", "elapsed": "45m", "notes": "--",
                 "display_name": "Task One Display"},
                {"id": "task-002", "type": "TEST", "title": "Second flat task",
                 "state": "In Progress", "review": "--", "elapsed": "--", "notes": "--"},
            ],
            history_rows=[
                ("2026-05-01", "Work created", "--", "INTAKE"),
                ("2026-06-01", "DETAIL complete", "--", "notes"),
            ],
            qa_entries=[
                ("Q1", "Pending", "Architecture", "Monorepo or split?"),
                ("Q2", "Answered", "Requirements", "Already resolved."),
            ],
        )
        rc, out = run_migrate_converter(self.root)
        self.migrate_rc = rc
        self.migrate_out = out

    def tearDown(self):
        shutil.rmtree(self._tmpdir, ignore_errors=True)

    def test_converter_ran_and_produced_yaml(self):
        """SP-8(b): the REAL converter runs (exit 0, WARN-not-fail contract)
        and STATE.yml replaces STATE.md for the flat work."""
        self.assertEqual(self.migrate_rc, 0, f"migrate exit != 0: {self.migrate_out}")
        work_dir = self.aid / "works" / self.WORK_ID
        self.assertTrue((work_dir / "STATE.yml").is_file(),
                         f"STATE.yml not produced; migrate output:\n{self.migrate_out}")
        self.assertFalse((work_dir / "STATE.md").exists(), "legacy STATE.md must be gone")

    def test_python_matches_golden_baseline(self):
        """SP-8(b)/AC-2(b): post-refactor Python's read of the converted
        flat tree equals the golden baseline on every field, no parse_warning."""
        payload, warnings = read_payload_python(self.root, self.WORK_ID, self.GATE_TASK_ID)
        golden = load_golden("flat_golden")
        self.assertEqual(warnings, [], f"Python parse_warnings on converted tree: {warnings}")
        self.assertEqual(payload, golden)

    def test_node_matches_golden_baseline(self):
        """SP-8(b)/AC-2(b): post-refactor Node's read of the converted flat
        tree equals the golden baseline on every field, no parse_warning --
        except `delivery_state`, which Node's public readRepo() never
        exposes on a DeliverableRef in EITHER era (see
        without_node_unexposed_fields's docstring); that ONE field is
        verified via the Python leg instead."""
        if not _node_available():
            self.skipTest("node not available")
        payload, warnings = read_payload_node(self.root, self.WORK_ID, self.GATE_TASK_ID)
        golden = load_golden("flat_golden")
        self.assertEqual(warnings, [], f"Node parse_warnings on converted tree: {warnings}")
        self.assertEqual(payload, without_node_unexposed_fields(golden))

    def test_derived_counts_recomputed_not_persisted(self):
        """SP-3/C-8: the same derived_counts() function applied to the
        golden baseline's task list and to the live post-refactor read
        agree -- proving the count/percentage is recomputed fresh, not a
        persisted rollup surviving the conversion."""
        payload, _ = read_payload_python(self.root, self.WORK_ID)
        golden = load_golden("flat_golden")
        self.assertEqual(payload["counts"], golden["counts"])


# ===========================================================================
# Leg (b): hierarchical (full) layout, including per-delivery/per-task files.
# ===========================================================================

class TestHierarchicalConversionParity(unittest.TestCase):
    """SP-8(b): hierarchical fixture (2 deliveries, 3 tasks across them, one
    delivery carrying Cross-phase Q&A), converted by the REAL converter --
    per-delivery AND per-task STATE.md files, read by both post-refactor
    twins, compared against the committed golden baseline."""

    WORK_ID = "work-102-hier-golden"
    GATE_TASK_ID = "task-001"

    def setUp(self):
        if not _bash_available():
            self.skipTest("bash not available")
        if not _bash_crlf_strip_ok():
            self.skipTest(
                "local bash has the CRLF array-append parameter-expansion bug "
                "(see _bash_crlf_strip_ok's docstring) -- cannot exercise the "
                "real converter on this host; a correctly-behaving bash "
                "(e.g. CI) will run this test for real"
            )
        self._tmpdir = tempfile.mkdtemp()
        self.tmp = Path(self._tmpdir)
        self.root, self.aid = make_repo(self.tmp)
        build_hierarchical_legacy_work(
            self.aid,
            self.WORK_ID,
            deliveries=[
                {
                    "id": "delivery-001", "title": "Hierarchical Golden Delivery One",
                    "state": "Executing", "gate_tier": "Small", "gate_grade": "A",
                    "gate_timestamp": "2026-06-11T10:00:00Z",
                    "qa": [
                        ("Q1", "Pending", "Architecture", "Monorepo or split?"),
                        ("Q2", "Answered", "Requirements", "Already resolved."),
                    ],
                    "tasks": [
                        {"id": "task-001", "type": "IMPLEMENT", "title": "First hier task",
                         "state": "Done", "review": "A", "elapsed": "2h", "notes": "--"},
                        {"id": "task-002", "type": "TEST", "title": "Second hier task",
                         "state": "In Progress"},
                    ],
                },
                {
                    "id": "delivery-002", "title": "Hierarchical Golden Delivery Two",
                    "state": "Executing", "gate_tier": "Small", "gate_grade": "Pending",
                    "qa": [("Q3", "Pending", "Requirements", "Which framework?")],
                    "tasks": [
                        {"id": "task-003", "type": "DOCUMENT", "title": "Third hier task",
                         "state": "Pending"},
                    ],
                },
            ],
            history_rows=[
                ("2026-06-01", "Work created", "--", "INTAKE"),
                ("2026-06-10", "PLAN complete", "--", "notes"),
            ],
        )
        rc, out = run_migrate_converter(self.root)
        self.migrate_rc = rc
        self.migrate_out = out

    def tearDown(self):
        shutil.rmtree(self._tmpdir, ignore_errors=True)

    def test_converter_ran_on_every_level(self):
        """SP-8(b): the converter replaces STATE.md -> STATE.yml at the
        work, EACH delivery, and EACH task file level."""
        self.assertEqual(self.migrate_rc, 0, f"migrate exit != 0: {self.migrate_out}")
        work_dir = self.aid / "works" / self.WORK_ID
        self.assertTrue((work_dir / "STATE.yml").is_file())
        for did, tids in (("delivery-001", ("task-001", "task-002")), ("delivery-002", ("task-003",))):
            ddir = work_dir / "deliveries" / did
            self.assertTrue((ddir / "STATE.yml").is_file(), f"{did}/STATE.yml missing")
            self.assertFalse((ddir / "STATE.md").exists())
            for tid in tids:
                tdir = ddir / "tasks" / tid
                self.assertTrue((tdir / "STATE.yml").is_file(), f"{did}/{tid}/STATE.yml missing")
                self.assertFalse((tdir / "STATE.md").exists())

    def test_python_matches_golden_baseline(self):
        """SP-8(b)/AC-2(b): post-refactor Python's read of the converted
        hierarchical tree (per-delivery + per-task files) equals the golden
        baseline on every field, no parse_warning."""
        payload, warnings = read_payload_python(self.root, self.WORK_ID, self.GATE_TASK_ID)
        golden = load_golden("hierarchical_golden")
        self.assertEqual(warnings, [], f"Python parse_warnings on converted tree: {warnings}")
        self.assertEqual(payload, golden)

    def test_node_matches_golden_baseline(self):
        """SP-8(b)/AC-2(b): post-refactor Node's read of the converted
        hierarchical tree equals the golden baseline on every field, no
        parse_warning -- except `delivery_state` (see
        without_node_unexposed_fields's docstring), verified via Python."""
        if not _node_available():
            self.skipTest("node not available")
        payload, warnings = read_payload_node(self.root, self.WORK_ID, self.GATE_TASK_ID)
        golden = load_golden("hierarchical_golden")
        self.assertEqual(warnings, [], f"Node parse_warnings on converted tree: {warnings}")
        self.assertEqual(payload, without_node_unexposed_fields(golden))


# ===========================================================================
# KI-004 three-condition case (leg b applied to the exact trigger shape).
# ===========================================================================

class TestKI004ThreeConditionCase(unittest.TestCase):
    """known-issues.md KI-004: no `lifecycle` key, no `updated` key, AND a
    populated `lifecycle_history` -- the ONLY shape that exercises the
    coarse-`updated` fallback. Asserts both post-refactor twins derive the
    SAME coarse date (`max(lifecycle_history[].date)`) from the converted
    tree, matching the pre-refactor golden baseline. Per KI-004's own text,
    a fixture carrying an explicit `updated:` does NOT trigger this path --
    this is the one fixture in this suite that omits it on purpose."""

    WORK_ID = "work-103-ki004-golden"

    def setUp(self):
        if not _bash_available():
            self.skipTest("bash not available")
        if not _bash_crlf_strip_ok():
            self.skipTest(
                "local bash has the CRLF array-append parameter-expansion bug "
                "(see _bash_crlf_strip_ok's docstring) -- cannot exercise the "
                "real converter on this host; a correctly-behaving bash "
                "(e.g. CI) will run this test for real"
            )
        self._tmpdir = tempfile.mkdtemp()
        self.tmp = Path(self._tmpdir)
        self.root, self.aid = make_repo(self.tmp)
        build_ki004_legacy_work(
            self.aid,
            self.WORK_ID,
            history_rows=[
                ("2026-04-01", "Work created", "--", "INTAKE"),
                ("2026-04-20", "Some later transition", "--", "notes"),
            ],
        )
        rc, out = run_migrate_converter(self.root)
        self.migrate_rc = rc
        self.migrate_out = out

    def tearDown(self):
        shutil.rmtree(self._tmpdir, ignore_errors=True)

    def test_converter_preserves_absent_lifecycle_and_updated(self):
        """The converted STATE.yml must carry neither `lifecycle:` nor
        `updated:` (the converter copies the frontmatter verbatim) -- the
        precondition for the fallback to fire at all."""
        self.assertEqual(self.migrate_rc, 0, f"migrate exit != 0: {self.migrate_out}")
        yml_path = self.aid / "works" / self.WORK_ID / "STATE.yml"
        self.assertTrue(yml_path.is_file())
        text = yml_path.read_text(encoding="utf-8")
        self.assertNotRegex(text, r"(?m)^lifecycle:")
        self.assertNotRegex(text, r"(?m)^updated:")
        self.assertRegex(text, r"(?m)^lifecycle_history:")

    def test_python_derives_coarse_updated_from_history(self):
        """KI-004: post-refactor Python derives `updated` = max(date) over
        lifecycle_history (2026-04-20), matching the pre-refactor golden
        baseline, with source_mode=Fallback (no authoritative lifecycle key)."""
        payload, warnings = read_payload_python(self.root, self.WORK_ID)
        golden = load_golden("ki004_golden")
        self.assertEqual(warnings, [], f"Python parse_warnings: {warnings}")
        self.assertEqual(payload["updated"], "2026-04-20")
        self.assertEqual(payload["source_mode"], SourceMode.Fallback.value)
        self.assertEqual(payload["updated"], golden["updated"])

    def test_node_derives_same_coarse_updated_as_python(self):
        """KI-004: post-refactor Node derives the SAME coarse `updated`
        value as Python for the identical three-condition fixture --
        exactly the twin-parity property task-021 fixed and this suite now
        characterizes."""
        if not _node_available():
            self.skipTest("node not available")
        node_payload, node_warnings = read_payload_node(self.root, self.WORK_ID)
        py_payload, _ = read_payload_python(self.root, self.WORK_ID)
        self.assertEqual(node_warnings, [], f"Node parse_warnings: {node_warnings}")
        self.assertEqual(node_payload["updated"], py_payload["updated"])
        golden = load_golden("ki004_golden")
        self.assertEqual(node_payload["updated"], golden["updated"])


# ===========================================================================
# Leg (c): the UNCONVERTED legacy tree, read by both post-refactor twins,
# degrades to the minimal model + the SAME parse_warning naming the file
# and the migration command (SP-8c, SP-9, AC-5). Required behavior, not a
# shortfall of (b).
# ===========================================================================

class TestLegacyDegradationParity(unittest.TestCase):
    """SP-8(c)/SP-9/AC-5: an UNCONVERTED legacy STATE.md, read by both
    post-refactor twins, yields the minimal WorkModel plus the identical
    `parse_warning` naming the file and the migration command -- in BOTH
    runtimes, for BOTH layouts. This is the required behavior, asserted as
    success."""

    def setUp(self):
        self._tmpdir = tempfile.mkdtemp()
        self.tmp = Path(self._tmpdir)
        self.root, self.aid = make_repo(self.tmp)

    def tearDown(self):
        shutil.rmtree(self._tmpdir, ignore_errors=True)

    def _expected_warning(self, work_id: str) -> str:
        return (
            f"{work_id}: legacy STATE.md found with no STATE.yml sibling; "
            f"run 'aid update' to migrate this work; returning minimal WorkModel."
        )

    def test_flat_legacy_python_degrades(self):
        """SP-8(c): UNCONVERTED flat legacy tree -> Python minimal model +
        the exact parse_warning naming the file and 'aid update'."""
        work_id = "work-201-flat-legacy"
        build_flat_legacy_work(self.aid, work_id, tasks=[
            {"id": "task-001", "state": "Done"},
        ])
        payload, warnings = read_payload_python(self.root, work_id)
        self.assertIn(self._expected_warning(work_id), warnings)
        self.assertEqual(payload["tasks"], [], "minimal model carries no per-task state")
        self.assertEqual(payload["deliverables"], [], "minimal model carries no deliverables")

    def test_hierarchical_legacy_python_degrades(self):
        """SP-8(c): UNCONVERTED hierarchical legacy tree -> Python minimal
        model + the exact parse_warning (the SAME work-root check applies
        regardless of layout -- a hierarchical work's delivery/task STATE.md
        files are never reached once the work-root legacy guard fires)."""
        work_id = "work-202-hier-legacy"
        build_hierarchical_legacy_work(self.aid, work_id, deliveries=[
            {"id": "delivery-001", "tasks": [{"id": "task-001", "state": "Done"}]},
        ])
        payload, warnings = read_payload_python(self.root, work_id)
        self.assertIn(self._expected_warning(work_id), warnings)
        self.assertEqual(payload["tasks"], [])

    def test_flat_legacy_node_degrades_identically(self):
        """SP-8(c): the SAME unconverted flat tree, read by Node, yields the
        SAME parse_warning text as Python (byte-identical message)."""
        if not _node_available():
            self.skipTest("node not available")
        work_id = "work-203-flat-legacy-node"
        build_flat_legacy_work(self.aid, work_id, tasks=[{"id": "task-001", "state": "Done"}])
        py_payload, py_warnings = read_payload_python(self.root, work_id)
        node_payload, node_warnings = read_payload_node(self.root, work_id)
        self.assertIn(self._expected_warning(work_id), node_warnings)
        self.assertEqual(node_warnings, py_warnings, "identical parse_warning text, both runtimes")
        self.assertEqual(node_payload["tasks"], py_payload["tasks"])
        self.assertEqual(node_payload["deliverables"], py_payload["deliverables"])

    def test_hierarchical_legacy_node_degrades_identically(self):
        """SP-8(c): the SAME unconverted hierarchical tree, read by Node,
        yields the SAME parse_warning text as Python."""
        if not _node_available():
            self.skipTest("node not available")
        work_id = "work-204-hier-legacy-node"
        build_hierarchical_legacy_work(self.aid, work_id, deliveries=[
            {"id": "delivery-001", "tasks": [{"id": "task-001", "state": "Done"}]},
        ])
        py_payload, py_warnings = read_payload_python(self.root, work_id)
        node_payload, node_warnings = read_payload_node(self.root, work_id)
        self.assertIn(self._expected_warning(work_id), node_warnings)
        self.assertEqual(node_warnings, py_warnings, "identical parse_warning text, both runtimes")
        self.assertEqual(node_payload["tasks"], py_payload["tasks"])


if __name__ == "__main__":
    unittest.main()
