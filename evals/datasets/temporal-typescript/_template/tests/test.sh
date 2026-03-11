#!/bin/bash
# Validates the generated TypeScript Temporal application.
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
# check '[ -f workflows.ts ]' "workflows.ts exists"
# check 'grep -q "proxyActivities" workflows.ts' "proxyActivities pattern"

# --- Compute reward ---
if [ "$TOTAL" -gt 0 ]; then
    REWARD=$(node -e "console.log(($PASSED / $TOTAL).toFixed(2))")
else
    REWARD="0.0"
fi

echo ""
echo "Score: $PASSED / $TOTAL  =>  $REWARD"
echo "$REWARD" > /logs/verifier/reward.txt
