"""Activity for running Harbor eval jobs."""

import os
import select
import shutil
import subprocess

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
    Reads stdout via os.read() on the raw fd to avoid blocking in
    Python's text-mode codec layer (which isn't cancellation-safe).
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
        "-n", "2",
    ]
    if input.skills_dir:
        cmd.extend(["--skills-dir", input.skills_dir])

    activity.logger.info(f"Running: {' '.join(cmd)}")

    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )

    output_lines: list[str] = []
    buf = b""
    fd = proc.stdout.fileno()

    try:
        while proc.poll() is None:
            activity.heartbeat(f"running {input.job_name}")
            # Wait up to 30s for output, then loop back to heartbeat
            ready, _, _ = select.select([fd], [], [], 30)
            if ready:
                chunk = os.read(fd, 8192)
                if not chunk:
                    break
                buf += chunk
                while b"\n" in buf:
                    line, buf = buf.split(b"\n", 1)
                    decoded = line.decode("utf-8", errors="replace").rstrip()
                    output_lines.append(decoded)
                    activity.logger.info(decoded)
    except Exception:
        proc.kill()
        proc.wait()
        raise

    # Drain remaining output after process exits
    try:
        while True:
            chunk = os.read(fd, 8192)
            if not chunk:
                break
            buf += chunk
    except OSError:
        pass

    for line in buf.split(b"\n"):
        decoded = line.decode("utf-8", errors="replace").rstrip()
        if decoded:
            output_lines.append(decoded)

    proc.wait()
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
