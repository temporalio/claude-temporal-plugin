# advanced-features.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Ruby | Rb# | Go |
|---------|------|--------|-----|------------|-----|------|-----|-----|
| Schedules | — | ✓ | 1 | ✓ | 1 | TODO | 1 | |
| Async Activity Completion | — | ✓ | 2 | ✓ | 2 | TODO | 2 | |
| Sandbox Customization | — | ✓ | 3 | — | — | — | — | |
| Gevent Compatibility Warning | — | ✓ | 4 | — | — | — | — | |
| Worker Tuning | — | ✓ | 5 | ✓ | 3 | TODO | 3 | |
| Workflow Init Decorator | — | ✓ | 6 | — | — | — | — | |
| Workflow Failure Exception Types | — | ✓ | 7 | — | — | TODO | 4 | |
| Continue-as-New | — | — | — | — | — | — | — | |
| Workflow Updates | — | — | — | — | — | — | — | |
| Nexus Operations | — | — | — | — | — | — | — | |
| Activity Cancellation and Heartbeating | — | — | — | — | — | — | — | |
| Sinks | — | — | — | ✓ | 4 | — | — | |
| Activity Concurrency and Executors | — | — | — | — | — | TODO | 5 | |
| Rails Integration | — | — | — | — | — | TODO | 6 | |
| CancellationScope Patterns | — | — | — | — | — | — | — | |
| Best Practices | — | — | — | — | — | — | — | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | 7 sections |
| TypeScript | ✓ aligned | 4 sections (removed duplicates) |
| Ruby | — | Not started |
| Go | ✓ aligned | 4 sections — Schedules, Async Completion, Worker Tuning, Sessions |

## Status

**Intentionally missing (`—`):**
- Core column: advanced features are implementation-specific
- Sandbox Customization: Python-specific; Ruby/Go have no sandbox
- Gevent Compatibility Warning: Python-specific
- Workflow Init Decorator: Python-specific (`@workflow.init`); Ruby uses `initialize` naturally; Go N/A
- Sinks: TS-specific feature
- Workflow Failure Exception Types: Python has `workflow_failure_exception_types`; Ruby has similar `workflow_failure_exception_type` class method — should include; Go: Python-specific
- Sessions: Go-specific (not in Python/TS/Ruby)
- Interceptors: Decided not to include for any language (all SDKs have them, but too advanced for current scope)

**Ruby notes:**
- Schedules: `Temporalio::Client::ScheduleHandle` — same API pattern as other SDKs
- Async Activity Completion: `Temporalio::Client::AsyncActivityHandle` for completing activities from external processes
- Worker Tuning: `max_concurrent_workflow_tasks`, `max_concurrent_activities`, resource-based auto-tuning
- Workflow Failure Exception Types: `workflow_failure_exception_type` on workflow class or `workflow_failure_exception_types` on worker
- Activity Concurrency and Executors: Ruby-specific — `Temporalio::Worker::ActivityExecutor::ThreadPool`, fiber-based execution, `max_concurrent_activities`
- Rails Integration: Ruby-specific — ActiveRecord concerns, lazy/eager loading, Zeitwerk compatibility

**Go notes:**
- Schedules: `client.ScheduleClient` — same concept as Python/TS
- Async Activity Completion: `activity.GetInfo(ctx).TaskToken` + `client.CompleteActivity` / `client.CompleteActivityByID`
- Worker Tuning: `worker.Options` — `MaxConcurrentActivityExecutionSize`, `MaxConcurrentWorkflowTaskExecutionSize`, `MaxConcurrentActivityTaskPollers`
- Sessions: Go-specific feature — `workflow.CreateSession(ctx, options)` pins activities to a specific worker. Useful for file processing where activities need local state.

**Sections needing review (empty cells):**
- Ruby column: all TODO — Ruby reference files not yet created

**Order alignment:** N/A — Files have different structures by design

**Style alignment:** ✅ Complete (Python, TypeScript, Go)
- Python: 7 sections (Schedules, Async Activity Completion, Sandbox Customization, Gevent Warning, Worker Tuning, Workflow Init, Failure Exception Types)
- TypeScript: 4 sections (Schedules, Async Activity Completion, Worker Tuning, Sinks)
- Go: 4 sections (Schedules, Async Completion, Worker Tuning, Sessions)
- Ruby: ~6 sections planned (Schedules, Async Activity Completion, Worker Tuning, Failure Exception Types, Activity Concurrency/Executors, Rails Integration)
- Removed duplicates from TS (Continue-as-New, Workflow Updates, CancellationScope Patterns, Nexus Operations, Activity Cancellation, Best Practices — all covered elsewhere)
