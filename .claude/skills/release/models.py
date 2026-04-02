"""Shared data models for the release workflow."""

from dataclasses import dataclass, field
from enum import Enum


class ReleasePhase(str, Enum):
    PENDING = "pending"
    INTERNAL_RELEASE = "internal_release"
    AWAITING_PHASE2 = "awaiting_phase2"
    EXTERNAL_RELEASE_PR = "external_release_pr"
    AWAITING_PR_MERGE = "awaiting_pr_merge"
    EXTERNAL_RELEASE_COMPLETE = "external_release_complete"
    CODEX_RELEASE = "codex_release"
    DONE = "done"
    FAILED = "failed"


@dataclass
class ReleaseInput:
    """Input to start a release workflow."""

    version_level: str  # "major", "minor", or "patch"
    codex_only: bool = False  # Skip to Codex phase (for re-pushing after review feedback)


@dataclass
class ReleaseStatus:
    """Current state of the release workflow, returned by queries."""

    phase: str
    current_version: str = ""
    new_version: str = ""
    release_pr_url: str = ""
    codex_pr_url: str = ""
    error: str = ""


@dataclass
class ActivityResult:
    """Standard result from activities."""

    success: bool
    output: str = ""
    error: str = ""
    pr_url: str = ""


TASK_QUEUE = "release-pipeline"
WORKFLOW_ID = "release-temporal-developer"
