# gotchas.md

## Section Inventory

| Section | Core | Core# | Python | Py# | TypeScript | TS# | Java | J# | Go | Go# |
|---------|------|-------|--------|-----|------------|-----|------|----|----|-----|
| Idempotency / Non-Idempotent Activities | ✓ | 1 | — | — | — | — | — | — | — | — |
| Replay Safety / Side Effects & Non-Determinism | ✓ | 2 | — | — | — | — | — | — | — | — |
| Multiple Workers with Different Code | ✓ | 3 | — | — | — | — | — | — | — | — |
| Retry Policies / Failing Activities Too Quickly | ✓ | 4 | — | — | — | — | — | — | — | — |
| Query Handlers / Query Handler Mistakes | ✓ | 5 | — | — | — | — | — | — | — | — |
| File Organization | ✓ | 6 | ✓ | 1 | — | — | — | — | — | — |
| Activity Imports | — | — | — | — | ✓ | 1 | — | — | — | — |
| Bundling Issues | — | — | — | — | ✓ | 2 | — | — | — | — |
| Async vs Sync Activities | — | — | ✓ | 2 | — | — | — | — | — | — |
| Non-Deterministic Operations | — | — | — | — | — | — | ✓ | 1 | ✓ | 2 |
| Goroutines and Concurrency | — | — | — | — | — | — | — | — | ✓ | 1 |
| Error Handling | ✓ | 8 | — | — | — | — | — | — | — | — |
| Wrong Retry Classification | ✓ | 8 | ✓ | 3 | ✓ | 3 | ✓ | 2 | ✓ | 3 |
| Heartbeating | — | — | ✓ | 5 | ✓ | 5 | ✓ | 3 | ✓ | 4 |
| Cancellation | ✓ | 10 | ✓ | 4 | ✓ | 4 | ✓ | 4 | ✓ | 5 |
| Testing | ✓ | 7 | ✓ | 6 | ✓ | 6 | ✓ | 5 | ✓ | 6 |
| Timers and Sleep | — | — | ✓ | 7 | ✓ | 7 | ✓ | 6 | ✓ | 7 |
| Payload Size Limits | ✓ | 9 | — | — | — | — | — | — | — | — |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Core | ✓ reference | Conceptual gotchas |
| Python | ✓ aligned | Language-specific gotchas |
| TypeScript | ✓ aligned | Language-specific gotchas |
| Java | ✓ aligned | 6 sections; Non-Deterministic Operations is Java-specific (no sandbox to catch these) |
| Go | ✓ aligned | Language-specific gotchas — goroutines, channels, selectors, map range |

## Status

**Java column decisions:**
- Non-Deterministic Operations: Java-specific gotcha — using `Thread.sleep()` instead of `Workflow.sleep()`, `UUID.randomUUID()` instead of `Workflow.randomUUID()`, `Math.random()` instead of `Workflow.newRandom()`, using Java `Thread`/locks/synchronization. Java has NO sandbox so these are not caught automatically.
- File Organization: — (less critical in Java; no sandbox reload, no bundling concerns)
- Activity Imports: — (TS-specific bundling concern)
- Bundling Issues: — (TS-specific)
- Async vs Sync Activities: — (Python-specific; Java activities are always blocking/synchronous by default)
- Wrong Retry Classification: same concept as Python/TS
- Cancellation: Java has `CancellationScope` and `CanceledFailure`
- Heartbeating: same concept as Python/TS
- Testing: same concept (test failures, replay compatibility)
- Timers and Sleep: `Thread.sleep()` vs `Workflow.sleep()`, `Workflow.await()` with timeout

**Go-specific notes:**
- Goroutines and Concurrency: MUST use `workflow.Go()` not native `go`, `workflow.Channel` not native channels, `workflow.Selector` not native `select`
- Non-Deterministic Operations: map range iteration, `time.Now()`/`time.Sleep()`, `math/rand`, accessing `os.Stdin`/`os.Stdout`/`os.Stderr`, anonymous functions as local activities (non-deterministic name — use named functions instead)
- Wrong Retry Classification: cross-references `error-handling.md` (no inline code, matching Python style)
- Heartbeating: moved before Cancellation (Go# 4) to match conceptual flow — heartbeating is prerequisite for activity cancellation
- Cancellation: Go uses `ctx.Done()` channel + `workflow.NewDisconnectedContext` for cleanup
- Testing: common mistakes with Go test framework (forgetting to register activities, using `time.Sleep` in tests)
- Timers: using `time.Sleep` instead of `workflow.Sleep`; using `time.After` instead of `workflow.NewTimer`

**Decided to keep as-is:**
- Multiple Workers with Different Code: Core-only (conceptual explanation sufficient)
- Heartbeating: Py/TS/Java/Go-only (language-specific code examples, no Core conceptual section needed)

**Intentionally missing (`—`):**
- Idempotency, Replay Safety, Query Handlers, Error Handling, Retry Policies, Payload Size Limits: Core-only (conceptual)
- Multiple Workers with Different Code: Core-only (conceptual)
- File Organization: Core + Python; TS covers similar in Activity Imports; Java/Go don't need (no sandbox/bundling)
- Activity Imports: TS-specific (bundling/sandbox concerns)
- Bundling Issues: TS-specific (workflow bundling)
- Async vs Sync Activities: Python-specific
- Goroutines and Concurrency: Go-specific (native goroutines are non-deterministic in Go)

**Order alignment:** N/A — Core has conceptual sections, language files have implementation-specific sections

**Style alignment:** ✅ Complete (Python, TypeScript, Java, Go)
- Core: 10 conceptual sections with symptoms/fixes
- TypeScript: 7 sections (Activity Imports, Bundling, Cancellation, Heartbeating, Testing, Timers, Wrong Retry Classification)
- Python: 7 sections (File Organization, Async vs Sync, Wrong Retry Classification, Cancellation, Heartbeating, Testing, Timers and Sleep)
- Java: 6 sections (Non-Deterministic Operations, Wrong Retry Classification, Heartbeating, Cancellation, Testing, Timers and Sleep)
- Go: 7 sections (Goroutines and Concurrency, Non-Deterministic Operations, Wrong Retry Classification, Heartbeating, Cancellation, Testing, Timers and Sleep)
