# observability.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | .NET | DN# | Go |
|---------|------|--------|-----|------------|-----|------|-----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | TODO | 1 | |
| Logging / Replay-Aware Logging | — | ✓ | 2 | ✓ | 2 | TODO | 2 | |
| Customizing the Logger | — | ✓ | 2 | ✓ | 3 | TODO | 3 | |
| OpenTelemetry Integration | — | — | — | — | — | — | — | |
| Metrics | — | ✓ | 3 | ✓ | 4 | TODO | 4 | |
| Search Attributes (Visibility) | — | ✓ | 4 | — | — | — | — | |
| Debugging with Event History | — | — | — | — | — | — | — | |
| Best Practices | — | ✓ | 5 | ✓ | 5 | TODO | 5 | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Removed verbose sections |
| .NET | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Intentionally missing (`—`):**
- Core column: no core observability.md exists (implementation-specific)
- Search Attributes: Python includes as observability concept; TS keeps in data-handling.md; .NET keeps in data-handling.md (follows TS pattern)
- OpenTelemetry Integration: Removed from all languages (too detailed for this reference)
- Debugging with Event History: Removed from all languages (too detailed)

**.NET alignment notes:**
- Logging: .NET uses `Workflow.Logger` (replay-aware, uses `ILogger` interface)
- Customizing the Logger: .NET uses `LoggerFactory` on client/worker options (standard .NET logging)
- Metrics: .NET uses `Temporalio.Extensions.OpenTelemetry` package for metrics
- Search Attributes: Kept in data-handling.md (follows TS pattern)

**Order alignment:** ✓ Aligned — TS# monotonically increases; DN# monotonically increases

**Style alignment:** ✅ Complete (Python/TS). .NET not started.
