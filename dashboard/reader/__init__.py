# dashboard/reader/__init__.py
# Public entry point for the AID state reader (feature-002).
#
# Primary export: read_repo(aid_root) -> RepoModel
# Plus resolve_work_dir(served_root, work_id) -> Path | None (task-002, WT-1) --
# the worktree-aware work-directory resolver feature-001's write layer imports
# alongside read_repo / read_repo_detail.
#
# Python 3.11+ stdlib only. Zero third-party deps.
# No write / no LLM / one read-only `git log` subprocess for KB freshness (FR35).

from .reader import read_repo, read_repo_detail, resolve_work_dir
from .models import (
    RepoModel,
    ToolInfo,
    RepoInfo,
    KbStateRef,
    KbStatus,
    KbBaseline,
    WorkModel,
    TaskModel,
    PendingInput,
    ReadMeta,
    Lifecycle,
    Phase,
    TaskStatus,
    # feature-008 LC-TR TaskDetail sub-model (task-069)
    TaskDetail,
    Finding,
    TaskLedger,
    DeferredIssue,
    RawStateRef,
    LogAvailability,
)

__all__ = [
    "read_repo",
    "read_repo_detail",
    "resolve_work_dir",
    "RepoModel",
    "ToolInfo",
    "RepoInfo",
    "KbStateRef",
    "KbStatus",
    "KbBaseline",
    "WorkModel",
    "TaskModel",
    "PendingInput",
    "ReadMeta",
    "Lifecycle",
    "Phase",
    "TaskStatus",
    # feature-008 LC-TR TaskDetail sub-model (task-069)
    "TaskDetail",
    "Finding",
    "TaskLedger",
    "DeferredIssue",
    "RawStateRef",
    "LogAvailability",
]
