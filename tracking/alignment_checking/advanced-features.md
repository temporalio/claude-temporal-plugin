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
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created
- Ruby column: all TODO — Ruby files not yet created

**Intentionally missing (`—`):**
- Core column: advanced features are implementation-specific
- Sandbox Customization: Python-specific; Ruby covers in determinism-protection.md
- Gevent Compatibility Warning: Python-specific
- Workflow Init Decorator: Python-specific (`@workflow.init`); Ruby uses `initialize` method naturally
- Sinks: TS-specific feature
- Workflow Failure Exception Types: Python has `workflow_failure_exception_types`; Ruby has similar `workflow_failure_exception_type` class method — should include

**Ruby notes:**
- Schedules: `Temporalio::Client::ScheduleHandle` — same API pattern as other SDKs
- Async Activity Completion: `Temporalio::Client::AsyncActivityHandle` for completing activities from external processes
- Worker Tuning: `max_concurrent_workflow_tasks`, `max_concurrent_activities`, resource-based auto-tuning
- Workflow Failure Exception Types: `workflow_failure_exception_type` on workflow class or `workflow_failure_exception_types` on worker
- Activity Concurrency and Executors: Ruby-specific — `Temporalio::Worker::ActivityExecutor::ThreadPool`, fiber-based execution, `max_concurrent_activities`
- Rails Integration: Ruby-specific — ActiveRecord concerns, lazy/eager loading, Zeitwerk compatibility
- These last two are Ruby-specific features not present in Python/TS

**Order alignment:** N/A — Files have different structures by design (language-specific advanced features)

**Style alignment:** ✅ Complete (Python/TypeScript)
- Python: 7 sections (Schedules, Async Activity Completion, Sandbox Customization, Gevent Warning, Worker Tuning, Workflow Init, Failure Exception Types)
- TypeScript: 4 sections (Schedules, Async Activity Completion, Worker Tuning, Sinks)
- Ruby: ~6 sections (Schedules, Async Activity Completion, Worker Tuning, Failure Exception Types, Activity Concurrency/Executors, Rails Integration)
- Removed duplicates from TS (Continue-as-New, Workflow Updates, CancellationScope Patterns, Nexus Operations, Activity Cancellation, Best Practices — all covered elsewhere)
