# determinism-protection.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | .NET | DN# | Go |
|---------|------|--------|-----|------------|-----|------|-----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | TODO | 1 | |
| How the Sandbox Works | — | ✓ | 2 | — | — | — | — | |
| Import Blocking | — | — | — | ✓ | 2 | — | — | |
| Forbidden Operations | — | ✓ | 3 | — | — | — | — | |
| Function Replacement | — | — | — | ✓ | 3 | — | — | |
| Runtime Task Detection | — | — | — | — | — | TODO | 2 | |
| .NET Task Determinism Rules | — | — | — | — | — | TODO | 3 | |
| Workflow .editorconfig | — | — | — | — | — | TODO | 4 | |
| Pass-Through Pattern | — | ✓ | 4 | — | — | — | — | |
| Importing Activities | — | ✓ | 5 | — | — | — | — | |
| Disabling the Sandbox | — | ✓ | 6 | — | — | — | — | |
| Customizing Invalid Module Members | — | ✓ | 7 | — | — | — | — | |
| Import Notification Policy | — | ✓ | 8 | — | — | — | — | |
| Disable Lazy sys.modules Passthrough | — | ✓ | 9 | — | — | — | — | |
| File Organization | — | ✓ | 10 | — | — | — | — | |
| Common Issues | — | ✓ | 11 | — | — | — | — | |
| Best Practices | — | ✓ | 12 | — | — | TODO | 5 | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | Comprehensive (12 sections) |
| TypeScript | ✓ aligned | Minimal (3 sections) — V8 is automatic |
| .NET | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Intentionally missing (`—`):**
- Core column: no core file (sandbox implementation is language-specific)
- Most sections are language-specific due to different sandbox architectures:
  - Python: Pass-through pattern, customization APIs, notification policies (complex sandbox)
  - TypeScript: Import blocking, function replacement (V8-specific)
  - .NET: No sandbox at all — relies on runtime detection and developer discipline

**.NET alignment notes:**
- .NET has NO sandbox (unlike Python and TypeScript). Key differences:
  - Python: Full sandbox with import restrictions, pass-through pattern, customization APIs
  - TypeScript: V8 isolate with import blocking and function replacement
  - .NET: Custom TaskScheduler + runtime EventListener that detects invalid task scheduling
- .NET gets 5 sections (small, like TS's 3):
  1. Overview: Explains .NET's approach — no sandbox, developer discipline + runtime detection
  2. Runtime Task Detection: EventListener for task events, `InvalidWorkflowOperationException`, `DisableWorkflowTracingEventListener` option
  3. .NET Task Determinism Rules: Comprehensive list of what to avoid (Task.Run, Task.Delay, ConfigureAwait(false), etc.) and safe alternatives (Workflow.RunTaskAsync, Workflow.DelayAsync, etc.)
  4. Workflow .editorconfig: Recommended analyzer/editor config settings for workflow projects
  5. Best Practices: Summary of best practices for deterministic .NET workflow code

**Order alignment:** N/A — files have completely different structures (Python: 12 sections, TS: 3 sections, .NET: 5 sections)

**Style alignment:** ⚠️ Very different structures (intentional, different protection mechanisms)
- Python: Comprehensive (12 sections) — complex sandbox with many customization options
- TypeScript: Minimal (3 sections) — V8 sandbox is mostly automatic
- .NET: Medium (5 sections) — no sandbox, but extensive Task gotchas need documenting
- This is appropriate given the different determinism protection approaches
