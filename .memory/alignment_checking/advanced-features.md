# advanced-features.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | .NET | DN# | Go | Go# |
|---------|------|--------|-----|------------|-----|------|-----|----|-----|
| Schedules | — | ✓ | 1 | ✓ | 1 | ✓ | 1 | ✓ | 1 |
| Async Activity Completion | — | ✓ | 2 | ✓ | 2 | ✓ | 2 | ✓ | 2 |
| Sandbox Customization | — | ✓ | 3 | — | — | — | — | — | — |
| Gevent Compatibility Warning | — | ✓ | 4 | — | — | — | — | — | — |
| Worker Tuning | — | ✓ | 5 | ✓ | 3 | ✓ | 3 | ✓ | 3 |
| Workflow Init Decorator | — | ✓ | 6 | — | — | ✓ | 4 | — | — |
| Workflow Failure Exception Types | — | ✓ | 7 | — | — | ✓ | 5 | — | — |
| Dependency Injection | — | — | — | — | — | ✓ | 6 | — | — |
| Sessions | — | — | — | — | — | — | — | ✓ | 4 |
| Continue-as-New | — | — | — | — | — | — | — | — | — |
| Workflow Updates | — | — | — | — | — | — | — | — | — |
| Nexus Operations | — | — | — | — | — | — | — | — | — |
| Activity Cancellation and Heartbeating | — | — | — | — | — | — | — | — | — |
| Sinks | — | — | — | ✓ | 4 | — | — | — | — |
| CancellationScope Patterns | — | — | — | — | — | — | — | — | — |
| Best Practices | — | — | — | — | — | — | — | — | — |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | 7 sections |
| TypeScript | ✓ aligned | 4 sections (removed duplicates) |
| .NET | ✓ aligned | 6 sections — Schedules, Async Completion, Worker Tuning, Workflow Init, Failure Exception Types, DI |
| Go | ✓ aligned | 4 sections — Schedules, Async Completion, Worker Tuning, Sessions |

## Status

**Go-specific notes:**
- Schedules: `client.ScheduleClient` — same concept as Python/TS
- Async Activity Completion: `activity.GetInfo(ctx).TaskToken` + `client.CompleteActivity` / `client.CompleteActivityByID`
- Worker Tuning: `worker.Options` — `MaxConcurrentActivityExecutionSize`, `MaxConcurrentWorkflowTaskExecutionSize`, `MaxConcurrentActivityTaskPollers`
- Sessions: Go-specific feature — `workflow.CreateSession(ctx, options)` pins activities to a specific worker. Useful for file processing where activities need local state.
**Intentionally missing (`—`):**
- Core column: advanced features are implementation-specific
- Sandbox Customization: Python-specific; .NET/Go have no sandbox
- Gevent Compatibility Warning: Python-specific
- Workflow Init Decorator: Python-specific (@workflow.init)
- Workflow Failure Exception Types: Python and .NET (see .NET notes)
- Sinks: TS-specific feature
- Sessions: Go-specific (not in Python/TS/.NET)
- Interceptors: Decided not to include for any language (all SDKs have them, but too advanced for current scope)

**.NET alignment notes:**
- Workflow Failure Exception Types: ✓ for .NET — only `ApplicationFailureException` fails a workflow; other exceptions retry the workflow task.
- Dependency Injection: NEW .NET-specific section — `Temporalio.Extensions.Hosting` package, `AddTemporalClient()`, generic host worker setup, activity DI.
- .NET gets 6 sections (Schedules, Async Activity Completion, Worker Tuning, Workflow Init, Workflow Failure Exception Types, Dependency Injection)

**Order alignment:** N/A — Files have different structures by design

**Style alignment:** ✅ Complete (Python, TypeScript, Go)
- Python: 7 sections (Schedules, Async Activity Completion, Sandbox Customization, Gevent Warning, Worker Tuning, Workflow Init, Failure Exception Types)
- TypeScript: 4 sections (Schedules, Async Activity Completion, Worker Tuning, Sinks)
- Go: 4 sections (Schedules, Async Activity Completion, Worker Tuning, Sessions)
- .NET: 6 sections (Schedules, Async Activity Completion, Worker Tuning, Workflow Init, Workflow Failure Exception Types, Dependency Injection)
- Removed duplicates from TS (Continue-as-New, Workflow Updates, CancellationScope Patterns, Nexus Operations, Activity Cancellation, Best Practices — all covered elsewhere)
