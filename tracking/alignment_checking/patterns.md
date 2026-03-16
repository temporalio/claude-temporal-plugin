# patterns.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Java | J# | Go |
|---------|------|--------|-----|------------|-----|------|----|----|
| Signals | ✓ | ✓ | 1 | ✓ | 1 | TODO | 1 | |
| Dynamic Signal Handlers | — | ✓ | 2 | ✓ | 2 | TODO | 2 | |
| Queries | ✓ | ✓ | 3 | ✓ | 3 | TODO | 3 | |
| Dynamic Query Handlers | — | ✓ | 4 | ✓ | 4 | TODO | 4 | |
| Updates | ✓ | ✓ | 5 | ✓ | 5 | TODO | 5 | |
| Child Workflows | ✓ | ✓ | 6 | ✓ | 6 | TODO | 6 | |
| Child Workflow Options | — | — | — | ✓ | 7 | TODO | 7 | |
| Handles to External Workflows | — | ✓ | 7 | ✓ | 8 | TODO | 8 | |
| Parallel Execution | ✓ | ✓ | 8 | ✓ | 9 | TODO | 9 | |
| Deterministic Asyncio Alternatives | — | ✓ | 9 | — | — | — | — | |
| Continue-as-New | ✓ | ✓ | 10 | ✓ | 10 | TODO | 10 | |
| Saga Pattern | ✓ | ✓ | 11 | ✓ | 11 | TODO | 11 | |
| Cancellation Handling (asyncio) | — | ✓ | 12 | — | — | — | — | |
| Cancellation Scopes | — | — | — | ✓ | 12 | TODO | 12 | |
| Triggers | — | — | — | ✓ | 13 | — | — | |
| Wait Condition with Timeout | — | ✓ | 13 | ✓ | 14 | TODO | 13 | |
| Waiting for All Handlers to Finish | — | ✓ | 14 | ✓ | 15 | TODO | 14 | |
| Activity Heartbeating | ✓ | ✓ | 15 | ✓ | 16 | TODO | 15 | |
| Timers | ✓ | ✓ | 16 | ✓ | 17 | TODO | 16 | |
| Large Data Handling | ✓ | — | — | — | — | — | — | |
| Local Activities | ✓ | ✓ | 17 | ✓ | 18 | TODO | 17 | |
| Entity Workflow Pattern | ✓ | — | — | — | — | — | — | |
| Polling Patterns | ✓ | — | — | — | — | — | — | |
| Idempotency Patterns | ✓ | — | — | — | — | — | — | |
| Using Pydantic Models | — | ✓ | 18 | — | — | — | — | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Uses `log`, CancellationScope idiom |
| Java | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Java column decisions:**
- Signals, Queries, Updates, Dynamic Handlers: Java has `@SignalMethod`, `@QueryMethod`, `@UpdateMethod`, plus dynamic handlers via `DynamicSignalHandler`/`DynamicQueryHandler`
- Child Workflows: Java uses `Workflow.newChildWorkflowStub()` with `ChildWorkflowOptions`
- Child Workflow Options: Java has `ChildWorkflowOptions` (like TS, shows separately)
- Handles to External Workflows: Java has `Workflow.newExternalWorkflowStub()`
- Parallel Execution: Java uses `Async.function()` + `Promise.allOf()`
- Cancellation Scopes: Java has `CancellationScope` (like TS)
- Wait Condition with Timeout: Java has `Workflow.await(timeout, condition)`
- Deterministic Asyncio Alternatives: — (Python-specific, not applicable to Java)
- Cancellation Handling (asyncio): — (Python-specific, not applicable to Java)
- Triggers: — (TS-specific; Java has `CompletablePromise` but it's a different pattern, not a separate section)
- Large Data Handling, Entity Workflow, Polling, Idempotency: — (Core-only)
- Using Pydantic Models: — (Python-specific)

**Decided to keep as Core-only:**
- Large Data Handling: Core conceptual explanation sufficient (language-agnostic pattern)
- Polling Patterns: Core conceptual explanation sufficient
- Idempotency Patterns: Core conceptual explanation sufficient

**Intentionally missing (`—`):**
- Dynamic handlers, External workflow handles, Wait conditions: language-specific implementation, core has concepts only
- Child Workflow Options: TS/Java-specific (Python shows inline)
- Deterministic Asyncio Alternatives: Python-specific (TS/Java don't have this issue)
- Cancellation Handling vs Cancellation Scopes: different idioms per language (Python uses asyncio.CancelledError, TS/Java use CancellationScope)
- Triggers: TS-specific pattern
- Entity Workflow Pattern: conceptual in core, implementation left to user
- Using Pydantic Models: Python-specific

**Order alignment:** ✓ Aligned — TS# and J# monotonically increase

**Style alignment:** ✅ All issues fixed (Python, TypeScript)
- ✅ **Queries:** TS now has "Important: must NOT modify state" note
- ✅ **Saga Pattern:** TS now has idempotency note, comments about saving compensation BEFORE activity
- ✅ **Saga Pattern:** TS now uses `log` from `@temporalio/workflow`
