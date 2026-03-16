# testing.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Go | PHP | PHP# |
|---------|------|--------|-----|------------|-----|----|-----|------|
| Overview | — | ✓ | 1 | ✓ | 1 | | ✓ | 1 |
| Test Environment Setup | — | ✓ | 2 | ✓ | 2 | | ✓ | 2 |
| Time Skipping | — | — | — | — | — | | | |
| Activity Mocking | — | ✓ | 3 | ✓ | 3 | | ✓ | 3 |
| Testing Signals and Queries | — | ✓ | 4 | ✓ | 4 | | ✓ | 4 |
| Testing Failure Cases | — | ✓ | 5 | ✓ | 5 | | ✓ | 5 |
| Replay Testing | — | ✓ | 6 | ✓ | 6 | | ✓ | 6 |
| Activity Testing | — | ✓ | 7 | ✓ | 7 | | ✓ | 7 |
| Best Practices | — | ✓ | 8 | ✓ | 8 | | ✓ | 8 |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Added failure/activity testing |
| Go | — | Not started |
| PHP | ✓ aligned | Matches Python section structure and code-first style |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Intentionally missing (`—`):**
- Core column: no core testing.md exists (implementation-specific)

**Order alignment:** ✅ Aligned — Reordered TS sections to match Python order

**Style alignment:** ✅ Complete. Added Testing Failure Cases and Activity Testing to TypeScript. Removed dedicated Time Skipping section (mentioned inline like Python). Python, TypeScript, and PHP now have matching sections.
