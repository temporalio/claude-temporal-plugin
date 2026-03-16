# observability.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Go | PHP | PHP# |
|---------|------|--------|-----|------------|-----|----|-----|------|
| Overview | — | ✓ | 1 | ✓ | 1 | | ✓ | 1 |
| Logging / Replay-Aware Logging | — | ✓ | 2 | ✓ | 2 | | ✓ | 2 |
| Customizing the Logger | — | ✓ | 2 | ✓ | 3 | | ✓ | 3 |
| OpenTelemetry Integration | — | — | — | — | — | | | |
| Metrics | — | ✓ | 3 | ✓ | 4 | | — | — |
| Search Attributes (Visibility) | — | ✓ | 4 | — | — | | ✓ | 4 |
| Debugging with Event History | — | — | — | — | — | | | |
| Best Practices | — | ✓ | 5 | ✓ | 5 | | ✓ | 5 |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Removed verbose sections |
| Go | — | Not started |
| PHP | ✓ aligned | PSR-3 logging; Metrics omitted (uses RoadRunner pipeline, not SDK metrics API) |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Intentionally missing (`—`):**
- Core column: no core observability.md exists (implementation-specific)
- Search Attributes: Python and PHP include as observability concept; TS keeps in data-handling.md
- Metrics: PHP uses Go-based RoadRunner metrics pipeline, not the same SDK-level metrics API as Python/TS

**Order alignment:** ✓ Aligned — TS# monotonically increases (Py# 2 maps to both TS# 2 and 3, but order preserved)

**Style alignment:** ✅ Complete. TS and PHP are concise like Python. Removed OpenTelemetry Integration and Debugging with Event History (too detailed). PHP Metrics omitted — uses RoadRunner metrics pipeline, not the same SDK-level metrics API.
