"""Run eval workflows (baseline or with skills).

Usage:
    uv run --project evals eval-run baseline
    uv run --project evals eval-run skills

Connection logic:
    1. If TEMPORAL_ADDRESS is set, connect to it (no local worker).
    2. Else try localhost:7233 — if reachable, connect and start a local worker.
    3. Else fall back to an ephemeral in-process Temporal server + worker.
"""

import argparse
import asyncio
import contextlib
import os
import uuid

from temporalio.client import Client
from temporalio.testing import WorkflowEnvironment

from .models import AgentConfig, EvalRunInput
from .worker import worker
from .workflows import EvalWorkflow

TASK_QUEUE = "eval-runner"

# ============================================================
# Agent configurations to evaluate.
# Add new entries here to extend the eval matrix.
# ============================================================
AGENTS = [
    AgentConfig(name="claude-code", model="anthropic/claude-sonnet-4-6"),
    # AgentConfig(name="claude-code", model="anthropic/claude-opus-4-1"),
    # AgentConfig(name="aider", model="anthropic/claude-sonnet-4-6"),
]

DATASETS = [
    "temporal-python",
    "temporal-typescript",
    "temporal-questions",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run eval workflows")
    parser.add_argument(
        "mode",
        choices=["baseline", "skills"],
        help="'baseline' runs without skills, 'skills' runs with the temporal-developer skill",
    )
    return parser.parse_args()


async def _try_connect(address: str) -> Client | None:
    """Try to connect to a Temporal server, return None on failure."""
    try:
        client = await Client.connect(address)
        # Verify the connection is live
        await client.service_client.check_health()
        return client
    except Exception:
        return None


@contextlib.asynccontextmanager
async def _get_client_and_worker():
    """Resolve a Temporal client (and optionally a worker) based on environment.

    Yields (client, worker_context_manager_or_None).
    """
    # 1. Explicit TEMPORAL_ADDRESS — remote server, no local worker
    temporal_address = os.environ.get("TEMPORAL_ADDRESS")
    if temporal_address:
        print(f"Connecting to Temporal at {temporal_address} (from TEMPORAL_ADDRESS)")
        client = await Client.connect(temporal_address)
        yield client
        return

    # 2. Try localhost:7233
    client = await _try_connect("localhost:7233")
    if client is not None:
        print("Connected to Temporal at localhost:7233, starting local worker")
        async with worker(client):
            yield client
        return

    # 3. Fall back to ephemeral in-process server
    print("No Temporal server found, starting ephemeral in-process server")
    async with await WorkflowEnvironment.start_local(ui=True, port=7233) as env:
        async with worker(env.client):
            yield env.client


async def main():
    args = parse_args()
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

    is_baseline = args.mode == "baseline"

    skills_dir = None
    if not is_baseline:
        skills_dir = os.path.join(
            repo_root, "plugins", "temporal-developer", "skills", "temporal-developer"
        )

    eval_input = EvalRunInput(
        agents=AGENTS,
        datasets=DATASETS,
        repo_root=repo_root,
        skills_dir=skills_dir,
        baseline=is_baseline,
    )

    workflow_id = f"eval-{args.mode}-{uuid.uuid4().hex[:8]}"

    async with _get_client_and_worker() as client:
        result = await client.execute_workflow(
            EvalWorkflow.run,
            eval_input,
            id=workflow_id,
            task_queue=TASK_QUEUE,
        )

    # Print summary
    label = "Baseline" if is_baseline else "Skills"
    succeeded = sum(1 for r in result.results if r.success)
    failed = sum(1 for r in result.results if not r.success)
    print(f"\n=== {label} eval complete: {succeeded} succeeded, {failed} failed ===")
    if result.record_message:
        print(result.record_message)
    for r in result.results:
        status = "OK" if r.success else f"FAIL: {r.error}"
        print(f"  {r.dataset} ({r.agent_name}/{r.agent_model}): {status}")


def main_sync():
    asyncio.run(main())


if __name__ == "__main__":
    main_sync()
