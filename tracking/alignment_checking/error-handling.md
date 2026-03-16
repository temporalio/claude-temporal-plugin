# error-handling.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Go | PHP | PHP# |
|---------|------|--------|-----|------------|-----|----|-----|------|
| Overview | — | ✓ | 1 | ✓ | 1 | | ✓ | 1 |
| Application Errors | — | ✓ | 2 | ✓ | 2 | | ✓ | 2 |
| Non-Retryable Errors | — | ✓ | 3 | — | — | | ✓ | 3 |
| Activity Errors | — | — | — | ✓ | 3 | | — | — |
| Handling Activity Errors | — | ✓ | 4 | ✓ | 4 | | ✓ | 4 |
| Retry Policy Configuration | — | ✓ | 5 | ✓ | 5 | | ✓ | 5 |
| Timeout Configuration | — | ✓ | 6 | ✓ | 6 | | ✓ | 6 |
| Workflow Failure | — | ✓ | 7 | ✓ | 7 | | ✓ | 7 |
| Cancellation Handling in Activities | — | — | — | — | — | | | |
| Idempotency Patterns | — | — | — | — | — | | | |
| Best Practices | — | ✓ | 8 | ✓ | 9 | | ✓ | 8 |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Uses `log`, has retry defaults note |
| Go | — | Not started |
| PHP | ✓ aligned | Matches Python section structure and code-first style |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created
- Go column: all empty — Go files not yet created

**Intentionally missing (`—`):**
- Core column: error handling is implementation-specific, no core concepts doc needed
- Non-Retryable Errors: TS covers inline in Application Failures; PHP has dedicated section (nonRetryable param)
- Activity Errors: Python and PHP cover in Application Errors/Failures; TS-specific section
- Workflow Failure: TS-specific section not needed (different SDK design)
- Idempotency Patterns: TS-specific detailed section; Python/PHP reference core/patterns.md

**Order alignment:** ✓ Aligned — TS# monotonically increases

**Style alignment:** ✅ Complete. Added Workflow Failure section, removed Cancellation Handling (moved to patterns.md), replaced Idempotency Patterns with core reference. TS uses `log` for error handling, has note about preferring defaults for retry config. PHP added with matching section structure.
