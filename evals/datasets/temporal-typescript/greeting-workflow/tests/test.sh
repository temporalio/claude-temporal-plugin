#!/bin/bash
# Validates a generated TypeScript Temporal greeting workflow.
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

# Helper: find a file in . or src/
find_ts() {
    if [ -f "$1" ]; then echo "$1"; elif [ -f "src/$1" ]; then echo "src/$1"; else echo ""; fi
}

WORKFLOW_FILE=$(find_ts workflows.ts)
ACTIVITY_FILE=$(find_ts activities.ts)
WORKER_FILE=$(find_ts worker.ts)
CLIENT_FILE=$(find_ts client.ts)

# --- File existence ---
check '[ -n "$(find_ts workflows.ts)" ]'   "workflows.ts exists"
check '[ -n "$(find_ts activities.ts)" ]'   "activities.ts exists"
check '[ -n "$(find_ts worker.ts)" ]'       "worker.ts exists"
check '[ -n "$(find_ts client.ts)" ]'       "client.ts exists"
check '[ -f package.json ]'                  "package.json exists"
check '[ -f tsconfig.json ]'                 "tsconfig.json exists"

# --- Code patterns ---
if [ -n "$WORKFLOW_FILE" ]; then
    check 'grep -q "proxyActivities" "$WORKFLOW_FILE"'  "proxyActivities pattern"
    check 'grep -q "async"           "$WORKFLOW_FILE"'  "async in workflows"
    check 'grep -q "await"           "$WORKFLOW_FILE"'  "await in workflows"
    check 'grep -q "defineSignal"    "$WORKFLOW_FILE"'  "defineSignal in workflows"
    check 'grep -q "defineQuery"     "$WORKFLOW_FILE"'  "defineQuery in workflows"
fi

# --- @temporalio imports ---
check 'find . -name "*.ts" -not -path "./node_modules/*" -exec grep -l "@temporalio" {} + | head -1' \
    "@temporalio imports present"

# --- Dependencies ---
check 'grep -q "@temporalio" package.json' "@temporalio in package.json"

# --- TypeScript compilation (best-effort) ---
if command -v npx &> /dev/null && [ -f package.json ]; then
    [ ! -d node_modules ] && npm install --ignore-scripts > /dev/null 2>&1 || true
    check 'npx tsc --noEmit' "TypeScript compilation"
fi

# --- Compute reward ---
if [ "$TOTAL" -gt 0 ]; then
    REWARD=$(node -e "console.log(($PASSED / $TOTAL).toFixed(2))")
else
    REWARD="0.0"
fi

echo ""
echo "Score: $PASSED / $TOTAL  =>  $REWARD"
echo "$REWARD" > /logs/verifier/reward.txt
