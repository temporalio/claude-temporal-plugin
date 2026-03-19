# observability.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Java | J# | Go | Go# |
|---------|------|--------|-----|------------|-----|------|----|----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | TODO | 1 | ✓ | 1 |
| Logging / Replay-Aware Logging | — | ✓ | 2 | ✓ | 2 | TODO | 2 | ✓ | 2 |
| Customizing the Logger | — | ✓ | 2 | ✓ | 3 | TODO | 3 | ✓ | 3 |
| OpenTelemetry Integration | — | — | — | — | — | — | — | — | — |
| Metrics | — | ✓ | 3 | ✓ | 4 | TODO | 4 | ✓ | 4 |
| Search Attributes (Visibility) | — | ✓ | 4 | — | — | — | — | ✓ | 5 |
| Debugging with Event History | — | — | — | — | — | — | — | — | — |
| Best Practices | — | ✓ | 5 | ✓ | 5 | TODO | 5 | ✓ | 6 |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Removed verbose sections |
| Java | — | Not started |
| Go | ✓ aligned | workflow.GetLogger, slog integration, Tally/Prometheus metrics |

## Status

**Java column decisions:**
- Logging: Java uses `Workflow.getLogger()` (SLF4J-based, replay-aware)
- Customizing the Logger: SLF4J configuration (Logback, Log4j2, etc.)
- Metrics: Java uses Micrometer + `MicrometerClientStatsReporter` with Prometheus
- Search Attributes (Visibility): — (Java keeps this in data-handling.md, like TS)
- OpenTelemetry / Debugging: — (not documented for any language, too detailed)

**Go-specific notes:**
- Logging: `workflow.GetLogger(ctx)` for replay-safe workflow logging; `activity.GetLogger(ctx)` for activity logging
- Customizing: Go 1.21+ supports `log.NewStructuredLogger(slog.New(...))` via `client.Options.Logger`; also supports custom `log.Logger` interface
- Metrics: Go uses Tally library (`go.temporal.io/sdk/contrib/tally`) for Prometheus integration; `client.Options.MetricsHandler`
- Tracing: Go supports OpenTelemetry, OpenTracing, and Datadog via `contrib/` packages and interceptors
- Search Attributes: Go includes visibility/search attributes in observability (like Python, unlike TS)

**Intentionally missing (`—`):**
- Core column: no core observability.md exists (implementation-specific)
- OpenTelemetry / Debugging: Removed as too detailed
- Search Attributes: Python/Go include; TS/Java keep in data-handling.md

**Order alignment:** ✓ Aligned — Java follows same structure as TS (Overview, Logging, Customizing, Metrics, Best Practices)

**Style alignment:** ✅ Complete (Python, TypeScript, Go). Java: ~5 sections planned.
