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
# Single source of truth = feature-001 (canonical/templates/work-state-template.md).
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
    """Pipeline phase enum.

    Members from feature-001 work-state-template.md:
        Interview | Specify | Plan | Detail | Execute | Deploy | Monitor
    Reader-only:
        Unknown -- for an unrecognized Phase literal.
    """
    Interview = "Interview"
    Specify = "Specify"
    Plan = "Plan"
    Detail = "Detail"
    Execute = "Execute"
    Deploy = "Deploy"
    Monitor = "Monitor"
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
    """Records which derivation path produced WorkModel.lifecycle."""
    Normalized = "normalized"   # ## Pipeline Status block was present
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

@dataclass
class KbStateRef:
    """Thin reference to KB state (hook only; full KB card is feature-007).

    Populated from .aid/knowledge/STATE.md + .aid/knowledge/README.md.
    Absent KB (.aid/knowledge/ missing) -> null in RepoInfo.
    """
    summary_approved: bool
    last_summary_date: Optional[str] = None  # from STATE.md "User Approved: yes (YYYY-MM-DD...)"
    doc_count: Optional[int] = None          # rows in README.md ## Completeness table


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
    """A single row from ## Plan / Deliveries in STATE.md (prototype field)."""
    number: int
    name: str
    task_count: int


@dataclass
class WorkModel:
    """Level-2 work folder state. One per .aid/work-NNN-*/ directory.

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
    +-- works: list[WorkModel]  Level 2 -- one per .aid/work-NNN-*/ folder (FR12)
    +-- read:  ReadMeta         provenance of THIS read pass
    """
    tool: ToolInfo
    repo: RepoInfo
    works: list[WorkModel] = field(default_factory=list)
    read: ReadMeta = field(default_factory=lambda: ReadMeta(read_at=""))
