# determinism.md

## Section Inventory

| Section | Core | Core# | Python | Py# | TypeScript | TS# | Java | J# | Go | Go# |
|---------|------|-------|--------|-----|------------|-----|------|----|----|-----|
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
| Java | — | Not started |
| Go | ✓ aligned | Practical focus, no sandbox, workflowcheck tool, workflow.* replacements |

## Status

**Java column decisions:**
- Overview: Java has no sandbox — determinism protection relies on developer discipline
- Why Determinism Matters: Same as Python/TS — brief reference to core, focus on Java-specific implications
- SDK Protection / Sandbox: Java-specific — there is NO sandbox. SDK provides `Workflow.*` APIs but does NOT enforce them at compile/load time. Non-determinism caught at replay via `NonDeterministicException`. Cooperative threading model eliminates sync needs. See `determinism-protection.md` for details.
- Forbidden Operations: Java-specific list — `Thread.sleep()`, `new Thread()`, `synchronized` blocks, `UUID.randomUUID()`, `Math.random()`, `System.currentTimeMillis()`, direct file/network I/O, mutable global state
- Safe Builtin Alternatives: Java should have this (like Python) — table: `Thread.sleep()` → `Workflow.sleep()`, `UUID.randomUUID()` → `Workflow.randomUUID()`, etc.
- Testing Replay Compatibility: Java uses `WorkflowReplayer` class
- Best Practices: Same general guidance, Java-specific code

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
- SDK Protection / Sandbox: Go merged into Overview (cross-references determinism-protection.md)
- Safe Builtin Alternatives: Python/Java/Go have tables; TS doesn't need (V8 handles automatically)
- Detecting Non-Determinism: Core-only
- Recovery from Non-Determinism: Core-only

**Order alignment:** N/A — different structures by design

**Style alignment:** ✓ Well aligned (Python, TypeScript, Go)
- Core: Deep conceptual content (replay mechanism, commands/events, recovery)
- Python: Practical focus (forbidden operations, safe alternatives table, sandbox)
- TypeScript: Practical focus (V8 sandbox, forbidden operations)
- Java: Practical focus (no sandbox, forbidden operations, safe alternatives table, replay testing) — ~7 sections
- Go: Practical focus (forbidden operations, safe alternatives table, workflowcheck)
- Good division: Core explains "why", languages explain "how"
