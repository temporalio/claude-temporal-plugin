#!/bin/bash
set -e

# Load common functions
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

setup_paths
print_header "Temporal TypeScript Skill Integration Test"

# Common setup and validation
setup_workspace
check_claude_cli
check_api_key
generate_code
run_validation

# TypeScript-specific execution test
start_execution_test

# Install dependencies and build
echo -e "${YELLOW}Installing dependencies and building...${NC}"
npm install > /dev/null 2>&1 || true
npm run build > /dev/null 2>&1 || npx tsc > /dev/null 2>&1 || true

# Start worker
echo -e "${YELLOW}Starting worker...${NC}"
if [ -f "dist/worker.js" ]; then
    node dist/worker.js > worker.log 2>&1 &
elif [ -f "lib/worker.js" ]; then
    node lib/worker.js > worker.log 2>&1 &
else
    npx ts-node worker.ts > worker.log 2>&1 &
fi
WORKER_PID=$!
sleep 5

if ! kill -0 $WORKER_PID 2>/dev/null; then
    echo -e "${RED}✗ Worker failed to start${NC}"
    tail -20 worker.log
    cleanup_temporal
    exit 1
fi
echo -e "${GREEN}✓ Worker is running${NC}"

# Run client
echo -e "${YELLOW}Running client...${NC}"
if [ -f "dist/client.js" ]; then
    CLIENT_CMD="node dist/client.js"
elif [ -f "lib/client.js" ]; then
    CLIENT_CMD="node lib/client.js"
else
    CLIENT_CMD="npx ts-node client.ts"
fi

if $CLIENT_CMD TestUser 2>&1; then
    echo -e "${GREEN}✓ Workflow executed successfully${NC}"
    EXECUTION_SUCCESS=true
else
    echo -e "${RED}✗ Workflow execution failed${NC}"
    EXECUTION_SUCCESS=false
fi

# Cleanup
kill $WORKER_PID 2>/dev/null || true
report_execution_result "$EXECUTION_SUCCESS"
