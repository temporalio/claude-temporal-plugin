# determinism-protection.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Ruby | Rb# | Go |
|---------|------|--------|-----|------------|-----|------|-----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | TODO | 1 | |
| How the Sandbox Works | — | ✓ | 2 | — | — | — | — | |
| How Illegal Call Tracing Works | — | — | — | — | — | TODO | 2 | |
| Import Blocking | — | — | — | ✓ | 2 | — | — | |
| Forbidden Operations | — | ✓ | 3 | — | — | TODO | 3 | |
| Function Replacement | — | — | — | ✓ | 3 | — | — | |
| Durable Fiber Scheduler | — | — | — | — | — | TODO | 4 | |
| Pass-Through Pattern | — | ✓ | 4 | — | — | — | — | |
| Importing Activities | — | ✓ | 5 | — | — | — | — | |
| Disabling the Sandbox | — | ✓ | 6 | — | — | — | — | |
| Disabling Illegal Call Tracing | — | — | — | — | — | TODO | 5 | |
| Customizing Invalid Module Members | — | ✓ | 7 | — | — | — | — | |
| Customizing Illegal Calls | — | — | — | — | — | TODO | 6 | |
| Import Notification Policy | — | ✓ | 8 | — | — | — | — | |
| Disable Lazy sys.modules Passthrough | — | ✓ | 9 | — | — | — | — | |
| File Organization | — | ✓ | 10 | — | — | — | — | |
| Common Issues | — | ✓ | 11 | — | — | TODO | 7 | |
| Best Practices | — | ✓ | 12 | — | — | TODO | 8 | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | Comprehensive (12 sections) |
| TypeScript | ✓ aligned | Minimal (3 sections) — V8 is automatic |
| Ruby | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created
- Ruby column: all TODO — Ruby files not yet created

**Intentionally missing (`—`):**
- Core column: no core file (sandbox implementation is language-specific)
- Most sections are language-specific due to different sandbox/protection architectures:
  - Python: Pass-through pattern, customization APIs, notification policies (sandbox-based)
  - TypeScript: Import blocking, function replacement (V8-specific)
  - Ruby: Illegal call tracing, durable fiber scheduler, customization (TracePoint-based)

**Ruby notes:**
- Ruby's approach is fundamentally different from Python (sandbox) and TS (V8): uses TracePoint for illegal call tracing + custom Fiber::Scheduler for durable fibers
- "How Illegal Call Tracing Works": TracePoint catches illegal calls on workflow thread, configurable via `illegal_workflow_calls` worker param
- "Durable Fiber Scheduler": Custom Fiber::Scheduler makes fibers deterministic; `Kernel.sleep`, `Mutex` etc. are disabled by default even though they'd technically work
- "Disabling Illegal Call Tracing": `Temporalio::Workflow::Unsafe.illegal_call_tracing_disabled` block
- "Customizing Illegal Calls": `illegal_workflow_calls` parameter on worker, `Temporalio::Worker.default_illegal_workflow_calls`
- "Disabling" equivalents: `durable_scheduler_disabled` (implies `illegal_call_tracing_disabled`), `io_enabled` for IO wait
- Python's Import/Module sections don't apply (Ruby doesn't have module-level sandbox)
- Ruby estimated ~8 sections (moderate — more than TS's 3, less than Python's 12)

**Order alignment:** N/A — files have completely different structures (Python: 12 sections, TS: 3 sections, Ruby: ~8 sections)

**Style alignment:** ⚠️ Very different structures (intentional, different protection architectures)
- Python: Comprehensive (12 sections) — complex sandbox with many customization options
- TypeScript: Minimal (3 sections) — V8 sandbox is mostly automatic
- Ruby: Moderate (~8 sections) — TracePoint + Fiber Scheduler with customization options
- This is appropriate given the different protection architectures
