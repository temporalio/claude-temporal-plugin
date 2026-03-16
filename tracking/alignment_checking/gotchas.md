# gotchas.md

## Section Inventory

| Section | Core | Core# | Python | Py# | TypeScript | TS# | Go | Go# |
|---------|------|-------|--------|-----|------------|-----|-----|-----|
| Idempotency / Non-Idempotent Activities | ✓ | 1 | — | — | — | — | — | — |
| Replay Safety / Side Effects & Non-Determinism | ✓ | 2 | — | — | — | — | — | — |
| Multiple Workers with Different Code | ✓ | 3 | — | — | — | — | — | — |
| Retry Policies / Failing Activities Too Quickly | ✓ | 4 | — | — | — | — | — | — |
| Query Handlers / Query Handler Mistakes | ✓ | 5 | — | — | — | — | — | — |
| File Organization | ✓ | 6 | ✓ | 1 | — | — | — | — |
| Activity Imports | — | — | — | — | ✓ | 1 | — | — |
| Bundling Issues | — | — | — | — | ✓ | 2 | — | — |
| Async vs Sync Activities | — | — | ✓ | 2 | — | — | — | — |
| Goroutines and Concurrency | — | — | — | — | — | — | TODO | 1 |
| Non-Deterministic Operations | — | — | — | — | — | — | TODO | 2 |
| Error Handling | ✓ | 8 | — | — | — | — | — | — |
| Wrong Retry Classification | ✓ | 8 | ✓ | 3 | ✓ | 3 | TODO | 3 |
| Cancellation | ✓ | 10 | ✓ | 4 | ✓ | 4 | TODO | 4 |
| Heartbeating | — | — | ✓ | 5 | ✓ | 5 | TODO | 5 |
| Testing | ✓ | 7 | ✓ | 6 | ✓ | 6 | TODO | 6 |
| Timers and Sleep | — | — | ✓ | 7 | ✓ | 7 | TODO | 7 |
| Payload Size Limits | ✓ | 9 | — | — | — | — | — | — |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Core | ✓ reference | Conceptual gotchas |
| Python | ✓ aligned | Language-specific gotchas |
| TypeScript | ✓ aligned | Language-specific gotchas |
| Go | TODO | Language-specific gotchas — goroutines, channels, selectors, map range |

## Status

**Sections needing review (TODO cells):**
- Go column: TODO items — Go files to be created

**Go-specific notes:**
- Goroutines and Concurrency: MUST use `workflow.Go()` not native `go`, `workflow.Channel` not native channels, `workflow.Selector` not native `select`
- Non-Deterministic Operations: map range iteration, `time.Now()`/`time.Sleep()`, `math/rand`, accessing `os.Stdin`/`os.Stdout`/`os.Stderr`
- Wrong Retry Classification: same concept as Python/TS but uses Go error types (`temporal.NewNonRetryableApplicationError`)
- Cancellation: Go uses `ctx.Done()` channel + `workflow.NewDisconnectedContext` for cleanup
- Heartbeating: `activity.RecordHeartbeat`, `activity.GetHeartbeatDetails`
- Testing: common mistakes with Go test framework (forgetting to register activities, using `time.Sleep` in tests)
- Timers: using `time.Sleep` instead of `workflow.Sleep`; using `time.After` instead of `workflow.NewTimer`

**Decided to keep as-is:**
- Multiple Workers with Different Code: Core-only (conceptual explanation sufficient)
- Heartbeating: Py/TS/Go-only (language-specific code examples, no Core conceptual section needed)

**Intentionally missing (`—`):**
- Idempotency, Replay Safety, Query Handlers, Error Handling, Retry Policies, Payload Size Limits: Core-only (conceptual)
- Multiple Workers with Different Code: Core-only (conceptual)
- File Organization: Core + Python; TS covers similar in Activity Imports; Go has simpler package model
- Activity Imports: TS-specific (bundling/sandbox concerns)
- Bundling Issues: TS-specific (workflow bundling)
- Async vs Sync Activities: Python-specific

**Order alignment:** N/A — Core has conceptual sections, language files have implementation-specific sections

**Style alignment:** ✅ Complete (Python, TypeScript)
- Core: 10 conceptual sections with symptoms/fixes
- TypeScript: 7 sections (Activity Imports, Bundling, Cancellation, Heartbeating, Testing, Timers, Wrong Retry Classification)
- Python: 7 sections (File Organization, Async vs Sync, Wrong Retry Classification, Cancellation, Heartbeating, Testing, Timers and Sleep)
