"""Worker for the release pipeline."""

import asyncio
import concurrent.futures
import contextlib
import os
from collections.abc import AsyncIterator

from temporalio.client import Client
from temporalio.testing import WorkflowEnvironment
from temporalio.worker import Worker

from activities.git_ops import (
    codex_release,
    complete_external_release,
    create_release_pr,
    get_version_info,
    internal_release,
    preflight_checks,
    preflight_checks_codex,
)
from models import TASK_QUEUE
from workflows.release_workflow import ReleaseWorkflow

ALL_ACTIVITIES = [
    preflight_checks,
    preflight_checks_codex,
    get_version_info,
    internal_release,
    create_release_pr,
    complete_external_release,
    codex_release,
]


@contextlib.asynccontextmanager
async def create_worker(client: Client) -> AsyncIterator[Worker]:
    """Create and run a worker as a context manager."""
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
        w = Worker(
            client,
            task_queue=TASK_QUEUE,
            workflows=[ReleaseWorkflow],
            activities=ALL_ACTIVITIES,
            activity_executor=executor,
        )
        async with w:
            yield w


async def _try_connect(address: str) -> Client | None:
    """Try to connect to a Temporal server, return None on failure."""
    try:
        client = await Client.connect(address)
        await client.service_client.check_health()
        return client
    except Exception:
        return None


@contextlib.asynccontextmanager
async def get_client_and_worker() -> AsyncIterator[Client]:
    """Resolve a Temporal client (and optionally a worker) based on environment.

    Connection strategy:
    1. TEMPORAL_ADDRESS env var — remote server, start local worker
    2. localhost:7233 reachable — existing server, start local worker
    3. Neither — start ephemeral in-process server + worker
    """
    # 1. Explicit TEMPORAL_ADDRESS
    temporal_address = os.environ.get("TEMPORAL_ADDRESS")
    if temporal_address:
        print(f"Connecting to Temporal at {temporal_address} (from TEMPORAL_ADDRESS)")
        client = await Client.connect(temporal_address)
        async with create_worker(client):
            yield client
        return

    # 2. Try localhost:7233
    client = await _try_connect("localhost:7233")
    if client is not None:
        print("Connected to Temporal at localhost:7233, starting local worker")
        async with create_worker(client):
            yield client
        return

    # 3. Fall back to ephemeral in-process server
    print("No Temporal server found, starting ephemeral in-process server")
    async with await WorkflowEnvironment.start_local() as env:
        async with create_worker(env.client):
            yield env.client


async def run_standalone() -> None:
    """Run the worker standalone (connects to localhost:7233)."""
    client = await Client.connect("localhost:7233")
    async with create_worker(client):
        print(f"Worker started, listening on task queue: {TASK_QUEUE}")
        await asyncio.Event().wait()  # Run forever


if __name__ == "__main__":
    asyncio.run(run_standalone())
