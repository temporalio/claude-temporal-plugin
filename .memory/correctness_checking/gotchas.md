# gotchas.md

Correctness verification for `references/{language}/gotchas.md`.

## TypeScript

**File:** `references/typescript/gotchas.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Activity Imports - Type vs Implementation | all good | | context7 sdk-typescript |
| 2 | Activity Imports - Node.js Modules | all good | | context7 sdk-typescript |
| 3 | Bundling Issues - workflowsPath in Production | FIXED | Added new gotcha section | SDK team feedback |
| 4 | Bundling Issues - Missing Dependencies | FIXED | Clarified ignoreModules excludes modules | context7 sdk-typescript |
| 5 | Bundling Issues - Version Mismatches | all good | | context7 sdk-typescript |
| 6 | Wrong Retry Classification | all good | | context7 sdk-typescript |
| 7 | Cancellation - Not Handling Workflow | all good | | context7 sdk-typescript |
| 7b | Cancellation - Not Handling Activity | FIXED | Added activity cancellation section | SDK team feedback |
| 8 | Heartbeating - Forgetting to Heartbeat | all good | | context7 sdk-typescript |
| 9 | Heartbeating - Timeout Too Short | all good | | context7 sdk-typescript |
| 10 | Testing - Not Testing Failures | all good | | context7 sdk-typescript |
| 11 | Testing - Not Testing Replay | FIXED | Fixed fs.promises.readFile pattern | context7 sdk-typescript |
| 12 | Timers and Sleep | all good | | context7 sdk-typescript |

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

#### 3. Bundling Issues - workflowsPath in Production
**Status:** FIXED

**SDK team feedback:** `workflowsPath` runs bundler at Worker startup (slow). Should use `workflowBundle` with pre-bundled code for production. Added new gotcha section with example showing build-time bundling with `bundleWorkflowCode()`. Also updated examples in typescript.md, advanced-features.md, versioning.md, determinism-protection.md to caveat `workflowsPath` usage.

---

#### 4. Bundling Issues - Missing Dependencies
**Status:** FIXED

**Fixed:** Clarified that ignoreModules EXCLUDES modules and they are completely unavailable at workflow runtime.

---

#### 5. Bundling Issues - Version Mismatches
**Status:** all good

**Verified:** Package version matching claim and BAD/GOOD JSON examples are correct

---

#### 6. Wrong Retry Classification
**Status:** all good

**Verified:** error examples, ApplicationFailure.create() without nonRetryable, .nonRetryable() API, error-handling.md reference all correct

---

#### 7. Cancellation - Not Handling Workflow
**Status:** all good

**Verified:** CancellationScope import, .nonCancellable() for cleanup, try/finally pattern all correct

---

#### 7b. Cancellation - Not Handling Activity
**Status:** FIXED

**SDK team feedback:** Original section was only about workflow cleanup, missing the important case of activity cancellation handling. Activities must opt in to receive cancellation via:
1. Heartbeating (cancellation is delivered via heartbeat)
2. Checking for cancellation via `Context.current().cancelled` promise or `cancellationSignal()` AbortSignal

**Added content:**
- `Context.current().cancelled` - Promise that rejects with CancelledFailure
- `cancellationSignal()` - AbortSignal for use with fetch, child_process, etc.
- Note about Promise.race not stopping the losing promise

**Key guidance (apply to all languages):**
- Activities that don't heartbeat won't know they've been cancelled
- Two approaches: await cancelled promise, or use AbortSignal with compatible libraries

---

#### 8. Heartbeating - Forgetting to Heartbeat
**Status:** all good

**Verified:** heartbeat import, heartbeat(details) API, progress reporting pattern all correct

---

#### 9. Heartbeating - Timeout Too Short
**Status:** all good

**Verified:** heartbeatTimeout in proxyActivities and timeout guidance correct

---

#### 10. Testing - Not Testing Failures
**Status:** all good

**Verified:** createTimeSkipping(), nativeConnection, runUntil(), ApplicationFailure.nonRetryable() all correct

---

#### 11. Testing - Not Testing Replay
**Status:** FIXED

**Fixed:** Updated history loading to use fs.promises.readFile pattern for clarity.

---

#### 12. Timers and Sleep
**Status:** all good

**Verified:** setTimeout BAD pattern, sleep import, duration string format, durability claim all correct

---


## Python

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
| 10 | Cancellation - Not Handling Workflow | FIXED | Added workflow cancellation section | SDK team feedback |
| 11 | Cancellation - Not Handling Activity | FIXED | Added activity cancellation section | SDK team feedback |
| 12 | Testing / Timers and Sleep | needs fixes | | context7 sdk-python |

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

#### 10. Cancellation - Not Handling Workflow
**Status:** FIXED

**SDK team feedback:** Added workflow cancellation section (parallel to TypeScript). Shows try/finally pattern to ensure cleanup runs on cancellation.

---

#### 11. Cancellation - Not Handling Activity
**Status:** FIXED

**SDK team feedback:** Added activity cancellation handling section (parallel to TypeScript). Activities must opt in to receive cancellation via:
1. Heartbeating (cancellation is delivered via heartbeat)
2. Checking `activity.is_cancelled()` or catching cancellation exception

**Key differences from TypeScript:**
- No `cancellationSignal()` equivalent in Python
- Exception types differ: `asyncio.CancelledError` (async) vs `temporalio.exceptions.CancelledError` (sync threaded)

---

#### 12. Testing / Timers and Sleep
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


## Go

**File:** `references/go/gotchas.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Goroutines and Concurrency | all good | | temporal-docs |
| 2 | Non-Deterministic Operations | FIXED | Used `encoded.Get(&r)` pattern for SideEffect | temporal-docs |
| 3 | Wrong Retry Classification | all good | | temporal-docs |
| 4 | Cancellation | all good | | temporal-docs |
| 5 | Heartbeating | all good | | temporal-docs |
| 6 | Testing | all good | | temporal-docs |
| 7 | Timers and Sleep | all good | | temporal-docs |

### Detailed Notes

#### 1. Goroutines and Concurrency
**Status:** all good
**Verified:**
- Native `go`, `chan`, `select` flagged as non-deterministic ✓
- `workflow.Go`, `workflow.NewChannel`, `workflow.NewSelector` as safe alternatives ✓

---

#### 2. Non-Deterministic Operations
**Status:** FIXED

**Issue:** `workflow.SideEffect` is shown with tuple destructuring `val, _ := workflow.SideEffect(ctx, func(ctx workflow.Context) interface{} { ... })` but `workflow.SideEffect` returns a single `converter.EncodedValue`, not a tuple. Must use `.Get(&variable)` to extract the value. Code as written will not compile.

**Correct pattern:**
```go
encodedVal := workflow.SideEffect(ctx, func(ctx workflow.Context) interface{} {
    return rand.Intn(100)
})
var val int
_ = encodedVal.Get(&val)
```

---

#### 3. Wrong Retry Classification
**Status:** all good
**Verified:**
- `temporal.NewApplicationError` for retryable errors ✓
- `temporal.NewNonRetryableApplicationError` for permanent errors ✓

---

#### 4. Cancellation
**Status:** all good
**Verified:**
- `workflow.NewDisconnectedContext` for cleanup ✓
- Activity cancellation via heartbeat ✓

---

#### 5. Heartbeating
**Status:** all good
**Verified:**
- `activity.RecordHeartbeat` API ✓
- `HeartbeatTimeout` configuration ✓

---

#### 6. Testing
**Status:** all good
**Verified:**
- Testing patterns referenced correctly ✓

---

#### 7. Timers and Sleep
**Status:** all good
**Verified:**
- `time.Sleep` flagged as non-deterministic ✓
- `workflow.Sleep` as safe alternative ✓

---


## .NET

**File:** `references/dotnet/gotchas.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | .NET Task Determinism | all good | | SDK README |
| 2 | Wrong Retry Classification | all good | | — |
| 3 | Heartbeating | all good | `ActivityExecutionContext.Current.Heartbeat()` confirmed | temporal-docs API |
| 4 | Cancellation | all good | `CancellationToken.None` for cleanup confirmed | temporal-docs |
| 5 | Testing | all good | | — |
| 6 | Timers and Sleep | all good | | SDK README |
| 7 | Dictionary Iteration Order | all good | | SDK README |

### Detailed Notes

#### 1. .NET Task Determinism
**Status:** all good
**Verified:** All BAD/GOOD examples match SDK README `.NET Task Determinism` section exactly. `Workflow.RunTaskAsync`, `Workflow.DelayAsync`, `Workflow.WhenAllAsync`/`WhenAnyAsync`, `Temporalio.Workflows.Mutex`/`Semaphore` confirmed.

---

