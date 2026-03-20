"""CLI client for interacting with a running release workflow.

Use this to check status or send signals to an already-running workflow.
For starting a new release, use run.py instead.
"""

import argparse
import asyncio
import os
import sys

from temporalio.client import Client

from models import WORKFLOW_ID, ReleaseStatus
from workflows.release_workflow import ReleaseWorkflow


async def get_client() -> Client:
    address = os.environ.get("TEMPORAL_ADDRESS", "localhost:7233")
    return await Client.connect(address)


async def status(client: Client) -> None:
    handle = client.get_workflow_handle(WORKFLOW_ID)
    s = await handle.query(ReleaseWorkflow.get_status)
    _print_status(s)


async def signal(client: Client, signal_name: str) -> None:
    handle = client.get_workflow_handle(WORKFLOW_ID)
    signals = {
        "approve-phase2": ReleaseWorkflow.approve_phase2,
        "pr-merged": ReleaseWorkflow.pr_merged,
        "start-codex": ReleaseWorkflow.start_codex,
        "skip-codex": ReleaseWorkflow.skip_codex,
    }
    if signal_name not in signals:
        print(f"Unknown signal: {signal_name}")
        print(f"Available: {', '.join(signals.keys())}")
        sys.exit(1)

    await handle.signal(signals[signal_name])
    print(f"Signal '{signal_name}' sent.")

    await asyncio.sleep(2)
    await status(client)


def _print_status(s: ReleaseStatus) -> None:
    print(f"Phase:           {s.phase}")
    if s.current_version:
        print(f"Version:         {s.current_version} → {s.new_version}")
    if s.release_pr_url:
        print(f"Release PR:      {s.release_pr_url}")
    if s.codex_pr_url:
        print(f"Codex PR:        {s.codex_pr_url}")
    if s.error:
        print(f"Error:           {s.error}")

    hints = {
        "awaiting_phase2": "→ Send 'approve-phase2' signal when ready for external release.",
        "awaiting_pr_merge": "→ Review and merge the PR above, then send 'pr-merged' signal.",
        "external_release_complete": "→ Send 'start-codex' or 'skip-codex' signal.",
    }
    if s.phase in hints:
        print(f"\n{hints[s.phase]}")


async def main() -> None:
    parser = argparse.ArgumentParser(description="Release workflow client")
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("status", help="Check release status")

    signal_parser = subparsers.add_parser("signal", help="Send a signal")
    signal_parser.add_argument(
        "name",
        choices=["approve-phase2", "pr-merged", "start-codex", "skip-codex"],
    )

    args = parser.parse_args()
    client = await get_client()

    if args.command == "status":
        await status(client)
    elif args.command == "signal":
        await signal(client, args.name)


if __name__ == "__main__":
    asyncio.run(main())
