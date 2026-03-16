# error-handling.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Ruby | Rb# | Go |
|---------|------|--------|-----|------------|-----|------|-----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | TODO | 1 | |
| Application Errors/Failures | — | ✓ | 2 | ✓ | 2 | TODO | 2 | |
| Non-Retryable Errors | — | ✓ | 3 | — | — | TODO | 3 | |
| Activity Errors | — | — | — | ✓ | 3 | — | — | |
| Handling Activity Errors in Workflows | — | ✓ | 4 | ✓ | 4 | TODO | 4 | |
| Retry Configuration | — | ✓ | 5 | ✓ | 5 | TODO | 5 | |
| Timeout Configuration | — | ✓ | 6 | ✓ | 6 | TODO | 6 | |
| Workflow Failure | — | ✓ | 7 | ✓ | 7 | TODO | 7 | |
| Cancellation Handling in Activities | — | — | — | — | — | — | — | |
| Idempotency Patterns | — | — | — | — | — | — | — | |
| Best Practices | — | ✓ | 8 | ✓ | 9 | TODO | 8 | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Uses `log`, has retry defaults note |
| Ruby | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created
- Ruby column: all TODO — Ruby files not yet created

**Intentionally missing (`—`):**
- Core column: error handling is implementation-specific, no core concepts doc needed
- Non-Retryable Errors: TS covers inline in Application Failures; Ruby should have like Python (`non_retryable: true` on `ApplicationError`)
- Activity Errors: Python covers in Application Errors; TS-specific section
- Workflow Failure: Ruby should have — only `ApplicationError` raised from workflow code causes workflow failure; other exceptions cause workflow task failure (retried)

**Ruby notes:**
- `Temporalio::Error::ApplicationError` with `non_retryable:` parameter
- Any non-`ApplicationError` exception in a workflow causes workflow task failure (retried), NOT workflow failure
- Activity exceptions auto-converted to `ApplicationError`
- `Temporalio::RetryPolicy.new(max_interval:, initial_interval:, backoff_coefficient:, max_attempts:, non_retryable_error_types:)`
- Timeouts: `start_to_close_timeout`, `schedule_to_close_timeout`, `schedule_to_start_timeout` (same as other SDKs)
- `workflow_failure_exception_types` on Worker or `workflow_failure_exception_type` on Workflow class
- `next_retry_delay:` parameter on `ApplicationError` to override retry interval

**Order alignment:** ✓ Aligned — Ruby follows Python order

**Style alignment:** ✅ Complete (Python/TypeScript). Ruby should follow same structure.
