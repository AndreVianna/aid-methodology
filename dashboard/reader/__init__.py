# dashboard/reader/__init__.py
# Public entry point for the AID state reader (feature-002).
#
# Single export: read_repo(aid_root) -> RepoModel
#
# Python 3.11+ stdlib only. Zero third-party deps.
# Read-only by construction: no write, no append, no lock, no subprocess, no agent/LLM.

from .reader import read_repo
from .models import (
    RepoModel,
    ToolInfo,
    RepoInfo,
    KbStateRef,
    WorkModel,
    TaskModel,
    PendingInput,
    ReadMeta,
    Lifecycle,
    Phase,
    TaskStatus,
)

__all__ = [
    "read_repo",
    "RepoModel",
    "ToolInfo",
    "RepoInfo",
    "KbStateRef",
    "WorkModel",
    "TaskModel",
    "PendingInput",
    "ReadMeta",
    "Lifecycle",
    "Phase",
    "TaskStatus",
]
