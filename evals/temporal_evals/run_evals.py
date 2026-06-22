"""Run skill evals against the temporal-developer skill.

Conceptually this is just: run the task suites with the skill, run them
without (baseline), and track the per-task rewards so we can see the delta.
Harbor does the actual running, parallelism, attempts, and metrics; this
script only orchestrates the matrix and records results over time.

Usage:
    uv run --project evals eval-run baseline   # no skill
    uv run --project evals eval-run skills     # with the temporal-developer skill
"""

import argparse
from datetime import datetime
from pathlib import Path

from .models import AgentConfig
from .record import get_existing_results, record_results
from .runner import run_harbor_job

# ============================================================
# Agent configurations to evaluate. Each agent runs across all
# datasets; `models` is passed to Harbor as a list in one run.
# ============================================================
AGENTS = [
    AgentConfig(name="claude-code", model="anthropic/claude-sonnet-4-6"),
    # AgentConfig(name="claude-code", model="anthropic/claude-opus-4-8"),
    # AgentConfig(name="aider", model="anthropic/claude-sonnet-4-6"),
]

DATASETS = [
    "temporal-python",
    "temporal-typescript",
    "temporal-questions",
]

ATTEMPTS = 2      # repeated attempts per task (averaged in record.py)
CONCURRENCY = 4   # concurrent trials within a single Harbor run

SKILL_PATH = ("plugins", "temporal-developer", "skills", "temporal-developer")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run skill evals")
    parser.add_argument(
        "mode",
        choices=["baseline", "skills"],
        help="'baseline' runs without skills, 'skills' runs with the temporal-developer skill",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    baseline = args.mode == "baseline"

    repo_root = Path(__file__).resolve().parents[2]
    evals_root = repo_root / "evals"
    jobs_dir = str(evals_root / "jobs")

    skills_dir: str | None = None
    skills: list[str] = []
    if not baseline:
        skills_dir = str(repo_root.joinpath(*SKILL_PATH))
        skills = [Path(skills_dir).name]

    existing = get_existing_results(
        baseline=baseline, evals_root=evals_root, skills=skills
    )
    timestamp = datetime.now().strftime("%Y-%m-%d__%H-%M-%S")

    results = []
    skipped = 0
    for agent in AGENTS:
        for dataset in DATASETS:
            model_key = agent.model.replace("/", "-")
            if (agent.name, model_key, dataset) in existing:
                print(f"Skipping {agent.name}/{agent.model} on {dataset} — already recorded")
                skipped += 1
                continue

            suffix = "__baseline" if baseline else ""
            job_name = f"{timestamp}__{agent.name}__{dataset}{suffix}"
            results.append(
                run_harbor_job(
                    repo_root=str(repo_root),
                    agent_name=agent.name,
                    models=[agent.model],
                    dataset_path=str(evals_root / "datasets" / dataset),
                    job_name=job_name,
                    jobs_dir=jobs_dir,
                    skills_dir=skills_dir,
                    attempts=ATTEMPTS,
                    concurrency=CONCURRENCY,
                )
            )

    successful_dirs = [r.job_dir for r in results if r.success]
    if successful_dirs:
        msg = record_results(
            job_dirs=successful_dirs,
            baseline=baseline,
            evals_root=evals_root,
            skills=skills,
        )
        print(f"\n{msg}")

    label = "Baseline" if baseline else "Skills"
    succeeded = sum(1 for r in results if r.success)
    failed = sum(1 for r in results if not r.success)
    print(f"\n=== {label} eval complete: {succeeded} succeeded, {failed} failed, {skipped} skipped ===")
    for r in results:
        status = "OK" if r.success else f"FAIL: {r.error}"
        print(f"  {r.dataset} ({r.agent_name}): {status}")


def main_sync() -> None:
    main()


if __name__ == "__main__":
    main_sync()
