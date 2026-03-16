# patterns.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Ruby | Rb# | Go |
|---------|------|--------|-----|------------|-----|------|-----|-----|
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
| Cancellation Scopes | — | — | — | ✓ | 12 | — | — | |
| Cancellation (Token-based) | — | — | — | — | — | TODO | 12 | |
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
| Using ActiveModel | — | — | — | — | — | TODO | 18 | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Uses `log`, CancellationScope idiom |
| Ruby | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created
- Ruby column: all TODO — Ruby files not yet created

**Decided to keep as Core-only:**
- Large Data Handling: Core conceptual explanation sufficient (language-agnostic pattern)
- Polling Patterns: Core conceptual explanation sufficient
- Idempotency Patterns: Core conceptual explanation sufficient

**Intentionally missing (`—`):**
- Dynamic handlers, External workflow handles, Wait conditions: language-specific implementation, core has concepts only
- Child Workflow Options: TS-specific (Python shows inline); Ruby includes because it has explicit `parent_close_policy`, `cancellation_type` params
- Deterministic Asyncio Alternatives: Python-specific (TS/Ruby don't have this issue)
- Cancellation Handling (asyncio): Python-specific (uses `asyncio.CancelledError`)
- Cancellation Scopes: TS-specific (uses `CancellationScope`)
- Cancellation (Token-based): Ruby-specific (uses `Temporalio::Cancellation` token objects with detached cancellation)
- Triggers: TS-specific pattern (`Trigger` class)
- Entity Workflow Pattern: conceptual in core, implementation left to user
- Using Pydantic Models: Python-specific
- Using ActiveModel: Ruby-specific (equivalent of Pydantic for Ruby; refs data-handling.md)

**Ruby notes:**
- Ruby uses `workflow_signal`, `workflow_query`, `workflow_update` class methods (not decorators)
- Dynamic handlers use `dynamic: true` parameter
- Parallel execution uses `Temporalio::Workflow::Future.all_of` (not Promise.all or asyncio.gather)
- Continue-as-New raises `Temporalio::Workflow::ContinueAsNewError` (not a function call)
- Cancellation uses token-based `Temporalio::Cancellation` objects, similar to .NET — not scope-based (TS) or exception-based (Python)
- Child Workflow Options: Ruby has `parent_close_policy`, `cancellation_type` as params on `execute_child_workflow`/`start_child_workflow`
- `workflow_query_attr_reader` shorthand can be mentioned in Queries section

**Order alignment:** ✓ Aligned — TS# and Rb# monotonically increase

**Style alignment:** ✅ All issues fixed (Python/TypeScript)
- ✅ **Queries:** TS now has "Important: must NOT modify state" note
- ✅ **Saga Pattern:** TS now has idempotency note, comments about saving compensation BEFORE activity
- ✅ **Saga Pattern:** TS now uses `log` from `@temporalio/workflow`
