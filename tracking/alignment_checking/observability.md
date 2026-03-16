# observability.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Go | Go# |
|---------|------|--------|-----|------------|-----|-----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | TODO | 1 |
| Logging / Replay-Aware Logging | — | ✓ | 2 | ✓ | 2 | TODO | 2 |
| Customizing the Logger | — | ✓ | 2 | ✓ | 3 | TODO | 3 |
| OpenTelemetry Integration | — | — | — | — | — | — | — |
| Metrics | — | ✓ | 3 | ✓ | 4 | TODO | 4 |
| Search Attributes (Visibility) | — | ✓ | 4 | — | — | TODO | 5 |
| Debugging with Event History | — | — | — | — | — | — | — |
| Best Practices | — | ✓ | 5 | ✓ | 5 | TODO | 6 |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Removed verbose sections |
| Go | TODO | workflow.GetLogger, slog integration, Tally/Prometheus metrics |

## Status

**Sections needing review (TODO cells):**
- Go column: TODO items — Go files to be created

**Go-specific notes:**
- Logging: `workflow.GetLogger(ctx)` for replay-safe workflow logging; `activity.GetLogger(ctx)` for activity logging
- Customizing: Go 1.21+ supports `log.NewStructuredLogger(slog.New(...))` via `client.Options.Logger`; also supports custom `log.Logger` interface
- Metrics: Go uses Tally library (`go.temporal.io/sdk/contrib/tally`) for Prometheus integration; `client.Options.MetricsHandler`
- Tracing: Go supports OpenTelemetry, OpenTracing, and Datadog via `contrib/` packages and interceptors
- Search Attributes: Go includes visibility/search attributes in observability (like Python, unlike TS)

**Intentionally missing (`—`):**
- Core column: no core observability.md exists (implementation-specific)
- OpenTelemetry / Debugging: Removed as too detailed
- Search Attributes: Python/Go include; TS keeps in data-handling.md

**Order alignment:** ✓ Aligned — Go# monotonically increases

**Style alignment:** ✅ Complete (Python, TypeScript)
