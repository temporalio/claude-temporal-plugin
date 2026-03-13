"""Temporal worker for eval workflows."""

import asyncio
import concurrent.futures

from temporalio.client import Client
from temporalio.worker import Worker

from .activities import get_existing_results, record_results, run_harbor_job
from .workflows import EvalWorkflow

TASK_QUEUE = "eval-runner"

def worker(client: Client):
    return Worker(
        client,
        task_queue=TASK_QUEUE,
        workflows=[EvalWorkflow],
        activities=[run_harbor_job, get_existing_results, record_results],
        activity_executor=concurrent.futures.ThreadPoolExecutor(max_workers=10),
    )    


async def main():
    client = await Client.connect("localhost:7233")

    the_worker = worker(client)
    print(f"Worker started on task queue: {TASK_QUEUE}")
    await the_worker.run()


def main_sync():
    asyncio.run(main())


if __name__ == "__main__":
    main_sync()
