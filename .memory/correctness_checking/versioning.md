# versioning.md

Correctness verification for `references/{language}/versioning.md`.

## TypeScript

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

**SDK Team Feedback (for Go):** TypeScript `patched()` is NOT memoized on negative return (can use in loops, may need manual memoization for coordinated changes). Python/.NET/Ruby ARE memoized (cannot use in loops, workaround: append sequence number to patch ID). See temporalio/features#591.

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


## Python

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

**SDK Team Feedback (for Go):** Python `patched()` IS memoized on first call (cannot use in loops, workaround: append sequence number to patch ID). TypeScript is NOT memoized on negative return (can use in loops). Check Go SDK behavior. See temporalio/features#591.

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


## PHP

**File:** `references/php/versioning.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Patching API | all good | | context7 sdk-php |
| 2 | Workflow Type Versioning | all good | | context7 sdk-php |
| 3 | Worker Versioning | needs verification | | context7 sdk-php |
| 4 | Best Practices | all good | | context7 sdk-php |

### Detailed Notes

#### 1. Patching API
**Status:** all good

**Verified:**
- `Workflow::getVersion('changeId', Workflow::DEFAULT_VERSION, 1)` signature is correct
- `yield` on `getVersion()` is correct (it is a coroutine)
- `Workflow::DEFAULT_VERSION` constant is correct
- Three-step patching process (patch in, deprecate with min=max=1, remove) is correct
- The reference checks `$version === 1` for new code; official SDK example checks `$version === Workflow::DEFAULT_VERSION` for old code. Both are logically equivalent and correct.
- `TemporalChangeVersion` search attribute in query filters is correct

---

#### 2. Workflow Type Versioning
**Status:** all good

**Verified:**
- `#[WorkflowInterface]` and `#[WorkflowMethod(name: '...')]` attributes are correct
- V2 interface pattern is valid
- `registerWorkflowTypes()` API is correct
- `$client->newWorkflowStub()` with `WorkflowOptions::new()` is correct

---

#### 3. Worker Versioning
**Status:** needs verification

**Issues:**
- **`WorkerDeploymentOptions` class name could not be fully verified** — Context7 docs do not include Worker Versioning configuration examples for PHP SDK.
- The `deploymentOptions` parameter on `$factory->newWorker()` could not be verified.
- Worker Versioning is noted as Public Preview which is correct.
- Legacy API deprecation timeline (March 2026) is correct.
- PINNED vs AUTO_UPGRADE conceptual descriptions are correct.
- CLI commands (`temporal worker deployment set-current-version`, `TemporalWorkerDeploymentVersion` search attribute) are correct.

**Note:** Unable to verify Worker Versioning PHP-specific API due to limited documentation availability.

---

#### 4. Best Practices
**Status:** all good

**Verified:**
- All 5 best practices are valid
- "Use `yield` on `getVersion()`" is correctly emphasized as PHP-specific
- Guidance aligns with official documentation patterns

---


## Go

**File:** `references/go/versioning.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | GetVersion API | all good | | temporal-docs |
| 2 | Workflow Type Versioning | all good | | temporal-docs |
| 3 | Worker Versioning | all good | | temporal-docs |
| 4 | Best Practices | all good | | temporal-docs |

### Detailed Notes

#### 1. GetVersion API
**Status:** all good
**Verified:**
- `workflow.GetVersion(ctx, "changeID", workflow.DefaultVersion, maxSupported)` API ✓
- `workflow.DefaultVersion` constant ✓
- Three-step lifecycle (version with both paths, deprecate, remove) ✓

---

#### 2. Workflow Type Versioning
**Status:** all good
**Verified:**
- V2 workflow function pattern ✓
- Worker registration of both versions ✓

---

#### 3. Worker Versioning
**Status:** all good
**Verified:**
- `worker.DeploymentOptions` struct ✓
- `worker.WorkerDeploymentVersion` with `DeploymentName` and `BuildId` fields ✓
- `UseVersioning` field ✓
- `DefaultVersioningBehavior` field ✓
- `workflow.VersioningBehaviorPinned` / `workflow.VersioningBehaviorAutoUpgrade` constants ✓

---

#### 4. Best Practices
**Status:** all good
**Verified:**
- All best practices valid ✓

---

