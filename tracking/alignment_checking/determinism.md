# determinism.md

## Section Inventory

| Section | Core | Core# | Python | Py# | TypeScript | TS# | Go | Go# |
|---------|------|-------|--------|-----|------------|-----|-----|-----|
| Overview | ✓ | 1 | ✓ | 1 | ✓ | 1 | TODO | 1 |
| Why Determinism Matters | ✓ | 2 | ✓ | 2 | ✓ | 2 | TODO | 2 |
| Sources of Non-Determinism | ✓ | 3 | — | — | — | — | — | — |
| Central Concept: Activities | ✓ | 4 | — | — | — | — | — | — |
| SDK Protection / Sandbox | ✓ | 5 | ✓ | 6 | ✓ | 3 | TODO | 3 |
| Forbidden Operations | — | — | ✓ | 3 | ✓ | 4 | TODO | 4 |
| Safe Builtin Alternatives | — | — | ✓ | 4 | — | — | TODO | 5 |
| Detecting Non-Determinism | ✓ | 6 | — | — | — | — | — | — |
| Recovery from Non-Determinism | ✓ | 7 | — | — | — | — | — | — |
| Testing Replay Compatibility | — | — | ✓ | 5 | ✓ | 5 | TODO | 6 |
| Best Practices | ✓ | 8 | ✓ | 7 | ✓ | 6 | TODO | 7 |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Core | ✓ reference | Deep conceptual content |
| Python | ✓ aligned | Practical focus |
| TypeScript | ✓ aligned | Practical focus, V8 sandbox |
| Go | TODO | Practical focus, no sandbox, workflowcheck tool, workflow.* replacements |

## Status

**Sections needing review (TODO cells):**
- Go column: all TODO — Go files to be created

**Go-specific notes:**
- SDK Protection: Go has NO runtime sandbox (unlike Python/TS). Uses `workflowcheck` static analysis tool + convention
- Forbidden Operations: Go-specific list — native goroutines, native channels, native select, map range iteration, time.Now/Sleep, crypto/rand, os.Stdin/Stdout/Stderr
- Safe Builtin Alternatives: Go has a table similar to Python — `workflow.Go()` for goroutines, `workflow.Channel` for channels, `workflow.Selector` for select, `workflow.Now()` for time, `workflow.SideEffect` for random, `workflow.Sleep` for sleep
- Testing Replay: Go uses `worker.ReplayWorkflowHistory` from testsuite
- `workflowcheck` tool: static analysis that detects non-deterministic function calls at compile time (runs as linter)

**Intentionally missing (`—`):**
- Sources of Non-Determinism: Core-only (conceptual categories)
- Central Concept: Activities: Core-only (conceptual)
- Forbidden Operations: Language-specific (Core covers in Sources)
- Safe Builtin Alternatives: Python has table, Go will have table, TS doesn't need (V8 sandbox handles automatically)
- Detecting Non-Determinism: Core-only
- Recovery from Non-Determinism: Core-only
- Testing Replay Compatibility: Language-specific (Core covers in Detecting)

**Order alignment:** N/A — different structures by design

**Style alignment:** ✓ Well aligned (Python, TypeScript)
- Core: Deep conceptual content (replay mechanism, commands/events, recovery)
- Python: Practical focus (forbidden operations, safe alternatives table, sandbox)
- TypeScript: Practical focus (V8 sandbox, forbidden operations)
- Go will follow Python pattern: forbidden operations + safe alternatives table + workflowcheck
- Good division: Core explains "why", languages explain "how"
