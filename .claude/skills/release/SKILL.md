---
name: release
description: Run the release workflow for the temporal-developer skill. Use when the user says "release", "cut a release", "bump version", "publish", or "ship it".
version: 0.1.0
---

# Release Workflow

This skill orchestrates releasing the temporal-developer skill using a Temporal workflow. The workflow manages the two-phase release pipeline with human checkpoints via signals.

## Architecture

The release is a single Temporal workflow (`ReleaseWorkflow`) that:
- Runs activities for git/GitHub operations
- Waits for human signals at checkpoints
- Exposes query handlers for status

**Entry points:**
- `run.py` — Starts Temporal (if needed), a worker, and the workflow. Blocks until completion.
- `client.py` — Send signals and check status on a running workflow.
- `worker.py` — Standalone worker (for use with an existing Temporal server).

## Step 1: Determine Version

Ask the user: **major, minor, or patch?**

## Step 2: Start the Release

Start the workflow in a background terminal:

```bash
cd .claude/skills/release && uv run run.py <level>
```

The runner will:
1. Connect to Temporal (or start an ephemeral in-process server if none is running)
2. Start a local worker
3. Run preflight checks (clean git state, both repos on `dev`)
4. Execute Phase 1 (internal release) automatically
5. Block, waiting for signals at each checkpoint

## Step 3: Phase 1 Complete — Approve Phase 2

Check status and tell the user Phase 1 is done. They can dogfood test (optional).

```bash
cd .claude/skills/release && uv run client.py status
```

When the user is ready for the external release:

```bash
cd .claude/skills/release && uv run client.py signal approve-phase2
```

## Step 4: Review and Merge the Release PR

Check status to get the release PR URL:

```bash
cd .claude/skills/release && uv run client.py status
```

Show the user the PR URL. They need to review and merge it. Once merged:

```bash
cd .claude/skills/release && uv run client.py signal pr-merged
```

The workflow will complete the outer repo release automatically.

## Step 5: Codex Release (Optional)

After Phase 2 completes, send one of:

```bash
cd .claude/skills/release && uv run client.py signal start-codex
# or
cd .claude/skills/release && uv run client.py signal skip-codex
```

## Codex-Only Mode

If the core + Claude Code release is already done and you just need to push to the Codex PR (first submission or after review feedback on Codex-only changes):

```bash
cd .claude/skills/release && uv run run.py --codex-only
```

This skips Phase 1 and 2 entirely and runs the Codex release immediately — no signals needed.

## Handling Codex Review Feedback

- **Codex-only changes** (`.codex-plugin/` metadata): fix in the outer repo, then `python run.py --codex-only`.
- **Skill content changes**: must flow through the full pipeline (new workflow run: Phase 1 → Phase 2 → Codex).
