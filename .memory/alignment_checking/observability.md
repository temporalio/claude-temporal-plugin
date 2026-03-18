# observability.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Go |
|---------|------|--------|-----|------------|-----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | |
| Logging / Replay-Aware Logging | — | ✓ | 2 | ✓ | 2 | |
| Customizing the Logger | — | ✓ | 2 | ✓ | 3 | |
| OpenTelemetry Integration | — | — | — | — | — | |
| Metrics | — | ✓ | 3 | ✓ | 4 | |
| Search Attributes (Visibility) | — | ✓ | 4 | — | — | |
| Debugging with Event History | — | — | — | — | — | |
| Best Practices | — | ✓ | 5 | ✓ | 5 | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Removed verbose sections |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Intentionally missing (`—`):**
- Core column: no core observability.md exists (implementation-specific)
- Search Attributes: Python includes as observability concept; TS keeps in data-handling.md

**Order alignment:** ✓ Aligned — TS# monotonically increases (Py# 2 maps to both TS# 2 and 3, but order preserved)

**Style alignment:** ✅ Complete. TS is now concise like Python. Removed OpenTelemetry Integration and Debugging with Event History (too detailed).
