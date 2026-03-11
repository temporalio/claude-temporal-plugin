#!/bin/bash
# Validates the generated Python Temporal application.
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

# --- Add your checks here ---
# check '[ -f main.py ]' "main.py exists"
# check 'grep -q "@workflow.defn" workflows.py' "@workflow.defn decorator"

# --- Compute reward ---
if [ "$TOTAL" -gt 0 ]; then
    REWARD=$(python3 -c "print(round($PASSED / $TOTAL, 2))")
else
    REWARD="0.0"
fi

echo ""
echo "Score: $PASSED / $TOTAL  =>  $REWARD"
echo "$REWARD" > /logs/verifier/reward.txt
