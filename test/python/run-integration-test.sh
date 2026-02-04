#!/bin/bash
set -e

# Load common functions
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

setup_paths
print_header "Temporal Python Skill Integration Test"

# Common setup and validation
setup_workspace
check_claude_cli
check_api_key
generate_code
run_validation

# Python-specific execution test
start_execution_test

# Install dependencies
if [ -f "requirements.txt" ]; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    pip install -r requirements.txt > /dev/null 2>&1 || true
fi

# Start worker
echo -e "${YELLOW}Starting worker...${NC}"
python3 worker.py > worker.log 2>&1 &
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
if python3 client.py --name TestUser 2>&1 || python3 client.py TestUser 2>&1; then
    echo -e "${GREEN}✓ Workflow executed successfully${NC}"
    EXECUTION_SUCCESS=true
else
    echo -e "${RED}✗ Workflow execution failed${NC}"
    EXECUTION_SUCCESS=false
fi

# Cleanup
kill $WORKER_PID 2>/dev/null || true
report_execution_result "$EXECUTION_SUCCESS"
