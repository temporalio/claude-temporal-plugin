# Correctness Checking

Track verification of factual statements and code examples in reference files for the **temporal-developer** skill.

**Skill location:** `plugins/temporal-developer/skills/temporal-developer/`
**Reference files:** `plugins/temporal-developer/skills/temporal-developer/references/`

## Task Prompt (for session recovery)

**Goal:** Verify correctness of every factual statement and code example in reference files.

**Workflow for each section:**

1. Read the section from the reference file
2. Query documentation sources to verify:
   - Use `mcp__context7__query-docs` with appropriate `libraryId` (e.g., `/temporalio/sdk-typescript`, `/temporalio/sdk-python`)
   - Use `mcp__temporal-docs__search_temporal_knowledge_sources` for conceptual/pattern verification
3. Compare the code example against official documentation
4. Update this tracking file:
   - Update the table row with status and sources consulted
   - Update the detailed notes section with verification details and any needed edits
5. If edits are needed, apply them to the source file after documenting here

**Status values:**
- `unchecked` - Not yet verified
- `all good` - Verified correct, no changes needed
- `needs fixes` - Issues found but not yet corrected
- `FIXED` - Issues found and corrected

**Resume instructions:** Find the first `unchecked` section in any table and continue from there.

---

## TypeScript: patterns.md

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
| 15 | Waiting for All Handlers to Finish | FIXED | Simplified to `await condition(allHandlersFinished)` | temporal-docs api reference |
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

**Issue:** Current code used overly complex condition with `workflowInfo().unsafe.isReplaying` and was missing import of `allHandlersFinished`.

**Before:**
```typescript
import { condition, workflowInfo } from '@temporalio/workflow';
// ...
await condition(() => workflowInfo().unsafe.isReplaying || allHandlersFinished());
```

**After:**
```typescript
import { condition, allHandlersFinished } from '@temporalio/workflow';
// ...
await condition(allHandlersFinished);
```

**Source:** https://typescript.temporal.io/api/namespaces/workflow#allhandlersfinished

**Notes:**
- `allHandlersFinished` is a function that returns `boolean`
- Pass it directly to `condition()` (not wrapped in a lambda)
- Official pattern: `await wf.condition(wf.allHandlersFinished)`

---

#### 16. Activity Heartbeat Details
**Status:** all good

**Verified:**
- `heartbeat`, `activityInfo` imports from `@temporalio/activity` ✓
- `activityInfo().heartbeatDetails` gets heartbeat from previous failed attempt ✓
- `heartbeat(details)` records checkpoint for resume ✓
- Pattern matches official samples-typescript/activities-cancellation-heartbeating ✓

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

## TypeScript: testing.md

**File:** `references/typescript/testing.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | FIXED | Manually updated to encourage startLocal over time skipping | temporal-docs |
| 2 | Test Environment Setup | FIXED | Manually updated to prefer startLocal | temporal-docs |
| 3 | Activity Mocking | all good | | context7 sdk-typescript |
| 4 | Testing Signals and Queries | FIXED | Use defined signal/query objects | context7 sdk-typescript |
| 5 | Testing Failure Cases | FIXED | Added WorkflowFailedError import | context7 sdk-typescript |
| 6 | Replay Testing | FIXED | Added complete history fetching patterns | context7 sdk-typescript |
| 7 | Activity Testing | FIXED | Replaced {cancelled:true} with env.cancel() | context7 sdk-typescript |
| 8 | Best Practices | FIXED | Manually updated to prefer startLocal | temporal-docs |

### Detailed Notes

#### 1. Overview
**Status:** FIXED

**Fixed:** Manually updated by user to encourage `startLocal` over time skipping.

---

#### 2. Test Environment Setup
**Status:** FIXED

**Fixed:** Manually updated by user to prefer `startLocal`.

---

#### 3. Activity Mocking
**Status:** all good

**Verified:**
- Inline activity object in `Worker.create()` for mocking is correct
- Mock function signature pattern is valid

---

#### 4. Testing Signals and Queries
**Status:** FIXED

**Fixed:** Updated to use defined signal/query objects (`defineQuery`/`defineSignal`) instead of string names.

---

#### 5. Testing Failure Cases
**Status:** FIXED

**Fixed:** Added missing `import { WorkflowFailedError } from '@temporalio/client';`

---

#### 6. Replay Testing
**Status:** FIXED

**Fixed:** Added complete history fetching patterns (from JSON file and from server).

---

#### 7. Activity Testing
**Status:** FIXED

**Fixed:** Replaced `{ cancelled: true }` with `env.cancel()` method, added `CancelledFailure` import.

---

#### 8. Best Practices
**Status:** FIXED

**Fixed:** Manually updated by user to prefer `startLocal`.

---

## TypeScript: typescript.md

**File:** `references/typescript/typescript.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | FIXED | Changed to "isolated runtime with bundling" | context7 sdk-typescript |
| 2 | Understanding Replay | FIXED | Fixed ref path to references/core/ | context7 sdk-typescript |
| 3 | Quick Start | all good | | context7 sdk-typescript |
| 4 | Key Concepts | FIXED | Added defineUpdate() and activities param | context7 sdk-typescript |
| 5 | File Organization Best Practice | all good | | context7 sdk-typescript |
| 6 | Determinism Rules | all good | | context7 sdk-typescript |
| 7 | Common Pitfalls | FIXED | Corrected logging guidance | context7 sdk-typescript |
| 8 | Writing Tests | all good | | context7 sdk-typescript |
| 9 | Additional Resources | all good | | context7 sdk-typescript |

### Detailed Notes

#### 1. Overview
**Status:** FIXED

**Fixed:** Changed "V8 sandbox" to "isolated runtime with bundling and automatic replacements".

---

#### 2. Understanding Replay
**Status:** FIXED

**Fixed:** Changed ref path from `core/determinism.md` to `references/core/determinism.md`.

---

#### 3. Quick Start
**Status:** all good

**Verified:** All code examples are correct - npm packages, activities.ts, workflows.ts, worker.ts, client.ts, commands, expected output

---

#### 4. Key Concepts
**Status:** FIXED

**Fixed:** Added `defineUpdate()` to Workflow Definition, added `activities` parameter to Worker Setup.

---

#### 5. File Organization Best Practice
**Status:** all good

**Verified:** Bundling performance claim, directory structure, type-only import pattern all correct

---

#### 6. Determinism Rules
**Status:** all good

**Verified:** Math.random(), Date.now(), setTimeout replacements are accurate. sleep() and condition() as safe alternatives is correct.

---

#### 7. Common Pitfalls
**Status:** FIXED

**Fixed:** Updated logging guidance to recommend `import { log } from '@temporalio/workflow'` for replay-safe logging with automatic workflow context. Removed incorrect suggestion that console.log works.

---

#### 8. Writing Tests
**Status:** all good

**Verified:** Reference path to testing.md is correct

---

#### 9. Additional Resources
**Status:** all good

**Verified:** All 10 reference file paths exist and are correct

---

## TypeScript: versioning.md

**File:** `references/typescript/versioning.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | all good | | context7 sdk-typescript |
| 2 | Why Versioning Matters | FIXED | Improved non-determinism explanation | context7 sdk-typescript |
| 3 | Workflow Versioning with the Patching API | all good | | context7 sdk-typescript |
| 4 | Three-Step Patching Process | all good | | context7 sdk-typescript |
| 5 | Multiple Patches | FIXED | Clarified same patchId for related changes | context7 sdk-typescript |
| 6 | Query Filters for Versioned Workflows | FIXED | Added spaces around = operator | context7 sdk-typescript |
| 7 | Workflow Type Versioning | all good | | context7 sdk-typescript |
| 8 | Worker Versioning | FIXED | Updated to 2025 Public Preview API | context7 sdk-typescript, temporal-docs |
| 9 | Choosing a Versioning Strategy | FIXED | Corrected deprecation info - only legacy API deprecated | context7 sdk-typescript, temporal-docs |
| 10 | Best Practices | FIXED | Removed incorrect deprecation notes | context7 sdk-typescript, temporal-docs |

### Detailed Notes

#### 1. Overview
**Status:** all good

**Verified:** Three approaches (Patching API, Workflow Type Versioning, Worker Versioning) are correctly listed

---

#### 2. Why Versioning Matters
**Status:** FIXED

**Fixed:** Improved non-determinism explanation to clarify it's about different execution paths and command sequences.

---

#### 3. Workflow Versioning with the Patching API
**Status:** all good

**Verified:** patched() import, boolean return, marker insertion, replay behavior all correct

---

#### 4. Three-Step Patching Process
**Status:** all good

**Verified:** All three steps are correct - patched() with both paths, deprecatePatch() API, clean removal

---

#### 5. Multiple Patches
**Status:** FIXED

**Fixed:** Clarified that it's about using same patchId in multiple patched() calls for related changes.

---

#### 6. Query Filters for Versioned Workflows
**Status:** FIXED

**Fixed:** Added spaces around `=` operator in query examples. IS NULL syntax verified as correct.

---

#### 7. Workflow Type Versioning
**Status:** all good

**Verified:** V2 pattern, worker registration, client code, List Filter all correct

---

#### 8. Worker Versioning
**Status:** FIXED

**Fixed:** Completely rewrote section with correct 2025 Public Preview API. Key changes:
- Added note that Worker Versioning is in **Public Preview** (not deprecated)
- Clarified that only the **legacy** Worker Versioning API (pre-2025) is being removed in March 2026
- Updated to use `workerDeploymentOptions` configuration with `useWorkerVersioning`, `version.deploymentName`, `version.buildId`
- Removed detailed PINNED/AUTO_UPGRADE behaviors and deployment strategies (simplified for skill token efficiency)
- Added deployment workflow using Temporal CLI

---

#### 9. Choosing a Versioning Strategy
**Status:** FIXED

**Fixed:** Removed incorrect deprecation notice. Worker Versioning is actively supported (Public Preview). Updated table to show Worker Versioning as a valid option for short-running workflows and frequent deploys.

---

#### 10. Best Practices
**Status:** FIXED

**Fixed:** Removed incorrect deprecation notes from best practices. Added Worker Versioning-specific practices (consistent deployment names, traceable Build IDs).

---

## TypeScript: advanced-features.md

**File:** `references/typescript/advanced-features.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Schedules | FIXED | Use ScheduleOverlapPolicy.SKIP (not string literal), use intervals (recommended over cronExpressions) | context7 sdk-typescript, temporal-docs |
| 2 | Async Activity Completion | FIXED | Manually corrected to match official docs: activityInfo().taskToken, AsyncCompletionClient, CompleteAsyncError | temporal-docs |
| 3 | Worker Tuning | FIXED | Reverted to non-default values (100, 200) to demonstrate customization | context7 sdk-typescript |
| 4 | Sinks | all good | | context7 sdk-typescript |

### Detailed Notes

#### 1. Schedules
**Status:** FIXED

**Fixed:**
- Use `ScheduleOverlapPolicy.SKIP` import (not string literal) to match official samples
- Use `intervals` (not `cronExpressions`) - intervals is the recommended approach for new code (cronExpressions is only for legacy migration)
- Added import for `ScheduleOverlapPolicy` from `@temporalio/client`

---

#### 2. Async Activity Completion
**Status:** FIXED

**Fixed:** Manually corrected by user to match official docs:
- `activityInfo().taskToken` (returns `Uint8Array`)
- `AsyncCompletionClient` for external completion
- `CompleteAsyncError` to signal async completion

---

#### 3. Worker Tuning
**Status:** FIXED

**Fixed:** Reverted to non-default values (100 for workflows, 200 for activities) - the point of the example is to show customization, not defaults.

---

#### 4. Sinks
**Status:** all good

**Verified:** proxySinks, Sinks imports, interface pattern, Worker sinks config, handler signature, callDuringReplay option all correct

---

## TypeScript: data-handling.md

**File:** `references/typescript/data-handling.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | all good | | context7 sdk-typescript |
| 2 | Default Data Converter | FIXED | Clarified Protobuf requires custom converter | context7 sdk-typescript |
| 3 | Custom Data Converter | FIXED | Uses payloadConverterPath pattern | context7 sdk-typescript |
| 4 | Payload Codec (Encryption) | FIXED | Changed to payloadCodecs (plural, array) | context7 sdk-typescript |
| 5 | Search Attributes | all good | | context7 sdk-typescript |
| 6 | Workflow Memo | all good | | context7 sdk-typescript |
| 7 | Protobuf Support | all good | | context7 sdk-typescript |
| 8 | Large Payloads | FIXED | Import already present | context7 sdk-typescript |
| 9 | Best Practices | all good | | context7 sdk-typescript |

### Detailed Notes

#### 1. Overview
**Status:** all good

**Verified:** Data converter role description is accurate

---

#### 2. Default Data Converter
**Status:** FIXED

**Fixed:** Removed misleading Protobuf claim, added note that Protobuf requires `DefaultPayloadConverterWithProtobufs`.

---

#### 3. Custom Data Converter
**Status:** FIXED

**Fixed:** Uses `payloadConverterPath: require.resolve()` pattern, added Payload import, uses generic `<T>`.

---

#### 4. Payload Codec (Encryption)
**Status:** FIXED

**Fixed:** Changed `payloadCodec` to `payloadCodecs` (plural, as array).

---

#### 5. Search Attributes
**Status:** all good

**Verified:** searchAttributes option, array format, upsertSearchAttributes, workflowInfo().searchAttributes, client.workflow.list, query syntax all correct

---

#### 6. Workflow Memo
**Status:** all good

**Verified:** memo option, workflowInfo().memo, distinction from search attributes all correct

---

#### 7. Protobuf Support
**Status:** all good

**Verified:** Import path `@temporalio/common/lib/protobufs` and `protobufRoot` option are correct

---

#### 8. Large Payloads
**Status:** FIXED

**Fixed:** Import already present in current file (verified correct).

---

#### 9. Best Practices
**Status:** all good

**Verified:** All 6 best practices are valid and aligned with SDK documentation

---

## TypeScript: determinism-protection.md

**File:** `references/typescript/determinism-protection.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | FIXED | Removed "unique to TS" claim | context7 sdk-typescript |
| 2 | Import Blocking | FIXED | Clarified ignoreModules excludes | context7 sdk-typescript |
| 3 | Function Replacement | all good | | context7 sdk-typescript |

### Detailed Notes

#### 1. Overview
**Status:** FIXED

**Fixed:** Removed "unique to TypeScript SDK" claim (Python also has sandbox).

---

#### 2. Import Blocking
**Status:** FIXED

**Fixed:** Clarified that ignoreModules EXCLUDES modules, added note that excluded modules are unavailable at runtime and node: prefix note.

---

#### 3. Function Replacement
**Status:** all good

**Verified:** Math.random(), Date, setTimeout() replacements all correct. Date behavior, code example, FinalizationRegistry/WeakRef removal, GC explanation all accurate.

---

## TypeScript: determinism.md

**File:** `references/typescript/determinism.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | all good | | context7 sdk-typescript |
| 2 | Why Determinism Matters | all good | | context7 sdk-typescript |
| 3 | Temporal's V8 Sandbox | all good | | context7 sdk-typescript |
| 4 | Deterministic UUID Generation | all good | | context7 sdk-typescript |
| 5 | Forbidden Operations | all good | | context7 sdk-typescript |
| 6 | Testing Replay Compatibility | FIXED | Changed Replayer to Worker.runReplayHistory() | context7 sdk-typescript |
| 7 | Best Practices | all good | | context7 sdk-typescript |

### Detailed Notes

#### 1. Overview
**Status:** all good

**Verified:** V8 sandbox automatic determinism claim is accurate

---

#### 2. Why Determinism Matters
**Status:** all good

**Verified:** History Replay explanation, scenarios (crash, cache eviction, long timer), determinism requirement all correct

---

#### 3. Temporal's V8 Sandbox
**Status:** all good

**Verified:** Sandbox replacements, Math.random() with same seed, reference to determinism-protection.md all correct

---

#### 4. Deterministic UUID Generation
**Status:** all good

**Verified:** uuid4 import, workflow seeded PRNG, same UUID during replay, use cases all correct

---

#### 5. Forbidden Operations
**Status:** all good

**Verified:** fs forbidden, fetch() forbidden, console.log side effect claim, activities recommendation all correct

---

#### 6. Testing Replay Compatibility
**Status:** FIXED

**Issues:**
- "Replayer" class reference should be `Worker.runReplayHistory()` - no Replayer class in TS SDK
- Reference to testing.md path is correct

---

#### 7. Best Practices
**Status:** all good

**Verified:** All 5 best practices are valid

---

## TypeScript: error-handling.md

**File:** `references/typescript/error-handling.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | all good | | context7 sdk-typescript |
| 2 | Application Failures | FIXED | Verified ApplicationFailure.create() is correct | context7 sdk-typescript |
| 3 | Activity Errors | FIXED | Import from @temporalio/activity | context7 sdk-typescript |
| 4 | Handling Errors in Workflows | all good | | context7 sdk-typescript |
| 5 | Retry Configuration | all good | | context7 sdk-typescript |
| 6 | Timeout Configuration | all good | | context7 sdk-typescript |
| 7 | Workflow Failure | all good | | context7 sdk-typescript |
| 8 | Idempotency | all good | | context7 sdk-typescript |
| 9 | Best Practices | FIXED | Clarified log import for workflows vs activities | context7 sdk-typescript |

### Detailed Notes

#### 1. Overview
**Status:** all good

**Verified:** ApplicationFailure description and non-retryable support claim are accurate

---

#### 2. Application Failures
**Status:** FIXED

**Fixed:** Verified ApplicationFailure.create() API is correct (both .create() and .nonRetryable() are valid).

---

#### 3. Activity Errors
**Status:** FIXED

**Fixed:** Import from `@temporalio/activity` for activities (re-exports from @temporalio/common).

---

#### 4. Handling Errors in Workflows
**Status:** all good

**Verified:** imports, instanceof check, err.type/message properties, re-throw pattern all correct

---

#### 5. Retry Configuration
**Status:** all good

**Verified:** retry option, all interval/attempts options, nonRetryableErrorTypes, defaults note all correct

---

#### 6. Timeout Configuration
**Status:** all good

**Verified:** startToCloseTimeout, scheduleToCloseTimeout, heartbeatTimeout descriptions all accurate

---

#### 7. Workflow Failure
**Status:** all good

**Verified:** ApplicationFailure pattern, nonRetryable warning, caller-controlled retries explanation all correct

---

#### 8. Idempotency
**Status:** all good

**Verified:** Reference to core/patterns.md path is correct

---

#### 9. Best Practices
**Status:** FIXED

**Fixed:** Clarified log import: @temporalio/workflow for workflows, @temporalio/activity for activities.

---

## TypeScript: gotchas.md

**File:** `references/typescript/gotchas.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Activity Imports - Type vs Implementation | all good | | context7 sdk-typescript |
| 2 | Activity Imports - Node.js Modules | all good | | context7 sdk-typescript |
| 3 | Bundling Issues - Missing Dependencies | FIXED | Clarified ignoreModules excludes modules | context7 sdk-typescript |
| 4 | Bundling Issues - Version Mismatches | all good | | context7 sdk-typescript |
| 5 | Wrong Retry Classification | all good | | context7 sdk-typescript |
| 6 | Cancellation - Not Handling | all good | | context7 sdk-typescript |
| 7 | Heartbeating - Forgetting to Heartbeat | all good | | context7 sdk-typescript |
| 8 | Heartbeating - Timeout Too Short | all good | | context7 sdk-typescript |
| 9 | Testing - Not Testing Failures | all good | | context7 sdk-typescript |
| 10 | Testing - Not Testing Replay | FIXED | Fixed fs.promises.readFile pattern | context7 sdk-typescript |
| 11 | Timers and Sleep | all good | | context7 sdk-typescript |

### Detailed Notes

#### 1. Activity Imports - Type vs Implementation
**Status:** all good

**Verified:**
- BAD pattern: `import * as activities from './activities'` ✓
- GOOD pattern: `import type * as activities from './activities'` ✓
- V8 sandbox bundling explanation is accurate ✓

---

#### 2. Activity Imports - Node.js Modules
**Status:** all good

**Verified:**
- `fs` import example as BAD ✓
- Activity delegation as GOOD pattern ✓
- Sandbox restriction explanation is accurate ✓

---

#### 3. Bundling Issues - Missing Dependencies
**Status:** FIXED

**Fixed:** Clarified that ignoreModules EXCLUDES modules and they are completely unavailable at workflow runtime.

---

#### 4. Bundling Issues - Version Mismatches
**Status:** all good

**Verified:** Package version matching claim and BAD/GOOD JSON examples are correct

---

#### 5. Wrong Retry Classification
**Status:** all good

**Verified:** error examples, ApplicationFailure.create() without nonRetryable, .nonRetryable() API, error-handling.md reference all correct

---

#### 6. Cancellation - Not Handling
**Status:** all good

**Verified:** CancellationScope import, .nonCancellable() for cleanup, try/finally pattern all correct

---

#### 7. Heartbeating - Forgetting to Heartbeat
**Status:** all good

**Verified:** heartbeat import, heartbeat(details) API, progress reporting pattern all correct

---

#### 8. Heartbeating - Timeout Too Short
**Status:** all good

**Verified:** heartbeatTimeout in proxyActivities and timeout guidance correct

---

#### 9. Testing - Not Testing Failures
**Status:** all good

**Verified:** createTimeSkipping(), nativeConnection, runUntil(), ApplicationFailure.nonRetryable() all correct

---

#### 10. Testing - Not Testing Replay
**Status:** FIXED

**Fixed:** Updated history loading to use fs.promises.readFile pattern for clarity.

---

#### 11. Timers and Sleep
**Status:** all good

**Verified:** setTimeout BAD pattern, sleep import, duration string format, durability claim all correct

---

## TypeScript: observability.md

**File:** `references/typescript/observability.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | all good | | context7 sdk-typescript |
| 2 | Replay-Aware Logging - Workflow | FIXED | Clarified log export since SDK 1.8.0 | context7 sdk-typescript |
| 3 | Replay-Aware Logging - Activity | FIXED | Use log from @temporalio/activity | context7 sdk-typescript |
| 4 | Customizing the Logger - Basic | all good | | context7 sdk-typescript |
| 5 | Customizing the Logger - Winston | all good | | context7 sdk-typescript |
| 6 | Metrics - Prometheus | all good | | context7 sdk-typescript |
| 7 | Metrics - OTLP | all good | | context7 sdk-typescript |
| 8 | Best Practices | all good | | context7 sdk-typescript |

### Detailed Notes

#### 1. Overview
**Status:** all good

**Verified:** Replay-aware logging claim and metrics/OpenTelemetry mention are correct

---

#### 2. Replay-Aware Logging - Workflow
**Status:** FIXED

**Fixed:** Clarified that `import { log } from '@temporalio/workflow'` is correct since SDK 1.8.0.

---

#### 3. Replay-Aware Logging - Activity
**Status:** FIXED

**Fixed:** Updated to use `import { log } from '@temporalio/activity'` with direct `log.info()` calls.

---

#### 4. Customizing the Logger - Basic
**Status:** all good

**Verified:** DefaultLogger, Runtime imports, constructor pattern, Runtime.install API all correct

---

#### 5. Customizing the Logger - Winston
**Status:** all good

**Verified:** Winston integration, entry properties (level, message, meta, timestampNanos), BigInt division all correct

---

#### 6. Metrics - Prometheus
**Status:** all good

**Verified:** Runtime.install with telemetryOptions.metrics.prometheus and bindAddress format correct

---

#### 7. Metrics - OTLP
**Status:** all good

**Verified:** telemetryOptions.metrics.otel configuration, url and metricsExportInterval options correct

---

#### 8. Best Practices
**Status:** all good

**Verified:** All 6 best practices valid, "never console.log in workflows" guidance correct

---

## Python: advanced-features.md

**File:** `references/python/advanced-features.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Schedules | all good | | context7 sdk-python |
| 2 | Async Activity Completion | all good | | context7 sdk-python |
| 3 | Sandbox Customization | all good | | context7 sdk-python |
| 4 | Gevent Compatibility Warning | all good | | context7 sdk-python |
| 5 | Worker Tuning | all good | | context7 sdk-python |
| 6 | Workflow Init Decorator | needs fixes | | context7 sdk-python |
| 7 | Workflow Failure Exception Types | all good | | context7 sdk-python |

### Detailed Notes

#### 1. Schedules
**Status:** all good

**Verified:** All imports, create_schedule API, ScheduleActionStartWorkflow, ScheduleSpec, handle methods all correct

---

#### 2. Async Activity Completion
**Status:** all good

**Verified:** activity.info().task_token, raise_complete_async(), get_async_activity_handle, handle methods all correct

---

#### 3. Sandbox Customization
**Status:** all good

**Verified:** Reference to determinism-protection.md path is correct

---

#### 4. Gevent Compatibility Warning
**Status:** all good

**Verified:** Gevent incompatibility claim and monkey patching explanation are accurate

---

#### 5. Worker Tuning
**Status:** all good

**Verified:**
- `ThreadPoolExecutor` import from `concurrent.futures` ✓
- `Worker()` constructor options all correct ✓
- `max_concurrent_workflow_tasks` option exists ✓
- `max_concurrent_activities` option exists ✓
- `activity_executor` option with ThreadPoolExecutor ✓
- `graceful_shutdown_timeout` option with timedelta ✓

---

#### 6. Workflow Init Decorator
**Status:** needs fixes

**Issues:**
- `@workflow.init` decorator and `__init__` method pattern are correct
- "Runs only on first execution, not replay" claim needs clarification
- The decorator ensures init runs before handlers/run, but the "not replay" behavior needs verification
- Purpose description is accurate

---

#### 7. Workflow Failure Exception Types
**Status:** all good

**Verified:**
- `@workflow.defn(failure_exception_types=[...])` parameter exists ✓
- Listed exception types fail workflow instead of task ✓
- `NondeterminismError` special case documented ✓
- Worker-level `workflow_failure_exception_types` parameter exists ✓
- Testing tip about `[Exception]` is valid ✓

---

## Python: ai-patterns.md

**File:** `references/python/ai-patterns.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | needs fixes | | context7 sdk-python |
| 2 | Pydantic Data Converter Setup | needs fixes | | context7 sdk-python |
| 3 | OpenAI Client Configuration | all good | | context7 openai-python, temporal-docs |
| 4 | LiteLLM Configuration | all good | | litellm docs |
| 5 | Generic LLM Activity | all good | | context7 sdk-python |
| 6 | Activity Retry Policy | all good | | context7 sdk-python |
| 7 | Tool-Calling Agent Workflow | needs fixes | | context7 sdk-python |
| 8 | Structured Outputs | needs fixes | | context7 openai-python |
| 9 | Multi-Agent Pipeline | all good | | context7 sdk-python |
| 10 | OpenAI Agents SDK Integration | needs fixes | | context7 sdk-python |
| 11 | Best Practices | all good | | context7 sdk-python |

### Detailed Notes

#### 1. Overview
**Status:** needs fixes

**Issues:**
- Reference path `references/core/ai-integration.md` is INCORRECT - file does not exist
- Correct path should be `references/core/ai-patterns.md`

---

#### 2. Pydantic Data Converter Setup
**Status:** needs fixes

**Issues:**
- Import and converter name are correct (`from temporalio.contrib.pydantic import pydantic_data_converter`)
- `Client.connect()` with `data_converter` parameter placement needs verification
- Claim about "complex types like OpenAI response objects" is misleading - Pydantic converter is for Pydantic models that WRAP responses, not raw OpenAI response objects

---

#### 3. OpenAI Client Configuration
**Status:** all good

**Verified:**
- `AsyncOpenAI` import from `openai` ✓
- `max_retries=0` recommendation is valid and explicitly recommended by Temporal docs ✓
- `timeout` parameter accepts float value in seconds ✓

---

#### 4. LiteLLM Configuration
**Status:** all good

**Verified:**
- `litellm.num_retries = 0` is correct module-level variable for disabling retries ✓

---

#### 5. Generic LLM Activity
**Status:** all good

**Verified:**
- `@activity.defn` decorator ✓
- `ApplicationError` import from `temporalio.exceptions` ✓
- `non_retryable=True` parameter ✓
- `next_retry_delay` parameter for rate limits ✓
- All OpenAI exception types exist (AuthenticationError, RateLimitError, APIStatusError, APIConnectionError) ✓
- Pydantic `BaseModel` usage ✓

---

#### 6. Activity Retry Policy
**Status:** all good

**Verified:**
- `workflow.unsafe.imports_passed_through()` context manager ✓
- `workflow.execute_activity()` API ✓
- `start_to_close_timeout` parameter ✓
- Note about automatic retry behavior is accurate ✓

**Note:** Unused `RetryPolicy` import is technically unnecessary but not incorrect.

---

#### 7. Tool-Calling Agent Workflow
**Status:** needs fixes

**Issues:**
- `@workflow.defn`, `@workflow.run`, `workflow.execute_activity()` patterns are all correct
- **Message accumulation pattern is problematic:**
  - Code converts `messages` list to string: `current_input = f"Tool results: {messages}"`
  - This loses proper message structure expected by OpenAI API
  - Missing assistant's message with tool calls before tool results
  - `LLMRequest` model should accept `messages` list, not just `user_input`

**Recommended:** Either modify `LLMRequest` to accept messages list, or use `temporalio.contrib.openai_agents` integration.

---

#### 8. Structured Outputs
**Status:** needs fixes

**Issues:**
- `openai_client.beta.chat.completions.parse()` is INCORRECT
- Correct API: `openai_client.chat.completions.parse()` (no `beta` prefix)
- `response_format=AnalysisResult` (Pydantic model) is correct ✓
- `response.choices[0].message.parsed` returns Pydantic instance is correct ✓

---

#### 9. Multi-Agent Pipeline
**Status:** all good

**Verified:**
- `asyncio.gather(*tasks, return_exceptions=True)` pattern ✓
- `schedule_to_close_timeout` vs `start_to_close_timeout` usage together is valid ✓
- Parallel activity execution pattern ✓
- Partial failure handling with `isinstance(r, Exception)` filter ✓

---

#### 10. OpenAI Agents SDK Integration
**Status:** needs fixes

**Issues:**
- `from temporalio.contrib.openai import create_workflow_agent` is INCORRECT
- `create_workflow_agent()` function does NOT exist
- Correct module is `temporalio.contrib.openai_agents`
- Correct API uses `OpenAIAgentsPlugin` as a client plugin:
  ```python
  from temporalio.contrib.openai_agents import OpenAIAgentsPlugin, ModelActivityParameters
  client = await Client.connect(..., plugins=[OpenAIAgentsPlugin(...)])
  ```
- `Agent`, `Runner` imports from `agents` are correct ✓
- "Automatically dispatches to activities for LLM calls" claim is accurate ✓

---

#### 11. Best Practices
**Status:** all good

**Verified:**
- All 8 best practices are valid ✓
- "Disable retries in LLM clients" recommendation is correct - prevents double-retry with Temporal ✓

---

## Python: data-handling.md

**File:** `references/python/data-handling.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | all good | | context7 sdk-python |
| 2 | Default Data Converter | all good | | context7 sdk-python |
| 3 | Pydantic Integration | all good | | context7 sdk-python |
| 4 | Custom Data Conversion | all good | | context7 sdk-python, samples-python |
| 5 | Payload Encryption | needs fixes | | context7 sdk-python |
| 6 | Search Attributes | needs fixes | | context7 sdk-python, sdk source |
| 7 | Querying Workflows by Search Attributes | all good | | context7 sdk-python, temporal-docs |
| 8 | Workflow Memo | needs fixes | | context7 sdk-python, sdk source |
| 9 | Large Payloads | all good | | temporal-docs |
| 10 | Deterministic APIs for Values | all good | | context7 sdk-python, sdk source |
| 11 | Best Practices | all good | | context7 sdk-python, temporal-docs |

### Detailed Notes

#### 1. Overview
**Status:** all good

**Verified:**
- Data converter role description is accurate ✓

---

#### 2. Default Data Converter
**Status:** all good

**Verified:**
- Supported types list is accurate (intentionally simplified) ✓
- `None`, `bytes`, Protobuf messages, JSON-serializable types all correct ✓
- SDK actually supports additional types (dataclasses, UUID, datetime) but examples listed are correct ✓

---

#### 3. Pydantic Integration
**Status:** all good

**Verified:**
- `pydantic.BaseModel` subclass as workflow input/output type ✓
- `pydantic_data_converter` import from `temporalio.contrib.pydantic` ✓
- Client configuration with `data_converter=pydantic_data_converter` ✓
- Automatic validation claim is accurate ✓

---

#### 4. Custom Data Conversion
**Status:** all good

**Verified:**
- `EncodingPayloadConverter` and `CompositePayloadConverter` approach is correct ✓
- Both sample URLs are valid and accessible ✓

---

#### 5. Payload Encryption
**Status:** needs fixes

**Issues:**
- `PayloadCodec` import from `temporalio.converter` is correct ✓
- `Payload` import from `temporalio.api.common.v1` is correct ✓
- `encode()` and `decode()` methods are correct ✓
- `Sequence[Payload]` parameter and `list[Payload]` return type are correct ✓
- `DataConverter(payload_codec=...)` configuration is correct ✓
- **`asyncio.to_thread()` usage is NOT in official samples** - official encryption sample calls crypto synchronously
- Missing `import asyncio` if keeping `asyncio.to_thread()` pattern
- The pattern is a valid optimization but not official - should add note or align with official samples

---

#### 6. Search Attributes
**Status:** needs fixes

**Issues:**
- Imports from `temporalio.common` are correct ✓
- `SearchAttributeKey.for_keyword()`, `.for_float()`, `.for_datetime()` factory methods are correct ✓
- `client.start_workflow()` with `search_attributes=TypedSearchAttributes([...])` is correct ✓
- **`workflow.upsert_search_attributes()` API is INCORRECT:**
  - Document shows: `workflow.upsert_search_attributes(TypedSearchAttributes([SearchAttributePair(...)]))`
  - Correct API: `workflow.upsert_search_attributes([KEY.value_set(value)])`
  - Function takes `Sequence[SearchAttributeUpdate]`, not `TypedSearchAttributes`
  - Use `.value_set()` or `.value_unset()` on `SearchAttributeKey`

---

#### 7. Querying Workflows by Search Attributes
**Status:** all good

**Verified:**
- `client.list_workflows(query)` API ✓
- Query string syntax with `=`, `OR` operators ✓
- Async iteration over results ✓

---

#### 8. Workflow Memo
**Status:** needs fixes

**Issues:**
- `memo` parameter type is correct (dict works as Mapping) ✓
- "Not searchable" distinction is correctly stated ✓
- **`workflow.memo_value()` signature is incomplete:**
  - Document shows: `workflow.memo_value("key", type_hint=Type)`
  - Missing `default` parameter: `workflow.memo_value(key, default=..., type_hint=...)`
  - Without default, `KeyError` is raised if key missing
  - Should document: `workflow.memo_value("key", default="", type_hint=str)`

---

#### 9. Large Payloads
**Status:** all good

**Verified:**
- External storage pattern (S3/GCS) ✓
- Payload Codec compression suggestion ✓
- Chunking suggestion ✓
- Reference pattern code example is correct ✓

---

#### 10. Deterministic APIs for Values
**Status:** all good

**Verified:**
- `workflow.uuid4()` returns deterministic UUID based on `random()` ✓
- `workflow.random()` returns deterministically-seeded pseudo-RNG ✓
- `rng.randint(a, b)` API works (returns Python's `random.Random` class) ✓
- "Same on replay" claim is accurate - both are deterministically-seeded ✓

---

#### 11. Best Practices
**Status:** all good

**Verified:**
- All 6 best practices are valid ✓
- 2MB payload recommendation matches Temporal Cloud limits ✓
- `workflow.uuid4()` and `workflow.random()` recommendation is correct ✓

---

## Python: determinism-protection.md

**File:** `references/python/determinism-protection.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | needs fixes | | context7 sdk-python, temporal-docs |
| 2 | How the Sandbox Works | all good | | context7 sdk-python |
| 3 | Forbidden Operations | all good | | context7 sdk-python, sdk source |
| 4 | Pass-Through Pattern | all good | | context7 sdk-python |
| 5 | Importing Activities | all good | | context7 sdk-python |
| 6 | Disabling the Sandbox | all good | | context7 sdk-python |
| 7 | Customizing Invalid Module Members | needs fixes | | context7 sdk-python |
| 8 | Import Notification Policy | all good | | sdk source (v1.21.1) |
| 9 | Disable Lazy sys.modules Passthrough | all good | | sdk source |
| 10 | File Organization | needs fixes | | context7 sdk-python |
| 11 | Common Issues | needs fixes | | context7 sdk-python, sdk source |
| 12 | Best Practices | all good | | context7 sdk-python |

### Detailed Notes

#### 1. Overview
**Status:** needs fixes

**Issues:**
- "Unique to the Python SDK" claim is INCORRECT
- TypeScript SDK also has sandbox protection (V8 isolates + Webpack bundling)
- Should remove uniqueness claim or clarify that Python's approach (exec + proxy objects) is distinct

---

#### 2. How the Sandbox Works
**Status:** all good

**Verified:**
- "Isolates global state via `exec` compilation" ✓
- "Restricts non-deterministic library calls via proxy objects" ✓
- "Passes through standard library with restrictions" ✓
- "Reloads workflow files on each execution" ✓

---

#### 3. Forbidden Operations
**Status:** all good

**Verified:**
- Direct I/O forbidden (socket, http.client, open, pathlib.Path) ✓
- `threading` module blocked ✓
- `subprocess` blocked ✓
- Global state modification blocked ✓
- `time.sleep()` blocked ✓

---

#### 4. Pass-Through Pattern
**Status:** all good

**Verified:**
- `workflow.unsafe.imports_passed_through()` context manager ✓
- Use cases listed are accurate ✓
- Note about top-of-file imports is correct ✓

---

#### 5. Importing Activities
**Status:** all good

**Verified:**
- Pass-through required for activity imports ✓
- `workflow.execute_activity()` API with activity function reference ✓
- `start_to_close_timeout` parameter ✓

---

#### 6. Disabling the Sandbox
**Status:** all good

**Verified:**
- `workflow.unsafe.sandbox_unrestricted()` context manager exists ✓
- "Per-block escape hatch" description is accurate ✓
- Warning about losing determinism checks is present ✓

---

#### 7. Customizing Invalid Module Members
**Status:** needs fixes

**Issues:**
- Import path is INCORRECT: `temporalio.worker.workflow_sandbox` should be `temporalio.worker_sandbox`
- All other APIs (`SandboxRestrictions.default`, `dataclasses.replace()`, `with_child_unrestricted()`, etc.) are correct
- Affects multiple code blocks in the section (lines 101-105, 134-136, 167)

---

#### 8. Import Notification Policy
**Status:** all good

**Verified:**
- `SandboxRestrictions.default.with_import_notification_policy()` API ✓
- `workflow.SandboxImportNotificationPolicy` enum exists as `enum.Flag` ✓
- All enum values correct: WARN_ON_DYNAMIC_IMPORT (2), WARN_ON_UNINTENTIONAL_PASSTHROUGH (4), RAISE_ON_UNINTENTIONAL_PASSTHROUGH (8), SILENT (1) ✓
- `workflow.unsafe.sandbox_import_notification_policy()` context manager exists ✓

---

#### 9. Disable Lazy sys.modules Passthrough
**Status:** all good

**Verified:**
- `disable_lazy_sys_module_passthrough` option exists on `SandboxRestrictions` ✓
- Behavior description is accurate ✓

---

#### 10. File Organization
**Status:** needs fixes

**Issues:**
- "Reloads workflow definition files on every execution" is slightly imprecise
- It's specifically NON-STANDARD library imports that cause overhead, not all file contents
- Standard library and Temporal SDK modules are passed through (not re-imported)
- Should clarify that performance is tied to import overhead, not general file size

---

#### 11. Common Issues
**Status:** needs fixes

**Issues:**
- Import error message is FABRICATED - actual error is `RestrictedWorkflowAccessError: Cannot access X from inside a workflow...`
- Pass-through fix pattern is correct ✓
- Library caching explanation needs clarification - issue occurs specifically with pass-through modules that maintain mutable internal state

---

#### 12. Best Practices
**Status:** all good

**Verified:**
- All 5 best practices are valid ✓

---

## Python: determinism.md

**File:** `references/python/determinism.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | all good | | context7 sdk-python |
| 2 | Why Determinism Matters | all good | | context7 sdk-python |
| 3 | Forbidden Operations | needs fixes | | context7 sdk-python |
| 4 | Safe Builtin Alternatives | needs fixes | | context7 sdk-python, sdk source |
| 5 | Testing Replay Compatibility | all good | | context7 sdk-python |
| 6 | Sandbox Behavior | all good | | context7 sdk-python |
| 7 | Best Practices | needs fixes | | context7 sdk-python |

### Detailed Notes

#### 1. Overview
**Status:** all good

**Verified:**
- Sandbox automatic protection claim is accurate ✓

---

#### 2. Why Determinism Matters
**Status:** all good

**Verified:**
- History Replay explanation is accurate ✓
- Scenarios: crash, cache eviction, long timer are all correct ✓

---

#### 3. Forbidden Operations
**Status:** needs fixes

**Issues:**
- List is correct but INCOMPLETE
- Missing: `set` iteration (non-deterministic ordering)
- Missing: Raw randomness (`random` module)
- "and so on" is vague - consider being more specific

---

#### 4. Safe Builtin Alternatives
**Status:** needs fixes

**Issues:**
- All replacements are technically correct
- **Inconsistency:** Table uses `workflow.new_random()` but Best Practices section says `workflow.random()`
- Both exist and are valid, but should be consistent
- Recommend using `workflow.random()` throughout (simpler approach)

---

#### 5. Testing Replay Compatibility
**Status:** all good

**Verified:**
- `Replayer` class mention is correct ✓
- Reference to `references/python/testing.md` path follows consistent pattern ✓

---

#### 6. Sandbox Behavior
**Status:** all good

**Verified:**
- Sandbox behavior bullets match determinism-protection.md ✓
- Reference to `references/python/determinism-protection.md` path is correct ✓

---

#### 7. Best Practices
**Status:** needs fixes

**Issues:**
- Best Practices list itself is accurate ✓
- **Internal inconsistency:** Table in §4 (Safe Builtin Alternatives) uses `workflow.new_random()` but Best Practices #2 says `workflow.random()`
- Both APIs exist but should be consistent - recommend `workflow.random()` throughout

---

## Python: error-handling.md

**File:** `references/python/error-handling.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | all good | | context7 sdk-python |
| 2 | Application Errors | all good | | context7 sdk-python |
| 3 | Non-Retryable Errors | all good | | context7 sdk-python |
| 4 | Handling Activity Errors | all good | | context7 sdk-python |
| 5 | Retry Policy Configuration | all good | | context7 sdk-python |
| 6 | Timeout Configuration | all good | | context7 sdk-python |
| 7 | Workflow Failure | needs fixes | | context7 sdk-python |
| 8 | Best Practices | all good | | context7 sdk-python |

### Detailed Notes

#### 1. Overview
**Status:** all good

**Verified:**
- `ApplicationError` for application-specific errors ✓
- Comprehensive retry policy configuration ✓
- Applies to activities, child workflows, Nexus operations ✓

---

#### 2. Application Errors
**Status:** all good

**Verified:**
- `from temporalio.exceptions import ApplicationError` ✓
- `ApplicationError(message, type=...)` constructor signature ✓
- `@activity.defn` decorator context ✓

---

#### 3. Non-Retryable Errors
**Status:** all good

**Verified:**
- `non_retryable=True` parameter ✓
- Behavior: prevents activity retries ✓
- Example use case (invalid credit card) matches official docs ✓

---

#### 4. Handling Activity Errors
**Status:** all good

**Verified:**
- `from temporalio.exceptions import ActivityError, ApplicationError` ✓
- `ActivityError` is subclass of `FailureError` ✓
- `workflow.logger.error()` API ✓
- Try/except/raise pattern ✓

---

#### 5. Retry Policy Configuration
**Status:** all good

**Verified:**
- `RetryPolicy` import from `temporalio.common` ✓
- All RetryPolicy parameters (`maximum_interval`, `maximum_attempts`, `non_retryable_error_types`) ✓
- Note about preferring defaults is valid guidance ✓

---

#### 6. Timeout Configuration
**Status:** all good

**Verified:**
- `start_to_close_timeout` - "Single attempt" ✓
- `schedule_to_close_timeout` - "Including retries" ✓
- `heartbeat_timeout` - "Between heartbeats" ✓

---

#### 7. Workflow Failure
**Status:** needs fixes

**Issues:**
- Code example for raising `ApplicationError` in workflow is correct ✓
- **Note is misleading:** "Do not use `non_retryable=` with `ApplicationError` inside a workflow"
- `non_retryable` parameter IS valid for `ApplicationError` in workflows per SDK docs
- The SDK says: "ApplicationError should be used; this allows for marking the error as non-retryable"
- The difference is that workflow retry behavior is controlled by the caller's retry policy, not the exception's `non_retryable` flag
- **Recommendation:** Clarify the note to explain the behavioral difference rather than saying "do not use"

---

#### 8. Best Practices
**Status:** all good

**Verified:**
- All 6 best practices are valid ✓
- Reference to `references/core/patterns.md` path is correct ✓
- "Mark permanent failures as non-retryable" guidance ✓
- "Design code to be idempotent" guidance ✓

---

## Python: gotchas.md

**File:** `references/python/gotchas.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | File Organization (intro) | needs fixes | | context7 sdk-python |
| 2 | File Organization | needs fixes | | context7 sdk-python |
| 3 | Importing Activities into Workflow Files | needs fixes | | context7 sdk-python |
| 4 | Mixing Workflows and Activities | needs fixes | | context7 sdk-python |
| 5 | Async vs Sync Activities | needs fixes | | context7 sdk-python |
| 6 | Blocking in Async Activities | all good | | context7 sdk-python |
| 7 | Missing Executor for Sync Activities | needs fixes | | context7 sdk-python |
| 8 | Wrong Retry Classification | all good | | context7 sdk-python |
| 9 | Heartbeating | all good | | context7 sdk-python |
| 10 | Testing / Timers and Sleep | needs fixes | | context7 sdk-python |

### Detailed Notes

#### 1. File Organization (intro)
**Status:** needs fixes

**Issues:**
- **Inaccurate claim:** "The Python sandbox reloads workflow files on every task"
- **Correct:** "The Python sandbox reloads non-standard-library and non-Temporal modules for each workflow run"
- Task vs workflow run is important distinction
- Standard library and Temporal SDK modules are passed through (not re-imported)

---

#### 2. File Organization
**Status:** needs fixes

**Issues:**
- Same inaccuracy as §1 - says "workflow files" but should say "non-standard-library modules"
- The `imports_passed_through()` pattern itself is correct ✓
- Missing context: should mention performance AND memory benefits, not just "slows down workers"

---

#### 3. Importing Activities into Workflow Files
**Status:** needs fixes

**Issues:**
- **Inaccurate:** "on every task" should be "for each workflow run or replay"
- The `workflow.unsafe.imports_passed_through()` pattern is correct ✓
- SDK docs: "re-imports the workflow definition file into a new sandbox environment for each workflow run or replay"

---

#### 4. Mixing Workflows and Activities
**Status:** needs fixes

**Issues:**
- Recommendation to separate files is correct ✓
- **Missing:** Primary documented reason is testability, not just performance
- **Incomplete:** The "GOOD" example shows `my_activity` referenced but never imported
- Should show complete pattern with `imports_passed_through()` for activity import
- Or reference §3 which covers the import pattern

---

#### 5. Async vs Sync Activities
**Status:** needs fixes

**Issues:**
- All technical claims about async vs sync activities are correct ✓
- **Typo:** Line 66 says "aysnc" should be "async"
- Blocking warning and executor requirement correctly documented ✓

---

#### 6. Blocking in Async Activities
**Status:** all good

**Verified:**
- Blocking I/O in async activity is BAD ✓
- SDK docs: "WARNING: Do not block the thread in `async def` Python functions"
- GOOD Option 1: sync activity with `ThreadPoolExecutor` ✓
- GOOD Option 2: async I/O with `aiofiles` ✓

---

#### 7. Missing Executor for Sync Activities
**Status:** needs fixes

**Issues:**
- Core claim is correct: sync activities REQUIRE executor ✓
- **Claim unverified:** "THIS IMMEDIATELY RAISES AN EXCEPTION!"
- SDK docs say executor "must be set" but don't specify exact error behavior
- The requirement is documented, but the timing/nature of error is not explicitly stated
- **Recommendation:** Soften to "Sync activities require an executor" without specific exception claim

---

#### 8. Wrong Retry Classification
**Status:** all good

**Verified:**
- Concept is accurate ✓
- Reference to `references/python/error-handling.md` path is correct ✓

---

#### 9. Heartbeating
**Status:** all good

**Verified:**
- `activity.heartbeat(details)` API ✓
- Progress reporting pattern ✓
- `heartbeat_timeout` parameter in `workflow.execute_activity()` ✓
- Guidance on appropriate timeout values ✓
- SDK docs: "It is strongly recommended that all but the fastest executing activities call this function regularly"

---

#### 10. Testing / Timers and Sleep
**Status:** needs fixes

**Issues:**
- **MAJOR ERROR:** Document claims `asyncio.sleep` is "Non-deterministic!" in workflows
- **This is INCORRECT** - In Temporal Python workflows, `asyncio.sleep` IS backed by workflow timers
- SDK docs: "Timers in Temporal workflows are typically implemented using `asyncio.sleep()` or `workflow.sleep()`"
- SDK example shows: `await asyncio.sleep(24 * 60 * 60)` in a workflow
- Both `asyncio.sleep()` and `workflow.sleep()` create deterministic timers in workflows
- `workflow.sleep()` accepts `timedelta` or string durations, `asyncio.sleep()` accepts numeric seconds
- **Recommendation:** Remove the BAD/GOOD framing - both are valid

---

## Python: observability.md

**File:** `references/python/observability.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | all good | | context7 sdk-python |
| 2 | Workflow Logging (Replay-Safe) | all good | | context7 sdk-python |
| 3 | Activity Logging | needs fixes | | context7 sdk-python, sdk source |
| 4 | Customizing Logger Configuration | needs fixes | | context7 sdk-python, sdk source |
| 5 | Enabling SDK Metrics | needs fixes | | context7 sdk-python, temporal-docs |
| 6 | Key SDK Metrics | all good | | temporal-docs |
| 7 | Search Attributes (Visibility) | needs fixes | | context7 sdk-python |
| 8 | Best Practices | needs fixes | | context7 sdk-python |

### Detailed Notes

#### 1. Overview
**Status:** all good

**Verified:**
- Logging via `workflow.logger` and `activity.logger` ✓
- Metrics via SDK metrics emission and custom metric meters ✓
- Tracing via OpenTelemetry integration with `TracingInterceptor` ✓
- Visibility (Search Attributes) for querying and filtering workflows ✓

---

#### 2. Workflow Logging (Replay-Safe)
**Status:** all good

**Verified:**
- `workflow.logger` API ✓
- `workflow.logger.info(message, extra={...})` signature ✓
- "Suppresses duplicate logs during replay" - SDK confirms logger "skips logging during replay operations" ✓
- Includes workflow context ✓

---

#### 3. Activity Logging
**Status:** needs fixes

**Issues:**
- `activity.logger` API is correct ✓
- **Incomplete context list:** Document says "Activity ID, type, and task queue; Workflow ID and run ID; Attempt number"
- **Actual SDK includes:** activity_id, activity_type, attempt, namespace, task_queue, workflow_id, workflow_run_id, workflow_type
- **Missing from doc:** `namespace` and `workflow_type`

---

#### 4. Customizing Logger Configuration
**Status:** needs fixes

**Issues:**
- `logging.basicConfig()` does affect Temporal loggers ✓
- **Misleading comment:** "Temporal inherits the default logger" is incorrect
- Temporal loggers are named loggers (`temporalio.workflow`, `temporalio.activity`) that propagate to root
- Configuration works via **propagation**, not inheritance of default logger

---

#### 5. Enabling SDK Metrics
**Status:** needs fixes

**Issues:**
- All imports and API are correct ✓
- `Runtime.set_default()` is technically valid ✓
- **Non-standard approach:** Official docs and samples pass `runtime=` to `Client.connect()` instead
- Official pattern: `client = await Client.connect(..., runtime=runtime)`
- Document's approach works but diverges from canonical examples

---

#### 6. Key SDK Metrics
**Status:** all good

**Verified:**
- `temporal_request` - Client requests to server ✓
- `temporal_workflow_task_execution_latency` - Workflow task processing time ✓
- `temporal_activity_execution_latency` - Activity execution time ✓
- `temporal_workflow_task_replay_latency` - Replay duration ✓

---

#### 7. Search Attributes (Visibility)
**Status:** needs fixes

**Issues:**
- Reference to `data-handling.md` is correct ✓
- **Same issue as data-handling.md §6:** `workflow.upsert_search_attributes()` API is incorrect
- Document shows: `workflow.upsert_search_attributes(TypedSearchAttributes([...]))`
- Correct API: `workflow.upsert_search_attributes([KEY.value_set(value)])`

---

#### 8. Best Practices
**Status:** needs fixes

**Issues:**
- Best practices #2-4 are valid ✓
- **Best practice #1 is INCORRECT:** "`activity.logger` in activities" - `activity.logger` does NOT exist
- Activities can use standard Python logging or print statements
- Should say: "Use `workflow.logger` in workflows for replay-safe logging; activities can use standard Python logging"

---

## Python: patterns.md

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
| 14 | Waiting for All Handlers to Finish | all good | | context7 sdk-python |
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
**Status:** all good

**Verified:**
- `workflow.all_handlers_finished` function exists ✓
- `workflow.wait_condition(workflow.all_handlers_finished)` pattern is correct ✓
- Use cases: async handlers, before continue-as-new ✓
- SDK docs: "One way to ensure that handler tasks have finished is to wait on the `workflow.all_handlers_finished` condition"

---

#### 15. Activity Heartbeat Details
**Status:** all good

**Verified:**
- `activity.info().heartbeat_details` returns iterable (indexable) ✓
- `activity.heartbeat(progress)` API with `*details` signature ✓
- Resume pattern: check heartbeat_details, skip processed items ✓
- SDK docs: "If an activity calls `temporalio.activity.heartbeat(123, 456)` and then fails and is retried, `temporalio.activity.info().heartbeat_details` will return an iterable containing `123` and `456` on the next run."

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

## Python: python.md

**File:** `references/python/python.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | needs fixes | | context7 sdk-python |
| 2 | Quick Demo of Temporal | all good | | context7 sdk-python |
| 3 | Key Concepts - Workflow Definition | all good | | context7 sdk-python |
| 4 | Key Concepts - Activity Definition | all good | | context7 sdk-python |
| 5 | Key Concepts - Worker Setup | all good | | context7 sdk-python |
| 6 | Key Concepts - Determinism | all good | | file verification |
| 7 | File Organization Best Practice | needs fixes | | context7 sdk-python |
| 8 | Common Pitfalls | needs fixes | | context7 sdk-python |
| 9 | Writing Tests | all good | | file verification |
| 10 | Additional Resources | all good | | file verification |

### Detailed Notes

#### 1. Overview
**Status:** needs fixes

**Issues:**
- "Fully async, type-safe" description ✓
- **"Python 3.9+ required" is OUTDATED** - SDK v1.22.0 requires **Python 3.10+**
- "Sandbox by default for determinism protection" ✓

---

#### 2. Quick Demo of Temporal
**Status:** all good

**Verified:**
- `temporalio` package name ✓
- `@activity.defn` decorator on sync function ✓
- `@workflow.defn` on class, `@workflow.run` on method ✓
- `workflow.unsafe.imports_passed_through()` for activity import ✓
- `workflow.execute_activity(fn, arg, start_to_close_timeout=...)` API ✓
- `Client.connect()`, `Worker()` constructor, `worker.run()` pattern ✓
- `ThreadPoolExecutor` for sync activity executor ✓
- `workflows=[...]` and `activities=[...]` parameters ✓
- `client.execute_workflow(Workflow.run, arg, id=..., task_queue=...)` API ✓
- `temporal server start-dev` command ✓
- Expected output "Result: Hello, my-name!" ✓

---

#### 3. Key Concepts - Workflow Definition
**Status:** all good

**Verified:**
- `@workflow.defn` decorator on class ✓
- `@workflow.run` on entry point method ✓
- Must be async (`async def`) ✓
- `@workflow.signal`, `@workflow.query`, `@workflow.update` decorators ✓
- SDK docs: "The decorated method must be an `async def` function"

---

#### 4. Key Concepts - Activity Definition
**Status:** all good

**Verified:**
- `@activity.defn` decorator ✓
- Can be sync or async functions ✓
- "Default to sync activities" recommendation matches official guidance ✓
- Sync activities need `activity_executor` (ThreadPoolExecutor) ✓
- Async activities require async-safe libraries ✓
- Reference to `sync-vs-async.md` path exists ✓

---

#### 5. Key Concepts - Worker Setup
**Status:** all good

**Verified:**
- Connect client, create Worker pattern ✓
- `await worker.run()` method ✓
- Custom executor via `activity_executor` parameter ✓

---

#### 6. Key Concepts - Determinism
**Status:** all good

**Verified:**
- "Workflow code must be deterministic" claim ✓
- Both reference files exist:
  - `references/core/determinism.md` ✓
  - `references/python/determinism.md` ✓

---

#### 7. File Organization Best Practice
**Status:** needs fixes

**Issues:**
- **Imprecise claim:** "Sandbox reloads Workflow definition files on every execution"
- **More accurate:** "Sandbox re-imports non-passthrough modules in Workflow files for each workflow run"
- SDK docs: "re-imports the workflow definition file into a new sandbox environment for each workflow run or replay"
- Standard library and passthrough modules are NOT reloaded
- Directory structure recommendation is valid ✓
- Pass-through import pattern is correct ✓

---

#### 8. Common Pitfalls
**Status:** needs fixes

**Issues:**
- Pitfalls 1-4, 6-7 are accurate ✓
- **Pitfall 5 (gevent) needs refinement:** Says "Incompatible with SDK" but SDK docs note a workaround exists
- SDK docs: "This is a known incompatibility... But if you must, there is a sample showing how it is possible"
- Suggest: "gevent is problematic and discouraged, but possible with workarounds (see samples-python/gevent_async)"

---

#### 9. Writing Tests
**Status:** all good

**Verified:**
- Reference path `references/python/testing.md` exists ✓

---

#### 10. Additional Resources
**Status:** all good

**Verified:**
- All 12 reference file paths exist ✓

---

## Python: sync-vs-async.md

**File:** `references/python/sync-vs-async.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | all good | | context7 sdk-python |
| 2 | Recommendation: Default to Synchronous | all good | | context7 sdk-python |
| 3 | The Event Loop Problem | all good | | context7 sdk-python |
| 4 | Synchronous Activities | all good | | context7 sdk-python |
| 5 | Asynchronous Activities | all good | | context7 sdk-python, aiohttp docs |
| 6 | HTTP Libraries: A Critical Choice | all good | | context7 sdk-python, temporal-docs |
| 7 | Running Blocking Code in Async Activities | all good | | context7 sdk-python |
| 8 | When to Use Async Activities | all good | | context7 sdk-python |
| 9 | When to Use Sync Activities | all good | | context7 sdk-python |
| 10 | Debugging Tip | all good | | context7 sdk-python |
| 11 | Multi-Core Usage | all good | | context7 sdk-python, temporal-docs |
| 12 | Separate Workers for Workflows vs Activities | all good | | context7 sdk-python, temporal-docs |
| 13 | Complete Example: Sync Activity | all good | | context7 sdk-python |
| 14 | Complete Example: Async Activity | all good | | context7 sdk-python |
| 15 | Summary Table | all good | | context7 sdk-python |

### Detailed Notes

#### 1. Overview
**Status:** all good

**Verified:**
- Three approaches: asyncio, ThreadPoolExecutor, ProcessPoolExecutor ✓
- SDK docs: "Asynchronous activities are functions defined with `async def`"
- SDK docs: "activity_executor... must be set with a `concurrent.futures.Executor` instance"
- SDK docs: mentions ThreadPoolExecutor for threaded and ProcessPoolExecutor for multiprocess

---

#### 2. Recommendation: Default to Synchronous
**Status:** all good

**Verified:**
- "Default to synchronous" recommendation is pragmatically sound ✓
- SDK docs: "Threaded activities are the initial recommendation"
- SDK warning: "Do not block the thread in `async def` Python functions. This can stop the processing of the rest of the Temporal."
- Note: SDK says async is "more performant" when done correctly, but sync is safer for most developers

---

#### 3. The Event Loop Problem
**Status:** all good

**Verified:**
- Single-thread event loop explanation ✓
- Blocking call consequences list ✓
- SDK warning: "Do not block the thread in `async def` Python functions. This can stop the processing of the rest of the Temporal."
- "Stop the processing" confirms blocking affects entire worker

---

#### 4. Synchronous Activities
**Status:** all good

**Verified:**
- "Run in activity_executor" ✓
- "Must provide executor" - SDK: "activity_executor... must be set" ✓
- `ThreadPoolExecutor` context manager pattern ✓
- `activity_executor` parameter in `Worker()` ✓

---

#### 5. Asynchronous Activities
**Status:** all good

**Verified:**
- "Share default asyncio event loop" ✓ - no separate executor needed for async
- "Any blocking call freezes the entire loop" ✓ - confirmed by SDK warning
- `aiohttp.ClientSession` async context manager pattern ✓ - matches official aiohttp docs

---

#### 6. HTTP Libraries: A Critical Choice
**Status:** all good

**Verified:**
- `requests` blocking - SDK: "making an HTTP call with the popular `requests` library...would lead to blocking your event loop" ✓
- `urllib3` blocking - implied (synchronous by design) ✓
- `aiohttp` async - SDK: "This Activity uses the `aiohttp` library to make an async safe HTTP request" ✓
- `httpx` both - SDK: "you should use an async-safe HTTP library such as `aiohttp` or `httpx`" ✓
- BAD/GOOD examples correctly demonstrate anti-pattern and correct pattern ✓

---

#### 7. Running Blocking Code in Async Activities
**Status:** all good

**Verified:**
- `loop.run_in_executor(None, fn)` pattern ✓
- `asyncio.to_thread(fn)` pattern (Python 3.9+) ✓
- SDK docs mention both: "loop.run_in_executor()" and "asyncio.to_thread()"
- Note: Modern code should prefer `asyncio.get_running_loop()` over `get_event_loop()`

---

#### 8. When to Use Async Activities
**Status:** all good

**Verified:**
- All 4 criteria are accurate guidance ✓
- SDK: "Do not block the thread in `async def` Python functions" supports criteria 1
- SDK: "Asynchronous activities are often much more performant" supports criteria 3
- Criteria 2 and 4 are sound practical advice

---

#### 9. When to Use Sync Activities
**Status:** all good

**Verified:**
- All 5 use cases are accurate ✓
- SDK: "By default, Activities should be synchronous rather than asynchronous"
- SDK: "making an HTTP call with the popular `requests` library...would lead to blocking" supports case 1
- SDK: file I/O is listed as blocking call, supports case 2

---

#### 10. Debugging Tip
**Status:** all good

**Verified:**
- Convert async to sync debugging approach is valid ✓
- SDK warning: "Do not block the thread in `async def` Python functions. This can stop the processing of the rest of the Temporal."
- If bugs disappear when converting to sync, indicates blocking calls were the issue

---

#### 11. Multi-Core Usage
**Status:** all good

**Verified:**
- Multiple worker processes recommendation ✓ - SDK: "Run more than one Worker Process"
- ProcessPoolExecutor with caveats ✓ - SDK: "Users should prefer threaded activities over multiprocess ones since, among other reasons, threaded activities can raise on cancellation"
- Extra complexity: requires SharedStateManager, pickling, spawn/fork issues

---

#### 12. Separate Workers for Workflows vs Activities
**Status:** all good

**Verified:**
- Workflow-only vs Activity-only workers pattern ✓ - confirmed in Slack and community docs
- Resource contention and scaling benefits ✓
- Note: Workflows are more memory-bound than CPU-bound; characterization could be refined but core message is correct

---

#### 13. Complete Example: Sync Activity
**Status:** all good

**Verified:**
- `@activity.defn` on sync function ✓
- `requests` library usage appropriate for sync ✓
- `ThreadPoolExecutor` with `max_workers=100` matches SDK examples ✓
- Worker configuration code matches official pattern ✓

---

#### 14. Complete Example: Async Activity
**Status:** all good

**Verified:**
- Activity class with session injection ✓ - SDK: "Activities can be defined on methods... allows the instance to carry state"
- `@activity.defn` on async method ✓
- `async with session.get()` pattern ✓
- No `activity_executor` needed ✓ - SDK: "When using asynchronous activities no special worker parameters are needed"

---

#### 15. Summary Table
**Status:** all good

**Verified:**
- All table cells are accurate ✓
- "Debugging: Easier/Harder" not explicitly documented but reasonable industry knowledge
- All other cells match SDK documentation

---

## Python: testing.md

**File:** `references/python/testing.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | all good | | context7 sdk-python |
| 2 | Workflow Test Environment | needs fixes | | context7 sdk-python |
| 3 | Mocking Activities | all good | | context7 sdk-python |
| 4 | Testing Signals and Queries | all good | | context7 sdk-python |
| 5 | Testing Failure Cases | all good | | context7 sdk-python |
| 6 | Workflow Replay Testing | all good | | context7 sdk-python |
| 7 | Activity Testing | all good | | context7 sdk-python |
| 8 | Best Practices | all good | | context7 sdk-python |

### Detailed Notes

#### 1. Overview
**Status:** all good

**Verified:**
- `WorkflowEnvironment` from `temporalio.testing` ✓
- `ActivityEnvironment` from `temporalio.testing` ✓

---

#### 2. Workflow Test Environment
**Status:** needs fixes

**Verified:**
- `WorkflowEnvironment.start_local()` API ✓
- `async with await WorkflowEnvironment.start_local() as env` pattern ✓
- `env.client` property ✓
- `async with Worker(...)` context manager ✓
- `env.client.execute_workflow()` API ✓
- `@pytest.mark.asyncio` decorator ✓
- `WorkflowEnvironment.start_time_skipping()` API ✓
- "Cannot be shared among tests" for time-skipping ✓

**Issues:**
- **Code example has bug:** `task_queue` variable is used in `execute_workflow()` but never defined
- Should define `task_queue = str(uuid.uuid4())` before the Worker context

---

#### 3. Mocking Activities
**Status:** all good

**Verified:**
- `@activity.defn(name="...")` for mock with same name ✓
- Register mock activity with Worker instead of real one ✓
- SDK: "Simply write different ones and pass those to the worker"

---

#### 4. Testing Signals and Queries
**Status:** all good

**Verified:**
- `env.client.start_workflow()` returns handle ✓
- `handle.signal(Workflow.signal_method, data)` API ✓
- `handle.query(Workflow.query_method)` API ✓
- `handle.result()` API ✓

---

#### 5. Testing Failure Cases
**Status:** all good

**Verified:**
- `ApplicationError(..., non_retryable=True)` from `temporalio.exceptions` ✓
- `WorkflowFailureError` from `temporalio.client` ✓
- `pytest.raises(WorkflowFailureError)` pattern ✓

---

#### 6. Workflow Replay Testing
**Status:** all good

**Verified:**
- `Replayer` import from `temporalio.worker` ✓
- `WorkflowHistory` import from `temporalio.client` ✓
- `Replayer(workflows=[...])` constructor ✓
- `replayer.replay_workflow()` API ✓
- `WorkflowHistory.from_json()` API ✓
- Note: SDK examples use positional args but keyword args in section should also work

---

#### 7. Activity Testing
**Status:** all good

**Verified:**
- `ActivityEnvironment` from `temporalio.testing` ✓
- `ActivityEnvironment()` constructor ✓
- `env.run(activity_fn, *args)` API ✓
- Note: Section is minimal but accurate; ActivityEnvironment has additional features (info, on_heartbeat, cancel)

---

#### 8. Best Practices
**Status:** all good

**Verified:**
- All 6 best practices are valid ✓
- UUID recommendation for test isolation ✓
- Time-skipping for workflows with timers ✓
- Replay tests for determinism verification ✓
- `async with Worker(...)` context manager
- `env.client.execute_workflow()` API
- `@pytest.mark.asyncio` decorator
- UUID for task queue and workflow ID pattern
- `WorkflowEnvironment.start_time_skipping()` API
- "Cannot be shared among tests" for time-skipping claim

---

## Python: versioning.md

**File:** `references/python/versioning.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | needs fixes | | context7 sdk-python, temporal-docs |
| 2 | Why Versioning is Needed | all good | | context7 sdk-python, temporal-docs |
| 3 | The patched() Function | all good | | context7 sdk-python, temporal-docs |
| 4 | Three-Step Patching Process | all good | | context7 sdk-python, temporal-docs |
| 5 | Branching with Multiple Patches | all good | | context7 sdk-python, temporal-docs |
| 6 | Query Filters for Finding Workflows by Version | all good | | context7 sdk-python, temporal-docs |
| 7 | Workflow Type Versioning | all good | | context7 sdk-python, temporal-docs |
| 8 | Worker Versioning Key Concepts | all good | | context7 sdk-python, temporal-docs |
| 9 | Configuring Workers for Versioning | needs fixes | | context7 sdk-python, temporal-docs |
| 10 | PINNED vs AUTO_UPGRADE Behaviors | needs fixes | | context7 sdk-python, temporal-docs |
| 11 | Worker Configuration with Default Behavior | all good | | context7 sdk-python, temporal-docs |
| 12 | Deployment Strategies | all good | | context7 sdk-python, temporal-docs |
| 13 | Querying Workflows by Worker Version | all good | | context7 sdk-python, temporal-docs |
| 14 | Choosing a Strategy | needs fixes | | context7 sdk-python, temporal-docs |
| 15 | Best Practices | all good | | context7 sdk-python, temporal-docs |

### Detailed Notes

#### 1. Overview
**Status:** needs fixes

**Issues:**
- **Lists 3 approaches but official docs list 2 primary methods:**
  - Official: Patching API, Worker Versioning (2 primary)
  - Section: Patching API, Workflow Type Versioning, Worker Versioning (3)
- Workflow Type Versioning is acknowledged in learning materials but NOT listed as primary in SDK docs
- SDK docs: "There are two primary Versioning methods"
- Workflow Type Versioning is more of a manual convention than SDK-provided mechanism

---

#### 2. Why Versioning is Needed
**Status:** all good

**Verified:**
- History Replay explanation ✓ - "Workers will resume those executions automatically after the restart. They do this through History Replay"
- Non-deterministic error cause ✓ - "If that produces a different sequence of Commands than the code in use before the restart, then it will result in a non-deterministic error"
- Three-point explanation is accurate ✓

---

#### 3. The patched() Function
**Status:** all good

**Verified:**
- `workflow.patched("patch-id")` API returns bool ✓
- "For new executions returns True and records marker" behavior ✓
- "For replay with marker returns True" behavior ✓
- "For replay without marker returns False" behavior ✓

---

#### 4. Three-Step Patching Process
**Status:** all good

**Verified:**
- Step 1: `workflow.patched()` with both code paths ✓
- Step 2: `workflow.deprecate_patch()` API ✓
- Step 3: Remove deprecate_patch call ✓
- Process aligns with official SDK documentation

---

#### 5. Branching with Multiple Patches
**Status:** all good

**Verified:**
- Multiple `workflow.patched()` calls in if/elif/else chain ✓
- Single patch ID for multiple changes pattern ✓
- Code example correctly demonstrates branching logic

---

#### 6. Query Filters for Finding Workflows by Version
**Status:** all good

**Verified:**
- `TemporalChangeVersion` search attribute ✓
- `TemporalChangeVersion IS NULL` for pre-patch workflows ✓
- CLI query syntax is correct ✓

---

#### 7. Workflow Type Versioning
**Status:** all good

**Verified:**
- `@workflow.defn(name="...")` for explicit name ✓
- New workflow class with V2 suffix pattern ✓
- Register both workflows with Worker ✓
- Check for open executions CLI command ✓

---

#### 8. Worker Versioning Key Concepts
**Status:** all good

**Verified:**
- Worker Deployment definition accurate ✓
- Worker Deployment Version definition (deployment name + Build ID) ✓
- Conceptual explanations align with official documentation

---

#### 9. Configuring Workers for Versioning
**Status:** needs fixes

**Issues:**
- **Wrong import paths for Worker Versioning classes:**
  - Doc shows: `from temporalio.worker.deployment_config import WorkerDeploymentConfig, WorkerDeploymentVersion`
  - Correct: `WorkerDeploymentConfig` from `temporalio.worker`
  - Correct: `WorkerDeploymentVersion` from `temporalio.common`
- `deployment_config` parameter in `Worker()` is correct ✓
- Constructor patterns are correct ✓

---

#### 10. PINNED vs AUTO_UPGRADE Behaviors
**Status:** needs fixes

**Issues:**
- **Wrong import location for VersioningBehavior:**
  - Doc shows: `from temporalio.workflow import VersioningBehavior`
  - Correct: `from temporalio.common import VersioningBehavior`
- PINNED behavior description is correct ✓
- AUTO_UPGRADE behavior description is correct ✓
- "AUTO_UPGRADE still needs patching" claim is accurate ✓
- Use case recommendations are valid ✓

---

#### 11. Worker Configuration with Default Behavior
**Status:** all good

**Verified:**
- `default_versioning_behavior` parameter correctly shown ✓
- `os.environ["BUILD_ID"]` pattern is reasonable ✓
- Configuration example is accurate

---

#### 12. Deployment Strategies
**Status:** all good

**Verified:**
- Blue-Green deployment description accurate ✓
- Rainbow deployment description accurate ✓
- Kubernetes ReplicaSets mention is appropriate ✓

---

#### 13. Querying Workflows by Worker Version
**Status:** all good

**Verified:**
- `TemporalWorkerDeploymentVersion` search attribute ✓
- CLI query syntax is correct ✓

---

#### 14. Choosing a Strategy
**Status:** needs fixes

**Issues:**
- **Missing deprecation notice:** The pre-2025 Worker Versioning API (Build ID-based versioning) is being removed in March 2026
- Decision table and factors are otherwise accurate
- Should add note about deprecation timeline for old Worker Versioning

---

#### 15. Best Practices
**Status:** all good

**Verified:**
- All 7 best practices are valid ✓
- Guidance aligns with official documentation

---
