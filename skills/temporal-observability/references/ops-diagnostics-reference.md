# Operational Diagnostics Reference

<!-- Sources: Adapted from temporalio/temporal-pm-skills ops-health skill (PR #102), cross-referenced with docs/cloud/worker-health.mdx, docs/cloud/service-health.mdx, docs/troubleshooting/performance-bottlenecks.mdx -->

This reference provides the USE methodology framework, metric name mappings, decision trees, and platform-specific query examples for the Diagnosis Protocol defined in SKILL.md. For threshold values and detailed metric descriptions, see `worker-health-monitoring.md`, `service-health-monitoring.md`, and `troubleshooting.md`.

## USE Resource Inventory

The USE method (Utilization, Saturation, Errors) applied to Temporal resources. For every resource relevant to the user's symptom, check all three dimensions before concluding.

| Resource | Utilization | Saturation | Errors |
|---|---|---|---|
| **Task Queue** | Sync match rate (poll_success_sync / poll_success) | `approximate_backlog_count`, schedule-to-start latency | `no_poller_tasks_count`, poll timeouts |
| **Worker Task Slots** | Slots in use vs available (`worker_task_slots_available`) | Slots at 0 (fully consumed) | Task execution failures |
| **Activity Execution** | Activity execution duration | Retry pressure (repeated failures consuming slots) | `activity_fail_count`, timeout errors |
| **Workflow Execution** | Workflow task execution latency | Concurrent workflows at limit | `workflow_failed_count` |
| **Sticky Cache** | `sticky_cache_size` vs WorkflowCacheSize config | `sticky_cache_total_forced_eviction` | Cache miss ratio (miss / (hit + miss)) |
| **Namespace Actions** | `total_action_count` / `action_limit` | `total_action_throttled_count` | `resource_exhausted_error_count` |
| **Namespace Requests** | `service_request_count` / `service_request_limit` | `service_request_throttled_count` | `resource_exhausted_error_count` |
| **Namespace Operations** | `operations_count` / `operations_limit` | `operations_throttled_count` | `resource_exhausted_error_count` |

All Cloud metric names above are shorthand — full names use the `temporal_cloud_v1_` prefix. See `cloud-metrics-catalog.md` for complete definitions. SDK metrics use `temporal_` prefix without `cloud`. For namespace limit triads, see `service-health-monitoring.md` § Monitoring Trends Against Limits.

## Metric Name Mapping: Cloud vs SDK

When diagnosing, the metric name depends on the user's environment. Use this table to select the right metric.

### Scenario 1: Task Backlog / Schedule-to-Start Latency

| What to Measure | Cloud Metric | SDK Metric |
|---|---|---|
| Backlog depth | `temporal_cloud_v1_approximate_backlog_count` | N/A (use `DescribeTaskQueue` API) |
| Schedule-to-start latency (workflow tasks) | N/A (derived from SDK) | `temporal_workflow_task_schedule_to_start_latency` |
| Schedule-to-start latency (activities) | N/A (derived from SDK) | `temporal_activity_schedule_to_start_latency` |
| Poll success (sync) | `temporal_cloud_v1_poll_success_sync_count` | N/A |
| Poll success (total) | `temporal_cloud_v1_poll_success_count` | N/A |
| Poll timeouts | `temporal_cloud_v1_poll_timeout_count` | N/A |
| Available task slots | N/A | `temporal_worker_task_slots_available` |
| Sync match rate | Derived: `poll_success_sync_count / poll_success_count` | N/A |
| Poll success rate | Derived: `poll_success_count / (poll_success_count + poll_timeout_count)` | N/A |
| No-poller tasks | `temporal_cloud_v1_no_poller_tasks_count` | N/A |

### Scenario 2: Activity Failure Cascade

| What to Measure | Cloud Metric | SDK Metric |
|---|---|---|
| Activity failures | `temporal_cloud_v1_activity_fail_count` | `temporal_activity_execution_failed` |
| Workflow failures | `temporal_cloud_v1_workflow_failed_count` | `temporal_workflow_failed` |
| Activity success | `temporal_cloud_v1_activity_success_count` | `temporal_activity_execution_latency` (duration, not count) |
| Failure conversion rate | Derived: `workflow_failed_count / activity_fail_count` | Derived: `workflow_failed / activity_execution_failed` |
| Activity execution latency | `temporal_cloud_v1_activity_start_to_close_latency_p99` | `temporal_activity_execution_latency` |
| Resource exhaustion | `temporal_cloud_v1_resource_exhausted_error_count` | `temporal_request_failure` (filtered by status) |

For threshold values (failure conversion rate >0.1 = poor, <0.01 = good; activity success rate target >95%), see `service-health-monitoring.md` § Ratio-Based Monitoring. For schedule-to-start and sync match thresholds, see `worker-health-monitoring.md` § Minimal Observations.

## Environment Detection

When the user hasn't stated their environment, use these clues. Ask if confidence is below 95%.

| Clue | Likely Environment |
|---|---|
| Namespace format `*.tmprl.cloud` or `<name>.<account>.tmprl.cloud` | Cloud |
| `temporal_cloud_v1_*` metrics | Cloud |
| Mentions `metrics.temporal.io`, API key auth, tcld, Cloud UI | Cloud |
| Mentions Actions billing, Temporal Resource Units | Cloud |
| Custom server addresses, internal IPs, non-`.tmprl.cloud` domains | Self-hosted |
| References Helm charts, docker-compose, Cassandra/MySQL persistence | Self-hosted |
| References `dynamicconfig/`, `config/development.yaml` | Self-hosted |
| Mentions history/matching/frontend service components | Self-hosted |
| Mentions `temporal server start-dev` | Dev server |
| Only SDK-side metrics, `localhost` addresses, no namespace mentioned | Ambiguous — ask |

## Decision Trees

### Scenario 1: Task Backlog / Schedule-to-Start Latency

```
User reports: workflows slow to start / backlog growing / high latency
│
├─ Check: schedule-to-start latency (SDK metric)
│   Ref: worker-health-monitoring.md § Schedule-to-Start Latency for thresholds
│
│  ├─ LOW → Backlog is NOT the problem
│  │  └─ Check execution latency, replay latency
│  │     Ref: troubleshooting.md § temporal_workflow_task_execution_latency,
│  │          § temporal_activity_execution_latency
│  │
│  └─ HIGH → Backlog confirmed, continue below
│
├─ Check: sync match rate (Cloud metric)
│   Ref: worker-health-monitoring.md § Sync Match Rate for calculation + thresholds
│
│  ├─ HIGH (healthy) → Workers exist and are matching, but cannot keep up
│  │  │
│  │  ├─ Check: worker_task_slots_available (SDK metric)
│  │  │  ├─ ZERO on all workers → Slots depleted
│  │  │  │  ├─ Host CPU/memory high → Scale horizontally (add worker instances)
│  │  │  │  └─ Host CPU/memory low → Increase max concurrent execution size
│  │  │  │     (hand off to skill-temporal-workertuning for tuning guidance)
│  │  │  │
│  │  │  └─ Slots available → Workers have capacity but aren't polling fast enough
│  │  │     └─ Increase concurrent pollers per worker
│  │  │
│  │  └─ Ref: worker-health-monitoring.md § Handling Task Backlog Issues
│  │        § High Schedule-to-Start Latency and High Sync Match Rate
│  │
│  └─ LOW → Tasks not matching to waiting pollers
│     │
│     ├─ Check: approximate_backlog_count trend
│     │  ├─ Growing → Tasks accumulating faster than consumed
│     │  └─ Stable → May be transient spike, monitor
│     │
│     ├─ Check: no_poller_tasks_count
│     │  ├─ Non-zero → Task queue has no registered pollers at all
│     │  │  └─ Verify workers are configured for the correct task queue name
│     │  └─ Zero → Pollers exist but aren't matching
│     │
│     └─ Ref: worker-health-monitoring.md § Handling Task Backlog Issues
│           § High Schedule-to-Start Latency and Low Sync Match Rate
│
├─ Also check: is this workflow tasks or activity tasks?
│  ├─ Workflow tasks → Check replay latency, sticky cache evictions
│  │  Ref: troubleshooting.md § High temporal_workflow_task_replay_latency
│  └─ Activity tasks → Check activity execution latency, downstream dependencies
│     Ref: troubleshooting.md § temporal_activity_execution_latency Spike
│
└─ Also check: namespace capacity
   Ref: service-health-monitoring.md § Monitoring Trends Against Limits
   └─ resource_exhausted_error_count > 0 → Namespace-level throttling,
      separate problem from worker capacity
```

### Scenario 2: Activity Failure Cascade

```
User reports: activity failures / workflow failures / error rate spiking
│
├─ Check: activity failure rate
│   Cloud: temporal_cloud_v1_activity_fail_count
│   SDK: temporal_activity_execution_failed
│
│  ├─ LOW / ZERO → Failures not activity-driven
│  │  └─ Check workflow_failed_count, service_error_count directly
│  │     Ref: service-health-monitoring.md § Service Error Rate
│  │
│  └─ ELEVATED → Activity failures confirmed, continue below
│
├─ Check: failure conversion rate
│   (workflow_failed_count / activity_fail_count)
│   Ref: service-health-monitoring.md § Failure Conversion Rate for thresholds
│
│  ├─ HIGH → Workflows not handling activity failures gracefully
│  │  └─ Fix: add error handling in workflow code (try/catch, fallbacks,
│  │     compensation logic, human notification)
│  │     Hand off to skill-temporal-developer for code changes
│  │
│  └─ LOW → Good resilience; activities fail but workflows recover
│     └─ Focus on reducing the activity failure rate itself (below)
│
├─ Check: activity success rate
│   Ref: service-health-monitoring.md § Activity Success Rate for formula + target
│
│  ├─ Below target → Systematic activity problem
│  │  │
│  │  ├─ Failures concentrated on one activity type?
│  │  │  └─ YES → Downstream dependency problem for that activity
│  │  │     ├─ Check: is the activity timing out (execution latency ≈ timeout)?
│  │  │     │  ├─ YES → Dependency slow or unresponsive; consider circuit breaker
│  │  │     │  └─ NO → Dependency returning errors; check its logs/health
│  │  │     └─ Each failed retry holds a task slot for the full timeout duration,
│  │  │        potentially starving other activities (link to Scenario 1 if
│  │  │        schedule-to-start latency also elevated)
│  │  │
│  │  └─ Failures spread across all activity types?
│  │     └─ Infrastructure-level issue
│  │        ├─ Check worker host resources (CPU, memory, disk, network)
│  │        ├─ Check for resource_exhausted_error_count (namespace limits)
│  │        └─ Check network between workers and downstream services
│  │
│  └─ Above target → Intermittent failures, likely transient
│
├─ Check: are retries eventually succeeding?
│  ├─ YES → Transient issue; monitor, may self-resolve
│  │  └─ Watch for retry storms consuming worker capacity
│  └─ NO → Persistent failure; retries waste capacity
│     └─ Fix root cause; reduce retry attempts or add backoff
│
└─ Also check: is schedule-to-start latency elevated?
   ├─ YES → Combined backlog + failure problem → also run Scenario 1
   │  (retry storms can consume slots and cause backlog)
   └─ NO → Pure failure problem, focus on activity code/dependencies
```

## Query Examples by Platform

**Critical**: All `temporal_cloud_v1_*` metrics are pre-computed per-second rates with delta temporality. NEVER apply `rate()`, `increase()`, `irate()`, or `histogram_quantile()` to them — on any platform. See SKILL.md § Critical Rules. The `rate()` function IS correct for SDK metrics (`temporal_workflow_*`, `temporal_activity_*`, etc.) and self-hosted cluster metrics.

For PromQL queries already defined in existing references, see:
- Sync match rate, poll success rate, schedule-to-start latency: `worker-health-monitoring.md`
- Failure conversion rate, activity success rate, service error rate: `service-health-monitoring.md`

### Datadog

These examples show Datadog syntax for queries not covered in other reference files.

**Backlog trend by task queue:**
```
sum:temporal_cloud_v1_approximate_backlog_count{temporal_namespace:$namespace} by {temporal_task_queue}
```

**Activity failure rate by activity type:**
```
sum:temporal_cloud_v1_activity_fail_count{temporal_namespace:$namespace} by {temporal_activity_type}
```

**Failure conversion rate:**
```
sum:temporal_cloud_v1_workflow_failed_count{temporal_namespace:$namespace}
/
sum:temporal_cloud_v1_activity_fail_count{temporal_namespace:$namespace}
```

**Namespace capacity utilization (actions):**
```
sum:temporal_cloud_v1_total_action_count{temporal_namespace:$namespace}
/
sum:temporal_cloud_v1_action_limit{temporal_namespace:$namespace}
```

**SDK schedule-to-start latency (Datadog with SDK metrics via DogStatsD or OpenMetrics):**
```
p99:temporal_activity_schedule_to_start_latency{namespace:$namespace}
```

### New Relic (NRQL)

**Backlog count:**
```sql
SELECT latest(temporal_cloud_v1_approximate_backlog_count) FROM Metric
WHERE temporal_namespace = '{namespace}' FACET temporal_task_queue TIMESERIES
```

**Failure conversion rate:**
```sql
SELECT sum(temporal_cloud_v1_workflow_failed_count) / sum(temporal_cloud_v1_activity_fail_count)
FROM Metric WHERE temporal_namespace = '{namespace}' TIMESERIES
```

## Capacity Quick Reference

For full details on limit/count/throttle triads and alerting guidance, see `service-health-monitoring.md` § Monitoring Trends Against Limits. This table adds the USE diagnostic lens.

| Resource | Utilization Check | Saturation Signal | Error Signal | Alert Strategy |
|---|---|---|---|---|
| Actions | `total_action_count / action_limit` | `total_action_throttled_count > 0` | `resource_exhausted_error_count > 0` | See alert guidance below |
| Service Requests | `service_request_count / service_request_limit` | `service_request_throttled_count > 0` | `resource_exhausted_error_count > 0` | See alert guidance below |
| Operations | `operations_count / operations_limit` | `operations_throttled_count > 0` | `resource_exhausted_error_count > 0` | See alert guidance below |
| Pollers | `service_pending_requests` approaching `poller_limit` | N/A | N/A | Monitor trend |

For alert thresholds on these limits, see `service-health-monitoring.md` § Alerting Guidance.

All metric names above are shorthand for `temporal_cloud_v1_` prefix.
