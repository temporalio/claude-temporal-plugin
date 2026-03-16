# testing.md

Correctness verification for `references/{language}/testing.md`.

## TypeScript

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


## Python

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


## Java

**File:** `references/java/testing.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | TestWorkflowExtension | all good | | temporal-docs |
| 2 | Mockito Pattern | all good | | temporal-docs |
| 3 | WorkflowReplayer | all good | | temporal-docs |
| 4 | Activity Testing | all good | | temporal-docs |
| 5 | Best Practices | all good | | temporal-docs |

### Detailed Notes

All sections verified correct against temporal-docs. TestWorkflowExtension, Mockito pattern, and WorkflowReplayer all confirmed accurate.

---

