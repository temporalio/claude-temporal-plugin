# gotchas.md

## Section Inventory

| Section | Core | Core# | Python | Py# | TypeScript | TS# | Go | PHP | PHP# |
|---------|------|-------|--------|-----|------------|-----|----|-----|------|
| Idempotency / Non-Idempotent Activities | ✓ | 1 | — | — | — | — | | | |
| Replay Safety / Side Effects & Non-Determinism | ✓ | 2 | — | — | — | — | | | |
| Multiple Workers with Different Code | ✓ | 3 | — | — | — | — | | | |
| Retry Policies / Failing Activities Too Quickly | ✓ | 4 | — | — | — | — | | | |
| Query Handlers / Query Handler Mistakes | ✓ | 5 | — | — | — | — | | | |
| File Organization | ✓ | 6 | ✓ | 1 | — | — | | — | — |
| Activity Imports | — | — | — | — | ✓ | 1 | | — | — |
| Bundling Issues | — | — | — | — | ✓ | 2 | | — | — |
| Async vs Sync Activities | — | — | ✓ | 2 | — | — | | — | — |
| Error Handling | ✓ | 8 | — | — | — | — | | | |
| Wrong Retry Classification | ✓ | 8 | ✓ | 3 | ✓ | 3 | | TODO | 1 |
| Cancellation | ✓ | 10 | ✓ | 4 | ✓ | 4 | | TODO | 2 |
| Heartbeating | — | — | ✓ | 5 | ✓ | 5 | | TODO | 3 |
| Testing | ✓ | 7 | ✓ | 6 | ✓ | 6 | | TODO | 4 |
| Timers and Sleep | — | — | ✓ | 7 | ✓ | 7 | | TODO | 5 |
| Payload Size Limits | ✓ | 9 | — | — | — | — | | | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Core | ✓ reference | Conceptual gotchas |
| Python | ✓ aligned | Language-specific gotchas |
| TypeScript | ✓ aligned | Language-specific gotchas |
| Go | — | Not started |
| PHP | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created
- PHP column: all TODO — PHP files not yet created

**Decided to keep as-is:**
- Multiple Workers with Different Code: Core-only (conceptual explanation sufficient)
- Heartbeating: Py/TS-only (language-specific code examples, no Core conceptual section needed)

**Intentionally missing (`—`):**
- Idempotency, Replay Safety, Query Handlers, Error Handling, Retry Policies, Payload Size Limits: Core-only (conceptual)
- Multiple Workers with Different Code: Core-only (conceptual)
- File Organization: Core + Python; TS covers similar in Activity Imports; PHP has RoadRunner structure (different concern)
- Activity Imports: TS-specific (bundling/sandbox concerns)
- Bundling Issues: TS-specific (workflow bundling)
- Async vs Sync Activities: Python-specific (PHP uses generators + yield, different model)
- Cancellation: Core has conceptual overview, TS/Python/PHP have language-specific patterns
- Timers and Sleep: TS-specific naming; PHP has equivalent TODO

**Order alignment:** N/A — Core has conceptual sections, language files have implementation-specific sections

**Style alignment:** ✅ Complete
- Core: 10 conceptual sections with symptoms/fixes (authoritative for cross-cutting concerns)
- TypeScript: 7 sections (Activity Imports, Bundling, Cancellation, Heartbeating, Testing, Timers, Wrong Retry Classification)
- Python: 7 sections (File Organization, Async vs Sync, Wrong Retry Classification, Cancellation, Heartbeating, Testing, Timers and Sleep)
