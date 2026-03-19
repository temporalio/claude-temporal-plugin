# determinism.md

Correctness verification for `references/{language}/determinism.md`.

## TypeScript

**File:** `references/typescript/determinism.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | all good | | context7 sdk-typescript |
| 2 | Why Determinism Matters | all good | | context7 sdk-typescript |
| 3 | Temporal's V8 Sandbox | all good | | context7 sdk-typescript |
| 4 | Deterministic UUID Generation | all good | | context7 sdk-typescript |
| 5 | Forbidden Operations | FIXED | Removed console.log from forbidden list | SDK team feedback |
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
**Status:** FIXED

**SDK team feedback:** `console.log` is NOT forbidden - the SDK patches console.log/warn/error to include workflow ID. Removed from forbidden operations list.

**Verified:** fs forbidden, fetch() forbidden, activities recommendation all correct

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


## Python

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


## PHP

**File:** `references/php/determinism.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | unchecked | | |
| 2 | Why Determinism Matters: History Replay | unchecked | | |
| 3 | SDK Protection / Runtime Checking | unchecked | | |
| 4 | Forbidden Operations | unchecked | | |
| 5 | Testing Replay Compatibility | unchecked | | |
| 6 | Best Practices | unchecked | | |

### Detailed Notes

#### 1. Overview
**Status:** unchecked

---

#### 2. Why Determinism Matters: History Replay
**Status:** unchecked

---

#### 3. SDK Protection / Runtime Checking
**Status:** unchecked

---

#### 4. Forbidden Operations
**Status:** unchecked

---

#### 5. Testing Replay Compatibility
**Status:** unchecked

---

#### 6. Best Practices
**Status:** unchecked

---


## Go

**File:** `references/go/determinism.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | all good | | temporal-docs |
| 2 | Why Determinism Matters: History Replay | all good | | temporal-docs |
| 3 | SDK Protection | all good | | temporal-docs |
| 4 | Forbidden Operations | all good | | temporal-docs |
| 5 | Safe Builtin Alternatives | all good | | temporal-docs |
| 6 | Testing Replay Compatibility | all good | | temporal-docs |
| 7 | Best Practices | all good | | temporal-docs |

### Detailed Notes

#### 1. Overview
**Status:** all good
**Verified:**
- No runtime sandbox, developer convention-based determinism ✓
- `workflowcheck` static analysis tool reference ✓

---

#### 2. Why Determinism Matters: History Replay
**Status:** all good
**Verified:**
- History Replay explanation ✓
- Reference to `references/core/determinism.md` ✓

---

#### 3. SDK Protection
**Status:** all good
**Verified:**
- No automatic sandbox, limited runtime command-ordering check ✓

---

#### 4. Forbidden Operations
**Status:** all good
**Verified:**
- Native goroutines, channels, time, rand, I/O all listed as forbidden ✓

---

#### 5. Safe Builtin Alternatives
**Status:** all good
**Verified:**
- `workflow.Now`, `workflow.Sleep`, `workflow.SideEffect`, `workflow.Go`, `workflow.NewChannel` ✓

---

#### 6. Testing Replay Compatibility
**Status:** all good
**Verified:**
- `worker.NewWorkflowReplayer` API ✓
- `ReplayWorkflowHistoryFromJSONFile` API ✓

**Style nit:** Replay testing passes `nil` for logger param (functional but could show logger usage). Not a correctness issue.

---

#### 7. Best Practices
**Status:** all good
**Verified:**
- All best practices valid ✓

---

