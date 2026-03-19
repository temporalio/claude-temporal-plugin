# advanced-features.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Go | PHP | PHP# |
|---------|------|--------|-----|------------|-----|----|-----|------|
| Schedules | — | ✓ | 1 | ✓ | 1 | | ✓ | 1 |
| Async Activity Completion | — | ✓ | 2 | ✓ | 2 | | ✓ | 2 |
| Sandbox Customization | — | ✓ | 3 | — | — | | — | — |
| Gevent Compatibility Warning | — | ✓ | 4 | — | — | | — | — |
| Worker Tuning | — | ✓ | 5 | ✓ | 3 | | ✓ | 3 |
| Workflow Init Decorator | — | ✓ | 6 | — | — | | — | — |
| Workflow Failure Exception Types | — | ✓ | 7 | — | — | | — | — |
| RoadRunner Configuration | — | — | — | — | — | | ✓ | 4 |
| Continue-as-New | — | — | — | — | — | | | |
| Workflow Updates | — | — | — | — | — | | | |
| Nexus Operations | — | — | — | — | — | | | |
| Activity Cancellation and Heartbeating | — | — | — | — | — | | | |
| Sinks | — | — | — | ✓ | 4 | | — | — |
| CancellationScope Patterns | — | — | — | — | — | | | |
| Best Practices | — | — | — | — | — | | | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | 7 sections |
| TypeScript | ✓ aligned | 4 sections (removed duplicates) |
| Go | ✓ aligned | 4 sections — Schedules, Async Completion, Worker Tuning, Sessions |
| PHP | ✓ aligned | 4 sections (Schedules, Async Activity Completion, Worker Tuning, RoadRunner Configuration) |

## Status

**Go-specific notes:**
- Schedules: `client.ScheduleClient` — same concept as Python/TS
- Async Activity Completion: `activity.GetInfo(ctx).TaskToken` + `client.CompleteActivity` / `client.CompleteActivityByID`
- Worker Tuning: `worker.Options` — `MaxConcurrentActivityExecutionSize`, `MaxConcurrentWorkflowTaskExecutionSize`, `MaxConcurrentActivityTaskPollers`
- Sessions: Go-specific feature — `workflow.CreateSession(ctx, options)` pins activities to a specific worker. Useful for file processing where activities need local state.
**Intentionally missing (`—`):**
- Core column: advanced features are implementation-specific
- Sandbox Customization: Python-specific; PHP/Go have no sandbox
- Gevent Compatibility Warning: Python-specific
- Workflow Init Decorator: Python-specific (@workflow.init); PHP has #[WorkflowInit] but not an "advanced" feature
- Workflow Failure Exception Types: Python-specific
- Sinks: TS-specific feature
- Sessions: Go-specific (not in Python/TS/PHP)
- Interceptors: Decided not to include for any language (all SDKs have them, but too advanced for current scope)

**PHP-specific additions:**
- RoadRunner Configuration: PHP-specific (no equivalent in Python/TS/Go)

**Order alignment:** N/A — Files have different structures by design

**Style alignment:** ✅ Complete (Python, TypeScript, Go, PHP)
- Python: 7 sections (Schedules, Async Activity Completion, Sandbox Customization, Gevent Warning, Worker Tuning, Workflow Init, Failure Exception Types)
- TypeScript: 4 sections (Schedules, Async Activity Completion, Worker Tuning, Sinks)
- Go: 4 sections (Schedules, Async Activity Completion, Worker Tuning, Sessions)
- PHP: 4 sections (Schedules, Async Activity Completion, Worker Tuning, RoadRunner Configuration)
- Removed duplicates from TS (Continue-as-New, Workflow Updates, CancellationScope Patterns, Nexus Operations, Activity Cancellation, Best Practices — all covered elsewhere)
