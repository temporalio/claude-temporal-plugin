# advanced-features.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Java | J# | Go | Go# |
|---------|------|--------|-----|------------|-----|------|----|----|-----|
| Schedules | — | ✓ | 1 | ✓ | 1 | TODO | 1 | ✓ | 1 |
| Async Activity Completion | — | ✓ | 2 | ✓ | 2 | TODO | 2 | ✓ | 2 |
| Sandbox Customization | — | ✓ | 3 | — | — | — | — | — | — |
| Gevent Compatibility Warning | — | ✓ | 4 | — | — | — | — | — | — |
| Worker Tuning | — | ✓ | 5 | ✓ | 3 | TODO | 3 | ✓ | 3 |
| Workflow Init Decorator | — | ✓ | 6 | — | — | — | — | — | — |
| Workflow Failure Exception Types | — | ✓ | 7 | — | — | TODO | 4 | — | — |
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
| Go | ✓ aligned | 4 sections — Schedules, Async Completion, Worker Tuning, Sessions |
| Java | — | Not started |

## Status

**Go-specific notes:**
- Schedules: `client.ScheduleClient` — same concept as Python/TS
- Async Activity Completion: `activity.GetInfo(ctx).TaskToken` + `client.CompleteActivity` / `client.CompleteActivityByID`
- Worker Tuning: `worker.Options` — `MaxConcurrentActivityExecutionSize`, `MaxConcurrentWorkflowTaskExecutionSize`, `MaxConcurrentActivityTaskPollers`
- Sessions: Go-specific feature — `workflow.CreateSession(ctx, options)` pins activities to a specific worker. Useful for file processing where activities need local state.

**Java column decisions:**
- Schedules: Java has full Schedule API (`ScheduleClient`, `Schedule.newBuilder()`)
- Async Activity Completion: Java has `ActivityCompletionClient` for completing activities from external processes
- Worker Tuning: Java has `WorkerOptions.newBuilder()` with `setMaxConcurrentWorkflowTaskExecutionSize()`, `setMaxConcurrentActivityExecutionSize()`, etc.
- Workflow Failure Exception Types: Java has similar behavior — only `ApplicationFailure` fails workflows, other exceptions cause workflow task retry. `WorkflowImplementationOptions.setFailWorkflowExceptionTypes()` can override.
- Sandbox Customization: — (Java has no sandbox)
- Gevent Compatibility Warning: — (Python-specific)
- Workflow Init Decorator: — (Python-specific `@workflow.init`; Java doesn't have equivalent — workflow constructors serve a different purpose)
- Sinks: — (TS-specific feature)

**Intentionally missing (`—`):**
- Core column: advanced features are implementation-specific
- Sandbox Customization: Python-specific (TS has determinism-protection.md, Java has no sandbox, Go has no sandbox)
- Gevent Compatibility Warning: Python-specific
- Workflow Init Decorator: Python-specific (@workflow.init)
- Sinks: TS-specific feature
- Sessions: Go-specific
- Interceptors: Decided not to include for any language (all SDKs have them, but too advanced for current scope)
- Continue-as-New, Workflow Updates, CancellationScope Patterns, Nexus Operations, Activity Cancellation, Best Practices: all covered elsewhere

**Order alignment:** N/A — Files have different structures by design

**Style alignment:** ✅ Complete (Python, TypeScript)
- Python: 7 sections (Schedules, Async Activity Completion, Sandbox Customization, Gevent Warning, Worker Tuning, Workflow Init, Failure Exception Types)
- TypeScript: 4 sections (Schedules, Async Activity Completion, Worker Tuning, Sinks)
- Java: 4 sections planned (Schedules, Async Activity Completion, Worker Tuning, Workflow Failure Exception Types)

