# advanced-features.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | .NET | DN# | Go |
|---------|------|--------|-----|------------|-----|------|-----|-----|
| Schedules | — | ✓ | 1 | ✓ | 1 | TODO | 1 | |
| Async Activity Completion | — | ✓ | 2 | ✓ | 2 | TODO | 2 | |
| Sandbox Customization | — | ✓ | 3 | — | — | — | — | |
| Gevent Compatibility Warning | — | ✓ | 4 | — | — | — | — | |
| Worker Tuning | — | ✓ | 5 | ✓ | 3 | TODO | 3 | |
| Workflow Init Decorator | — | ✓ | 6 | — | — | — | — | |
| Workflow Failure Exception Types | — | ✓ | 7 | — | — | TODO | 4 | |
| Dependency Injection | — | — | — | — | — | TODO | 5 | |
| Continue-as-New | — | — | — | — | — | — | — | |
| Workflow Updates | — | — | — | — | — | — | — | |
| Nexus Operations | — | — | — | — | — | — | — | |
| Activity Cancellation and Heartbeating | — | — | — | — | — | — | — | |
| Sinks | — | — | — | ✓ | 4 | — | — | |
| CancellationScope Patterns | — | — | — | — | — | — | — | |
| Best Practices | — | — | — | — | — | — | — | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | 7 sections |
| TypeScript | ✓ aligned | 4 sections (removed duplicates) |
| .NET | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Intentionally missing (`—`):**
- Core column: advanced features are implementation-specific
- Sandbox Customization: TS has determinism-protection.md directly; .NET has no sandbox
- Gevent Compatibility Warning: Python-specific
- Workflow Init Decorator: Python-specific (@workflow.init)
- Sinks: TS-specific feature

**.NET alignment notes:**
- Workflow Failure Exception Types: ✓ for .NET — important to document that only `ApplicationFailureException` fails a workflow; other exceptions retry the workflow task. Similar concept to Python's section but with .NET-specific exception types.
- Dependency Injection: NEW .NET-specific section — `Temporalio.Extensions.Hosting` package, `AddTemporalClient()`, generic host worker setup, activity DI. This is a major .NET idiom not applicable to Python/TS.
- .NET gets 5 sections (Schedules, Async Activity Completion, Worker Tuning, Workflow Failure Exception Types, Dependency Injection)

**Order alignment:** N/A — Files have different structures by design (language-specific advanced features)

**Style alignment:** ✅ Complete (Python/TS)
- Python: 7 sections (Schedules, Async Activity Completion, Sandbox Customization, Gevent Warning, Worker Tuning, Workflow Init, Failure Exception Types)
- TypeScript: 4 sections (Schedules, Async Activity Completion, Worker Tuning, Sinks)
- .NET: 5 sections planned (Schedules, Async Activity Completion, Worker Tuning, Workflow Failure Exception Types, Dependency Injection)
- Removed duplicates from TS (Continue-as-New, Workflow Updates, CancellationScope Patterns, Nexus Operations, Activity Cancellation, Best Practices — all covered elsewhere)
