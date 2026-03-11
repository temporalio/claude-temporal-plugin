#!/bin/bash
# Validates a generated Python Temporal greeting workflow.
# Writes a partial-credit score (0.0–1.0) to /logs/verifier/reward.txt.
set -euo pipefail

cd /workspace

TOTAL=0
PASSED=0

check() {
    TOTAL=$((TOTAL + 1))
    if eval "$1" > /dev/null 2>&1; then
        PASSED=$((PASSED + 1))
        echo "PASS: $2"
    else
        echo "FAIL: $2"
    fi
}

# --- File existence ---
check '[ -f workflows.py ]'   "workflows.py exists"
check '[ -f activities.py ]'  "activities.py exists"
check '[ -f worker.py ]'      "worker.py exists"
check '[ -f client.py ]'      "client.py exists"
check '[ -f requirements.txt ] || [ -f pyproject.toml ]' "dependency file exists"

# --- Code patterns ---
check 'grep -q "@workflow.defn" workflows.py'   "@workflow.defn decorator"
check 'grep -q "@activity.defn" activities.py'   "@activity.defn decorator"
check 'grep -q "@workflow.run"  workflows.py'    "@workflow.run decorator"
check 'grep -q "async def"     workflows.py'     "async def in workflows"
check 'grep -q "await"         workflows.py'     "await in workflows"
check 'grep -rq "from temporalio\|import temporalio" *.py' "temporalio imports"

# --- Signal and query handlers ---
check 'grep -q "@workflow.signal" workflows.py'  "@workflow.signal decorator"
check 'grep -q "@workflow.query"  workflows.py'  "@workflow.query decorator"

# --- Python syntax ---
for f in workflows.py activities.py worker.py client.py; do
    check "[ ! -f $f ] || python3 -m py_compile $f" "$f syntax valid"
done

# --- Dependencies ---
check 'grep -q "temporalio" requirements.txt 2>/dev/null || grep -q "temporalio" pyproject.toml 2>/dev/null' \
    "temporalio in dependencies"

# --- Compute reward ---
if [ "$TOTAL" -gt 0 ]; then
    REWARD=$(python3 -c "print(round($PASSED / $TOTAL, 2))")
else
    REWARD="0.0"
fi

echo ""
echo "Score: $PASSED / $TOTAL  =>  $REWARD"
echo "$REWARD" > /logs/verifier/reward.txt
