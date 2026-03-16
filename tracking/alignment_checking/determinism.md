# determinism.md

## Section Inventory

| Section | Core | Core# | Python | Py# | TypeScript | TS# | Ruby | Rb# | Go |
|---------|------|-------|--------|-----|------------|-----|------|-----|-----|
| Overview | ✓ | 1 | ✓ | 1 | ✓ | 1 | TODO | 1 | |
| Why Determinism Matters | ✓ | 2 | ✓ | 2 | ✓ | 2 | TODO | 2 | |
| Sources of Non-Determinism | ✓ | 3 | — | — | — | — | — | — | |
| Central Concept: Activities | ✓ | 4 | — | — | — | — | — | — | |
| SDK Protection / Sandbox | ✓ | 5 | ✓ | 6 | ✓ | 3 | TODO | 3 | |
| Forbidden Operations | — | — | ✓ | 3 | ✓ | 4 | TODO | 4 | |
| Safe Builtin Alternatives | — | — | ✓ | 4 | — | — | TODO | 5 | |
| Detecting Non-Determinism | ✓ | 6 | — | — | — | — | — | — | |
| Recovery from Non-Determinism | ✓ | 7 | — | — | — | — | — | — | |
| Testing Replay Compatibility | — | — | ✓ | 5 | ✓ | 5 | TODO | 6 | |
| Best Practices | ✓ | 8 | ✓ | 7 | ✓ | 6 | TODO | 7 | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Core | ✓ reference | Deep conceptual content |
| Python | ✓ aligned | Practical focus |
| TypeScript | ✓ aligned | Practical focus, V8 sandbox |
| Ruby | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created
- Ruby column: all TODO — Ruby files not yet created

**Intentionally missing (`—`):**
- Sources of Non-Determinism: Core-only (conceptual categories)
- Central Concept: Activities: Core-only (conceptual)
- Forbidden Operations: Language-specific (Core covers in Sources)
- Safe Builtin Alternatives: Python-only table; Ruby should have equivalent (Ruby has `Temporalio::Workflow.random`, `Temporalio::Workflow.now`, `Temporalio::Workflow.sleep`, `Temporalio::Workflow.logger`)
- Detecting Non-Determinism: Core-only
- Recovery from Non-Determinism: Core-only
- Testing Replay Compatibility: Language-specific (Core covers in Detecting)

**Ruby notes:**
- Ruby's determinism protection uses Illegal Call Tracing (TracePoint) + Durable Fiber Scheduler — distinct from Python sandbox and TS V8 sandbox
- Ruby's TracePoint catches illegal calls like `sleep`, `Time.now`, `Thread.new` at runtime
- Ruby has safe alternatives: `Temporalio::Workflow.sleep`, `Temporalio::Workflow.now`, `Temporalio::Workflow.random`, `Temporalio::Workflow.logger`
- Safe Builtin Alternatives section is appropriate for Ruby (similar to Python's table, but with Ruby-specific mappings)
- Forbidden Operations section should list Ruby-specific illegal calls (e.g., `Kernel.sleep`, `Time.now` without args, `Thread.new`, `IO` operations)

**Order alignment:** N/A — different structures by design (Core#5 SDK Protection → Py#6, TS#3, Rb#3; languages have Forbidden Operations which Core covers in Sources)

**Style alignment:** ✓ Well aligned (Python/TypeScript)
- Core: Deep conceptual content (replay mechanism, commands/events, recovery)
- Python: Practical focus (forbidden operations, safe alternatives table, sandbox)
- TypeScript: Practical focus (V8 sandbox, forbidden operations). Removed dedicated UUID section (now brief mention in V8 Sandbox).
- Safe Builtin Alternatives intentionally Python-only (TS V8 sandbox handles automatically); Ruby should also have this (TracePoint doesn't auto-replace)
- Good division: Core explains "why", languages explain "how"
