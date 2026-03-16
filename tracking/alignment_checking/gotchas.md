# gotchas.md

## Section Inventory

| Section | Core | Core# | Python | Py# | TypeScript | TS# | .NET | DN# | Go |
|---------|------|-------|--------|-----|------------|-----|------|-----|-----|
| Idempotency / Non-Idempotent Activities | ✓ | 1 | — | — | — | — | — | — | |
| Replay Safety / Side Effects & Non-Determinism | ✓ | 2 | — | — | — | — | — | — | |
| Multiple Workers with Different Code | ✓ | 3 | — | — | — | — | — | — | |
| Retry Policies / Failing Activities Too Quickly | ✓ | 4 | — | — | — | — | — | — | |
| Query Handlers / Query Handler Mistakes | ✓ | 5 | — | — | — | — | — | — | |
| File Organization | ✓ | 6 | ✓ | 1 | — | — | — | — | |
| Activity Imports | — | — | — | — | ✓ | 1 | — | — | |
| Bundling Issues | — | — | — | — | ✓ | 2 | — | — | |
| Async vs Sync Activities | — | — | ✓ | 2 | — | — | — | — | |
| .NET Task Determinism | — | — | — | — | — | — | TODO | 1 | |
| Error Handling | ✓ | 8 | — | — | — | — | — | — | |
| Wrong Retry Classification | ✓ | 8 | ✓ | 3 | ✓ | 3 | TODO | 2 | |
| Cancellation | ✓ | 10 | ✓ | 4 | ✓ | 4 | TODO | 3 | |
| Heartbeating | — | — | ✓ | 5 | ✓ | 5 | TODO | 4 | |
| Testing | ✓ | 7 | ✓ | 6 | ✓ | 6 | TODO | 5 | |
| Timers and Sleep | — | — | ✓ | 7 | ✓ | 7 | TODO | 6 | |
| Payload Size Limits | ✓ | 9 | — | — | — | — | — | — | |
| Dictionary Iteration Order | — | — | — | — | — | — | TODO | 7 | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Core | ✓ reference | Conceptual gotchas |
| Python | ✓ aligned | Language-specific gotchas |
| TypeScript | ✓ aligned | Language-specific gotchas |
| .NET | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Decided to keep as-is:**
- Multiple Workers with Different Code: Core-only (conceptual explanation sufficient)
- Heartbeating: Py/TS/.NET-only (language-specific code examples, no Core conceptual section needed)

**Intentionally missing (`—`):**
- Idempotency, Replay Safety, Query Handlers, Error Handling, Retry Policies, Payload Size Limits: Core-only (conceptual)
- Multiple Workers with Different Code: Core-only (conceptual)
- File Organization: Core + Python; TS covers similar in Activity Imports; .NET doesn't need (no sandbox reloading)
- Activity Imports: TS-specific (bundling/sandbox concerns)
- Bundling Issues: TS-specific (workflow bundling)
- Async vs Sync Activities: Python-specific
- Cancellation: Core has conceptual overview, TS/Python/.NET have language-specific patterns
- Timers and Sleep: Language-specific (TS/Python/.NET each have their own timer gotchas)

**.NET alignment notes:**
- .NET Task Determinism: NEW .NET-specific section — the biggest .NET gotcha. Covers Task.Run, Task.Delay, ConfigureAwait(false), Task.WhenAny, Task.WhenAll, CancellationTokenSource.CancelAsync, System.Threading.Mutex/Semaphore, dictionary iteration. This is the primary determinism protection mechanism since .NET has no sandbox.
- Dictionary Iteration Order: NEW .NET-specific section — `Dictionary<TKey, TValue>` iteration order is not guaranteed in .NET; must use `SortedDictionary` or sort before iterating.
- Timers and Sleep: ✓ — Task.Delay vs Workflow.DelayAsync, Thread.Sleep forbidden
- File Organization: `—` for .NET — not as critical as Python (no sandbox reloading), standard .NET project structure is fine

**Order alignment:** N/A — Core has conceptual sections, language files have implementation-specific sections

**Style alignment:** ✅ Complete (Python/TS)
- Core: 10 conceptual sections with symptoms/fixes (authoritative for cross-cutting concerns)
- TypeScript: 7 sections (Activity Imports, Bundling, Cancellation, Heartbeating, Testing, Timers, Wrong Retry Classification)
- Python: 7 sections (File Organization, Async vs Sync, Wrong Retry Classification, Cancellation, Heartbeating, Testing, Timers and Sleep)
- .NET: 7 sections planned (.NET Task Determinism, Wrong Retry Classification, Cancellation, Heartbeating, Testing, Timers and Sleep, Dictionary Iteration Order)
