# error-handling.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Ruby | Rb# | Go | Go# |
|---------|------|--------|-----|------------|-----|------|-----|-----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | TODO | 1 | ✓ | 1 |
| Application Errors/Failures | — | ✓ | 2 | ✓ | 2 | TODO | 2 | ✓ | 2 |
| Non-Retryable Errors | — | ✓ | 3 | — | — | TODO | 3 | ✓ | 3 |
| Activity Errors | — | — | — | ✓ | 3 | — | — | — | — |
| Handling Activity Errors in Workflows | — | ✓ | 4 | ✓ | 4 | TODO | 4 | ✓ | 4 |
| Retry Configuration | — | ✓ | 5 | ✓ | 5 | TODO | 5 | ✓ | 5 |
| Timeout Configuration | — | ✓ | 6 | ✓ | 6 | TODO | 6 | ✓ | 6 |
| Workflow Failure | — | ✓ | 7 | ✓ | 7 | TODO | 7 | ✓ | 7 |
| Cancellation Handling in Activities | — | — | — | — | — | — | — | — | — |
| Idempotency Patterns | — | — | — | — | — | — | — | — | — |
| Best Practices | — | ✓ | 8 | ✓ | 9 | TODO | 8 | ✓ | 8 |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Uses `log`, has retry defaults note |
| Ruby | — | Not started |
| Go | ✓ aligned | Go-style error handling (errors.As, error returns, no exceptions) |

## Status

**Ruby notes:**
- `Temporalio::Error::ApplicationError` with `non_retryable:` parameter
- Any non-`ApplicationError` exception in a workflow causes workflow task failure (retried), NOT workflow failure
- Activity exceptions auto-converted to `ApplicationError`
- `Temporalio::RetryPolicy.new(max_interval:, initial_interval:, backoff_coefficient:, max_attempts:, non_retryable_error_types:)`
- Timeouts: `start_to_close_timeout`, `schedule_to_close_timeout`, `schedule_to_start_timeout` (same as other SDKs)
- `workflow_failure_exception_types` on Worker or `workflow_failure_exception_type` on Workflow class
- `next_retry_delay:` parameter on `ApplicationError` to override retry interval

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

**Order alignment:** ✓ Aligned — Ruby and Go# monotonically increase

**Style alignment:** ✅ Complete (Python, TypeScript, Go). Ruby: ~8 sections planned.
