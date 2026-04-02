"""Temporal workflow for the release pipeline."""

import json
from datetime import timedelta

from temporalio import workflow

with workflow.unsafe.imports_passed_through():
    from activities.git_ops import (
        codex_release,
        complete_external_release,
        create_release_pr,
        get_version_info,
        internal_release,
        preflight_checks,
        preflight_checks_codex,
    )
    from models import ReleaseInput, ReleasePhase, ReleaseStatus

ACTIVITY_TIMEOUT = timedelta(minutes=10)


@workflow.defn
class ReleaseWorkflow:
    """Orchestrates the two-phase release pipeline with human checkpoints."""

    def __init__(self) -> None:
        self._phase = ReleasePhase.PENDING
        self._current_version = ""
        self._new_version = ""
        self._release_pr_url = ""
        self._codex_pr_url = ""
        self._error = ""
        # Signal flags
        self._phase2_approved = False
        self._pr_merged = False
        self._codex_requested = False
        self._codex_skipped = False

    @workflow.run
    async def run(self, input: ReleaseInput) -> ReleaseStatus:
        workflow.logger.info(f"Starting release workflow: level={input.version_level}, codex_only={input.codex_only}")

        # --- Codex-only mode: verify on main, then run Codex ---
        if input.codex_only:
            preflight = await workflow.execute_activity(
                preflight_checks_codex,
                start_to_close_timeout=ACTIVITY_TIMEOUT,
            )
            if not preflight.success:
                return self._fail(f"Preflight failed: {preflight.error}")
            self._phase = ReleasePhase.CODEX_RELEASE
            codex_result = await workflow.execute_activity(
                codex_release,
                start_to_close_timeout=ACTIVITY_TIMEOUT,
            )
            if not codex_result.success:
                return self._fail(f"Codex release failed: {codex_result.error}")
            self._codex_pr_url = codex_result.pr_url or ""
            self._phase = ReleasePhase.DONE
            return self._status()

        # --- Full release: preflight + version ---
        preflight = await workflow.execute_activity(
            preflight_checks,
            start_to_close_timeout=ACTIVITY_TIMEOUT,
        )
        if not preflight.success:
            return self._fail(f"Preflight failed: {preflight.error}")

        version_info = await workflow.execute_activity(
            get_version_info,
            input.version_level,
            start_to_close_timeout=ACTIVITY_TIMEOUT,
        )
        if not version_info.success:
            return self._fail(f"Version computation failed: {version_info.error}")

        versions = json.loads(version_info.output)
        self._current_version = versions["current"]
        self._new_version = versions["new"]
        workflow.logger.info(f"Version: {self._current_version} → {self._new_version}")

        # --- Phase 1: Internal Release ---
        self._phase = ReleasePhase.INTERNAL_RELEASE
        result = await workflow.execute_activity(
            internal_release,
            self._new_version,
            start_to_close_timeout=ACTIVITY_TIMEOUT,
        )
        if not result.success:
            return self._fail(f"Internal release failed: {result.error}")

        workflow.logger.info("Phase 1 complete. Waiting for user to approve Phase 2.")
        self._phase = ReleasePhase.AWAITING_PHASE2

        # --- Wait for Phase 2 approval ---
        await workflow.wait_condition(lambda: self._phase2_approved)

        # --- Phase 2: External Release ---
        self._phase = ReleasePhase.EXTERNAL_RELEASE_PR
        pr_result = await workflow.execute_activity(
            create_release_pr,
            self._new_version,
            start_to_close_timeout=ACTIVITY_TIMEOUT,
        )
        if not pr_result.success:
            return self._fail(f"Release PR creation failed: {pr_result.error}")

        self._release_pr_url = pr_result.pr_url
        workflow.logger.info(f"Release PR: {self._release_pr_url}. Waiting for merge.")
        self._phase = ReleasePhase.AWAITING_PR_MERGE

        # --- Wait for PR merge confirmation ---
        await workflow.wait_condition(lambda: self._pr_merged)

        self._phase = ReleasePhase.EXTERNAL_RELEASE_COMPLETE
        complete_result = await workflow.execute_activity(
            complete_external_release,
            self._new_version,
            start_to_close_timeout=ACTIVITY_TIMEOUT,
        )
        if not complete_result.success:
            return self._fail(f"External release completion failed: {complete_result.error}")

        workflow.logger.info("Phase 2 complete.")

        # --- Codex Release (optional) ---
        return await self._run_codex()

    # --- Signals ---

    @workflow.signal
    async def approve_phase2(self) -> None:
        """User approves moving from Phase 1 (internal) to Phase 2 (external)."""
        workflow.logger.info("Signal received: approve_phase2")
        self._phase2_approved = True

    @workflow.signal
    async def pr_merged(self) -> None:
        """User confirms the submodule dev→main PR has been merged."""
        workflow.logger.info("Signal received: pr_merged")
        self._pr_merged = True

    @workflow.signal
    async def start_codex(self) -> None:
        """User requests Codex plugin release."""
        workflow.logger.info("Signal received: start_codex")
        self._codex_requested = True

    @workflow.signal
    async def skip_codex(self) -> None:
        """User skips Codex plugin release."""
        workflow.logger.info("Signal received: skip_codex")
        self._codex_skipped = True

    # --- Queries ---

    @workflow.query
    def get_status(self) -> ReleaseStatus:
        """Return the current release status."""
        return self._status()

    # --- Helpers ---

    async def _run_codex(self) -> ReleaseStatus:
        """Wait for user to request or skip Codex, then run if requested."""
        workflow.logger.info("Waiting for user to request Codex release (or skip).")
        self._phase = ReleasePhase.EXTERNAL_RELEASE_COMPLETE
        await workflow.wait_condition(
            lambda: self._codex_requested or self._codex_skipped
        )

        if self._codex_requested:
            self._phase = ReleasePhase.CODEX_RELEASE
            codex_result = await workflow.execute_activity(
                codex_release,
                start_to_close_timeout=ACTIVITY_TIMEOUT,
            )
            if not codex_result.success:
                return self._fail(f"Codex release failed: {codex_result.error}")
            self._codex_pr_url = codex_result.pr_url or ""
            workflow.logger.info(f"Codex PR: {self._codex_pr_url}")

        self._phase = ReleasePhase.DONE
        return self._status()

    def _status(self) -> ReleaseStatus:
        return ReleaseStatus(
            phase=self._phase.value,
            current_version=self._current_version,
            new_version=self._new_version,
            release_pr_url=self._release_pr_url,
            codex_pr_url=self._codex_pr_url,
            error=self._error,
        )

    def _fail(self, error: str) -> ReleaseStatus:
        workflow.logger.error(error)
        self._error = error
        self._phase = ReleasePhase.FAILED
        return self._status()
