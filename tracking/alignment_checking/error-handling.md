# error-handling.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Java | J# | Go |
|---------|------|--------|-----|------------|-----|------|----|----|
| Overview | — | ✓ | 1 | ✓ | 1 | TODO | 1 | |
| Application Errors/Failures | — | ✓ | 2 | ✓ | 2 | TODO | 2 | |
| Non-Retryable Errors | — | ✓ | 3 | — | — | TODO | 3 | |
| Activity Errors | — | — | — | ✓ | 3 | TODO | 4 | |
| Handling Activity Errors in Workflows | — | ✓ | 4 | ✓ | 4 | TODO | 5 | |
| Retry Configuration | — | ✓ | 5 | ✓ | 5 | TODO | 6 | |
| Timeout Configuration | — | ✓ | 6 | ✓ | 6 | TODO | 7 | |
| Workflow Failure | — | ✓ | 7 | ✓ | 7 | TODO | 8 | |
| Cancellation Handling in Activities | — | — | — | — | — | — | — | |
| Idempotency Patterns | — | — | — | — | — | — | — | |
| Best Practices | — | ✓ | 8 | ✓ | 9 | TODO | 9 | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Uses `log`, has retry defaults note |
| Java | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Java column decisions:**
- Application Errors/Failures: Java uses `ApplicationFailure.newFailure()` and `ApplicationFailure.newNonRetryableFailure()`
- Non-Retryable Errors: Java has explicit `ApplicationFailure.newNonRetryableFailure()` + `RetryOptions.setDoNotRetry()` — warrants own section (like Python)
- Activity Errors: Java wraps activity failures in `ActivityFailure` (like TS) — warrants own section showing unwrapping
- Handling Activity Errors: Java catches `ActivityFailure` in workflow code, checks cause type (`ApplicationFailure`, `TimeoutFailure`)
- Retry Configuration: Java uses `RetryOptions.newBuilder()` with `ActivityOptions`
- Timeout Configuration: Java uses `ActivityOptions.newBuilder().setStartToCloseTimeout()` etc.
- Workflow Failure: Important Java-specific behavior — only `ApplicationFailure` fails workflows; other exceptions cause workflow task retry indefinitely

**Intentionally missing (`—`):**
- Core column: error handling is implementation-specific, no core concepts doc needed
- Cancellation Handling in Activities: not yet documented for any language here
- Idempotency Patterns: covered in core/patterns.md

**Order alignment:** ✓ Aligned — Java has both Non-Retryable Errors (like Python) AND Activity Errors (like TS), since both are important in Java

**Style alignment:** ✅ Complete (Python, TypeScript)
