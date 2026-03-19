# gotchas.md

## Section Inventory

| Section | Core | Core# | Python | Py# | TypeScript | TS# | Ruby | Rb# | Go | Go# |
|---------|------|-------|--------|-----|------------|-----|------|-----|-----|-----|
| Idempotency / Non-Idempotent Activities | ✓ | 1 | — | — | — | — | — | — | — | — |
| Replay Safety / Side Effects & Non-Determinism | ✓ | 2 | — | — | — | — | — | — | — | — |
| Multiple Workers with Different Code | ✓ | 3 | — | — | — | — | — | — | — | — |
| Retry Policies / Failing Activities Too Quickly | ✓ | 4 | — | — | — | — | — | — | — | — |
| Query Handlers / Query Handler Mistakes | ✓ | 5 | — | — | — | — | — | — | — | — |
| File Organization | ✓ | 6 | ✓ | 1 | — | — | TODO | 1 | — | — |
| Activity Imports | — | — | — | — | ✓ | 1 | — | — | — | — |
| Bundling Issues | — | — | — | — | ✓ | 2 | — | — | — | — |
| Async vs Sync Activities | — | — | ✓ | 2 | — | — | — | — | — | — |
| Goroutines and Concurrency | — | — | — | — | — | — | — | — | ✓ | 1 |
| Non-Deterministic Operations | — | — | — | — | — | — | — | — | ✓ | 2 |
| Error Handling | ✓ | 8 | — | — | — | — | — | — | — | — |
| Wrong Retry Classification | ✓ | 8 | ✓ | 3 | ✓ | 3 | TODO | 2 | ✓ | 3 |
| Heartbeating | — | — | ✓ | 5 | ✓ | 5 | TODO | 4 | ✓ | 4 |
| Cancellation | ✓ | 10 | ✓ | 4 | ✓ | 4 | TODO | 3 | ✓ | 5 |
| Testing | ✓ | 7 | ✓ | 6 | ✓ | 6 | TODO | 5 | ✓ | 6 |
| Timers and Sleep | — | — | ✓ | 7 | ✓ | 7 | TODO | 6 | ✓ | 7 |
| Payload Size Limits | ✓ | 9 | — | — | — | — | — | — | — | — |
| Illegal Call Tracing Gotchas | — | — | — | — | — | — | TODO | 7 | — | — |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Core | ✓ reference | Conceptual gotchas |
| Python | ✓ aligned | Language-specific gotchas |
| TypeScript | ✓ aligned | Language-specific gotchas |
| Ruby | — | Not started |
| Go | ✓ aligned | Language-specific gotchas — goroutines, channels, selectors, map range |

## Status

**Ruby notes:**
- File Organization: Ruby class-per-file convention, `require_relative` for activities in workflows
- Wrong Retry Classification: `non_retryable: true` on `ApplicationError`, `non_retryable_error_types` in retry policy
- Cancellation: `Temporalio::Cancellation` tokens, detached cancellation for cleanup, `Error.canceled?` helper
- Heartbeating: `Temporalio::Activity::Context.current.heartbeat(details)`, heartbeat_details on retry
- Testing: common testing gotchas with `WorkflowExecutor::ThreadPool`, `activity_name` for mocking
- Timers and Sleep: `Temporalio::Workflow.sleep` vs `Kernel.sleep` (illegal), duration in seconds (Float)
- Illegal Call Tracing Gotchas: Ruby-specific — third-party gems triggering illegal calls, using `Unsafe.illegal_call_tracing_disabled` for safe workarounds, `durable_scheduler_disabled` for IO

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
- Heartbeating: Py/TS/Ruby/Go-only (language-specific code examples, no Core conceptual section needed)

**Intentionally missing (`—`):**
- Idempotency, Replay Safety, Query Handlers, Error Handling, Retry Policies, Payload Size Limits: Core-only (conceptual)
- Multiple Workers with Different Code: Core-only (conceptual)
- File Organization: Core + Python; TS covers similar in Activity Imports; Go has simpler package model
- Activity Imports: TS-specific (bundling/sandbox concerns)
- Bundling Issues: TS-specific (workflow bundling)
- Async vs Sync Activities: Python-specific (Ruby activities run in executors but this is less of a gotcha)
- Illegal Call Tracing Gotchas: Ruby-specific

**Order alignment:** N/A — Core has conceptual sections, language files have implementation-specific sections

**Style alignment:** ✅ Complete (Python, TypeScript, Go). Ruby: ~7 sections planned.
- Core: 10 conceptual sections with symptoms/fixes
- TypeScript: 7 sections (Activity Imports, Bundling, Cancellation, Heartbeating, Testing, Timers, Wrong Retry Classification)
- Python: 7 sections (File Organization, Async vs Sync, Wrong Retry Classification, Cancellation, Heartbeating, Testing, Timers and Sleep)
