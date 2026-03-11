# patterns.md

Correctness verification for `references/{language}/patterns.md`.

## TypeScript

**File:** `references/typescript/patterns.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Signals | all good | | context7 sdk-typescript, temporal-docs |
| 2 | Dynamic Signal Handlers | FIXED | Used `setDefaultSignalHandler` | context7 sdk-typescript, temporal-docs |
| 3 | Queries | all good | Added "Important" note during alignment | context7 sdk-typescript, temporal-docs |
| 4 | Dynamic Query Handlers | FIXED | Used `setDefaultQueryHandler` | temporal-docs |
| 5 | Updates | all good | | context7 sdk-typescript, temporal-docs |
| 6 | Child Workflows | all good | | context7 sdk-typescript, temporal-docs |
| 7 | Child Workflow Options | all good | | context7 sdk-typescript, temporal-docs |
| 8 | Handles to External Workflows | all good | | context7 sdk-typescript |
| 9 | Parallel Execution | all good | | context7 sdk-typescript |
| 10 | Continue-as-New | all good | | context7 sdk-typescript |
| 11 | Saga Pattern | all good | Added idempotency note, BEFORE comments, `log` import during alignment | temporal-docs, samples-typescript, edu-102-typescript |
| 12 | Cancellation Scopes | all good | | context7 sdk-typescript, temporal-docs |
| 13 | Triggers (Promise-like Signals) | all good | | temporal-docs api reference |
| 14 | Wait Condition with Timeout | all good | | context7 sdk-typescript, temporal-docs |
| 15 | Waiting for All Handlers to Finish | FIXED | Simplified; added context about non-async handler preference | SDK team feedback, temporal-docs |
| 16 | Activity Heartbeat Details | all good | | context7 sdk-typescript, temporal-docs |
| 17 | Timers | all good | | context7 sdk-typescript |
| 18 | Local Activities | FIXED | Wrong import: `executeLocalActivity` → `proxyLocalActivities` | context7 sdk-typescript |

### Detailed Notes

#### 1. Signals
**Status:** all good

**Verified:**
- `defineSignal`, `setHandler`, `condition` imports from `@temporalio/workflow` ✓
- `defineSignal<[boolean]>('approve')` syntax with type parameter as array of arg types ✓
- `setHandler(signal, handler)` pattern ✓
- `await condition(() => approved)` for waiting on state ✓

---

#### 2. Dynamic Signal Handlers
**Status:** FIXED

**Issue:** The current code uses a non-existent predicate-based `setHandler` API. The TypeScript SDK uses `setDefaultSignalHandler` for handling signals with unknown names.

**Before:**
```typescript
setHandler(
  (signalName: string) => true, // This API doesn't exist
  (signalName: string, ...args: unknown[]) => { ... }
);
```

**After:**
```typescript
import { setDefaultSignalHandler, condition } from '@temporalio/workflow';

export async function dynamicSignalWorkflow(): Promise<Record<string, unknown[]>> {
  const signals: Record<string, unknown[]> = {};

  setDefaultSignalHandler((signalName: string, ...args: unknown[]) => {
    if (!signals[signalName]) {
      signals[signalName] = [];
    }
    signals[signalName].push(args);
  });

  await condition(() => signals['done'] !== undefined);
  return signals;
}
```

**Source:** https://typescript.temporal.io/api/namespaces/workflow#setdefaultsignalhandler

---

#### 3. Queries
**Status:** all good

**Verified:**
- `defineQuery`, `setHandler` imports from `@temporalio/workflow` ✓
- `defineQuery<string>('status')` - return type as type parameter ✓
- `setHandler(query, () => value)` - synchronous handler returning value ✓
- Query handlers must be synchronous (not async) ✓
- **Important note verified**: "Queries must NOT modify workflow state or have side effects" ✓
  - temporal-docs: "Queries are _read-only_ and must complete synchronously"
  - temporal-docs: "A Query handler returns a value: it must not mutate the Workflow state"

---

#### 4. Dynamic Query Handlers
**Status:** FIXED

**Issue:** Same as Dynamic Signal Handlers - uses non-existent predicate-based API.

**Correct API:** `setDefaultQueryHandler`

```typescript
setDefaultQueryHandler((queryName: string, ...args: any[]) => {
  // return value
});
```

**Source:** https://typescript.temporal.io/api/namespaces/workflow#setdefaultqueryhandler

---

#### 5. Updates
**Status:** all good

**Verified:**
- `defineUpdate<Ret, Args>('name')` syntax - return type first, then args as tuple type ✓
- `setHandler(update, handler, { validator })` pattern matches official docs ✓
- Validator is synchronous, throws error to reject ✓
- Handler can be sync or async, returns a value ✓
- Imports `defineUpdate`, `setHandler`, `condition` from `@temporalio/workflow` ✓

---

#### 6. Child Workflows
**Status:** all good

**Verified:**
- `executeChild` import from `@temporalio/workflow` ✓
- `executeChild(workflowFunc, { args, workflowId })` syntax correct ✓
- Child scheduled on same task queue as parent by default ✓

---

#### 7. Child Workflow Options
**Status:** all good

**Verified:**
- `ParentClosePolicy` values: `TERMINATE` (default), `ABANDON`, `REQUEST_CANCEL` ✓
- `ChildWorkflowCancellationType` values: `WAIT_CANCELLATION_COMPLETED` (default), `WAIT_CANCELLATION_REQUESTED`, `TRY_CANCEL`, `ABANDON` ✓
- Both imported from `@temporalio/workflow` ✓

---

#### 8. Handles to External Workflows
**Status:** all good

**Verified:**
- `getExternalWorkflowHandle(workflowId)` from `@temporalio/workflow` ✓
- Synchronous function (not async) ✓
- `handle.signal()` and `handle.cancel()` methods exist ✓

---

#### 9. Parallel Execution
**Status:** all good

**Verified:**
- `Promise.all` for parallel execution is standard pattern ✓
- Used in official examples for parallel child workflows ✓

---

#### 10. Continue-as-New
**Status:** all good

**Verified:**
- `continueAsNew`, `workflowInfo` imports from `@temporalio/workflow` ✓
- `await continueAsNew<typeof workflow>(args)` syntax correct ✓
- `workflowInfo().continueAsNewSuggested` property exists ✓
- Checking history length threshold is standard pattern ✓

---

#### 11. Saga Pattern
**Status:** all good

**Verified:**
- Array of compensation functions pattern ✓
- Try/catch with compensations in reverse order ✓
- Official samples-typescript/saga uses same pattern ✓
- No built-in Saga class in TS SDK (unlike Java), manual implementation correct ✓

**Alignment changes verified:**
- **Idempotency note**: "Compensation activities should be idempotent" ✓
  - temporal-docs blog: "you, the programmer, need to make sure each Temporal Activity is *idempotent*"
- **BEFORE comments**: "Save compensation BEFORE calling the activity" ✓
  - All official samples show `saga.addCompensation()` BEFORE activity execution
  - Reason: if activity crashes mid-execution but completed its side effect, compensation must still run
- **Replay-safe logging**: `import { log } from '@temporalio/workflow'` ✓
  - docs.temporal.io: "This logger is replay-aware and will omit log messages on workflow replay"
  - edu-102-typescript: "import `log` from `@temporalio/workflow` to access the Workflow Logger"

---

#### 12. Cancellation Scopes
**Status:** all good

**Verified:**
- `CancellationScope` from `@temporalio/workflow` ✓
- `CancellationScope.nonCancellable(fn)` - prevents cancellation propagation ✓
- `CancellationScope.withTimeout(timeout, fn)` - auto-cancels after timeout ✓
- `new CancellationScope()` + `scope.run(fn)` + `scope.cancel()` pattern ✓

---

#### 13. Triggers (Promise-like Signals)
**Status:** all good

**Verified:**
- `Trigger` class from `@temporalio/workflow` ✓
- `new Trigger<T>()` creates a PromiseLike that exposes resolve/reject ✓
- `trigger.resolve(value)` to resolve from signal handler ✓
- `await trigger` works because Trigger implements PromiseLike ✓
- CancellationScope-aware (throws when scope cancelled) ✓

---

#### 14. Wait Condition with Timeout
**Status:** all good

**Verified:**
- `condition(fn, timeout)` with timeout returns `Promise<boolean>` ✓
- Returns `true` if condition met, `false` if timeout expires ✓
- String duration format `'24 hours'` supported (ms-formatted string) ✓
- Import of `CancelledFailure` unused in example but harmless ✓

---

#### 15. Waiting for All Handlers to Finish
**Status:** FIXED

**Issue 1:** Current code used overly complex condition with `workflowInfo().unsafe.isReplaying` and was missing import of `allHandlersFinished`.

**Issue 2 (SDK team feedback):** Section was missing important context about when this pattern is needed.

**Key guidance (apply to all languages):**
- Signal/update handlers should generally be non-async (avoid running activities from them)
- Otherwise, the workflow may complete before handlers finish
- Making handlers non-async sometimes requires workarounds that add complexity
- This pattern (`allHandlersFinished`) is for cases where async handlers are necessary

**After:**
```typescript
import { condition, allHandlersFinished } from '@temporalio/workflow';
// ...
await condition(allHandlersFinished);
```

**Source:** SDK team feedback, https://typescript.temporal.io/api/namespaces/workflow#allhandlersfinished

**Notes:**
- `allHandlersFinished` is a function that returns `boolean`
- Pass it directly to `condition()` (not wrapped in a lambda)
- Official pattern: `await wf.condition(wf.allHandlersFinished)`

---

#### 16. Activity Heartbeat Details
**Status:** FIXED

**Verified:**
- `heartbeat`, `activityInfo` imports from `@temporalio/activity` ✓
- `activityInfo().heartbeatDetails` gets heartbeat from previous failed attempt ✓
- `heartbeat(details)` records checkpoint for resume ✓
- Pattern matches official samples-typescript/activities-cancellation-heartbeating ✓

**SDK team feedback (apply to all languages):**
- **Most important use case is activity cancellation support** - cancellations are delivered to activities via heartbeat
- Activities that don't heartbeat cannot receive or respond to cancellation
- If activity is cancelled, `heartbeat()` throws `CancelledFailure` (TypeScript)
- Updated WHY/WHEN sections to emphasize cancellation as primary purpose
- Source: SDK team PR review, temporal-docs ("Activity Cancellations are delivered to Activities from the Temporal Service when they Heartbeat")

**Notes:**
- `activityInfo()` is convenience function for `Context.current().info`
- heartbeatDetails can be any serializable value (number, object, etc.)

---

#### 17. Timers
**Status:** all good

**Verified:**
- `sleep` from `@temporalio/workflow` accepts duration strings ✓
- `CancellationScope` for cancellable timers ✓
- `scope.run()` and `scope.cancel()` pattern ✓

**Notes:**
- Example uses `setHandler` and `cancelSignal` without imports (pattern demonstration)

---

#### 18. Local Activities
**Status:** FIXED

**Issue:** Wrong import - code imported `executeLocalActivity` but used `proxyLocalActivities`.

**Before:**
```typescript
import { executeLocalActivity } from '@temporalio/workflow';
```

**After:**
```typescript
import { proxyLocalActivities } from '@temporalio/workflow';
```

**Source:** context7 sdk-typescript documentation

---

## Python

**File:** `references/python/patterns.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Signals | needs fixes | | context7 sdk-python |
| 2 | Dynamic Signal Handlers | all good | | context7 sdk-python |
| 3 | Queries | needs fixes | | context7 sdk-python |
| 4 | Dynamic Query Handlers | needs fixes | | context7 sdk-python |
| 5 | Updates | all good | | context7 sdk-python |
| 6 | Child Workflows | all good | | context7 sdk-python, temporal-docs |
| 7 | Handles to External Workflows | all good | | context7 sdk-python |
| 8 | Parallel Execution | needs fixes | | context7 sdk-python, sdk source |
| 9 | Deterministic Alternatives to asyncio | needs fixes | | context7 sdk-python, sdk source |
| 10 | Continue-as-New | needs fixes | | context7 sdk-python, temporal-docs |
| 11 | Saga Pattern | needs fixes | | temporal-docs |
| 12 | Cancellation Handling | needs fixes | | context7 sdk-python |
| 13 | Wait Condition with Timeout | all good | | context7 sdk-python |
| 14 | Waiting for All Handlers to Finish | FIXED | Added context about non-async handler preference | SDK team feedback, context7 sdk-python |
| 15 | Activity Heartbeat Details | all good | | context7 sdk-python |
| 16 | Timers | all good | | context7 sdk-python |
| 17 | Local Activities | all good | | context7 sdk-python, temporal-docs |
| 18 | Using Pydantic Models | all good | | file verification |

### Detailed Notes

#### 1. Signals
**Status:** needs fixes

**Issues:**
- Basic signal pattern (`@workflow.signal`, async handler, state modification) all correct ✓
- `workflow.wait_condition(lambda: condition)` API correct ✓
- **Needs verification:** `workflow.payload_converter().from_payload()` in dynamic handler example
- SDK docs show `activity.payload_converter()` for activities but workflow equivalent needs confirmation

---

#### 2. Dynamic Signal Handlers
**Status:** all good

**Verified:**
- `@workflow.signal(dynamic=True)` decorator ✓
- Handler signature `(self, name: str, args: Sequence[RawValue])` ✓
- `workflow.payload_converter().from_payload(args[0])` pattern consistent with SDK examples ✓

---

#### 3. Queries
**Status:** needs fixes

**Issues:**
- `@workflow.query` decorator correct ✓
- Non-async query handlers shown correctly ✓
- "Queries must NOT modify workflow state" correctly stated ✓
- **Missing:** Should explicitly state "Query methods should NOT be `async`"
- SDK docs: "Query methods should return a value and should not be `async`"

---

#### 4. Dynamic Query Handlers
**Status:** needs fixes

**Issues:**
- `@workflow.query(dynamic=True)` correct ✓
- **Inconsistency in SDK docs:** SDK README says queries have "same semantics as signals" (requiring `Sequence[RawValue]`)
- But SDK README example shows simpler signature: `def get_dynamic_info(self, query_name: str) -> any:`
- Document uses full signature which is defensible but may not match simplest official example

---

#### 5. Updates
**Status:** all good

**Verified:**
- `@workflow.update` decorator ✓
- Async update handler can modify state and return value ✓
- `@update_handler.validator` decorator pattern ✓
- Validator not async, returns None, raises to reject ✓

---

#### 6. Child Workflows
**Status:** all good

**Verified:**
- `workflow.execute_child_workflow()` API ✓
- First arg is workflow method reference ✓
- `id` parameter is required for child workflows ✓
- `parent_close_policy=workflow.ParentClosePolicy.ABANDON` ✓

---

#### 7. Handles to External Workflows
**Status:** all good

**Verified:**
- `workflow.get_external_workflow_handle(workflow_id)` API ✓
- `await handle.signal(TargetWorkflow.method, data)` ✓
- `await handle.cancel()` ✓

---

#### 8. Parallel Execution
**Status:** needs fixes

**Issues:**
- `asyncio.gather(*tasks)` for parallel activities ✓
- **INCORRECT:** `workflow.WaitConditionResult.FIRST_COMPLETED` does NOT exist
- SDK source shows `return_when` is a string parameter accepting `asyncio.FIRST_COMPLETED`
- Correct: `workflow.wait(futures, return_when=asyncio.FIRST_COMPLETED)`

---

#### 9. Deterministic Alternatives to asyncio
**Status:** needs fixes

**Issues:**
- `workflow.wait()` and `workflow.as_completed()` exist ✓
- **Same issue as §8:** `workflow.WaitConditionResult` enum does NOT exist
- `return_when` accepts standard asyncio constants: `asyncio.FIRST_COMPLETED`, `asyncio.FIRST_EXCEPTION`, `asyncio.ALL_COMPLETED`

---

#### 10. Continue-as-New
**Status:** needs fixes

**Issues:**
- `workflow.info().is_continue_as_new_suggested()` API correct ✓
- "Fresh history before hitting limits" explanation correct ✓
- **Non-idiomatic:** `workflow.continue_as_new(args=[state])` uses `args` (plural)
- Official docs pass single arg directly: `workflow.continue_as_new(state)`
- Or use `arg=state` (singular) for single argument

---

#### 11. Saga Pattern
**Status:** needs fixes

**Issues:**
- Compensation list pattern correct ✓
- `reversed(compensations)` for LIFO correct ✓
- "Save compensation BEFORE running activity" correct and well-explained ✓
- Idempotent compensation naming convention correct ✓
- **Missing:** `ship_order` activity has no compensation registered
- Should either add compensation or explain why shipping is terminal action

---

#### 12. Cancellation Handling
**Status:** needs fixes

**Issues:**
- `asyncio.CancelledError` for cancellation detection ✓
- Re-raise `CancelledError` to mark workflow as cancelled ✓
- **Misleading comment:** "Cleanup activities still run even after cancellation"
- SDK docs: Activities executed after catching CancelledError will also receive cancellation requests
- Should use `asyncio.shield()` to protect cleanup activities, or correct the comment

---

#### 13. Wait Condition with Timeout
**Status:** all good

**Verified:**
- `workflow.wait_condition(lambda: cond, timeout=timedelta(...))` API ✓
- `asyncio.TimeoutError` on timeout expiry ✓
- Pattern matches official SDK examples ✓

---

#### 14. Waiting for All Handlers to Finish
**Status:** FIXED

**Verified:**
- `workflow.all_handlers_finished` function exists ✓
- `workflow.wait_condition(workflow.all_handlers_finished)` pattern is correct ✓
- Use cases: async handlers, before continue-as-new ✓
- SDK docs: "One way to ensure that handler tasks have finished is to wait on the `workflow.all_handlers_finished` condition"

**SDK team feedback (apply to all languages):**
- Signal/update handlers should generally be non-async (avoid running activities from them)
- Otherwise, the workflow may complete before handlers finish
- Making handlers non-async sometimes requires workarounds that add complexity
- This pattern is for cases where async handlers are necessary
- Added explanatory context to section

---

#### 15. Activity Heartbeat Details
**Status:** FIXED

**Verified:**
- `activity.info().heartbeat_details` returns iterable (indexable) ✓
- `activity.heartbeat(progress)` API with `*details` signature ✓
- Resume pattern: check heartbeat_details, skip processed items ✓
- SDK docs: "If an activity calls `temporalio.activity.heartbeat(123, 456)` and then fails and is retried, `temporalio.activity.info().heartbeat_details` will return an iterable containing `123` and `456` on the next run."

**SDK team feedback (apply to all languages):**
- **Most important use case is activity cancellation support** - cancellations are delivered to activities via heartbeat
- Activities that don't heartbeat cannot receive or respond to cancellation
- If activity is cancelled, `heartbeat()` raises `asyncio.CancelledError` (async) or `temporalio.exceptions.CancelledError` (sync threaded)
- Updated WHY/WHEN sections to emphasize cancellation as primary purpose
- Source: SDK team PR review, temporal-docs ("Activity Cancellations are delivered to Activities from the Temporal Service when they Heartbeat")

---

#### 16. Timers
**Status:** all good

**Verified:**
- `workflow.sleep(timedelta(...))` API ✓
- Accepts `timedelta` objects (hours, minutes, days, etc.) ✓
- Alternative: `asyncio.sleep()` also works (backed by workflow timer) ✓
- "Temporal timers are server-side, so sub-second resolution might not be meaningful"

---

#### 17. Local Activities
**Status:** all good

**Verified:**
- `workflow.execute_local_activity()` API exists ✓
- `start_to_close_timeout` parameter exists ✓
- "Skip the task queue" explanation is accurate ✓
- "Not durable and distributed" warning is accurate ✓
- Temporal docs: "avoid roundtripping to the Temporal Service" and "reduced durability guarantees"

---

#### 18. Using Pydantic Models
**Status:** all good

**Verified:**
- Reference path `references/python/data-handling.md` exists ✓
- File contains Pydantic integration documentation starting at line 15 ✓

---

