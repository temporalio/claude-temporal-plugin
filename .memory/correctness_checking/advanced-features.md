# advanced-features.md

Correctness verification for `references/{language}/advanced-features.md`.

## TypeScript

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


## Python

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


## PHP

**File:** `references/php/advanced-features.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Schedules | unchecked | | |
| 2 | Async Activity Completion | unchecked | | |
| 3 | Worker Tuning | unchecked | | |
| 4 | RoadRunner Configuration | unchecked | | |

### Detailed Notes

#### 1. Schedules
**Status:** unchecked

---

#### 2. Async Activity Completion
**Status:** unchecked

---

#### 3. Worker Tuning
**Status:** unchecked

---

#### 4. RoadRunner Configuration
**Status:** unchecked

---


## Go

**File:** `references/go/advanced-features.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Schedules | all good | | temporal-docs |
| 2 | Async Activity Completion | all good | | temporal-docs |
| 3 | Worker Tuning | all good | | temporal-docs |
| 4 | Sessions | all good | | temporal-docs |

### Detailed Notes

#### 1. Schedules
**Status:** all good
**Verified:**
- `client.ScheduleClient().Create` API ✓
- `client.ScheduleOptions` struct ✓
- `client.ScheduleSpec` configuration ✓

---

#### 2. Async Activity Completion
**Status:** all good
**Verified:**
- `activity.ErrResultPending` to signal async completion ✓
- `CompleteActivity` / `CompleteActivityByID` for external completion ✓

---

#### 3. Worker Tuning
**Status:** all good
**Verified:**
- Worker tuning options ✓

---

#### 4. Sessions
**Status:** all good
**Verified:**
- `workflow.CreateSession` API ✓
- `workflow.CompleteSession` API ✓
- `EnableSessionWorker` worker option ✓
- `workflow.ErrSessionFailed` sentinel error ✓
- `workflow.SessionOptions` struct ✓

---

