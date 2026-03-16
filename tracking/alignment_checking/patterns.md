# patterns.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Go | Go# |
|---------|------|--------|-----|------------|-----|-----|-----|
| Signals | ✓ | ✓ | 1 | ✓ | 1 | TODO | 1 |
| Dynamic Signal Handlers | — | ✓ | 2 | ✓ | 2 | — | — |
| Queries | ✓ | ✓ | 3 | ✓ | 3 | TODO | 2 |
| Dynamic Query Handlers | — | ✓ | 4 | ✓ | 4 | — | — |
| Updates | ✓ | ✓ | 5 | ✓ | 5 | TODO | 3 |
| Child Workflows | ✓ | ✓ | 6 | ✓ | 6 | TODO | 4 |
| Child Workflow Options | — | — | — | ✓ | 7 | TODO | 5 |
| Handles to External Workflows | — | ✓ | 7 | ✓ | 8 | TODO | 6 |
| Parallel Execution | ✓ | ✓ | 8 | ✓ | 9 | TODO | 7 |
| Deterministic Asyncio Alternatives | — | ✓ | 9 | — | — | — | — |
| Selector Pattern | — | — | — | — | — | TODO | 8 |
| Continue-as-New | ✓ | ✓ | 10 | ✓ | 10 | TODO | 9 |
| Saga Pattern | ✓ | ✓ | 11 | ✓ | 11 | TODO | 10 |
| Cancellation Handling (asyncio) | — | ✓ | 12 | — | — | — | — |
| Cancellation Scopes | — | — | — | ✓ | 12 | — | — |
| Cancellation Handling | — | — | — | — | — | TODO | 11 |
| Triggers | — | — | — | ✓ | 13 | — | — |
| Wait Condition with Timeout | — | ✓ | 13 | ✓ | 14 | TODO | 12 |
| Waiting for All Handlers to Finish | — | ✓ | 14 | ✓ | 15 | TODO | 13 |
| Activity Heartbeating | ✓ | ✓ | 15 | ✓ | 16 | TODO | 14 |
| Timers | ✓ | ✓ | 16 | ✓ | 17 | TODO | 15 |
| Large Data Handling | ✓ | — | — | — | — | — | — |
| Local Activities | ✓ | ✓ | 17 | ✓ | 18 | TODO | 16 |
| Entity Workflow Pattern | ✓ | — | — | — | — | — | — |
| Polling Patterns | ✓ | — | — | — | — | — | — |
| Idempotency Patterns | ✓ | — | — | — | — | — | — |
| Using Pydantic Models | — | ✓ | 18 | — | — | — | — |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Uses `log`, CancellationScope idiom |
| Go | TODO | Channel-based signals, SetQueryHandler, SetUpdateHandler, Selector, defer saga |

## Status

**Sections needing review (TODO cells):**
- Go column: all TODO — Go files to be created

**Go-specific notes:**
- Signals use `workflow.GetSignalChannel` + `workflow.Selector` (channel-based, not handler-based)
- Dynamic Signal/Query Handlers: Go handles signals by channel name; no "default handler" concept → marked `—`
- Queries use `workflow.SetQueryHandler` (string name + function)
- Updates use `workflow.SetUpdateHandlerWithOptions` with optional `Validator`
- Parallel Execution uses `workflow.Go()` (not goroutines) + `workflow.Selector`
- Selector Pattern: Go-specific section — `workflow.Selector` replaces `select` statement (unique to Go SDK)
- Cancellation Handling: Go uses `ctx.Done()` channel + `workflow.NewDisconnectedContext` (different from Python asyncio.CancelledError and TS CancellationScope)
- Saga Pattern: Go idiom uses `defer` for compensations
- Wait Condition: Go uses `workflow.Await` / `workflow.AwaitWithTimeout`
- Continue-as-New: Go returns `workflow.NewContinueAsNewError` (error-based, not function call)
- Cancellation Scopes / Triggers / Deterministic Asyncio: Not applicable to Go → marked `—`

**Decided to keep as Core-only:**
- Large Data Handling: Core conceptual explanation sufficient (language-agnostic pattern)
- Polling Patterns: Core conceptual explanation sufficient
- Idempotency Patterns: Core conceptual explanation sufficient

**Intentionally missing (`—`):**
- Dynamic handlers, External workflow handles, Wait conditions: language-specific implementation, core has concepts only
- Child Workflow Options: TS-specific (Python shows inline)
- Deterministic Asyncio Alternatives: Python-specific (TS doesn't have this issue)
- Cancellation Handling vs Cancellation Scopes: different idioms per language
- Triggers: TS-specific pattern
- Entity Workflow Pattern: conceptual in core, implementation left to user
- Using Pydantic Models: Python-specific

**Order alignment:** ✓ Aligned — TS# and Go# monotonically increase

**Style alignment:** ✅ All issues fixed (Python, TypeScript)
- ✅ **Queries:** TS now has "Important: must NOT modify state" note
- ✅ **Saga Pattern:** TS now has idempotency note, comments about saving compensation BEFORE activity
- ✅ **Saga Pattern:** TS now uses `log` from `@temporalio/workflow`
