# determinism-protection.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Java | J# | Go | Go# |
|---------|------|--------|-----|------------|-----|------|----|----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | TODO | 1 | ✓ | 1 |
| How the Sandbox Works | — | ✓ | 2 | — | — | — | — | — | — |
| Import Blocking | — | — | — | ✓ | 2 | — | — | — | — |
| Forbidden Operations | — | ✓ | 3 | — | — | TODO | 2 | — | — |
| Function Replacement | — | — | — | ✓ | 3 | — | — | — | — |
| Static Analysis (workflowcheck) | — | — | — | — | — | TODO | 3 | ✓ | 2 |
| Convention-Based Enforcement / Determinism Rules | — | — | — | — | — | TODO | 4 | ✓ | 3 |
| Pass-Through Pattern | — | ✓ | 4 | — | — | — | — | — | — |
| Importing Activities | — | ✓ | 5 | — | — | — | — | — | — |
| Disabling the Sandbox | — | ✓ | 6 | — | — | — | — | — | — |
| Customizing Invalid Module Members | — | ✓ | 7 | — | — | — | — | — | — |
| Import Notification Policy | — | ✓ | 8 | — | — | — | — | — | — |
| Disable Lazy sys.modules Passthrough | — | ✓ | 9 | — | — | — | — | — | — |
| File Organization | — | ✓ | 10 | — | — | — | — | — | — |
| Common Issues | — | ✓ | 11 | — | — | — | — | — | — |
| Best Practices | — | ✓ | 12 | — | — | TODO | 5 | ✓ | 4 |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | Comprehensive (12 sections) |
| TypeScript | ✓ aligned | Minimal (3 sections) — V8 is automatic |
| Java | — | Not started |
| Go | ✓ aligned | Minimal (4 sections) — no runtime sandbox, convention + static analysis |

## Status

**Java column decisions:**
- Overview: Java has NO sandbox. A static analysis tool (`temporal-workflowcheck`, beta) is available. Non-determinism is only caught at replay time via `NonDeterministicException`. The SDK's cooperative threading model eliminates synchronization needs but does NOT prevent calling non-deterministic APIs.
- How the Sandbox Works: — (Java has no sandbox)
- Import Blocking: — (Java has no import restrictions)
- Forbidden Operations: Java-specific list — `Thread.sleep()`, `new Thread()`, synchronization primitives, `UUID.randomUUID()`, `Math.random()`, `System.currentTimeMillis()`, direct I/O in workflows. NOT blocked by SDK — developer must avoid manually.
- Function Replacement: — (Java does not replace any functions)
- Static Analysis (workflowcheck): Java has `temporal-workflowcheck` (beta) — similar concept to Go's tool but separate
- Convention-Based Enforcement / Determinism Rules: Java-specific — explains cooperative threading model, `NonDeterministicException` at replay, `temporal-workflowcheck` for static analysis, and `WorkflowReplayer` for replay testing
- Best Practices: Java best practices for determinism (use Workflow.* APIs, avoid stdlib alternatives, test with replay)

**Go-specific notes:**
- Go has NO runtime sandbox (unlike Python's import-restricting sandbox or TS's V8 isolate)
- Determinism enforcement is purely by developer convention + optional static analysis
- `workflowcheck` tool: `go.temporal.io/sdk/contrib/tools/workflowcheck` — detects non-deterministic function calls, channel ops, goroutines, map range
- The tool flags: `time.Now`, `time.Sleep`, `math/rand.globalRand`, `crypto/rand.Reader`, `os.Stdin/Stdout/Stderr`, native goroutines, channel send/receive/range, map range iteration
- Determinism Rules section: covers what developers must avoid (unique to Go since no sandbox catches these)
- Overview: brief explanation that Go relies on convention rather than sandboxing
- Best Practices: use workflowcheck in CI, follow workflow.* API conventions

**Intentionally missing (`—`):**
- Core column: no core file (sandbox implementation is language-specific)
- Most Python sections (sandbox internals, import blocking, pass-through, customization): Not applicable to Go (no sandbox)
- TS sections (Import Blocking, Function Replacement): Not applicable to Go (no V8 isolate)
- Go doesn't need sandbox customization sections because there's no sandbox to customize

**Order alignment:** N/A — files have completely different structures per language

**Style alignment:** ⚠️ Very different structures (intentional, different protection mechanisms)
- Python: Comprehensive (12 sections) — complex sandbox with many customization options
- TypeScript: Minimal (3 sections) — V8 sandbox is mostly automatic
- Java: ~5 sections — no sandbox, `temporal-workflowcheck` (beta), cooperative threading, replay detection
- Go: Minimal (4 sections) — no sandbox, convention-based with static analysis tool
