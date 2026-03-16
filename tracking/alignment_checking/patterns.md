# patterns.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | .NET | DN# | Go |
|---------|------|--------|-----|------------|-----|------|-----|-----|
| Signals | ✓ | ✓ | 1 | ✓ | 1 | TODO | 1 | |
| Dynamic Signal Handlers | — | ✓ | 2 | ✓ | 2 | TODO | 2 | |
| Queries | ✓ | ✓ | 3 | ✓ | 3 | TODO | 3 | |
| Dynamic Query Handlers | — | ✓ | 4 | ✓ | 4 | TODO | 4 | |
| Updates | ✓ | ✓ | 5 | ✓ | 5 | TODO | 5 | |
| Child Workflows | ✓ | ✓ | 6 | ✓ | 6 | TODO | 6 | |
| Child Workflow Options | — | — | — | ✓ | 7 | — | — | |
| Handles to External Workflows | — | ✓ | 7 | ✓ | 8 | TODO | 7 | |
| Parallel Execution | ✓ | ✓ | 8 | ✓ | 9 | TODO | 8 | |
| Deterministic Asyncio Alternatives | — | ✓ | 9 | — | — | — | — | |
| Deterministic Task Alternatives | — | — | — | — | — | TODO | 9 | |
| Continue-as-New | ✓ | ✓ | 10 | ✓ | 10 | TODO | 10 | |
| Saga Pattern | ✓ | ✓ | 11 | ✓ | 11 | TODO | 11 | |
| Cancellation Handling (asyncio) | — | ✓ | 12 | — | — | — | — | |
| Cancellation Scopes | — | — | — | ✓ | 12 | — | — | |
| Cancellation Handling (CancellationToken) | — | — | — | — | — | TODO | 12 | |
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
| .NET | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Decided to keep as Core-only:**
- Large Data Handling: Core conceptual explanation sufficient (language-agnostic pattern)
- Polling Patterns: Core conceptual explanation sufficient
- Idempotency Patterns: Core conceptual explanation sufficient

**Intentionally missing (`—`):**
- Dynamic handlers, External workflow handles, Wait conditions: language-specific implementation, core has concepts only
- Child Workflow Options: TS-specific (Python shows inline; .NET shows inline with ChildWorkflowOptions)
- Deterministic Asyncio Alternatives: Python-specific (TS doesn't have this issue)
- Deterministic Task Alternatives: .NET-specific (Workflow.WhenAllAsync, Workflow.RunTaskAsync, etc.)
- Cancellation Handling (asyncio) vs Cancellation Scopes vs Cancellation Handling (CancellationToken): different idioms per language
- Triggers: TS-specific pattern
- Entity Workflow Pattern: conceptual in core, implementation left to user
- Using Pydantic Models: Python-specific

**.NET alignment notes:**
- .NET gets 17 sections, parallel to Python/TS
- "Deterministic Task Alternatives" is .NET-specific analog of Python's "Deterministic Asyncio Alternatives" — covers Workflow.WhenAllAsync, Workflow.WhenAnyAsync, Workflow.RunTaskAsync, Workflow.DelayAsync, Temporalio.Workflows.Mutex/Semaphore
- "Cancellation Handling (CancellationToken)" is .NET-specific — uses standard CancellationToken pattern, not asyncio.CancelledError or CancellationScopes
- Child Workflow Options marked `—` for .NET — shown inline like Python (ChildWorkflowOptions passed to ExecuteChildWorkflowAsync)

**Order alignment:** ✓ Aligned — TS# monotonically increases; DN# monotonically increases

**Style alignment:** ✅ All issues fixed (Python/TS)
- ✅ **Queries:** TS now has "Important: must NOT modify state" note
- ✅ **Saga Pattern:** TS now has idempotency note, comments about saving compensation BEFORE activity
- ✅ **Saga Pattern:** TS now uses `log` from `@temporalio/workflow`
