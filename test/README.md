# Temporal Skill Integration Tests

These tests validate that the Temporal skill (`plugins/temporal-developer/skills/temporal-developer`) works correctly when used with Claude Code to generate applications.

## Test Structure

```
test/
├── python/
│   ├── run-integration-test.sh   # Full integration test
│   └── test-prompt.txt           # Prompt for code generation
└── typescript/
    ├── run-integration-test.sh   # Full integration test
    └── test-prompt.txt           # Prompt for code generation
```

## What These Tests Do

1. **Set up a test workspace** with the skill installed in `.claude/skills/`
2. **Invoke Claude CLI** with a test prompt that triggers skill usage
3. **Validate generated code**:
   - Correct file structure
   - Required patterns present (decorators, async/await)
   - Valid syntax
   - Proper dependencies
4. **Optionally run the application** with a real Temporal server

## Prerequisites

### Required
- **Claude CLI**: `curl -fsSL https://claude.ai/install.sh | bash`
- **Anthropic API Key**: Set `ANTHROPIC_API_KEY` environment variable
- **Python 3.10+** (for Python tests)
- **Node.js 18+** (for TypeScript tests)

### Optional (for execution tests)
- **Temporal CLI**: `brew install temporal` (macOS) or see [docs.temporal.io/cli](https://docs.temporal.io/cli)

## Running Tests

### Python

```bash
# Full test (with execution)
export ANTHROPIC_API_KEY='your-key'
cd test/python
./run-integration-test.sh

# Validation only (skip execution)
SKIP_EXECUTION=true ./run-integration-test.sh
```

### TypeScript

```bash
# Full test (with execution)
export ANTHROPIC_API_KEY='your-key'
cd test/typescript
./run-integration-test.sh

# Validation only (skip execution)
SKIP_EXECUTION=true ./run-integration-test.sh
```

## Manual Testing

If you don't have the Claude CLI:

1. Set up the test workspace:
   ```bash
   cd test/python  # or test/typescript
   ./run-integration-test.sh  # Will fail at CLI check but set up workspace
   ```

2. Navigate to the workspace:
   ```bash
   cd test-workspace
   ```

3. Use Claude (any interface) to generate code from `test-prompt.txt`

4. Validate the generated code:
   ```bash
   ./validate.sh
   ```

## Test Results

### Success
```
╔════════════════════════════════════════════════╗
║       FULL INTEGRATION TEST PASSED!            ║
╚════════════════════════════════════════════════╝
```

### Partial Success (validation passed, execution failed)
```
╔════════════════════════════════════════════════╗
║       PARTIAL SUCCESS                          ║
║       Structure & Validation: PASSED           ║
║       Execution Test: FAILED                   ║
╚════════════════════════════════════════════════╝
```

This indicates the generated code is structurally correct but had runtime issues.

## Troubleshooting

### "Claude CLI not found"
```bash
npm install -g @anthropic-ai/claude-code
```

### "ANTHROPIC_API_KEY not set"
```bash
export ANTHROPIC_API_KEY='your-key-here'
```

### "Temporal CLI not found"
Either install Temporal CLI or skip execution tests:
```bash
SKIP_EXECUTION=true ./run-integration-test.sh
```

### Python syntax errors
Check that generated code uses proper async/await and decorators.

### TypeScript compilation errors
The test will note these but continue - some errors may be due to missing type definitions that would resolve with full dependency installation.
