# Temporal Developer Skill Evals

Benchmarks for measuring the impact of the `temporal-developer` skill on code generation quality.

## Prerequisites

```bash
# Install harbor CLI from local submodule
uv tool install --from ./evals/harbor harbor
```

## Quick Start

```bash
# Run a single task WITHOUT skill (baseline)
harbor run -p evals/datasets/temporal-python/greeting-workflow \
  -a claude-code -m anthropic/claude-sonnet-4-6

# Run a single task WITH skill
harbor run -p evals/datasets/temporal-python/greeting-workflow \
  -a claude-code -m anthropic/claude-sonnet-4-6 \
  --skills-dir plugins/temporal-developer/skills/temporal-developer

# Full comparison (with vs without skill)
./evals/scripts/run-comparison.sh --dataset temporal-python

# Specific model
./evals/scripts/run-comparison.sh --dataset temporal-python --model anthropic/claude-sonnet-4-6
```

## Directory Structure

```
evals/
├── harbor/                          # Harbor framework (git submodule)
├── scripts/
│   └── run-comparison.sh           # Wrapper for skill vs no-skill comparisons
└── datasets/
    ├── temporal-python/
    │   ├── greeting-workflow/       # Python greeting workflow task
    │   └── _template/              # Copyable template for new Python tasks
    ├── temporal-typescript/
    │   ├── greeting-workflow/       # TypeScript greeting workflow task
    │   └── _template/              # Copyable template for new TS tasks
    └── temporal-questions/
        ├── what-is-workflow-determinism/  # Q/A: workflow determinism
        └── _template/              # Copyable template for new Q/A tasks
```

## Adding a New Task

### Code generation tasks (temporal-python, temporal-typescript)

1. Copy the template: `cp -r evals/datasets/temporal-python/_template evals/datasets/temporal-python/my-task`
2. Edit `instruction.md` with the task prompt
3. Edit `tests/test.sh` with validation logic (write score to `/logs/verifier/reward.txt`)
4. Edit `solution/solve.sh` with a reference solution
5. Adjust `task.toml` timeouts and resources as needed
6. Optionally customize `environment/Dockerfile`

### Q/A tasks (temporal-questions)

1. Copy the template: `cp -r evals/datasets/temporal-questions/_template evals/datasets/temporal-questions/my-question`
2. Edit `instruction.md` with your question (must tell the agent to write to `answer.md`)
3. Edit the rubric in `tests/test.sh` — define what key concepts a correct answer should cover
4. Edit `solution/solve.sh` with a reference answer

Q/A tasks use LLM-as-judge (Claude Haiku) to grade the answer against the rubric. The verifier gets `ANTHROPIC_API_KEY` via the `[verifier.env]` section in `task.toml`.

## Scoring

Tests write a score between 0.0 and 1.0 to `/logs/verifier/reward.txt`.

**Code generation tasks** use partial credit: `passed_checks / total_checks`.

**Q/A tasks** use LLM-as-judge with a rubric:

| Score | Meaning |
|-------|---------|
| 1.0   | Covers all rubric areas accurately with good depth |
| 0.75  | Covers most areas well, or all with minor gaps |
| 0.5   | Covers about half, or has some inaccuracies |
| 0.25  | Covers little, or is mostly vague |
| 0.0   | Missing, wrong, or off-topic |
