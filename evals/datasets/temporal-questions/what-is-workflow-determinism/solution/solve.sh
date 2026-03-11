#!/bin/bash
set -euo pipefail
cd /workspace

cat > answer.md << 'EOF'
# Workflow Determinism in Temporal

## What Determinism Means

In Temporal, workflow determinism means that workflow code must produce the exact same sequence of commands every time it is executed with the same input history. This is because Temporal uses an event-sourcing model where workflows are reconstructed by replaying their event history.

## Why It Matters

When a workflow needs to be restored (after a worker crash, during scaling, etc.), Temporal replays the workflow code against the recorded event history. During replay, the workflow code must generate the same commands in the same order as the original execution. If the code produces different commands on replay, Temporal detects a "non-determinism error" and the workflow fails.

## Common Violations

The following patterns violate determinism constraints:

- **Random numbers**: `random.random()` produces different values each call
- **Current time**: `datetime.now()` returns a different value on replay
- **UUIDs**: `uuid.uuid4()` generates a new value each time
- **Network/IO calls**: HTTP requests, file reads, database queries may return different results
- **Threading**: Concurrent execution with non-deterministic scheduling
- **Global mutable state**: Shared state modified outside the workflow
- **Non-deterministic iteration**: Iterating over sets or dicts with unstable ordering

## Workarounds

1. **Use activities**: Wrap all side effects (API calls, file I/O, database operations) in activities. Activity results are recorded in the event history and returned from the history on replay.
2. **SDK deterministic APIs**: Use `workflow.now()` instead of `datetime.now()`, `workflow.random()` instead of `random.random()`, and `workflow.uuid4()` instead of `uuid.uuid4()`.
3. **SideEffect**: For small non-deterministic values that don't need an activity, use `workflow.side_effect()` — the value is recorded once and replayed.
4. **Versioning**: Use `workflow.patched()` / `workflow.deprecate_patch()` to safely change workflow logic without breaking running workflows.
EOF
