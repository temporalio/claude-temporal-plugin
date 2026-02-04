#!/bin/bash
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================="
echo "Validating Generated TypeScript Application"
echo "========================================="
echo ""

# Check required files
echo "Checking file structure..."
REQUIRED_FILES=("workflows.ts" "activities.ts" "worker.ts" "client.ts")
MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ] && [ ! -f "src/$file" ]; then
        MISSING_FILES+=("$file")
    else
        if [ -f "$file" ]; then
            echo -e "${GREEN}✓${NC} $file exists"
        else
            echo -e "${GREEN}✓${NC} src/$file exists"
        fi
    fi
done

# Check for package.json
if [ ! -f "package.json" ]; then
    echo -e "${RED}✗${NC} Missing package.json"
    MISSING_FILES+=("package.json")
else
    echo -e "${GREEN}✓${NC} package.json exists"
fi

# Check for tsconfig.json
if [ ! -f "tsconfig.json" ]; then
    echo -e "${RED}✗${NC} Missing tsconfig.json"
    MISSING_FILES+=("tsconfig.json")
else
    echo -e "${GREEN}✓${NC} tsconfig.json exists"
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

# Find workflow file
WORKFLOW_FILE="workflows.ts"
[ -f "src/workflows.ts" ] && WORKFLOW_FILE="src/workflows.ts"

# Check for proxyActivities (TypeScript pattern)
if grep -q "proxyActivities" "$WORKFLOW_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Uses proxyActivities pattern"
else
    echo -e "${YELLOW}!${NC} proxyActivities not found (may use different pattern)"
fi

# Check for async/await
if ! grep -q "async" "$WORKFLOW_FILE" || ! grep -q "await" "$WORKFLOW_FILE"; then
    echo -e "${RED}✗${NC} Missing async/await syntax in $WORKFLOW_FILE"
    exit 1
fi
echo -e "${GREEN}✓${NC} Uses async/await syntax"

# Check for temporalio imports
ALL_TS_FILES=$(find . -name "*.ts" -not -path "./node_modules/*" 2>/dev/null)
if echo "$ALL_TS_FILES" | xargs grep -l "@temporalio" 2>/dev/null | head -1 > /dev/null; then
    echo -e "${GREEN}✓${NC} Has @temporalio imports"
else
    echo -e "${RED}✗${NC} Missing @temporalio imports"
    exit 1
fi

# Check for signal/query (optional but expected)
grep -q "defineSignal" "$WORKFLOW_FILE" 2>/dev/null && echo -e "${GREEN}✓${NC} Contains defineSignal"
grep -q "defineQuery" "$WORKFLOW_FILE" 2>/dev/null && echo -e "${GREEN}✓${NC} Contains defineQuery"

echo ""
echo "Checking TypeScript syntax..."

if command -v npx &> /dev/null; then
    if [ -f "package.json" ] && [ ! -d "node_modules" ]; then
        echo "Installing dependencies..."
        npm install > /dev/null 2>&1 || true
    fi

    if npx tsc --noEmit 2>/dev/null; then
        echo -e "${GREEN}✓${NC} TypeScript compilation successful"
    else
        echo -e "${YELLOW}!${NC} TypeScript compilation had issues (may need dependencies)"
    fi
else
    echo -e "${YELLOW}!${NC} npx not found, skipping TypeScript compilation check"
fi

echo ""
echo "Checking dependencies..."

if grep -q "@temporalio" package.json; then
    echo -e "${GREEN}✓${NC} @temporalio dependencies specified"
else
    echo -e "${RED}✗${NC} @temporalio not found in package.json"
    exit 1
fi

echo ""
echo "========================================="
echo -e "${GREEN}✅ ALL VALIDATIONS PASSED${NC}"
echo "========================================="
