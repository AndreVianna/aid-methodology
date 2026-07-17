# dashboard/reader/models.py
# Normalized in-memory display model for the AID state reader (feature-002).
#
# These types are the single source of truth for the reader's output shape.
# They mirror the enum vocabularies declared in feature-001's work-state-template.md (DM-6).
#
# Python 3.11+ stdlib only. Read-only data records; no persistence, no I/O.

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Optional


# ---------------------------------------------------------------------------
# DM-6: Enum definitions
# Single source of truth = feature-001 (canonical/aid/templates/work-state-template.md).
# Members reproduced here verbatim so the reader's switch is total.
# The reader adds one reader-only sentinel per enum (Unknown) per DM-6 contract.
# ---------------------------------------------------------------------------

class Lifecycle(str, Enum):
    """FR16 lifecycle states for a work folder.

    Members from feature-001 work-state-template.md:
        Running | Paused-Awaiting-Input | Blocked | Completed | Canceled
    Reader-only:
        Unknown -- returned when the normalized block is absent and no fallback fires.
                   Never written to disk. See task-011 for the full fallback adapter.
    """
    Running = "Running"
    PausedAwaitingInput = "Paused-Awaiting-Input"
    Blocked = "Blocked"
    Completed = "Completed"
    Canceled = "Canceled"
    Unknown = "Unknown"  # reader-only sentinel; never written to disk


class Phase(str, Enum):
    """Pipeline phase enum -- the faithful 6-phase pipeline (work-003-state-schema task-010).

    Members from feature-001 work-state-template.md (rebuilt task-010 to follow the
    2026-06-28 architecture.md prose rename, Interview -> Describe/Define):
        Describe | Define | Specify | Plan | Detail | Execute | Deploy
    NOT a member here: Discover. `aid-discover` is KB-level -- it writes the KB
    discovery-area STATE (`kb_status`), never a work `phase:` -- so Discover is
    surfaced in the dashboard stepper from `KbStateRef.status` (KbStatus), not from
    this enum. Deploy is an optional post-Execute indicator (aid-deploy pipeline mode).
    Reader-only:
        Unknown -- for an unrecognized Phase literal.
    Back-compat read alias (never written, see `_PHASE_MAP` / `PHASE_MAP`):
        "Interview" -> Phase.Describe (retired label, split into Describe + Define).
        "Monitor" -> Phase.Unknown (dead value; no skill ever wrote it).
    """
    Describe = "Describe"
    Define = "Define"
    Specify = "Specify"
    Plan = "Plan"
    Detail = "Detail"
    Execute = "Execute"
    Deploy = "Deploy"
    Unknown = "Unknown"  # reader-only sentinel; never written to disk


class TaskStatus(str, Enum):
    """Per-task status enum.

    Members from feature-001 work-state-template.md (closed; single source of truth):
        Pending | In Progress | In Review | Blocked | Done | Failed | Canceled
    Reader-only:
        Unknown -- for a row whose Status string matches no enum member (NFR7: never throws).
                   Never written to disk.
    """
    Pending = "Pending"
    InProgress = "In Progress"
    InReview = "In Review"
    Blocked = "Blocked"
    Done = "Done"
    Failed = "Failed"
    Canceled = "Canceled"
    Unknown = "Unknown"  # reader-only sentinel; never written to disk


class SourceMode(str, Enum):
    """Records which derivation path produced WorkModel.lifecycle.

    Extended (work-003-state-schema task-002) onto the KB path: KbStateRef.source_mode
    uses the same two values to record whether summary_approved/last_summary_date came
    from the frontmatter `summary_approved` scalar (Normalized) or the legacy
    `## Knowledge Summary Status` bold-line prose / nothing present (Fallback).
    """
    Normalized = "normalized"   # ## Pipeline Status block OR STATE frontmatter was present
    Fallback = "fallback"       # legacy derivation (task-011)
    Mixed = "mixed"             # rare: partial migration (task-011)


# ---------------------------------------------------------------------------
# DM-2: Level 0 -- ToolInfo
# ---------------------------------------------------------------------------

@dataclass
class ToolInfo:
    """Level-0 tool / installation metadata parsed from .aid/.aid-manifest.json.

    manifest_present=False means the manifest file was absent; fields are then None.
    Never errors on absent manifest -- render 'tool info unavailable'.
    """
    manifest_present: bool
    aid_version: Optional[str] = None
    installed_at: Optional[str] = None
    tools_installed: list[str] = field(default_factory=list)


# ---------------------------------------------------------------------------
# DM-3: Level 1 -- RepoInfo + KbStateRef
# ---------------------------------------------------------------------------

class KbStatus(str, Enum):
    """FR32 5-state KB status enum (feature-007 DM-A2).

    Derived by the reader (FF-A3 waterfall); never written to disk (NFR2).
    Members:
        pending    -- .aid/knowledge/ absent or empty
        generating -- KB present but not yet User Approved: yes (safe default, SPEC residual-#1)
        preparing  -- KB approved but kb.html absent OR summary not yet V1-approved
        approved   -- KB + kb.html ready, current, approved
        outdated   -- approved but default branch has advanced past kb_baseline (FR35)
    Reader-only:
        unknown    -- un-derivable combination falls back to pending treatment; never thrown
    """
    pending    = "pending"
    generating = "generating"
    preparing  = "preparing"
    approved   = "approved"
    outdated   = "outdated"
    unknown    = "unknown"  # reader-only sentinel; never written to disk


@dataclass
class KbBaseline:
    """Parsed projection of .aid/settings.yml kb_baseline block (DM-A4).

    branch:   the default branch the KB reflects (e.g. 'master'); None if absent
    tip_date: ISO-8601 commit date of that branch's tip at KB generation time; None if absent
    """
    branch: Optional[str] = None
    tip_date: Optional[str] = None


@dataclass
class DocFreshness:
    """Per-doc freshness verdict (feature-007 f007, task-042).

    Populated by derive_doc_freshness() in derivation.py; never persisted (NFR2).

    doc:             doc relative path under .aid/knowledge/ (e.g. "architecture.md")
    verdict:         "current" | "suspect" | "unknown"
    suspect_sources: list of sources: entries that drifted (empty unless verdict=="suspect")
    """
    doc: str
    verdict: str                        # "current" | "suspect" | "unknown"
    suspect_sources: list[str] = field(default_factory=list)


@dataclass
class KbStateRef:
    """KB state reference (feature-007 DM-A1 extended KbStateRef).

    Populated from .aid/knowledge/STATE.md + .aid/knowledge/README.md + derivation.
    Absent KB (.aid/knowledge/ missing) -> null in RepoInfo.

    Retained fields (feature-002 DM-3):
        summary_approved  -- from STATE.md ## Knowledge Summary Status **User Approved:** yes/no
        last_summary_date -- parenthesized date on that line
        doc_count         -- rows in README.md ## Completeness table

    New fields (feature-007 DM-A1, task-064):
        status          -- FR32 5-state KbStatus (derived, never persisted; NFR2)
        summary_present -- True if <repo>/.aid/knowledge/kb.html exists (stat only)
        kb_baseline     -- {branch, tip_date} from .aid/settings.yml; None if unset/unparseable

    New fields (feature-007 f007, task-042):
        doc_freshness   -- per-doc freshness list [{doc, verdict, suspect_sources}, ...]
        suspect_count   -- count of docs with verdict=="suspect" (badge rollup)

    New fields (work-003-state-schema task-002, dual-format frontmatter read):
        source_mode     -- which path produced summary_approved/last_summary_date:
                            Normalized (frontmatter `summary_approved` key present) or
                            Fallback (legacy `## Knowledge Summary Status` bold-line
                            prose, or nothing present). Extends the per-work SourceMode
                            machinery onto the KB path (it was work-only before this task).
        kb_status       -- discovery-workflow status (frontmatter `kb_status` or legacy
                            header blockquote `**Status:**`); a raw authored string
                            (Initial | In Progress | Approved), distinct from the derived
                            5-state `status` field above (never an enum here -- no reader
                            derivation involved).
        kb_grade        -- discovery current grade (frontmatter `kb_grade` or legacy
                            header blockquote `**Current Grade:**`); e.g. "A" or "Pending".
        last_kb_review  -- discovery last-review date (frontmatter `last_kb_review` or
                            legacy header blockquote `**Last KB Review:**`); ISO date or None.
    """
    summary_approved: bool
    last_summary_date: Optional[str] = None  # from STATE.md "User Approved: yes (YYYY-MM-DD...)"
    doc_count: Optional[int] = None          # rows in README.md ## Completeness table
    # feature-007 DM-A1 new fields (task-064):
    status: KbStatus = KbStatus.unknown      # FR32 5-state derived status
    summary_present: bool = False            # True if .aid/knowledge/kb.html exists
    kb_baseline: Optional[KbBaseline] = None # {branch, tip_date} or None
    # feature-007 f007 new fields (task-042):
    doc_freshness: list[DocFreshness] = field(default_factory=list)  # per-doc verdicts
    suspect_count: int = 0                   # count of suspect docs (badge rollup)
    # work-003-state-schema task-002 new fields (dual-format frontmatter read):
    source_mode: SourceMode = SourceMode.Fallback  # Normalized|Fallback; see docstring
    kb_status: Optional[str] = None          # raw authored discovery status (never an enum)
    kb_grade: Optional[str] = None           # raw authored current grade
    last_kb_review: Optional[str] = None     # raw authored last-review date


@dataclass
class RepoInfo:
    """Level-1 project / .aid/ state."""
    project_name: str           # from .aid/settings.yml project.name; fallback: dir basename
    aid_dir: str                # resolved .aid/ root path (as string)
    kb_state: Optional[KbStateRef] = None


# ---------------------------------------------------------------------------
# DM-5: Level 3 -- TaskModel
# ---------------------------------------------------------------------------

@dataclass
class TaskModel:
    """One row from ## Tasks Status in STATE.md.

    Table columns (work-state-template.md):
        # | Task | Type | Wave | Status | Review | Elapsed | Notes
    The _none yet_ placeholder row is skipped by the parser.

    PF-3/PF-5 fields (feature-009, schema_version 3):
        short_name -- parsed from tasks/task-NNN.md first line "# task-NNN: <title>"
        delivery   -- integer parsed from STATE Wave "delivery-NNN" (PF-5c; STATE wins)
        lane       -- integer derived from PLAN.md wave-map or prose fallback (PF-5a/5b)
    """
    task_id: str
    type: str
    wave: Optional[str] = None
    status: TaskStatus = TaskStatus.Unknown
    review_grade: Optional[str] = None
    elapsed: Optional[str] = None
    notes: Optional[str] = None
    # schema_version 3 fields (PF-3 / PF-5)
    short_name: Optional[str] = None
    delivery: Optional[int] = None
    lane: Optional[int] = None


# ---------------------------------------------------------------------------
# DM-4: Level 2 -- WorkModel (includes PendingInput)
# ---------------------------------------------------------------------------

@dataclass
class PendingInput:
    """A ### Q{N} entry under ## Cross-phase Q&A (Pending) with Status: Pending."""
    question_id: str      # e.g. "Q1"
    category: Optional[str] = None
    impact: Optional[str] = None
    context: Optional[str] = None
    suggested: Optional[str] = None


@dataclass
class FeatureRef:
    """A single row from ## Features Status in STATE.md (prototype field)."""
    number: int
    name: str


@dataclass
class DeliverableRef:
    """A single row from ## Plan / Deliveries in STATE.md (prototype field).

    delivery_state: the SD-8 lifecycle enum from ## Delivery Lifecycle -- the
    delivery-level deliveries/delivery-NNN/STATE.md for full-nested works, or the
    work-root STATE.md's own ## Delivery Lifecycle section for lite-flat works
    (Pending-Spec | Specified | Executing | Gated | Done | Blocked).
    None when the source STATE.md is absent or the field is unparseable (legacy works).
    """
    number: int
    name: str
    task_count: int
    delivery_state: Optional[str] = None


@dataclass
class WorkModel:
    """Level-2 work folder state. One per .aid/works/work-NNN-*/ directory.

    Retention = folder persistence (FR12): the model contains exactly the work
    folders that exist on disk; completed and in-flight works are represented
    identically.
    """
    work_id: str                    # folder name, e.g. "work-001-aid-dashboard"
    name: str                       # display label (slug portion)
    lifecycle: Lifecycle = Lifecycle.Unknown
    phase: Optional[Phase] = None
    active_skill: Optional[str] = None
    updated: Optional[str] = None   # ISO-8601 or None
    created: Optional[str] = None   # frontmatter `started` if present (task-002 retires the
                                     # fragile row-scrape for migrated works), else the legacy
                                     # ## Lifecycle History "Work created" row-scrape fallback
    pause_reason: Optional[str] = None  # present only when lifecycle=Paused-Awaiting-Input
    block_reason: Optional[str] = None  # present only when lifecycle=Blocked
    block_artifact: Optional[str] = None  # e.g. "IMPEDIMENT-task-NNN.md"
    tasks: list[TaskModel] = field(default_factory=list)
    pending_inputs: list[PendingInput] = field(default_factory=list)
    source_mode: SourceMode = SourceMode.Fallback
    # --- prototype: work-overview header fields (delivery-002 prototype) ---
    number: Optional[int] = None           # from folder prefix work-NNN-... -> NNN
    title: Optional[str] = None            # **Name:** from REQUIREMENTS.md
    description: Optional[str] = None      # **Description:** from REQUIREMENTS.md
    objective: Optional[str] = None        # body under ## 1. Objective in REQUIREMENTS.md
    work_path: Optional[str] = None        # **Path:** from STATE.md ## Triage (full/lite)
    recipe: Optional[str] = None           # lite-path recipe from Triage, else None
    features: list[FeatureRef] = field(default_factory=list)      # from ## Features Status
    deliverables: list[DeliverableRef] = field(default_factory=list)  # from ## Plan / Deliveries
    # work-004 Pillar 4: branch label from the worktree that owns this work folder.
    # "main" for the main worktree; branch name for persistent worktrees; None if unknown.
    branch_label: Optional[str] = None
    # --- work-003-state-schema task-002: dual-format frontmatter read, new fields ---
    kind: Optional[str] = None              # display verb resolved from pipeline.initiator
                                             # (e.g. "Refactor", "Create api", "full path");
                                             # None when initiator absent/unrecognized -- the
                                             # dashboard drops the redundant word in that case.
    started: Optional[str] = None           # frontmatter `started` scalar (ISO date); None
                                             # for un-migrated works (no working legacy prose
                                             # fallback ever existed for this field -- see
                                             # `created` below, which retains its own fallback).
    minimum_grade: Optional[str] = None      # frontmatter `minimum_grade`, else the legacy
                                             # header-blockquote `**Minimum Grade:**` scan
                                             # (derivation._parse_minimum_grade, unchanged --
                                             # this is a SEPARATE exposure, not a behavior change
                                             # to the sub-minimum Blocked-gate derivation).
    user_approved: Optional[bool] = None     # frontmatter `user_approved` (yes/no/true/false,
                                             # case-insensitive) or the legacy header-blockquote
                                             # `**User Approved:**` line; work-level approval,
                                             # distinct from KB KbStateRef.summary_approved.


# ---------------------------------------------------------------------------
# DM-1 (feature-008): TaskDetail sub-model (LC-TR, task-069)
# Populated ONLY for requested task_ids (detail_task_ids param).
# Never persisted (NFR2); all fields are read-derived.
# ---------------------------------------------------------------------------

@dataclass
class Finding:
    """One bullet under STATE.md ## Quick Check Findings ### task-NNN **Findings:** (DR-2).

    severity:       leading bracketed tag -- [CRITICAL] | [HIGH]; lower/unknown -> [MINOR] neutral
    description:    bullet text up to the first ' -- ' (em-dash segment separator)
    location:       '{source-file:line}' segment, null if absent
    disposition:    trailing 'Fixed-on-spot' / 'Deferred-to-gate' token, null if absent
    reviewer_tier:  the block's **Reviewer Tier:** line (always 'Small' for a quick check)
    """
    severity: str               # '[CRITICAL]' | '[HIGH]' | '[MINOR]' (neutral fallback)
    description: str
    location: Optional[str] = None
    disposition: Optional[str] = None
    reviewer_tier: Optional[str] = None


@dataclass
class DeferredIssue:
    """One row from delivery-NNN-issues.md filtered to Source task == task_id (DR-4).

    4-col table: Source task | Severity | Description | Status
    status enum: Open | Resolved | Accepted (unknown literal -> neutral, never throws)
    """
    source_task: str
    severity: str
    description: str
    status: str


@dataclass
class TaskLedger:
    """Delivery-level grade context for a task (DR-3/DR-4). NOT a per-task grade.

    delivery_id:     resolved delivery for this task (from ## Tasks Status Wave); null if unassociated
    grade:           per-delivery grade from ## Delivery Gates (verbatim, never re-graded -- NFR7)
    reviewer_tier:   delivery reviewer tier
    gate_timestamp:  when the delivery gate ran
    deferred_issues: rows from delivery-NNN-issues.md where Source task == task_id
    """
    delivery_id: Optional[str] = None
    grade: Optional[str] = None
    reviewer_tier: Optional[str] = None
    gate_timestamp: Optional[str] = None
    deferred_issues: list[DeferredIssue] = field(default_factory=list)


@dataclass
class RawStateRef:
    """Verbatim STATE.md bytes the reader ALREADY read this pass (DR-1, DD-3, NFR4).

    text:     whole work STATE.md verbatim (reused from memory, no re-read)
    byte_len: len(text) in bytes (corroborates NFR4 payload budget)
    path:     '.aid/works/{work}/STATE.md' -- read-only caption label, NOT an edit link
    """
    text: str
    byte_len: int
    path: str


@dataclass
class LogAvailability:
    """Honest DM-4 log inventory for a task (DR-5, KI-008).

    task_logs:           always 'none' (AID persists no per-task execution log)
    server_log_present:  stat .aid/.temp/dashboard.log (expected-false on Windows)
    heartbeat_present:   stat .aid/.heartbeat/ (liveness signal, corroborating-only, KI-004)
    """
    task_logs: str = "none"      # always "none" today (DM-4)
    server_log_present: bool = False
    heartbeat_present: bool = False


@dataclass
class TaskDetail:
    """Forensic sub-model for one drilled task (DM-1, feature-008 LC-TR).

    Populated ONLY when detail_task_ids is supplied to read_repo_detail().
    The always-on read_repo() path does NOT populate this; TaskModel is unchanged.

    task_id:   == TaskModel.task_id (the drill key)
    findings:  from ## Quick Check Findings ### task-NNN **Findings:** bullets
    ledger:    delivery-level grade join (## Delivery Gates + delivery-NNN-issues.md)
    raw_state: the already-read STATE.md bytes (no re-read, NFR4/DD-3)
    logs:      honest DM-4 log inventory
    """
    task_id: str
    findings: list[Finding] = field(default_factory=list)
    ledger: TaskLedger = field(default_factory=TaskLedger)
    raw_state: Optional[RawStateRef] = None
    logs: Optional[LogAvailability] = None


# ---------------------------------------------------------------------------
# DM-7: ReadMeta (provenance of this read pass)
# ---------------------------------------------------------------------------

@dataclass
class ReadMeta:
    """Provenance and health summary for a single read_repo() pass (DM-7).

    read_at:        wall-clock of this pass (the only place the reader reads the clock).
    work_count:     works enumerated.
    fallback_works: work_ids whose source_mode != normalized (live tech-debt surface, AC4).
    parse_warnings: non-fatal anomalies (missing section, unparseable row) -- never raised.
    bytes_read:     total bytes read across all files (corroborates NFR4 low overhead).
    """
    read_at: str                             # ISO-8601
    work_count: int = 0
    fallback_works: list[str] = field(default_factory=list)
    parse_warnings: list[str] = field(default_factory=list)
    bytes_read: int = 0


# ---------------------------------------------------------------------------
# DM-1: Top-level RepoModel
# ---------------------------------------------------------------------------

@dataclass
class RepoModel:
    """Top-level normalized in-memory display model returned by read_repo().

    RepoModel
    +-- tool:  ToolInfo         Level 0 -- machine CLI (FR7)
    +-- repo:  RepoInfo         Level 1 -- project / .aid/ + KB-state hook
    +-- works: list[WorkModel]  Level 2 -- one per .aid/works/work-NNN-*/ folder (FR12)
    +-- read:  ReadMeta         provenance of THIS read pass
    """
    tool: ToolInfo
    repo: RepoInfo
    works: list[WorkModel] = field(default_factory=list)
    read: ReadMeta = field(default_factory=lambda: ReadMeta(read_at=""))
