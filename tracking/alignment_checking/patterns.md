# patterns.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Go | PHP | PHP# |
|---------|------|--------|-----|------------|-----|----|-----|------|
| Signals | ✓ | ✓ | 1 | ✓ | 1 | | ✓ | 1 |
| Dynamic Signal Handlers | — | ✓ | 2 | ✓ | 2 | | ✓ | 2 |
| Queries | ✓ | ✓ | 3 | ✓ | 3 | | ✓ | 3 |
| Dynamic Query Handlers | — | ✓ | 4 | ✓ | 4 | | ✓ | 4 |
| Updates | ✓ | ✓ | 5 | ✓ | 5 | | ✓ | 5 |
| Child Workflows | ✓ | ✓ | 6 | ✓ | 6 | | ✓ | 6 |
| Child Workflow Options | — | — | — | ✓ | 7 | | — | — |
| Handles to External Workflows | — | ✓ | 7 | ✓ | 8 | | ✓ | 7 |
| Parallel Execution | ✓ | ✓ | 8 | ✓ | 9 | | ✓ | 8 |
| Deterministic Asyncio Alternatives | — | ✓ | 9 | — | — | | — | — |
| Continue-as-New | ✓ | ✓ | 10 | ✓ | 10 | | ✓ | 9 |
| Saga Pattern | ✓ | ✓ | 11 | ✓ | 11 | | ✓ | 10 |
| Cancellation Handling (asyncio) | — | ✓ | 12 | — | — | | — | — |
| Cancellation Scopes | — | — | — | ✓ | 12 | | — | — |
| Triggers | — | — | — | ✓ | 13 | | — | — |
| Wait Condition with Timeout | — | ✓ | 13 | ✓ | 14 | | ✓ | 11 |
| Waiting for All Handlers to Finish | — | ✓ | 14 | ✓ | 15 | | ✓ | 12 |
| Activity Heartbeating | ✓ | ✓ | 15 | ✓ | 16 | | ✓ | 13 |
| Timers | ✓ | ✓ | 16 | ✓ | 17 | | ✓ | 14 |
| Large Data Handling | ✓ | — | — | — | — | | — | — |
| Local Activities | ✓ | ✓ | 17 | ✓ | 18 | | ✓ | 15 |
| Entity Workflow Pattern | ✓ | — | — | — | — | | — | — |
| Polling Patterns | ✓ | — | — | — | — | | — | — |
| Idempotency Patterns | ✓ | — | — | — | — | | — | — |
| Using Pydantic Models | — | ✓ | 18 | — | — | | — | — |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Uses `log`, CancellationScope idiom |
| Go | — | Not started |
| PHP | ✓ aligned | Code-first, minimal prose, matches Python style |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Decided to keep as Core-only:**
- Large Data Handling: Core conceptual explanation sufficient (language-agnostic pattern)
- Polling Patterns: Core conceptual explanation sufficient
- Idempotency Patterns: Core conceptual explanation sufficient

**Intentionally missing (`—`):**
- Dynamic handlers, External workflow handles, Wait conditions: language-specific implementation, core has concepts only
- Child Workflow Options: TS-specific (Python shows inline; PHP also shows inline)
- Deterministic Asyncio Alternatives: Python-specific (TS/PHP don't have this issue)
- Cancellation Handling vs Cancellation Scopes: different idioms per language; PHP uses `Workflow::async()` scoping
- Triggers: TS-specific pattern
- Entity Workflow Pattern: conceptual in core, implementation left to user
- Using Pydantic Models: Python-specific
- Large Data Handling, Polling Patterns, Idempotency Patterns: Core-only (PHP same as Python/TS)

**Order alignment:** ✓ Aligned — TS# monotonically increases

**Style alignment:** ✅ All issues fixed
- ✅ **Queries:** TS now has "Important: must NOT modify state" note
- ✅ **Saga Pattern:** TS now has idempotency note, comments about saving compensation BEFORE activity
- ✅ **Saga Pattern:** TS now uses `log` from `@temporalio/workflow`
- ✅ **PHP:** All 15 sections created in `references/php/patterns.md`, code-first style, matches Python alignment
