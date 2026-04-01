# error-handling.md

Correctness verification for `references/{language}/error-handling.md`.

## TypeScript

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


## Python

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


## Go

**File:** `references/go/error-handling.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | all good | | temporal-docs |
| 2 | Application Errors | all good | | temporal-docs |
| 3 | Non-Retryable Errors | all good | | temporal-docs |
| 4 | Handling Activity Errors in Workflows | all good | | temporal-docs |
| 5 | Retry Configuration | all good | | temporal-docs |
| 6 | Timeout Configuration | all good | | temporal-docs |
| 7 | Workflow Failure | all good | | temporal-docs |
| 8 | Best Practices | all good | | temporal-docs |

### Detailed Notes

#### 1. Overview
**Status:** all good
**Verified:**
- Error return values (not exceptions) pattern ✓
- `*temporal.ActivityError` wrapping, `errors.As` unwrapping ✓

---

#### 2. Application Errors
**Status:** all good
**Verified:**
- `temporal.NewApplicationError(message, errType, cause, details...)` ✓

---

#### 3. Non-Retryable Errors
**Status:** all good
**Verified:**
- `temporal.NewNonRetryableApplicationError` API ✓

---

#### 4. Handling Activity Errors in Workflows
**Status:** all good
**Verified:**
- `errors.As(err, &appErr)` pattern for unwrapping ✓
- `appErr.Type()` for error type checking ✓

---

#### 5. Retry Configuration
**Status:** all good
**Verified:**
- `temporal.RetryPolicy` struct fields (`InitialInterval`, `BackoffCoefficient`, `MaximumInterval`, `MaximumAttempts`, `NonRetryableErrorTypes`) ✓

---

#### 6. Timeout Configuration
**Status:** all good
**Verified:**
- `ActivityOptions` timeout fields (`StartToCloseTimeout`, `ScheduleToCloseTimeout`, `HeartbeatTimeout`) ✓

---

#### 7. Workflow Failure
**Status:** all good
**Verified:**
- Returning error from workflow function ✓
- `temporal.NewApplicationError` usage in workflows ✓

---

#### 8. Best Practices
**Status:** all good
**Verified:**
- All best practices valid ✓

---


## .NET

**File:** `references/dotnet/error-handling.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | all good | | — |
| 2 | Application Failures | all good | `errorType:` param confirmed | temporal-docs API |
| 3 | Non-Retryable Errors | all good | `nonRetryable:` param confirmed | temporal-docs API |
| 4 | Handling Activity Errors | all good | `ActivityFailureException` confirmed | temporal-docs API |
| 5 | Retry Configuration | all good | `MaximumInterval`/`MaximumAttempts`/`NonRetryableErrorTypes` confirmed | temporal-docs, SDK samples |
| 6 | Timeout Configuration | all good | | temporal-docs |
| 7 | Workflow Failure | all good | Only `ApplicationFailureException` fails workflow — confirmed | SDK README |
| 8 | Best Practices | all good | | — |

### Detailed Notes

#### 2-3. Application Failures / Non-Retryable
**Status:** all good
**Verified:** `ApplicationFailureException(message, errorType:, nonRetryable:)` constructor — lowercase param names confirmed from API docs. Namespace `Temporalio.Exceptions` confirmed.

---

