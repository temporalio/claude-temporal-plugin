# patterns.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Ruby | Rb# | Go | Go# |
|---------|------|--------|-----|------------|-----|------|-----|-----|-----|
| Signals | ✓ | ✓ | 1 | ✓ | 1 | TODO | 1 | ✓ | 1 |
| Dynamic Signal Handlers | — | ✓ | 2 | ✓ | 2 | TODO | 2 | — | — |
| Queries | ✓ | ✓ | 3 | ✓ | 3 | TODO | 3 | ✓ | 2 |
| Dynamic Query Handlers | — | ✓ | 4 | ✓ | 4 | TODO | 4 | — | — |
| Updates | ✓ | ✓ | 5 | ✓ | 5 | TODO | 5 | ✓ | 3 |
| Child Workflows | ✓ | ✓ | 6 | ✓ | 6 | TODO | 6 | ✓ | 4 |
| Child Workflow Options | — | — | — | ✓ | 7 | TODO | 7 | ✓ | 4s |
| Handles to External Workflows | — | ✓ | 7 | ✓ | 8 | TODO | 8 | ✓ | 5 |
| Parallel Execution | ✓ | ✓ | 8 | ✓ | 9 | TODO | 9 | ✓ | 6 |
| Deterministic Asyncio Alternatives | — | ✓ | 9 | — | — | — | — | — | — |
| Selector Pattern | — | — | — | — | — | — | — | ✓ | 7 |
| Continue-as-New | ✓ | ✓ | 10 | ✓ | 10 | TODO | 10 | ✓ | 8 |
| Cancellation Handling (asyncio) | — | ✓ | 12 | — | — | — | — | — | — |
| Cancellation Scopes | — | — | — | ✓ | 12 | — | — | — | — |
| Cancellation (Token-based) | — | — | — | — | — | TODO | 12 | — | — |
| Cancellation Handling | — | — | — | — | — | — | — | ✓ | 9 |
| Saga Pattern | ✓ | ✓ | 11 | ✓ | 11 | TODO | 11 | ✓ | 10 |
| Triggers | — | — | — | ✓ | 13 | — | — | — | — |
| Wait Condition with Timeout | — | ✓ | 13 | ✓ | 14 | TODO | 13 | ✓ | 11 |
| Waiting for All Handlers to Finish | — | ✓ | 14 | ✓ | 15 | TODO | 14 | ✓ | 12 |
| Activity Heartbeat Details | ✓ | ✓ | 15 | ✓ | 16 | TODO | 15 | ✓ | 13 |
| Timers | ✓ | ✓ | 16 | ✓ | 17 | TODO | 16 | ✓ | 14 |
| Large Data Handling | ✓ | — | — | — | — | — | — | — | — |
| Local Activities | ✓ | ✓ | 17 | ✓ | 18 | TODO | 17 | ✓ | 15 |
| Entity Workflow Pattern | ✓ | — | — | — | — | — | — | — | — |
| Polling Patterns | ✓ | — | — | — | — | — | — | — | — |
| Idempotency Patterns | ✓ | — | — | — | — | — | — | — | — |
| Using Pydantic Models | — | ✓ | 18 | — | — | — | — | — | — |
| Using ActiveModel | — | — | — | — | — | TODO | 18 | — | — |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Uses `log`, CancellationScope idiom |
| Ruby | — | Not started |
| Go | ✓ aligned | Channel-based signals, SetQueryHandler, SetUpdateHandler, Selector, compensation slice saga |

## Status

**Ruby notes:**
- Ruby uses `workflow_signal`, `workflow_query`, `workflow_update` class methods (not decorators)
- Entry point is `def execute` — no annotation needed (unlike Python's `@workflow.run`)
- Dynamic handlers use `dynamic: true` parameter
- Parallel execution uses `Temporalio::Workflow::Future.all_of` (not Promise.all or asyncio.gather)
- Continue-as-New raises `Temporalio::Workflow::ContinueAsNewError` (not a function call)
- Cancellation uses token-based `Temporalio::Cancellation` objects, similar to .NET — not scope-based (TS) or exception-based (Python)
- Child Workflow Options: Ruby has `parent_close_policy`, `cancellation_type` as params on `execute_child_workflow`/`start_child_workflow`
- `workflow_query_attr_reader` shorthand can be mentioned in Queries section

**Cross-language notes:**
- **Updates — Validator constraints:** All languages (core, Python, TS, Go) now document that validators must NOT mutate state or block (read-only, like query handlers). Added in PR #38 review.
- Cancellation Handling reordered before Saga in Go (Go# 9→10) so `NewDisconnectedContext` is introduced before Saga uses it
- Saga Pattern in Go now uses `NewDisconnectedContext` for compensations (PR #38 review)
- Local Activities: added WFT persistence risk warning to **core** (applies to all languages, not Go-specific). PR #38 review.

**Go-specific notes:**
- Child Workflow Options: demoted to `###` subsection under Child Workflows in Go (Go# 4s = subsection of 4). TS has it as separate `##`.
- Activity Heartbeating renamed to Activity Heartbeat Details (matching Python/TS naming)

**Go-specific notes (API details):**
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
- Deterministic Asyncio Alternatives: Python-specific (TS/Ruby don't have this issue)
- Cancellation (Token-based): Ruby-specific (uses `Temporalio::Cancellation` token objects)
- Cancellation Scopes: TS-specific (uses `CancellationScope`)
- Triggers: TS-specific pattern
- Using Pydantic Models: Python-specific
- Using ActiveModel: Ruby-specific (equivalent of Pydantic)

**Order alignment:** ✓ Aligned — TS#, Rb#, and Go# monotonically increase

**Style alignment:** ✅ All issues fixed (Python, TypeScript, Go). Ruby: ~18 sections planned.
- ✅ **Queries:** TS now has "Important: must NOT modify state" note
- ✅ **Updates:** All languages now have "validators must NOT mutate state or block" note
- ✅ **Saga Pattern:** TS now has idempotency note, comments about saving compensation BEFORE activity
- ✅ **Saga Pattern:** TS now uses `log` from `@temporalio/workflow`
