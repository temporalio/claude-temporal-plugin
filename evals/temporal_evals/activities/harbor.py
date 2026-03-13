"""Activity for running Harbor eval jobs."""

import os
import shutil
import subprocess
import time

from temporalio import activity

from ..models import HarborJobInput, HarborJobOutput


def _find_harbor(repo_root: str) -> list[str]:
    """Resolve the harbor CLI command."""
    if shutil.which("harbor"):
        return ["harbor"]
    return ["uv", "run", "--project", os.path.join(repo_root, "evals", "harbor"), "harbor"]


@activity.defn
def run_harbor_job(input: HarborJobInput) -> HarborJobOutput:
    """Run a single Harbor eval job via the CLI.

    Uses heartbeating so long-running jobs don't time out silently.
    """
    harbor_cmd = _find_harbor(input.repo_root)

    cmd = [
        *harbor_cmd,
        "run",
        "-p", input.dataset_path,
        "-a", input.agent_name,
        "-m", input.agent_model,
        "--job-name", input.job_name,
        "-o", input.jobs_dir,
    ]
    if input.skills_dir:
        cmd.extend(["--skills-dir", input.skills_dir])

    activity.logger.info(f"Running: {' '.join(cmd)}")

    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )

    output_lines: list[str] = []
    while proc.poll() is None:
        activity.heartbeat(f"running {input.job_name}")
        if proc.stdout:
            line = proc.stdout.readline()
            if line:
                stripped = line.rstrip()
                output_lines.append(stripped)
                activity.logger.info(stripped)
        time.sleep(1)

    # Drain remaining output
    if proc.stdout:
        for line in proc.stdout:
            output_lines.append(line.rstrip())

    dataset = os.path.basename(input.dataset_path)

    if proc.returncode != 0:
        tail = output_lines[-5:] if output_lines else ["no output"]
        return HarborJobOutput(
            job_dir=os.path.join(input.jobs_dir, input.job_name),
            dataset=dataset,
            agent_name=input.agent_name,
            agent_model=input.agent_model,
            success=False,
            error=f"Exit code {proc.returncode}: {' | '.join(tail)}",
        )

    return HarborJobOutput(
        job_dir=os.path.join(input.jobs_dir, input.job_name),
        dataset=dataset,
        agent_name=input.agent_name,
        agent_model=input.agent_model,
        success=True,
    )
