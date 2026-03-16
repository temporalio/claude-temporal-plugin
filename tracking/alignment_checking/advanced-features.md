# advanced-features.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Go | Go# |
|---------|------|--------|-----|------------|-----|-----|-----|
| Schedules | — | ✓ | 1 | ✓ | 1 | TODO | 1 |
| Async Activity Completion | — | ✓ | 2 | ✓ | 2 | TODO | 2 |
| Sandbox Customization | — | ✓ | 3 | — | — | — | — |
| Gevent Compatibility Warning | — | ✓ | 4 | — | — | — | — |
| Worker Tuning | — | ✓ | 5 | ✓ | 3 | TODO | 3 |
| Workflow Init Decorator | — | ✓ | 6 | — | — | — | — |
| Workflow Failure Exception Types | — | ✓ | 7 | — | — | — | — |
| Sessions | — | — | — | — | — | TODO | 4 |
| Interceptors | — | — | — | — | — | — | — |
| Continue-as-New | — | — | — | — | — | — | — |
| Workflow Updates | — | — | — | — | — | — | — |
| Nexus Operations | — | — | — | — | — | — | — |
| Activity Cancellation and Heartbeating | — | — | — | — | — | — | — |
| Sinks | — | — | — | ✓ | 4 | — | — |
| CancellationScope Patterns | — | — | — | — | — | — | — |
| Best Practices | — | — | — | — | — | — | — |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | 7 sections |
| TypeScript | ✓ aligned | 4 sections (removed duplicates) |
| Go | TODO | 4 sections — Schedules, Async Completion, Worker Tuning, Sessions |

## Status

**Sections needing review (TODO cells):**
- Go column: TODO items — Go files to be created

**Go-specific notes:**
- Schedules: `client.ScheduleClient` — same concept as Python/TS
- Async Activity Completion: `activity.GetInfo(ctx).TaskToken` + `client.CompleteActivity` / `client.CompleteActivityByID`
- Worker Tuning: `worker.Options` — `MaxConcurrentActivityExecutionSize`, `MaxConcurrentWorkflowTaskExecutionSize`, `MaxConcurrentActivityTaskPollers`
- Sessions: Go-specific feature — `workflow.CreateSession(ctx, options)` pins activities to a specific worker. Useful for file processing where activities need local state.
**Intentionally missing (`—`):**
- Core column: advanced features are implementation-specific
- Sandbox Customization: Python-specific; Go has no sandbox
- Gevent Compatibility Warning: Python-specific
- Workflow Init Decorator: Python-specific
- Workflow Failure Exception Types: Python-specific
- Sinks: TS-specific feature
- Sessions: Go-specific (not in Python/TS)
- Interceptors: Decided not to include for any language (all SDKs have them, but too advanced for current scope)

**Order alignment:** N/A — Files have different structures by design

**Style alignment:** ✅ Complete (Python, TypeScript)
