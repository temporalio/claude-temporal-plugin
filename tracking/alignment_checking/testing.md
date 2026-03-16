# testing.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Go | PHP | PHP# |
|---------|------|--------|-----|------------|-----|----|-----|------|
| Overview | — | ✓ | 1 | ✓ | 1 | | TODO | 1 |
| Test Environment Setup | — | ✓ | 2 | ✓ | 2 | | TODO | 2 |
| Time Skipping | — | — | — | — | — | | | |
| Activity Mocking | — | ✓ | 3 | ✓ | 3 | | TODO | 3 |
| Testing Signals and Queries | — | ✓ | 4 | ✓ | 4 | | TODO | 4 |
| Testing Failure Cases | — | ✓ | 5 | ✓ | 5 | | TODO | 5 |
| Replay Testing | — | ✓ | 6 | ✓ | 6 | | TODO | 6 |
| Activity Testing | — | ✓ | 7 | ✓ | 7 | | TODO | 7 |
| Best Practices | — | ✓ | 8 | ✓ | 8 | | TODO | 8 |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Added failure/activity testing |
| Go | — | Not started |
| PHP | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created
- PHP column: all TODO — PHP files not yet created

**Intentionally missing (`—`):**
- Core column: no core testing.md exists (implementation-specific)

**Order alignment:** ✅ Aligned — Reordered TS sections to match Python order

**Style alignment:** ✅ Complete. Added Testing Failure Cases and Activity Testing to TypeScript. Removed dedicated Time Skipping section (mentioned inline like Python). Python and TypeScript now have matching sections.
