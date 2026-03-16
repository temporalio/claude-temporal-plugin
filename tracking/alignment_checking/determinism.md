# determinism.md

## Section Inventory

| Section | Core | Core# | Python | Py# | TypeScript | TS# | .NET | DN# | Go |
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
| .NET | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Intentionally missing (`—`):**
- Sources of Non-Determinism: Core-only (conceptual categories)
- Central Concept: Activities: Core-only (conceptual)
- Forbidden Operations: Language-specific (Core covers in Sources)
- Safe Builtin Alternatives: Python-only (table format) — BUT .NET also needs this (see below)
- Detecting Non-Determinism: Core-only
- Recovery from Non-Determinism: Core-only
- Testing Replay Compatibility: Language-specific (Core covers in Detecting)

**.NET alignment notes:**
- Safe Builtin Alternatives: ✓ for .NET — unlike TS (where V8 sandbox handles automatically), .NET needs explicit safe alternatives documented because there is no sandbox. Table of unsafe → safe: `Task.Run` → `Workflow.RunTaskAsync`, `Task.Delay` → `Workflow.DelayAsync`, `DateTime.Now` → `Workflow.UtcNow`, `Random` → `Workflow.Random`, `Guid.NewGuid()` → `Workflow.NewGuid()`, `Task.WhenAll` → `Workflow.WhenAllAsync`, `Task.WhenAny` → `Workflow.WhenAnyAsync`, `Mutex` → `Temporalio.Workflows.Mutex`, `Semaphore` → `Temporalio.Workflows.Semaphore`
- SDK Protection: .NET uses runtime EventListener + custom TaskScheduler (no sandbox). Brief here, references determinism-protection.md for details.
- Forbidden Operations: Standard list (I/O, external state, threading, system clock, random) plus .NET-specific (Task.Run, ConfigureAwait(false), dictionary iteration)

**Order alignment:** N/A — different structures by design (Core#5 SDK Protection → Py#6, TS#3, DN#3; languages have Forbidden Operations which Core covers in Sources)

**Style alignment:** ✓ Well aligned (Python/TS)
- Core: Deep conceptual content (replay mechanism, commands/events, recovery)
- Python: Practical focus (forbidden operations, safe alternatives table, sandbox)
- TypeScript: Practical focus (V8 sandbox, forbidden operations). Removed dedicated UUID section (now brief mention in V8 Sandbox).
- .NET: Will follow Python pattern (forbidden operations, safe alternatives table, runtime detection). Safe Builtin Alternatives is especially important for .NET since there's no sandbox.
- Good division: Core explains "why", languages explain "how"
