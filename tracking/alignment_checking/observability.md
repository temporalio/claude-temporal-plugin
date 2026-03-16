# observability.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Ruby | Rb# | Go |
|---------|------|--------|-----|------------|-----|------|-----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | TODO | 1 | |
| Logging / Replay-Aware Logging | — | ✓ | 2 | ✓ | 2 | TODO | 2 | |
| Customizing the Logger | — | ✓ | 2 | ✓ | 3 | — | — | |
| OpenTelemetry Integration | — | — | — | — | — | — | — | |
| Metrics | — | ✓ | 3 | ✓ | 4 | TODO | 3 | |
| Search Attributes (Visibility) | — | ✓ | 4 | — | — | — | — | |
| Debugging with Event History | — | — | — | — | — | — | — | |
| Best Practices | — | ✓ | 5 | ✓ | 5 | TODO | 4 | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Removed verbose sections |
| Ruby | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created
- Ruby column: all TODO — Ruby files not yet created

**Intentionally missing (`—`):**
- Core column: no core observability.md exists (implementation-specific)
- Search Attributes: Python includes as observability concept; TS and Ruby keep in data-handling.md
- Customizing the Logger: Ruby's `Temporalio::Workflow.logger` is straightforward; mention inline in Logging section like Python

**Ruby notes:**
- Logging: `Temporalio::Workflow.logger` is replay-aware; `Temporalio::Activity::Context.current.logger` for activities
- Metrics: `Temporalio::Runtime::MetricsOptions` with Prometheus (`PrometheusMetricsOptions`) or custom `MetricBuffer`
- OpenTelemetry: `Temporalio::Contrib::OpenTelemetry::TracingInterceptor` — mentioned inline, not separate section (matching Python/TS style)
- Ruby has Unsafe.replaying? for side-effect guards: `unless Temporalio::Workflow::Unsafe.replaying?`

**Order alignment:** ✓ Aligned — Ruby follows Python order (compact, 4 sections)

**Style alignment:** ✅ Complete (Python/TypeScript). Ruby should follow same concise structure.
