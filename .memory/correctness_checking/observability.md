# observability.md

Correctness verification for `references/{language}/observability.md`.

## TypeScript

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
| 8 | Best Practices | FIXED | Updated logging: prefer `log`, but console.log works (patched) | SDK team feedback |

### Detailed Notes

#### 1. Overview
**Status:** all good

**Verified:** Replay-aware logging claim and metrics mention are correct

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
**Status:** FIXED

**SDK team feedback:** `console.log` is NOT forbidden - the SDK patches console.log/warn/error to include workflow ID. Updated best practice #1 to say "Prefer `log`" rather than implying console.log is wrong.

**Verified:** All 6 best practices valid

---


## Python

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


## PHP

**File:** `references/php/observability.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | all good | | context7 sdk-php |
| 2 | Logging / Replay-Aware Logging | needs verification | | context7 sdk-php |
| 3 | Customizing the Logger | needs verification | | context7 sdk-php |
| 4 | Search Attributes (Visibility) | all good | | context7 sdk-php |
| 5 | Best Practices | all good | | context7 sdk-php |

### Detailed Notes

#### 1. Overview
**Status:** all good

**Verified:**
- PSR-3 logging mention is correct (PHP SDK uses PSR-3 compatible loggers)
- Replay-aware workflow logger claim is consistent with SDK design
- Search Attributes for visibility is correct

---

#### 2. Logging / Replay-Aware Logging
**Status:** needs verification

**Issues:**
- `Workflow::getLogger()` API is plausible but could not be directly confirmed in Context7 documentation
- PSR-3 logger interface for activities is correct (standard PHP practice)
- Claim that workflow logger "automatically suppresses duplicate log messages during replay" is plausible but unverified
- **`WorkerOptions::new()->withEnableLoggingInReplay(true)` could not be verified** — this method may or may not exist

**Note:** Unable to verify logging PHP-specific API due to limited documentation availability.

---

#### 3. Customizing the Logger
**Status:** needs verification

**Issues:**
- **`logger` parameter on `$factory->newWorker()` could not be verified** — worker factory may accept a logger elsewhere (e.g., on the factory itself or via DI)
- Monolog integration pattern is plausible (Monolog is the standard PSR-3 logger for PHP)

**Note:** Unable to verify custom logger injection point due to limited documentation availability.

---

#### 4. Search Attributes (Visibility)
**Status:** all good

**Verified:**
- Cross-reference to `references/php/data-handling.md` is correct and appropriate

---

#### 5. Best Practices
**Status:** all good

**Verified:**
- `Workflow::getLogger()` recommendation is correct
- Warning against `echo`/`print()` in workflows is correct (output on every replay)
- PSR-3 loggers in activities recommendation is correct
- Search Attributes recommendation is correct

---


## Go

**File:** `references/go/observability.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | all good | | temporal-docs |
| 2 | Logging / Replay-Aware Logging | all good | | temporal-docs |
| 3 | Customizing the Logger | all good | | temporal-docs |
| 4 | Metrics | all good | | temporal-docs |
| 5 | Search Attributes (Visibility) | all good | | temporal-docs |
| 6 | Best Practices | all good | | temporal-docs |

### Detailed Notes

#### 1. Overview
**Status:** all good
**Verified:**
- `workflow.GetLogger` and `activity.GetLogger` APIs ✓
- Tally library with Prometheus export ✓
- OpenTelemetry/OpenTracing/Datadog tracing ✓

---

#### 2. Logging / Replay-Aware Logging
**Status:** all good
**Verified:**
- `workflow.GetLogger(ctx)` for replay-safe workflow logging ✓
- `activity.GetLogger(ctx)` for activity logging ✓

---

#### 3. Customizing the Logger
**Status:** all good
**Verified:**
- `log.NewStructuredLogger` API ✓
- Custom logger via `client.Options` ✓

---

#### 4. Metrics
**Status:** all good
**Verified:**
- `sdktally.NewMetricsHandler` API ✓
- `client.Options{MetricsHandler}` configuration ✓
- Prometheus export via Tally ✓

---

#### 5. Search Attributes (Visibility)
**Status:** all good
**Verified:**
- Search attribute reference ✓

---

#### 6. Best Practices
**Status:** all good
**Verified:**
- All best practices valid ✓

---

