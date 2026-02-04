#!/bin/bash
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================="
echo "Validating Generated Python Application"
echo "========================================="
echo ""

# Check required files
echo "Checking file structure..."
REQUIRED_FILES=("workflows.py" "activities.py" "worker.py" "client.py")
MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    else
        echo -e "${GREEN}✓${NC} $file exists"
    fi
done

# Check for dependency file
if [ ! -f "requirements.txt" ] && [ ! -f "pyproject.toml" ]; then
    echo -e "${RED}✗${NC} Missing dependency file (requirements.txt or pyproject.toml)"
    MISSING_FILES+=("requirements.txt or pyproject.toml")
else
    [ -f "requirements.txt" ] && echo -e "${GREEN}✓${NC} requirements.txt exists"
    [ -f "pyproject.toml" ] && echo -e "${GREEN}✓${NC} pyproject.toml exists"
fi

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}❌ Missing required files:${NC}"
    for file in "${MISSING_FILES[@]}"; do
        echo "   - $file"
    done
    exit 1
fi

echo ""
echo "Checking code patterns..."

# Check for workflow decorator
if ! grep -q "@workflow.defn" workflows.py; then
    echo -e "${RED}✗${NC} Missing @workflow.defn decorator in workflows.py"
    exit 1
fi
echo -e "${GREEN}✓${NC} Contains @workflow.defn decorator"

# Check for activity decorator
if ! grep -q "@activity.defn" activities.py; then
    echo -e "${RED}✗${NC} Missing @activity.defn decorator in activities.py"
    exit 1
fi
echo -e "${GREEN}✓${NC} Contains @activity.defn decorator"

# Check for @workflow.run
if ! grep -q "@workflow.run" workflows.py; then
    echo -e "${RED}✗${NC} Missing @workflow.run decorator in workflows.py"
    exit 1
fi
echo -e "${GREEN}✓${NC} Contains @workflow.run decorator"

# Check for async/await
if ! grep -q "async def" workflows.py || ! grep -q "await" workflows.py; then
    echo -e "${RED}✗${NC} Missing async/await syntax in workflows.py"
    exit 1
fi
echo -e "${GREEN}✓${NC} Uses async/await syntax"

# Check for temporalio imports
if ! grep -q "from temporalio" *.py 2>/dev/null && ! grep -q "import temporalio" *.py 2>/dev/null; then
    echo -e "${RED}✗${NC} Missing temporalio imports"
    exit 1
fi
echo -e "${GREEN}✓${NC} Has temporalio imports"

# Check for signal/query decorators (optional but expected)
grep -q "@workflow.signal" workflows.py && echo -e "${GREEN}✓${NC} Contains @workflow.signal decorator"
grep -q "@workflow.query" workflows.py && echo -e "${GREEN}✓${NC} Contains @workflow.query decorator"

echo ""
echo "Checking Python syntax..."

SYNTAX_ERRORS=0
for file in *.py; do
    if [ -f "$file" ]; then
        if python3 -m py_compile "$file" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} $file syntax is valid"
        else
            echo -e "${RED}✗${NC} $file has syntax errors"
            python3 -m py_compile "$file"
            SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
        fi
    fi
done

if [ $SYNTAX_ERRORS -gt 0 ]; then
    echo ""
    echo -e "${RED}❌ Found syntax errors in $SYNTAX_ERRORS file(s)${NC}"
    exit 1
fi

echo ""
echo "Checking dependencies..."

if [ -f "requirements.txt" ]; then
    if ! grep -q "temporalio" requirements.txt; then
        echo -e "${RED}✗${NC} temporalio not found in requirements.txt"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} temporalio dependency specified"
fi

if [ -f "pyproject.toml" ]; then
    if ! grep -q "temporalio" pyproject.toml; then
        echo -e "${RED}✗${NC} temporalio not found in pyproject.toml"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} temporalio dependency specified"
fi

echo ""
echo "========================================="
echo -e "${GREEN}✅ ALL VALIDATIONS PASSED${NC}"
echo "========================================="
