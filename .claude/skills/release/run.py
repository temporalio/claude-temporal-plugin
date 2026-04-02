"""All-in-one release runner.

Starts Temporal (if needed), a worker, and the release workflow.
Keeps running until the workflow completes.

Usage:
    python run.py <major|minor|patch>
    python run.py --codex-only          # Re-push to Codex PR only

Use client.py from another terminal (or via the /release skill) to send signals.
"""

import argparse
import asyncio

from models import TASK_QUEUE, WORKFLOW_ID, ReleaseInput
from worker import get_client_and_worker
from workflows.release_workflow import ReleaseWorkflow


async def run(level: str, codex_only: bool = False) -> None:
    async with get_client_and_worker() as client:
        handle = await client.start_workflow(
            ReleaseWorkflow.run,
            ReleaseInput(version_level=level, codex_only=codex_only),
            id=WORKFLOW_ID,
            task_queue=TASK_QUEUE,
        )
        print(f"Release workflow started: {handle.id}")
        print("Use client.py to check status and send signals.")
        print("Waiting for workflow to complete (Ctrl+C to detach)...\n")

        result = await handle.result()
        print(f"\nWorkflow finished: phase={result.phase}")
        if result.error:
            print(f"Error: {result.error}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Start a release workflow")
    parser.add_argument("level", nargs="?", choices=["major", "minor", "patch"])
    parser.add_argument("--codex-only", action="store_true",
                        help="Skip to Codex release only (for re-pushing after review feedback)")
    args = parser.parse_args()

    if not args.codex_only and not args.level:
        parser.error("level is required unless --codex-only is specified")

    # In codex-only mode, level is unused but required by the dataclass
    level = args.level or "patch"
    asyncio.run(run(level, codex_only=args.codex_only))


if __name__ == "__main__":
    main()
