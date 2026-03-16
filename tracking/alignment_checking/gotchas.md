# gotchas.md

## Section Inventory

| Section | Core | Core# | Python | Py# | TypeScript | TS# | Java | J# | Go |
|---------|------|-------|--------|-----|------------|-----|------|----|----|
| Idempotency / Non-Idempotent Activities | ✓ | 1 | — | — | — | — | — | — | |
| Replay Safety / Side Effects & Non-Determinism | ✓ | 2 | — | — | — | — | — | — | |
| Multiple Workers with Different Code | ✓ | 3 | — | — | — | — | — | — | |
| Retry Policies / Failing Activities Too Quickly | ✓ | 4 | — | — | — | — | — | — | |
| Query Handlers / Query Handler Mistakes | ✓ | 5 | — | — | — | — | — | — | |
| File Organization | ✓ | 6 | ✓ | 1 | — | — | — | — | |
| Activity Imports | — | — | — | — | ✓ | 1 | — | — | |
| Bundling Issues | — | — | — | — | ✓ | 2 | — | — | |
| Async vs Sync Activities | — | — | ✓ | 2 | — | — | — | — | |
| Non-Deterministic Operations | — | — | — | — | — | — | TODO | 1 | |
| Error Handling | ✓ | 8 | — | — | — | — | — | — | |
| Wrong Retry Classification | ✓ | 8 | ✓ | 3 | ✓ | 3 | TODO | 2 | |
| Cancellation | ✓ | 10 | ✓ | 4 | ✓ | 4 | TODO | 3 | |
| Heartbeating | — | — | ✓ | 5 | ✓ | 5 | TODO | 4 | |
| Testing | ✓ | 7 | ✓ | 6 | ✓ | 6 | TODO | 5 | |
| Timers and Sleep | — | — | ✓ | 7 | ✓ | 7 | TODO | 6 | |
| Payload Size Limits | ✓ | 9 | — | — | — | — | — | — | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Core | ✓ reference | Conceptual gotchas |
| Python | ✓ aligned | Language-specific gotchas |
| TypeScript | ✓ aligned | Language-specific gotchas |
| Java | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Java column decisions:**
- Non-Deterministic Operations: Java-specific gotcha — using `Thread.sleep()` instead of `Workflow.sleep()`, `UUID.randomUUID()` instead of `Workflow.randomUUID()`, `Math.random()` instead of `Workflow.newRandom()`, using Java `Thread`/locks/synchronization. Java has NO sandbox so these are not caught automatically.
- File Organization: — (less critical in Java; no sandbox reload, no bundling concerns)
- Activity Imports: — (TS-specific bundling concern)
- Bundling Issues: — (TS-specific)
- Async vs Sync Activities: — (Python-specific; Java activities are always blocking/synchronous by default)
- Wrong Retry Classification: same concept as Python/TS
- Cancellation: Java has `CancellationScope` and `CanceledFailure`
- Heartbeating: same concept as Python/TS
- Testing: same concept (test failures, replay compatibility)
- Timers and Sleep: `Thread.sleep()` vs `Workflow.sleep()`, `Workflow.await()` with timeout

**Decided to keep as-is:**
- Multiple Workers with Different Code: Core-only (conceptual explanation sufficient)
- Heartbeating: Py/TS/Java-only (language-specific code examples, no Core conceptual section needed)

**Intentionally missing (`—`):**
- Idempotency, Replay Safety, Query Handlers, Error Handling, Retry Policies, Payload Size Limits: Core-only (conceptual)
- Multiple Workers with Different Code: Core-only (conceptual)
- File Organization: Core + Python; TS covers similar in Activity Imports; Java doesn't need (no sandbox/bundling)
- Activity Imports: TS-specific (bundling/sandbox concerns)
- Bundling Issues: TS-specific (workflow bundling)
- Async vs Sync Activities: Python-specific
- Non-Deterministic Operations: Java-specific (no sandbox to catch these automatically — critical gotcha)
- Cancellation: Core has conceptual overview, TS/Python/Java have language-specific patterns
- Timers and Sleep: Language-specific (Workflow.sleep vs language-native sleep)

**Order alignment:** N/A — Core has conceptual sections, language files have implementation-specific sections

**Style alignment:** ✅ Complete (Python, TypeScript)
- Core: 10 conceptual sections with symptoms/fixes (authoritative for cross-cutting concerns)
- TypeScript: 7 sections (Activity Imports, Bundling, Cancellation, Heartbeating, Testing, Timers, Wrong Retry Classification)
- Python: 7 sections (File Organization, Async vs Sync, Wrong Retry Classification, Cancellation, Heartbeating, Testing, Timers and Sleep)
- Java: 6 sections planned (Non-Deterministic Operations, Wrong Retry Classification, Cancellation, Heartbeating, Testing, Timers and Sleep)
