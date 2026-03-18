# error-handling.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Go |
|---------|------|--------|-----|------------|-----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | |
| Application Errors/Failures | — | ✓ | 2 | ✓ | 2 | |
| Non-Retryable Errors | — | ✓ | 3 | — | — | |
| Activity Errors | — | — | — | ✓ | 3 | |
| Handling Activity Errors in Workflows | — | ✓ | 4 | ✓ | 4 | |
| Retry Configuration | — | ✓ | 5 | ✓ | 5 | |
| Timeout Configuration | — | ✓ | 6 | ✓ | 6 | |
| Workflow Failure | — | ✓ | 7 | ✓ | 7 | |
| Cancellation Handling in Activities | — | — | — | — | — | |
| Idempotency Patterns | — | — | — | — | — | |
| Best Practices | — | ✓ | 8 | ✓ | 9 | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Uses `log`, has retry defaults note |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Intentionally missing (`—`):**
- Core column: error handling is implementation-specific, no core concepts doc needed
- Non-Retryable Errors: TS covers inline in Application Failures
- Activity Errors: Python covers in Application Errors
- Workflow Failure: TS-specific section not needed (different SDK design)
- Idempotency Patterns: TS-specific detailed section; Python references core/patterns.md

**Order alignment:** ✓ Aligned — TS# monotonically increases

**Style alignment:** ✅ Complete. Added Workflow Failure section, removed Cancellation Handling (moved to patterns.md), replaced Idempotency Patterns with core reference. TS uses `log` for error handling, has note about preferring defaults for retry config.
