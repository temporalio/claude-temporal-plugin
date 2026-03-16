"""Validates child workflows implementation."""

import json
import os
import py_compile
import re
import subprocess
import asyncio
from pathlib import Path

import subprocess as _sp
_sp.run(["pip", "install", "--break-system-packages", "-q", "temporalio"], check=True)
del _sp

from temporalio.testing import WorkflowEnvironment

WORKSPACE = Path("/workspace")
REWARD_PATH = Path("/logs/verifier/reward.json")
rewards: dict[str, float] = {}


def check(key: str, passed: bool, label: str) -> None:
    rewards[key] = 1.0 if passed else 0.0
    status = "PASS" if passed else "FAIL"
    print(f"{status}: {label}")


def run(cmd: list[str], timeout: int = 30) -> tuple[str, str, int]:
    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True, timeout=timeout, cwd=WORKSPACE
        )
        return result.stdout, result.stderr, result.returncode
    except subprocess.TimeoutExpired:
        return "", "TIMEOUT", -1


def any_py_contains(pattern: str) -> bool:
    for f in WORKSPACE.rglob("*.py"):
        try:
            if re.search(pattern, f.read_text()):
                return True
        except Exception:
            pass
    return False


os.chdir(WORKSPACE)


async def main() -> None:
    async with await WorkflowEnvironment.start_local(port=7233) as env:
        # Install deps
        _, _, sync_rc = run(["uv", "sync"], timeout=60)
        check("deps_installed", sync_rc == 0, "uv sync succeeds")

        # Run the program
        stdout, stderr, rc = run(["uv", "run", "python", "parent_child.py", "3"], timeout=15)
        check("runs_successfully", rc == 0, "program exits cleanly")
        check("correct_output", all(f"Task {n} complete" in stdout for n in [1, 2, 3]), "expected output")

        # Static checks
        check("has_workflow_defn", any_py_contains(r"@workflow\.defn"), "@workflow.defn decorator")

        py_files = list(WORKSPACE.rglob("*.py"))
        all_compile = True
        for f in py_files:
            try:
                py_compile.compile(str(f), doraise=True)
            except py_compile.PyCompileError:
                all_compile = False
                break
        check("syntax_valid", all_compile, "all .py files compile")

    REWARD_PATH.parent.mkdir(parents=True, exist_ok=True)
    REWARD_PATH.write_text(json.dumps(rewards))


asyncio.run(main())
