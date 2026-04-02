# error-handling.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Java | J# | Go | Go# |
|---------|------|--------|-----|------------|-----|------|----|----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | TODO | 1 | ✓ | 1 |
| Application Errors/Failures | — | ✓ | 2 | ✓ | 2 | TODO | 2 | ✓ | 2 |
| Non-Retryable Errors | — | ✓ | 3 | — | — | TODO | 3 | ✓ | 3 |
| Activity Errors | — | — | — | ✓ | 3 | TODO | 4 | — | — |
| Handling Activity Errors in Workflows | — | ✓ | 4 | ✓ | 4 | TODO | 5 | ✓ | 4 |
| Retry Configuration | — | ✓ | 5 | ✓ | 5 | TODO | 6 | ✓ | 5 |
| Timeout Configuration | — | ✓ | 6 | ✓ | 6 | TODO | 7 | ✓ | 6 |
| Workflow Failure | — | ✓ | 7 | ✓ | 7 | TODO | 8 | ✓ | 7 |
| Cancellation Handling in Activities | — | — | — | — | — | — | — | — | — |
| Idempotency Patterns | — | — | — | — | — | — | — | — | — |
| Best Practices | — | ✓ | 8 | ✓ | 9 | TODO | 9 | ✓ | 8 |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Uses `log`, has retry defaults note |
| Java | — | Not started |
| Go | ✓ aligned | Go-style error handling (errors.As, error returns, no exceptions) |

## Status

**Java column decisions:**
- Application Errors/Failures: Java uses `ApplicationFailure.newFailure()` and `ApplicationFailure.newNonRetryableFailure()`
- Non-Retryable Errors: Java has explicit `ApplicationFailure.newNonRetryableFailure()` + `RetryOptions.setDoNotRetry()` — warrants own section (like Python)
- Activity Errors: Java wraps activity failures in `ActivityFailure` (like TS) — warrants own section showing unwrapping
- Handling Activity Errors: Java catches `ActivityFailure` in workflow code, checks cause type (`ApplicationFailure`, `TimeoutFailure`)
- Retry Configuration: Java uses `RetryOptions.newBuilder()` with `ActivityOptions`
- Timeout Configuration: Java uses `ActivityOptions.newBuilder().setStartToCloseTimeout()` etc.
- Workflow Failure: Important Java-specific behavior — only `ApplicationFailure` fails workflows; other exceptions cause workflow task retry indefinitely

**Go-specific notes:**
- Go uses error returns (not exceptions) — `if err != nil` pattern
- Application Errors: `temporal.NewApplicationError("msg", "type", details...)` and `temporal.NewNonRetryableApplicationError("msg", "type", cause, details...)`
- Non-Retryable: Go has both `temporal.NewNonRetryableApplicationError()` and `NonRetryableErrorTypes` in RetryPolicy
- Handling Activity Errors: `errors.As(err, &applicationErr)` pattern — check `*temporal.ApplicationError`, `*temporal.TimeoutError`, `*temporal.CanceledError`, `*temporal.PanicError`
- Retry Config: `temporal.RetryPolicy` struct with `InitialInterval`, `BackoffCoefficient`, `MaximumInterval`, `MaximumAttempts`, `NonRetryableErrorTypes`
- Timeout Config: `workflow.ActivityOptions` with `StartToCloseTimeout`, `ScheduleToCloseTimeout`, etc.
- Workflow Failure: returning any error from a workflow function fails the workflow

**Intentionally missing (`—`):**
- Core column: error handling is implementation-specific
- Activity Errors: TS/Java-specific section (Go/Python cover in Handling Activity Errors)

**Order alignment:** ✓ Aligned — Java has both Non-Retryable Errors (like Python) AND Activity Errors (like TS); J# monotonically increases

**Style alignment:** ✅ Complete (Python, TypeScript, Go). Java: ~9 sections planned.
