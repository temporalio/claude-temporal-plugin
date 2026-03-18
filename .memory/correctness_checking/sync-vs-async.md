# sync-vs-async.md

Correctness verification for `references/python/sync-vs-async.md` (Python only).

## Python

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

