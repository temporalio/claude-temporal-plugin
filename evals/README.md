# Temporal Developer Skill Evals

Benchmarks for measuring the impact of the `temporal-developer` skill on code generation quality.

## Prerequisites

- [uv](https://docs.astral.sh/uv/) installed
- `ANTHROPIC_API_KEY` set in your environment

## Quick Start

```bash
uv run --project evals eval-run skills    # with skill (before submitting a PR)
uv run --project evals eval-run baseline  # without skill (when tasks or Harbor change)
```

Each invocation drives the `harbor` CLI directly — Harbor handles running the
tasks, concurrency, repeated attempts, and metrics. There is no server or
worker to start. Requires `ANTHROPIC_API_KEY` in your environment.

## Extending Agent Configurations

Edit the `AGENTS` list in `temporal_evals/run_evals.py`:

```python
AGENTS = [
    AgentConfig(name="claude-code", model="anthropic/claude-sonnet-4-6"),
    AgentConfig(name="claude-code", model="anthropic/claude-opus-4-1"),
    AgentConfig(name="aider", model="anthropic/claude-sonnet-4-6"),
]
```

Each agent config runs across all datasets. Each agent's `model` is passed to
`harbor run` (Harbor parallelizes the tasks within a run).

## Directory Structure

```
evals/
├── harbor/                          # Harbor framework (git submodule)
├── pyproject.toml                   # Python project (pyyaml only)
├── results.yaml                     # Eval results with skills (keyed by commit SHA)
├── baseline.yaml                    # Baseline results without skills (flat array)
├── temporal_evals/                  # Eval orchestration package
│   ├── models.py                   # AgentConfig
│   ├── runner.py                   # Drives the `harbor run` CLI (subprocess)
│   ├── record.py                   # Extract job results -> results.yaml / baseline.yaml
│   ├── dashboard.py                # Skill-vs-baseline comparison dashboard
│   └── run_evals.py               # CLI entry point (baseline or skills)
├── datasets/
│   ├── temporal-python/
│   │   └── greeting-workflow/       # Python greeting workflow task
│   ├── temporal-typescript/
│   │   └── greeting-workflow/       # TypeScript greeting workflow task
│   └── temporal-questions/
│       └── what-is-workflow-determinism/  # Q/A: workflow determinism
└── templates/                       # Copyable templates for new tasks
    ├── temporal-python/
    ├── temporal-typescript/
    └── temporal-questions/
```

## Adding a New Task

### Code generation tasks (temporal-python, temporal-typescript)

1. Copy the template: `cp -r evals/templates/temporal-python evals/datasets/temporal-python/my-task`
2. Edit `instruction.md` with the task prompt
3. Edit `tests/test.py` with validation checks (write rewards to `/logs/verifier/reward.json`)
4. Edit `solution/solve.sh` with a reference solution
5. Adjust `task.toml` timeouts and resources as needed
6. Optionally customize `environment/Dockerfile`

### Q/A tasks (temporal-questions)

1. Copy the template: `cp -r evals/templates/temporal-questions evals/datasets/temporal-questions/my-question`
2. Edit `instruction.md` with your question (must tell the agent to write to `answer.md`)
3. Edit the rubric in `tests/rubric.md` — define what key concepts a correct answer should cover
4. Edit `solution/solve.sh` with a reference answer

Q/A tasks use LLM-as-judge (Claude Haiku) to grade the answer against the rubric. The verifier gets `ANTHROPIC_API_KEY` via the `[verifier.env]` section in `task.toml`.

## Tracking Results

Two result files, both version-controlled:

- **`results.yaml`** — with-skill results, keyed by commit SHA. Updated on every skill change.
- **`baseline.yaml`** — no-skill results, flat array. Updated rarely (when tasks or Harbor change).

**Before submitting a PR:**

```bash
uv run --project evals eval-run skills
# Commit both the skill changes and the updated results.yaml
```

## Scoring

Tests write per-check rewards to `/logs/verifier/reward.json` as a dict of named scores (0.0 or 1.0 each).

**Q/A tasks** use LLM-as-judge with a rubric:

| Score | Meaning |
|-------|---------|
| 1.0   | Covers all rubric areas accurately with good depth |
| 0.75  | Covers most areas well, or all with minor gaps |
| 0.5   | Covers about half, or has some inaccuracies |
| 0.25  | Covers little, or is mostly vague |
| 0.0   | Missing, wrong, or off-topic |
