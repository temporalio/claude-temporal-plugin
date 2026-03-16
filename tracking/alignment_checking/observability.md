# observability.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Java | J# | Go |
|---------|------|--------|-----|------------|-----|------|----|----|
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
| Java | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Java column decisions:**
- Logging: Java uses `Workflow.getLogger()` (SLF4J-based, replay-aware)
- Customizing the Logger: SLF4J configuration (Logback, Log4j2, etc.)
- Metrics: Java uses Micrometer + `MicrometerClientStatsReporter` with Prometheus
- Search Attributes (Visibility): — (Java keeps this in data-handling.md, like TS)
- OpenTelemetry / Debugging: — (not documented for any language, too detailed)

**Intentionally missing (`—`):**
- Core column: no core observability.md exists (implementation-specific)
- Search Attributes: Python includes as observability concept; TS and Java keep in data-handling.md
- OpenTelemetry Integration and Debugging with Event History: not documented (too detailed)

**Order alignment:** ✓ Aligned — Java follows same structure as TS (Overview, Logging, Customizing, Metrics, Best Practices)

**Style alignment:** ✅ Complete (Python, TypeScript). TS is now concise like Python.
