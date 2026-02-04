#!/bin/bash
# Common functions and variables for integration tests

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Print functions
print_header() {
    local title="$1"
    local padded=$(printf "%-44s" "$title")
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  ${padded}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}[$(date +%H:%M:%S)] $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_result_box() {
    local color="$1"
    local line1="$2"
    local line2="${3:-}"
    local line3="${4:-}"

    echo -e "\n${color}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${color}║       ${line1}${NC}"
    if [ -n "$line2" ]; then
        echo -e "${color}║       ${line2}${NC}"
    fi
    if [ -n "$line3" ]; then
        echo -e "${color}║       ${line3}${NC}"
    fi
    echo -e "${color}╚════════════════════════════════════════════════╝${NC}\n"
}

# Setup paths - call this from the language-specific script
setup_paths() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    TEST_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    REPO_ROOT="$(cd "$TEST_ROOT/.." && pwd)"
    SKILL_DIR="${REPO_ROOT}/plugins/temporal-dev/skills/temporal-dev"
    WORKSPACE_DIR="${SCRIPT_DIR}/test-workspace"
}

# Setup workspace with skill installed
setup_workspace() {
    print_step "Setting up test workspace..."

    rm -rf "${WORKSPACE_DIR}"
    mkdir -p "${WORKSPACE_DIR}/.claude/skills/temporal-dev"

    cp -r "${SKILL_DIR}"/* "${WORKSPACE_DIR}/.claude/skills/temporal-dev/"
    print_success "Installed skill files"

    cp "${SCRIPT_DIR}/test-prompt.txt" "${WORKSPACE_DIR}/"
    print_success "Copied test prompt"

    cp "${SCRIPT_DIR}/validate.sh" "${WORKSPACE_DIR}/"
    chmod +x "${WORKSPACE_DIR}/validate.sh"
    print_success "Copied validation script"

    print_success "Workspace setup complete"
    echo ""
}

# Check for Claude CLI
check_claude_cli() {
    print_step "Checking for Claude CLI..."

    if ! command -v claude &> /dev/null; then
        print_error "Claude CLI not found"
        echo ""
        echo "Install with: curl -fsSL https://claude.ai/install.sh | bash"
        exit 1
    fi

    print_success "Claude CLI found"
    echo ""
}

# Check for API key
check_api_key() {
    print_step "Checking for API key..."

    if [ -z "$ANTHROPIC_API_KEY" ]; then
        print_error "ANTHROPIC_API_KEY environment variable not set"
        echo ""
        echo "Set it with: export ANTHROPIC_API_KEY='your-key-here'"
        exit 1
    fi

    print_success "API key found"
    echo ""
}

# Generate code using Claude CLI
generate_code() {
    print_step "Generating code using Claude CLI..."
    echo ""

    cd "${WORKSPACE_DIR}"
    PROMPT=$(cat test-prompt.txt)

    # Use -p for non-interactive mode, --dangerously-skip-permissions to allow file writes
    if claude -p --dangerously-skip-permissions "$PROMPT" 2>&1; then
        print_success "Code generation complete"
    else
        print_error "Code generation failed"
        exit 1
    fi
    echo ""
}

# Run validation
run_validation() {
    print_step "Validating generated code..."
    echo ""

    cd "${WORKSPACE_DIR}"
    ./validate.sh

    if [ $? -ne 0 ]; then
        print_error "Validation failed"
        echo ""
        echo "Generated files location: ${WORKSPACE_DIR}"
        exit 1
    fi

    echo ""
    print_success "Validation passed"
    echo ""
}

# Check if Temporal server is running (check if gRPC port 7233 is listening)
check_temporal() {
    nc -z localhost 7233 2>/dev/null
    return $?
}

# Start Temporal server
start_temporal() {
    echo -e "${YELLOW}Starting Temporal development server...${NC}"

    if ! command -v temporal &> /dev/null; then
        echo -e "${RED}✗ Temporal CLI not found${NC}"
        echo -e "Install it with:"
        echo -e "  ${YELLOW}brew install temporal${NC}  (macOS)"
        echo -e "  Or follow: https://docs.temporal.io/cli"
        return 1
    fi

    temporal server start-dev > temporal-server.log 2>&1 &
    TEMPORAL_PID=$!
    echo $TEMPORAL_PID > .temporal-server.pid

    echo -e "  Started Temporal server (PID: $TEMPORAL_PID)"
    echo -e "  Waiting for server to be ready..."

    for i in {1..30}; do
        if check_temporal; then
            echo -e "${GREEN}✓ Temporal server is ready${NC}"
            return 0
        fi
        sleep 1
        echo -n "."
    done

    echo -e "\n${RED}✗ Temporal server failed to start${NC}"
    # Kill the failed server
    kill $TEMPORAL_PID 2>/dev/null || true
    rm -f .temporal-server.pid
    return 1
}

# Ensure Temporal is running, returns whether we started it
ensure_temporal() {
    if check_temporal; then
        echo -e "${GREEN}✓ Temporal server is already running${NC}"
        TEMPORAL_STARTED_BY_US=false
        return 0
    else
        if start_temporal; then
            TEMPORAL_STARTED_BY_US=true
            return 0
        else
            return 1
        fi
    fi
}

# Cleanup Temporal if we started it
cleanup_temporal() {
    if [ "$TEMPORAL_STARTED_BY_US" = "true" ] && [ -f ".temporal-server.pid" ]; then
        kill $(cat .temporal-server.pid) 2>/dev/null || true
        rm -f .temporal-server.pid
    fi
    rm -f temporal-server.log
}

# Start execution test phase
start_execution_test() {
    print_step "Testing execution (optional)..."
    echo ""

    if [ "$SKIP_EXECUTION" = "true" ]; then
        echo -e "${YELLOW}Skipping execution test (SKIP_EXECUTION=true)${NC}"
        print_result_box "$GREEN" "INTEGRATION TEST PASSED!                 " "(Structure & Validation)                 "
        exit 0
    fi

    echo -e "${YELLOW}Running execution test (set SKIP_EXECUTION=true to skip)${NC}\n"

    cd "${WORKSPACE_DIR}"

    if ! ensure_temporal; then
        cleanup_temporal  # Clean up any partially started server
        echo -e "${YELLOW}Skipping execution test - Temporal not available${NC}"
        print_result_box "$GREEN" "INTEGRATION TEST PASSED!                 " "(Structure & Validation Only)            "
        exit 0
    fi
}

# Report final execution result
report_execution_result() {
    local success="$1"

    cleanup_temporal
    rm -f worker.log

    if [ "$success" = "true" ]; then
        print_result_box "$GREEN" "FULL INTEGRATION TEST PASSED!            "
    else
        print_result_box "$YELLOW" "PARTIAL SUCCESS                          " "Structure & Validation: PASSED           " "Execution Test: FAILED                   "
    fi
}
