"""Run Harbor eval jobs via the CLI.

No Temporal, no workflow engine — just a subprocess wrapper. Harbor itself
handles per-task parallelism (`-n`), repeated attempts (`-k`), and retries.
"""

import os
import shutil
import subprocess
from dataclasses import dataclass


def _find_harbor(repo_root: str) -> list[str]:
    """Resolve the harbor CLI command."""
    if shutil.which("harbor"):
        return ["harbor"]
    return ["uv", "run", "--project", os.path.join(repo_root, "evals", "harbor"), "harbor"]


@dataclass
class JobResult:
    job_dir: str
    dataset: str
    agent_name: str
    success: bool
    error: str | None = None


def run_harbor_job(
    *,
    repo_root: str,
    agent_name: str,
    models: list[str],
    dataset_path: str,
    job_name: str,
    jobs_dir: str,
    skills_dir: str | None,
    attempts: int = 2,
    concurrency: int = 4,
) -> JobResult:
    """Run a single Harbor job (one agent over one dataset, across `models`).

    Streams output live. Returns a JobResult; never raises on a non-zero exit.
    """
    cmd = [
        *_find_harbor(repo_root),
        "run",
        "-p", dataset_path,
        "-a", agent_name,
        "--job-name", job_name,
        "-o", jobs_dir,
        "-k", str(attempts),      # attempts per trial (averaged downstream)
        "-n", str(concurrency),   # concurrent trials within this run
    ]
    for model in models:
        cmd += ["-m", model]
    if skills_dir:
        # Upstream Harbor takes a skill directory (or a root of them) via --skill.
        cmd += ["--skill", skills_dir]

    dataset = os.path.basename(dataset_path)
    print(f"\n$ {' '.join(cmd)}\n", flush=True)

    proc = subprocess.run(cmd, text=True)

    job_dir = os.path.join(jobs_dir, job_name)
    if proc.returncode != 0:
        return JobResult(
            job_dir=job_dir,
            dataset=dataset,
            agent_name=agent_name,
            success=False,
            error=f"harbor exited {proc.returncode}",
        )
    return JobResult(job_dir=job_dir, dataset=dataset, agent_name=agent_name, success=True)
