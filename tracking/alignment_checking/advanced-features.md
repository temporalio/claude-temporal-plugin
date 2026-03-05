# advanced-features.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Go |
|---------|------|--------|-----|------------|-----|-----|
| Schedules | — | ✓ | 1 | ✓ | 1 | |
| Async Activity Completion | — | ✓ | 2 | ✓ | 2 | |
| Sandbox Customization | — | ✓ | 3 | — | — | |
| Gevent Compatibility Warning | — | ✓ | 4 | — | — | |
| Worker Tuning | — | ✓ | 5 | ✓ | 3 | |
| Workflow Init Decorator | — | ✓ | 6 | — | — | |
| Workflow Failure Exception Types | — | ✓ | 7 | — | — | |
| Continue-as-New | — | — | — | — | — | |
| Workflow Updates | — | — | — | — | — | |
| Nexus Operations | — | — | — | — | — | |
| Activity Cancellation and Heartbeating | — | — | — | — | — | |
| Sinks | — | — | — | ✓ | 4 | |
| CancellationScope Patterns | — | — | — | — | — | |
| Best Practices | — | — | — | — | — | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | 7 sections |
| TypeScript | ✓ aligned | 4 sections (removed duplicates) |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Intentionally missing (`—`):**
- Core column: advanced features are implementation-specific
- Sandbox Customization: TS has determinism-protection.md directly
- Gevent Compatibility Warning: Python-specific
- Workflow Init Decorator: Python-specific (@workflow.init)
- Workflow Failure Exception Types: Python-specific
- Sinks: TS-specific feature

**Order alignment:** N/A — Files have different structures by design (language-specific advanced features)

**Style alignment:** ✅ Complete
- Python: 7 sections (Schedules, Async Activity Completion, Sandbox Customization, Gevent Warning, Worker Tuning, Workflow Init, Failure Exception Types)
- TypeScript: 4 sections (Schedules, Async Activity Completion, Worker Tuning, Sinks)
- Removed duplicates from TS (Continue-as-New, Workflow Updates, CancellationScope Patterns, Nexus Operations, Activity Cancellation, Best Practices — all covered elsewhere)
