# error-handling.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | .NET | DN# | Go |
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
| .NET | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Intentionally missing (`—`):**
- Core column: error handling is implementation-specific, no core concepts doc needed
- Non-Retryable Errors: TS covers inline in Application Failures
- Activity Errors: Python covers in Application Errors; .NET covers in Application Failures
- Workflow Failure: Important for .NET — non-ApplicationFailureException retries the workflow task rather than failing the workflow

**.NET alignment notes:**
- Non-Retryable Errors: ✓ for .NET — follows Python's pattern with dedicated section. `ApplicationFailureException` with `nonRetryable: true` or `NonRetryableErrorTypes` in RetryPolicy.
- Workflow Failure: ✓ for .NET — critical to explain that only `ApplicationFailureException` fails a workflow; all other exceptions retry the workflow task. This is a key .NET gotcha.
- Application Failures: .NET uses `ApplicationFailureException` (vs Python's `ApplicationError`, TS's `ApplicationFailure`)

**Order alignment:** ✓ Aligned — TS# monotonically increases; DN# monotonically increases

**Style alignment:** ✅ Complete (Python/TS). .NET not started.
