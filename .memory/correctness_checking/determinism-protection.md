# determinism-protection.md

Correctness verification for `references/{language}/determinism-protection.md`.

## TypeScript

**File:** `references/typescript/determinism-protection.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | FIXED | Removed "unique to TS" claim | context7 sdk-typescript |
| 2 | Import Blocking | FIXED | Clarified ignoreModules excludes | context7 sdk-typescript |
| 3 | Function Replacement | FIXED | Removed bad activity advice | SDK team feedback |

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
**Status:** FIXED

**SDK team feedback:** Removed misleading advice about retrieving time in an activity. Getting time via activity doesn't provide better real-world time estimate than Date.now().

**Verified:** Math.random(), Date, setTimeout() replacements all correct. Date behavior, code example, FinalizationRegistry/WeakRef removal, GC explanation all accurate.

---


## Python

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


## Java

**File:** `references/java/determinism-protection.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | No Sandbox | all good | | temporal-docs |
| 2 | Determinism Responsibility | all good | | temporal-docs |
| 3 | Forbidden Operations | all good | | temporal-docs |
| 4 | Best Practices | all good | | temporal-docs |

### Detailed Notes

All claims verified correct against temporal-docs. Java has no sandbox confirmed -- determinism is the developer's responsibility. Forbidden operations and best practices all accurate.

---


## Go

**File:** `references/go/determinism-protection.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | all good | | temporal-docs |
| 2 | workflowcheck Static Analysis | all good | | temporal-docs |
| 3 | Determinism Rules | all good | | temporal-docs |
| 4 | Best Practices | all good | | temporal-docs |

### Detailed Notes

#### 1. Overview
**Status:** all good
**Verified:**
- No runtime sandbox, developer convention + optional static analysis ✓
- Limited runtime command-ordering check mentioned ✓

---

#### 2. workflowcheck Static Analysis
**Status:** all good
**Verified:**
- Tool path `go.temporal.io/sdk/contrib/tools/workflowcheck` ✓
- Flagged operations list (I/O, goroutines, time, rand, etc.) ✓
- `//workflowcheck:ignore` annotation syntax ✓

---

#### 3. Determinism Rules
**Status:** all good
**Verified:**
- Rules for workflow code correctness ✓

---

#### 4. Best Practices
**Status:** all good
**Verified:**
- All best practices valid ✓

---

