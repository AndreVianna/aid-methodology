# dashboard/reader/__init__.py
# Public entry point for the AID state reader (feature-002).
#
# Single export: read_repo(aid_root) -> RepoModel
#
# Python 3.11+ stdlib only. Zero third-party deps.
# No write / no LLM / one read-only `git log` subprocess for KB freshness (FR35).

from .reader import read_repo, read_repo_detail
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
