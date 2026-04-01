# error-handling.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | .NET | DN# | Go | Go# |
|---------|------|--------|-----|------------|-----|------|-----|----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | ✓ | 1 | ✓ | 1 |
| Application Errors/Failures | — | ✓ | 2 | ✓ | 2 | ✓ | 2 | ✓ | 2 |
| Non-Retryable Errors | — | ✓ | 3 | — | — | ✓ | 3 | ✓ | 3 |
| Activity Errors | — | — | — | ✓ | 3 | — | — | — | — |
| Handling Activity Errors in Workflows | — | ✓ | 4 | ✓ | 4 | ✓ | 4 | ✓ | 4 |
| Retry Configuration | — | ✓ | 5 | ✓ | 5 | ✓ | 5 | ✓ | 5 |
| Timeout Configuration | — | ✓ | 6 | ✓ | 6 | ✓ | 6 | ✓ | 6 |
| Workflow Failure | — | ✓ | 7 | ✓ | 7 | ✓ | 7 | ✓ | 7 |
| Cancellation Handling in Activities | — | — | — | — | — | — | — | — | — |
| Idempotency Patterns | — | — | — | — | — | — | — | — | — |
| Best Practices | — | ✓ | 8 | ✓ | 9 | ✓ | 8 | ✓ | 8 |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Uses `log`, has retry defaults note |
| .NET | ✓ aligned | ApplicationFailureException, ActivityFailureException, nonRetryable param |
| Go | ✓ aligned | Go-style error handling (errors.As, error returns, no exceptions) |

## Status

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
- Activity Errors: TS-specific section (Go covers in Handling Activity Errors)

**Order alignment:** ✓ Aligned — Go# monotonically increases

**Style alignment:** ✅ Complete (Python, TypeScript)
