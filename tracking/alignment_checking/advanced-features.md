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
| Go | — | Not started |
| PHP | ✓ aligned | 4 sections (Schedules, Async Activity Completion, Worker Tuning, RoadRunner Configuration) |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Intentionally missing (`—`):**
- Core column: advanced features are implementation-specific
- Sandbox Customization: TS has determinism-protection.md directly; PHP has no sandbox
- Gevent Compatibility Warning: Python-specific
- Workflow Init Decorator: Python-specific (@workflow.init); PHP has #[WorkflowInit] but not an "advanced" feature
- Workflow Failure Exception Types: Python-specific
- Sinks: TS-specific feature

**PHP-specific additions:**
- RoadRunner Configuration: PHP-specific (no equivalent in Python/TS)

**Order alignment:** N/A — Files have different structures by design (language-specific advanced features)

**Style alignment:** ✅ Complete
- Python: 7 sections (Schedules, Async Activity Completion, Sandbox Customization, Gevent Warning, Worker Tuning, Workflow Init, Failure Exception Types)
- TypeScript: 4 sections (Schedules, Async Activity Completion, Worker Tuning, Sinks)
- PHP: 4 sections (Schedules, Async Activity Completion, Worker Tuning, RoadRunner Configuration)
- Removed duplicates from TS (Continue-as-New, Workflow Updates, CancellationScope Patterns, Nexus Operations, Activity Cancellation, Best Practices — all covered elsewhere)
