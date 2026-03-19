# determinism.md

## Section Inventory

| Section | Core | Core# | Python | Py# | TypeScript | TS# | Ruby | Rb# | Go | Go# |
|---------|------|-------|--------|-----|------------|-----|------|-----|-----|-----|
| Overview | ✓ | 1 | ✓ | 1 | ✓ | 1 | TODO | 1 | ✓ | 1 |
| Why Determinism Matters | ✓ | 2 | ✓ | 2 | ✓ | 2 | TODO | 2 | ✓ | 2 |
| Sources of Non-Determinism | ✓ | 3 | — | — | — | — | — | — | — | — |
| Central Concept: Activities | ✓ | 4 | — | — | — | — | — | — | — | — |
| SDK Protection / Sandbox | ✓ | 5 | ✓ | 6 | ✓ | 3 | TODO | 3 | — | — |
| Forbidden Operations | — | — | ✓ | 3 | ✓ | 4 | TODO | 4 | ✓ | 3 |
| Safe Builtin Alternatives | — | — | ✓ | 4 | — | — | TODO | 5 | ✓ | 4 |
| Detecting Non-Determinism | ✓ | 6 | — | — | — | — | — | — | — | — |
| Recovery from Non-Determinism | ✓ | 7 | — | — | — | — | — | — | — | — |
| Testing Replay Compatibility | — | — | ✓ | 5 | ✓ | 5 | TODO | 6 | ✓ | 5 |
| Best Practices | ✓ | 8 | ✓ | 7 | ✓ | 6 | TODO | 7 | ✓ | 6 |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Core | ✓ reference | Deep conceptual content |
| Python | ✓ aligned | Practical focus |
| TypeScript | ✓ aligned | Practical focus, V8 sandbox |
| Ruby | — | Not started |
| Go | ✓ aligned | Practical focus, no sandbox, workflowcheck tool, workflow.* replacements |

## Status

**Ruby notes:**
- Ruby's determinism protection uses Illegal Call Tracing (TracePoint) + Durable Fiber Scheduler — distinct from Python sandbox and TS V8 sandbox
- Ruby's TracePoint catches illegal calls like `sleep`, `Time.now`, `Thread.new` at runtime
- Ruby has safe alternatives: `Temporalio::Workflow.sleep`, `Temporalio::Workflow.now`, `Temporalio::Workflow.random`, `Temporalio::Workflow.logger`
- Safe Builtin Alternatives section is appropriate for Ruby (similar to Python's table, but with Ruby-specific mappings)
- Forbidden Operations section should list Ruby-specific illegal calls (e.g., `Kernel.sleep`, `Time.now` without args, `Thread.new`, `IO` operations)

**Go-specific notes:**
- SDK Protection: Go merged this into Overview (cross-references `determinism-protection.md` instead of having separate section). Marked `—` in table.
- Testing Replay: Go cross-references `testing.md` rather than inlining code (matching Python style)
- Forbidden Operations: Go-specific list — native goroutines, native channels, native select, map range iteration, time.Now/Sleep, crypto/rand, os.Stdin/Stdout/Stderr, anonymous functions as local activities (non-deterministic name)
- Safe Builtin Alternatives: Go has a table similar to Python — `workflow.Go()` for goroutines, `workflow.Channel` for channels, `workflow.Selector` for select, `workflow.Now()` for time, `workflow.SideEffect` for random, `workflow.Sleep` for sleep
- Testing Replay: Go uses `worker.ReplayWorkflowHistory` from testsuite
- `workflowcheck` tool: static analysis that detects non-deterministic function calls at compile time (runs as linter)

**Intentionally missing (`—`):**
- Sources of Non-Determinism: Core-only (conceptual categories)
- Central Concept: Activities: Core-only (conceptual)
- Forbidden Operations: Language-specific (Core covers in Sources)
- Safe Builtin Alternatives: Python/Ruby/Go have tables; TS doesn't need (V8 sandbox handles automatically)
- Detecting Non-Determinism: Core-only
- Recovery from Non-Determinism: Core-only
- Testing Replay Compatibility: Language-specific (Core covers in Detecting)

**Order alignment:** N/A — different structures by design

**Style alignment:** ✓ Well aligned (Python, TypeScript, Go)
- Core: Deep conceptual content (replay mechanism, commands/events, recovery)
- Python: Practical focus (forbidden operations, safe alternatives table, sandbox)
- TypeScript: Practical focus (V8 sandbox, forbidden operations)
- Ruby: Practical focus (TracePoint + Fiber Scheduler, forbidden calls, safe alternatives table) — ~7 sections
- Go: Practical focus (forbidden operations, safe alternatives table, workflowcheck)
- Good division: Core explains "why", languages explain "how"
