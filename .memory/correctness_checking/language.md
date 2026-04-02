# {language}.md (top-level files)

Correctness verification for `references/{language}/{language}.md` (e.g., typescript.md, python.md).

## TypeScript

**File:** `references/typescript/typescript.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | FIXED | Changed to "isolated runtime with bundling" | context7 sdk-typescript |
| 2 | Understanding Replay | FIXED | Fixed ref path to references/core/ | context7 sdk-typescript |
| 3 | Quick Start | FIXED | Package-manager agnostic (removed `npm install` command) | SDK team feedback |
| 4 | Key Concepts | FIXED | Added defineUpdate() and activities param | context7 sdk-typescript |
| 5 | File Organization Best Practice | all good | | context7 sdk-typescript |
| 6 | Determinism Rules | all good | | context7 sdk-typescript |
| 7 | Common Pitfalls | FIXED | Updated logging: prefer `log`, but console.log works (patched) | SDK team feedback |
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
**Status:** FIXED

**SDK team feedback:** Users may use different package managers (npm, pnpm, yarn, bun). Removed specific `npm install` command, now just lists the packages to install.

**Verified:** Code examples (activities.ts, workflows.ts, worker.ts, client.ts), commands, expected output all correct

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

**SDK team feedback:** `console.log` is NOT forbidden - the SDK patches console.log/warn/error to include workflow ID. Updated to say "Prefer `log` from `@temporalio/workflow`" and note that "console.log also works (it's patched to include workflow ID)".

---

#### 8. Writing Tests
**Status:** all good

**Verified:** Reference path to testing.md is correct

---

#### 9. Additional Resources
**Status:** all good

**Verified:** All 10 reference file paths exist and are correct

---


## Python

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


## Java

**File:** `references/java/java.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | FIXED | Added Java 21+ recommendation; removed verbose Python/TS sandbox comparison | SDK team feedback |
| 2 | Quick Start | all good | | temporal-docs |
| 3 | Key Concepts | all good | | temporal-docs |
| 4 | Worker Setup | all good | | temporal-docs |
| 5 | Activity/Workflow Patterns | all good | | temporal-docs |

### Detailed Notes

#### 1. Overview
**Status:** FIXED

**SDK team feedback:** "Java 8+ required" was technically true but could lead agents to bootstrap new projects with Java 8. Updated to "Java 8+ required; Java 21+ strongly recommended for virtual thread support."

---

#### 2–5. Quick Start, Key Concepts, Worker Setup, Activity/Workflow Patterns
**Status:** all good

Verified correct against temporal-docs.

---


## Go

**File:** `references/go/go.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | all good | | temporal-docs |
| 2 | Quick Start | all good | | temporal-docs |
| 3 | Key Concepts | all good | | temporal-docs |
| 4 | File Organization Best Practice | all good | | temporal-docs |
| 5 | Common Pitfalls | all good | | temporal-docs |
| 6 | Writing Tests | all good | | temporal-docs |
| 7 | Additional Resources | all good | | temporal-docs |

### Detailed Notes

#### 1. Overview
**Status:** all good
**Verified:**
- No runtime sandbox, developer-convention-based determinism ✓
- `workflowcheck` static analysis tool mentioned ✓

---

#### 2. Quick Start
**Status:** all good
**Verified:**
- `go.temporal.io/sdk` dependency ✓
- Workflow, activity, worker, client code examples ✓

---

#### 3. Key Concepts
**Status:** all good
**Verified:**
- Workflow as exported Go function ✓
- Activity definition pattern ✓
- Worker setup with `worker.New` ✓

---

#### 4. File Organization Best Practice
**Status:** all good
**Verified:**
- Recommended directory structure ✓

---

#### 5. Common Pitfalls
**Status:** all good
**Verified:**
- Determinism pitfalls listed accurately ✓

---

#### 6. Writing Tests
**Status:** all good
**Verified:**
- Reference to testing.md path ✓

---

#### 7. Additional Resources
**Status:** all good
**Verified:**
- Reference file paths listed correctly ✓

---

