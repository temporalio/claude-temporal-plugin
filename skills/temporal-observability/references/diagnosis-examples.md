# Diagnosis Worked Examples

<!-- Sources: Adapted from temporalio/temporal-pm-skills ops-health skill (PR #102) examples, with corrections for v1 metric query rules and cross-references to existing reference files -->

These examples demonstrate the Diagnosis Protocol (SKILL.md § Diagnosis Protocol) applied to real scenarios. Each shows the full D1–D5 flow.

## Example 1: Task Backlog — Go SDK on Temporal Cloud (Datadog)

### User Prompt

> Our workflows are taking much longer to start than they used to. We're on Temporal Cloud and using the Go SDK. The namespace is `prod.abc123.tmprl.cloud`. We noticed the issue about 2 hours ago and it's getting worse.

### D1 — Classify

**Category:** Throughput/Backlog (tasks waiting, latency increasing)

### D2 — Detect Environment

- **Deployment:** Cloud (namespace format `*.tmprl.cloud`)
- **SDK:** Go (histogram units in seconds)
- **Platform:** Datadog (user mentions Datadog dashboard later)

### D3 — Establish Metrics Access

Request these specific values (explain why each matters):

1. `temporal_cloud_v1_approximate_backlog_count` by task queue — shows how many tasks are waiting. If growing, production rate exceeds consumption rate.
2. `temporal_activity_schedule_to_start_latency` p99 (SDK metric) — directly measures how long tasks wait before a worker picks them up.
3. `temporal_worker_task_slots_available` per worker (SDK metric) — shows if workers are at their concurrency limit.
4. Sync match rate: `temporal_cloud_v1_poll_success_sync_count / temporal_cloud_v1_poll_success_count` — measures how often tasks match immediately to a waiting worker.
5. Number of worker instances running.

Datadog queries to provide:
```
sum:temporal_cloud_v1_approximate_backlog_count{temporal_namespace:prod.abc123.tmprl.cloud} by {temporal_task_queue}
```
```
p99:temporal_activity_schedule_to_start_latency{namespace:prod.abc123.tmprl.cloud}
```

### User Provides Metrics

> - Backlog count: was ~0 this morning, now at 15,000 and climbing
> - Schedule-to-start latency p99: 4.2 seconds (was <50ms yesterday)
> - Worker task slots available: 0 on all 3 workers
> - Sync match rate: dropped from 99.5% to 62%
> - Running 3 worker instances, maxConcurrentActivityExecutionSize is default (1000 for Go)

### D4 — USE Analysis

Follow decision tree (ops-diagnostics-reference.md § Scenario 1):
- Schedule-to-start HIGH (4.2s >> 200ms threshold) → backlog confirmed
- Sync match rate LOW (62% << 95% threshold) → tasks not matching to waiting pollers
- Task slots ZERO on all workers → workers at capacity
- Backlog GROWING (0 → 15,000) → production exceeding consumption

| Resource | Utilization | Saturation | Errors |
|---|---|---|---|
| Worker Task Slots | 0 available across 3 workers (3,000 total slots all consumed) | Backlog: 15,000 and growing; s2s latency: 4.2s p99 | None observed |
| Task Queue Matching | Sync match rate: 62% (was 99.5%) | 38% of tasks going to backlog instead of immediate match | None observed |
| Namespace Limits | Not checked yet — request `total_action_count / action_limit` | No throttling reported | No resource_exhausted errors |

### D5 — Structured Response

**What's Happening:** All worker task slots are consumed (0 available across 3 workers with 1,000 slots each). Tasks are piling up in the backlog (15,000 and climbing) because no worker can accept new work. The sync match rate dropped from 99.5% to 62% — 38% of tasks now wait in the backlog instead of being served immediately.

**Why:** 3 workers × 1,000 slots = 3,000 total capacity, all occupied. Since the load was normal until 2 hours ago, the likely trigger is:
- A downstream dependency slowed down (activities hold slots longer, reducing throughput) — most common when traffic hasn't changed
- A deployment changed activity behavior
- A traffic spike in a specific workflow type

The "what changed 2 hours ago?" question is critical — the fix depends on the cause.

**Fix:**
1. **Immediate:** Scale workers from 3 to 6+ instances — doubles total slot capacity to 6,000. New workers start polling immediately.
2. **Before scaling:** Verify worker hosts have CPU/memory headroom. Adding slots to a CPU-saturated host makes things worse.
3. **Investigate:** Check activity execution duration over the last 2 hours. If a downstream service slowed down, scaling is a band-aid.
4. **For tuning parameters** (slot sizes, poller counts) → hand off to `skill-temporal-workertuning`.

**Monitor After:**
- `temporal_cloud_v1_approximate_backlog_count` should start decreasing within minutes of new workers coming online
- `temporal_worker_task_slots_available` should show >0 on new workers
- `temporal_activity_schedule_to_start_latency` p99 should drop back toward <100ms
- Sync match rate should recover toward >95%

**If Not Resolved:**
- Backlog doesn't decrease after scaling → activities aren't completing. Check for a dependency outage causing tasks to hang.
- New workers also saturate quickly → root cause is activity execution duration, not capacity. Find the slow dependency.
- `resource_exhausted_error_count` appears → namespace-level rate limits, separate from worker capacity.

---

## Example 2: Activity Failure Cascade — Java SDK, Self-Hosted (Grafana)

### User Prompt

> We're seeing a big spike in workflow failures over the last hour. We're self-hosted, running Temporal Server 1.24 with the Java SDK. Our monitoring shows activity failures are also elevated.

### D1 — Classify

**Category:** Failure/Error (activity failures, workflow failures spiking)

### D2 — Detect Environment

- **Deployment:** Self-hosted (mentions Temporal Server version)
- **SDK:** Java (histogram units in seconds)
- **Platform:** Grafana with Prometheus datasource

### D3 — Establish Metrics Access

Request these values (explain why each matters):

1. `temporal_activity_execution_failed` rate — volume and whether concentrated on one activity type (dependency issue) or spread across many (infrastructure issue).
2. `temporal_workflow_failed` rate — business impact. Workflow failures mean work is lost or needs manual recovery.
3. Failure conversion rate (`workflow_failed / activity_execution_failed`) — separates "flaky dependencies" from "broken error handling." See `service-health-monitoring.md` § Failure Conversion Rate for thresholds.
4. `temporal_activity_execution_latency` p99 — if activities are timing out rather than returning errors.
5. Whether failures are concentrated on specific activity types or spread across all.

PromQL queries for Grafana (note: `rate()` is correct here — these are SDK metrics, not Cloud v1):
```promql
sum(rate(temporal_activity_execution_failed_total[5m])) by (activity_type)
```
```promql
sum(rate(temporal_workflow_failed_total[5m]))
```

### User Provides Metrics

> - Activity failures: jumped from ~2/min to ~180/min starting about 70 minutes ago
> - Workflow failures: went from ~0 to ~45/min
> - Failures are almost entirely on `ProcessPayment` activity
> - Retries are not succeeding — activities fail all 3 retry attempts then the workflow fails
> - Activity execution latency for ProcessPayment: timing out at 10s (our StartToClose timeout)

### D4 — USE Analysis

Follow decision tree (ops-diagnostics-reference.md § Scenario 2):
- Activity failures ELEVATED (180/min, up from 2/min) → confirmed
- Failure conversion rate = 45/180 = 0.25 → HIGH (>> 0.1 threshold) → poor error handling
- Failures CONCENTRATED on one activity type (`ProcessPayment`) → downstream dependency problem
- Retries NOT succeeding → persistent failure, not transient
- Activities timing out at exactly the StartToClose timeout → dependency unresponsive

| Resource | Utilization | Saturation | Errors |
|---|---|---|---|
| Activity Execution (ProcessPayment) | Timing out at 10s StartToClose — consuming full timeout budget before failing | Each attempt holds a slot for 10s × 3 retries = 30s of wasted slot time per invocation | 180 failures/min (90× baseline) |
| Workflow Execution | Normal for non-payment workflows | N/A | 45 failures/min. Conversion rate 0.25 — critically high |

Hidden cost: 60 unique invocations/min × 30s wasted slot time each = 1,800 worker-seconds/min consumed by work that will never succeed. This can starve other activities (link to Scenario 1 if schedule-to-start latency also elevated).

### D5 — Structured Response

**What's Happening:** The `ProcessPayment` activity is timing out because its downstream payment service is unresponsive. Every call hits the 10-second StartToClose timeout, gets retried 3 times, and each retry also times out. After exhausting retries, the activity reports a permanent failure. The workflow code lets this error propagate uncaught, crashing the workflow.

**Why:** Two problems interacting:
1. **Payment service is down or unreachable** (primary cause). Activities time out at exactly their limit — the service isn't responding at all. Retries aren't helping because the issue is persistent.
2. **Workflows don't handle ProcessPayment failure gracefully** (amplifies impact). Failure conversion rate is 0.25 — for every 4 activity failures, 1 workflow dies. A resilient system should be <0.01.

**Fix:**
1. **Immediate:** Investigate the payment service directly. Check its health endpoint, recent deploys, error logs.
2. **If payment service is slow** (not fully down): increase StartToClose timeout to match current response time. Only if the service IS responding — a longer timeout on a dead service just wastes more slot time.
3. **Fix error handling** (prevent future cascades): wrap `ProcessPayment` in error handling that does NOT fail the workflow. Options:
   - Catch failure, enter a wait state (sleep + retry later)
   - Send notification for human intervention
   - Execute a compensation activity (mark order as "payment pending")
   - Hand off to `skill-temporal-developer` for code changes
4. **Reduce wasted capacity:** Add a circuit breaker — after N consecutive failures, stop retrying and fall back. Stops hammering a dead service and frees slots.

**Monitor After:**
- `ProcessPayment` activity failure rate should drop to baseline once payment service recovers
- Failure conversion rate should drop to <0.01 after error handling improvements
- `temporal_workflow_failed` should return to ~0 once both fixes are in place
- Watch worker task slot availability — retry storm may have been consuming slots needed by other activities

**If Not Resolved:**
- Payment service recovers but workflow failures persist → check for a second failing activity type
- Payment service stays down → error handling fix (#3) becomes urgent
- Worker capacity issues from retry storms → hand off to `skill-temporal-workertuning`
- Failures spread to other activity types → infrastructure-level issue (OOM, network), not a single dependency
