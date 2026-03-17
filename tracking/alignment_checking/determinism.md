# determinism.md

## Section Inventory

| Section | Core | Core# | Python | Py# | TypeScript | TS# | Java | J# | Go |
|---------|------|-------|--------|-----|------------|-----|------|----|----|
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
| Java | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Java column decisions:**
- Overview: Java has no sandbox — determinism protection relies on developer discipline
- Why Determinism Matters: Same as Python/TS — brief reference to core, focus on Java-specific implications
- SDK Protection / Sandbox: Java-specific — explains there is NO sandbox. SDK provides `Workflow.*` APIs as alternatives but does NOT enforce them at compile/load time. Non-determinism is only caught at replay time via `NonDeterministicException`. Cooperative threading model (global lock, one thread at a time) eliminates synchronization needs. See `determinism-protection.md` for details.
- Forbidden Operations: Java-specific list — `Thread.sleep()`, `new Thread()`, `synchronized` blocks, `UUID.randomUUID()`, `Math.random()`, `System.currentTimeMillis()`, direct file/network I/O, mutable global state
- Safe Builtin Alternatives: Java should have this (like Python) — table mapping Java stdlib → Workflow.* APIs (`Thread.sleep()` → `Workflow.sleep()`, `UUID.randomUUID()` → `Workflow.randomUUID()`, etc.). Important because Java has no auto-replacement.
- Testing Replay Compatibility: Java uses `WorkflowReplayer` class
- Best Practices: Same general guidance, Java-specific code

**Intentionally missing (`—`):**
- Sources of Non-Determinism: Core-only (conceptual categories)
- Central Concept: Activities: Core-only (conceptual)
- Detecting Non-Determinism: Core-only
- Recovery from Non-Determinism: Core-only

**Order alignment:** N/A — different structures by design (Core has conceptual sections, languages have practical sections)

**Style alignment:** ✓ Well aligned (Python, TypeScript)
- Core: Deep conceptual content (replay mechanism, commands/events, recovery)
- Python: Practical focus (forbidden operations, safe alternatives table, sandbox)
- TypeScript: Practical focus (V8 sandbox, forbidden operations). Removed dedicated UUID section.
- Java: Practical focus (no sandbox, no static analyzer, forbidden operations, safe alternatives table, replay testing). Cooperative threading under global lock eliminates sync needs but doesn't prevent non-deterministic calls.
- Safe Builtin Alternatives: Python and Java (important because no auto-replacement); TS doesn't need (V8 handles automatically)
- Good division: Core explains "why", languages explain "how"
