"""Validates a generated Python Temporal greeting workflow.

Writes per-check rewards to /logs/verifier/reward.json.
"""

import json
import os
import py_compile
import re
from pathlib import Path

WORKSPACE = Path("/workspace")
REWARD_PATH = Path("/logs/verifier/reward.json")

rewards: dict[str, float] = {}


def check(key: str, passed: bool, label: str) -> None:
    rewards[key] = 1.0 if passed else 0.0
    status = "PASS" if passed else "FAIL"
    print(f"{status}: {label}")


def any_py_contains(pattern: str) -> bool:
    """Search all .py files for a pattern."""
    for f in WORKSPACE.rglob("*.py"):
        if re.search(pattern, f.read_text()):
            return True
    return False


os.chdir(WORKSPACE)

py_files = list(WORKSPACE.rglob("*.py"))

# --- Project structure ---
check("file_deps", any((WORKSPACE / p).is_file() for p in ["requirements.txt", "pyproject.toml"]), "dependency file exists")
check("has_py_files", len(py_files) > 0, "has .py files")

# --- Code patterns ---
check("pattern_workflow_defn", any_py_contains(r"@workflow\.defn"), "@workflow.defn decorator")
check("pattern_activity_defn", any_py_contains(r"@activity\.defn"), "@activity.defn decorator")
check("pattern_workflow_run", any_py_contains(r"@workflow\.run"), "@workflow.run decorator")
check("pattern_async_def", any_py_contains(r"async\s+def"), "async def")
check("pattern_await", any_py_contains(r"await\s"), "await")
check("pattern_imports", any_py_contains(r"from temporalio|import temporalio"), "temporalio imports")
check("pattern_signal", any_py_contains(r"@workflow\.signal"), "@workflow.signal decorator")
check("pattern_query", any_py_contains(r"@workflow\.query"), "@workflow.query decorator")

# --- Python syntax ---
all_compile = True
for f in py_files:
    try:
        py_compile.compile(str(f), doraise=True)
    except py_compile.PyCompileError:
        all_compile = False
        break
check("syntax_valid", all_compile, "all .py files compile")

# --- Dependencies ---
check(
    "deps_temporalio",
    any(
        (WORKSPACE / p).is_file() and re.search(r"temporalio", (WORKSPACE / p).read_text()) is not None
        for p in ["requirements.txt", "pyproject.toml"]
    ),
    "temporalio in dependencies",
)

# --- Write rewards ---
REWARD_PATH.parent.mkdir(parents=True, exist_ok=True)
REWARD_PATH.write_text(json.dumps(rewards))
