#!/bin/bash
# Minimal reference solution for the Python greeting workflow task.
set -euo pipefail
cd /workspace

cat > activities.py << 'PYEOF'
from temporalio import activity


@activity.defn
async def format_greeting(name: str) -> str:
    return f"Hello, {name}!"
PYEOF

cat > workflows.py << 'PYEOF'
from datetime import timedelta
from temporalio import workflow

with workflow.unsafe.imports_passed_through():
    from activities import format_greeting


@workflow.defn
class GreetingWorkflow:
    def __init__(self) -> None:
        self._greeting_count: int = 0
        self._greeting_style: str = "Hello"

    @workflow.run
    async def run(self, name: str) -> str:
        self._greeting_count += 1
        result = await workflow.execute_activity(
            format_greeting,
            name,
            start_to_close_timeout=timedelta(seconds=10),
        )
        return result

    @workflow.signal
    async def update_greeting_style(self, style: str) -> None:
        self._greeting_style = style

    @workflow.query
    def get_greeting_count(self) -> int:
        return self._greeting_count
PYEOF

cat > worker.py << 'PYEOF'
import asyncio
from temporalio.client import Client
from temporalio.worker import Worker
from activities import format_greeting
from workflows import GreetingWorkflow


async def main() -> None:
    client = await Client.connect("localhost:7233")
    worker = Worker(
        client,
        task_queue="greeting-task-queue",
        workflows=[GreetingWorkflow],
        activities=[format_greeting],
    )
    await worker.run()


if __name__ == "__main__":
    asyncio.run(main())
PYEOF

cat > client.py << 'PYEOF'
import asyncio
import sys
from temporalio.client import Client
from workflows import GreetingWorkflow


async def main() -> None:
    name = sys.argv[1] if len(sys.argv) > 1 else "World"
    client = await Client.connect("localhost:7233")
    result = await client.execute_workflow(
        GreetingWorkflow.run,
        name,
        id=f"greeting-{name}",
        task_queue="greeting-task-queue",
    )
    print(result)


if __name__ == "__main__":
    asyncio.run(main())
PYEOF

cat > requirements.txt << 'PYEOF'
temporalio>=1.7.0
PYEOF
