"""Validates a generated TypeScript Temporal greeting workflow.

Writes per-check rewards to /logs/verifier/reward.json.
"""

import json
import os
import re
import subprocess
from pathlib import Path

WORKSPACE = Path("/workspace")
REWARD_PATH = Path("/logs/verifier/reward.json")

rewards: dict[str, float] = {}


def check(key: str, passed: bool, label: str) -> None:
    rewards[key] = 1.0 if passed else 0.0
    status = "PASS" if passed else "FAIL"
    print(f"{status}: {label}")


def any_ts_contains(pattern: str) -> bool:
    """Search all .ts files (excluding node_modules) for a pattern."""
    for f in WORKSPACE.rglob("*.ts"):
        if "node_modules" in f.parts:
            continue
        if re.search(pattern, f.read_text()):
            return True
    return False


os.chdir(WORKSPACE)

ts_files = [f for f in WORKSPACE.rglob("*.ts") if "node_modules" not in f.parts]

# --- Project structure ---
check("file_package", (WORKSPACE / "package.json").is_file(), "package.json exists")
check("has_ts_files", len(ts_files) > 0, "has .ts files")

# --- Code patterns ---
check("pattern_proxy_activities", any_ts_contains(r"proxyActivities"), "proxyActivities pattern")
check("pattern_async", any_ts_contains(r"async"), "async in code")
check("pattern_await", any_ts_contains(r"await"), "await in code")
check("pattern_define_signal", any_ts_contains(r"defineSignal"), "defineSignal")
check("pattern_define_query", any_ts_contains(r"defineQuery"), "defineQuery")
check("pattern_imports", any_ts_contains(r"@temporalio"), "@temporalio imports")

# --- Dependencies ---
pkg = WORKSPACE / "package.json"
check("deps_temporalio", pkg.is_file() and re.search(r"@temporalio", pkg.read_text()) is not None, "@temporalio in package.json")

# --- TypeScript compilation ---
tsc_passed = False
if (WORKSPACE / "package.json").is_file():
    if not (WORKSPACE / "node_modules").is_dir():
        subprocess.run(["npm", "install", "--ignore-scripts"], capture_output=True)
    tsc_result = subprocess.run(["npx", "tsc", "--noEmit"], capture_output=True)
    tsc_passed = tsc_result.returncode == 0
check("tsc_compiles", tsc_passed, "TypeScript compilation")

# --- Write rewards ---
REWARD_PATH.parent.mkdir(parents=True, exist_ok=True)
REWARD_PATH.write_text(json.dumps(rewards))
