# Temporal Cloud v1 OpenMetrics Catalog

<!-- Source: docs/cloud/metrics/openmetrics/metrics-reference.mdx -->

This reference enumerates every `temporal_cloud_v1_*` metric exposed by the Temporal Cloud OpenMetrics endpoint, organized by category. Each metric entry includes its description, type, and specific labels.

## Metric Conventions

### Metric Types
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:30-35 -->

All metrics are exposed as OpenMetrics gauges but represent different measurement types:

- **Rate**: Per-second rate of the aggregated values.
- **Value**: The most recent aggregate value within a look-back window (e.g., backlogs, limits).
- **Percentile**: Pre-calculated aggregated latency percentiles in seconds.

All metrics are stored as 1-minute aggregates. <!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:39 -->

### Common Labels
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:46-52 -->

Every v1 metric includes these base labels:

| Label | Description |
|---|---|
| `temporal_namespace` | The Temporal namespace |
| `temporal_account` | The Temporal account identifier |
| `region` | Cloud region where the metric originated |

**Exception:** Some namespace-scoped metrics (`temporal_cloud_v1_total_action_count`, `temporal_cloud_v1_action_on_demand_envelope_limit`, `temporal_cloud_v1_operations_on_demand_envelope_limit`, `temporal_cloud_v1_service_request_on_demand_envelope_limit`) do not include the `region` label. <!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:608,743,755,767 -->

### Opt-in Labels
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:55-78 -->

Some labels are opt-in due to high cardinality. They are not included by default; enable them via the `labels` query parameter on the scrape URL.

| Label | Available on | Description |
|---|---|---|
| `temporal_activity_type` | Activity metrics | The activity type name |
| `temporal_worker_deployment_name` | `temporal_cloud_v1_approximate_backlog_count`, `temporal_cloud_v1_approximate_backlog_age` | The Worker Deployment name |
| `temporal_worker_build_id` | `temporal_cloud_v1_approximate_backlog_count`, `temporal_cloud_v1_approximate_backlog_age` | The Worker Deployment Version Build ID |
| `nexus_service` | Nexus metrics | The Nexus Service name |
| `nexus_operation` | Nexus metrics | The Nexus Operation name |
| `worker_version` | `temporal_cloud_v1_approximate_backlog_count` | **Deprecated.** Legacy Worker Build ID from pre-Worker-Deployments versioning API. Use `temporal_worker_deployment_name` and `temporal_worker_build_id` instead |

Nexus labels `nexus_service` and `nexus_operation` are opt-in to manage cardinality.

Enable a single opt-in label: <!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:69-71 -->
```
/v1/metrics?labels=temporal_activity_type
```

Enable multiple opt-in labels: <!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:74-78 -->
```
/v1/metrics?labels=temporal_worker_build_id&labels=temporal_worker_deployment_name
```

---

## Frontend Service Metrics
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:84 -->

### `temporal_cloud_v1_service_request_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:85-93 -->

gRPC requests received per second.

| Label | Description |
|---|---|
| `operation` | The name of the RPC operation |

**Type:** Rate

### `temporal_cloud_v1_service_request_throttled_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:95-103 -->

gRPC requests throttled per second.

| Label | Description |
|---|---|
| `operation` | The name of the RPC operation |

**Type:** Rate

### `temporal_cloud_v1_service_error_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:105-113 -->

gRPC errors per second.

| Label | Description |
|---|---|
| `operation` | The name of the RPC operation |

**Type:** Rate

### `temporal_cloud_v1_service_pending_requests`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:115-123 -->

The number of pollers that are actively long polling for a task. Use this to track against `temporal_cloud_v1_poller_limit`.

| Label | Description |
|---|---|
| `operation` | The name of the operation |

**Type:** Value

### `temporal_cloud_v1_resource_exhausted_error_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:125-133 -->

Resource exhaustion errors per second. This metric does not include throttling due to Namespace limits.

| Label | Description |
|---|---|
| `operation` | The name of the operation |

**Type:** Rate

### `temporal_cloud_v1_service_latency_p50`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:135-149 -->

The 50th percentile latency of service requests in seconds. Avoid aggregating across dimensions because the percentile will not be accurate.

| Label | Description |
|---|---|
| `operation` | The name of the operation |

**Type:** Percentile (Latency)

### `temporal_cloud_v1_service_latency_p95`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:151-165 -->

The 95th percentile latency of service requests in seconds. Avoid aggregating across dimensions because the percentile will not be accurate.

| Label | Description |
|---|---|
| `operation` | The name of the operation |

**Type:** Percentile (Latency)

### `temporal_cloud_v1_service_latency_p99`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:167-181 -->

The 99th percentile latency of service requests in seconds. Avoid aggregating across dimensions because the percentile will not be accurate.

| Label | Description |
|---|---|
| `operation` | The name of the operation |

**Type:** Percentile (Latency)

---

## Workflow Completion Metrics
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:183-189 -->

These metrics could have high cardinality depending on the number of workflow types and task queues.

### `temporal_cloud_v1_workflow_success_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:191-200 -->

Successful workflow completions per second.

| Label | Description |
|---|---|
| `temporal_task_queue` | The task queue name |
| `temporal_workflow_type` | The workflow type |

**Type:** Rate

### `temporal_cloud_v1_workflow_failed_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:202-211 -->

Workflow failures per second.

| Label | Description |
|---|---|
| `temporal_task_queue` | The task queue name |
| `temporal_workflow_type` | The workflow type |

**Type:** Rate

### `temporal_cloud_v1_workflow_timeout_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:213-222 -->

Workflow timeouts per second.

| Label | Description |
|---|---|
| `temporal_task_queue` | The task queue name |
| `temporal_workflow_type` | The workflow type |

**Type:** Rate

### `temporal_cloud_v1_workflow_cancel_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:224-233 -->

Workflow cancellations per second.

| Label | Description |
|---|---|
| `temporal_task_queue` | The task queue name |
| `temporal_workflow_type` | The workflow type |

**Type:** Rate

### `temporal_cloud_v1_workflow_terminate_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:235-244 -->

Workflow terminations per second.

| Label | Description |
|---|---|
| `temporal_task_queue` | The task queue name |
| `temporal_workflow_type` | The workflow type |

**Type:** Rate

### `temporal_cloud_v1_workflow_continued_as_new_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:246-255 -->

Workflows continued as new per second.

| Label | Description |
|---|---|
| `temporal_task_queue` | The task queue name |
| `temporal_workflow_type` | The workflow type |

**Type:** Rate

### `temporal_cloud_v1_workflow_schedule_to_close_latency_p50`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:257-271 -->

The 50th percentile workflow schedule-to-close latency in seconds. Avoid aggregating across dimensions because the percentile will not be accurate.

| Label | Description |
|---|---|
| `temporal_workflow_type` | The workflow type |

**Type:** Percentile (Latency)

### `temporal_cloud_v1_workflow_schedule_to_close_latency_p95`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:273-287 -->

The 95th percentile workflow schedule-to-close latency in seconds. Avoid aggregating across dimensions because the percentile will not be accurate.

| Label | Description |
|---|---|
| `temporal_workflow_type` | The workflow type |

**Type:** Percentile (Latency)

### `temporal_cloud_v1_workflow_schedule_to_close_latency_p99`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:289-303 -->

The 99th percentile workflow schedule-to-close latency in seconds. Avoid aggregating across dimensions because the percentile will not be accurate.

| Label | Description |
|---|---|
| `temporal_workflow_type` | The workflow type |

**Type:** Percentile (Latency)

---

## Activity Metrics
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:305-317 -->

These metrics could have high cardinality depending on the number of activity types, workflow types, and task queues. The `temporal_activity_type` label is opt-in to help manage cardinality.

**Standalone Activities:** Activity Executions started independently without an associated Workflow use the placeholder value `"__standalone_activity"` for the `temporal_workflow_type` label. <!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:315-316 -->

### `temporal_cloud_v1_activity_success_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:320-330 -->

Successful activity completions per second.

| Label | Description |
|---|---|
| `temporal_task_queue` | The task queue name |
| `temporal_workflow_type` | The workflow type |
| `temporal_activity_type` | The activity type (opt-in) |

**Type:** Rate

### `temporal_cloud_v1_activity_fail_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:332-341 -->

Activity failures per second.

| Label | Description |
|---|---|
| `temporal_task_queue` | The task queue name |
| `temporal_workflow_type` | The workflow type |
| `temporal_activity_type` | The activity type (opt-in) |

**Type:** Rate

### `temporal_cloud_v1_activity_timeout_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:343-355 -->

Activity timeouts per second.

| Label | Description |
|---|---|
| `temporal_task_queue` | The task queue name |
| `temporal_workflow_type` | The workflow type |
| `temporal_activity_type` | The activity type (opt-in) |
| `timeout_type` | The timeout type |

**Type:** Rate

### `temporal_cloud_v1_activity_task_fail_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:357-367 -->

Activity task failures per second.

| Label | Description |
|---|---|
| `temporal_task_queue` | The task queue name |
| `temporal_workflow_type` | The workflow type |
| `temporal_activity_type` | The activity type (opt-in) |

**Type:** Rate

### `temporal_cloud_v1_activity_task_timeout_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:369-380 -->

Activity task timeouts per second.

| Label | Description |
|---|---|
| `temporal_task_queue` | The task queue name |
| `temporal_workflow_type` | The workflow type |
| `temporal_activity_type` | The activity type (opt-in) |
| `timeout_type` | The timeout type |

**Type:** Rate

### `temporal_cloud_v1_activity_cancel_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:382-392 -->

Activity cancellations per second.

| Label | Description |
|---|---|
| `temporal_task_queue` | The task queue name |
| `temporal_workflow_type` | The workflow type |
| `temporal_activity_type` | The activity type (opt-in) |

**Type:** Rate

### `temporal_cloud_v1_activity_terminate_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:394-404 -->

Activity terminations per second. This metric only applies to Standalone Activities. Regular Activities that run within a Workflow cannot be terminated independently.

| Label | Description |
|---|---|
| `temporal_task_queue` | The task queue name |
| `temporal_workflow_type` | The workflow type |
| `temporal_activity_type` | The activity type (opt-in) |

**Type:** Rate

### Activity Latency Metrics
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:406-410 -->

Activity latency metrics include only the `temporal_activity_type` label. Labels such as `temporal_task_queue` and `temporal_workflow_type` are intentionally excluded because pre-calculated percentile values cannot be accurately aggregated across additional dimensions.

### `temporal_cloud_v1_activity_start_to_close_latency_p50`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:413-427 -->

The 50th percentile activity start-to-close latency in seconds. Avoid aggregating across dimensions because the percentile will not be accurate.

| Label | Description |
|---|---|
| `temporal_activity_type` | The activity type (opt-in) |

**Type:** Percentile (Latency)

### `temporal_cloud_v1_activity_start_to_close_latency_p95`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:429-443 -->

The 95th percentile activity start-to-close latency in seconds. Avoid aggregating across dimensions because the percentile will not be accurate.

| Label | Description |
|---|---|
| `temporal_activity_type` | The activity type (opt-in) |

**Type:** Percentile (Latency)

### `temporal_cloud_v1_activity_start_to_close_latency_p99`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:445-459 -->

The 99th percentile activity start-to-close latency in seconds. Avoid aggregating across dimensions because the percentile will not be accurate.

| Label | Description |
|---|---|
| `temporal_activity_type` | The activity type (opt-in) |

**Type:** Percentile (Latency)

### `temporal_cloud_v1_activity_schedule_to_close_latency_p50`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:461-475 -->

The 50th percentile activity schedule-to-close latency in seconds. Avoid aggregating across dimensions because the percentile will not be accurate.

| Label | Description |
|---|---|
| `temporal_activity_type` | The activity type (opt-in) |

**Type:** Percentile (Latency)

### `temporal_cloud_v1_activity_schedule_to_close_latency_p95`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:477-491 -->

The 95th percentile activity schedule-to-close latency in seconds. Avoid aggregating across dimensions because the percentile will not be accurate.

| Label | Description |
|---|---|
| `temporal_activity_type` | The activity type (opt-in) |

**Type:** Percentile (Latency)

### `temporal_cloud_v1_activity_schedule_to_close_latency_p99`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:493-507 -->

The 99th percentile activity schedule-to-close latency in seconds. Avoid aggregating across dimensions because the percentile will not be accurate.

| Label | Description |
|---|---|
| `temporal_activity_type` | The activity type (opt-in) |

**Type:** Percentile (Latency)

---

## Nexus Metrics (Public Preview)

All `temporal_cloud_v1_nexus_*` metrics are Public Preview.

- **Operation metrics (caller side):** `temporal_namespace` is the caller Namespace. Latency `nexus_operation_{schedule_to_close,schedule_to_start,start_to_close}_latency_{p50,p95,p99}`; counts `nexus_operation_{success,cancel,terminate,fail,timeout}_count`. Labels: `nexus_endpoint`, `temporal_workflow_type` (`timeout_count` adds `timeout_type`).
- **Request metrics (handler side):** `temporal_namespace` is the handler Namespace. `nexus_request_count`, `nexus_request_error_count`, `nexus_request_latency_{p50,p95,p99}`. Labels: `nexus_endpoint`, `nexus_caller_type`.
- Opt-in labels `nexus_service` and `nexus_operation` apply to all of them (see Opt-in Labels).
- Start-to-close latency is not recorded for an Operation that completes synchronously or closes without starting; its schedule-to-start latency then equals schedule-to-close.
- Labels don't distinguish sync from async completion, so schedule-to-close and schedule-to-start series can't be filtered by it.
- Don't aggregate latency percentiles across dimensions.
- Each metric's stage is also reported as `release_stage` (`public-preview`, `general-availability`, `deprecated`) by `GET /v1/descriptors`.

## Task Queue Metrics
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:509-515 -->

These metrics could have high cardinality depending on the number of task queues.

### `temporal_cloud_v1_approximate_backlog_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:517-539 -->

The approximate number of tasks pending in a task queue. Started Activities are not included in the count as they have been dequeued from the task queue.

**Known accuracy limitations:** This metric is approximate. It can overcount because invalid or expired Tasks (from cancelled, terminated, completed, or timed out Workflows) remain in the count until they reach the head of the queue and are processed and discarded. It can also reset to zero on an idle Task Queue if no Worker polls, no new Tasks are added, and no other Task Queue calls occur for approximately 5 minutes, causing the Task Queue to be unloaded from memory.

| Label | Description |
|---|---|
| `temporal_task_queue` | The task queue name |
| `task_type` | Type of task: `workflow` or `activity` |
| `task_priority` | The task priority |
| `temporal_worker_deployment_name` | The Worker Deployment name (opt-in) |
| `temporal_worker_build_id` | The Worker Deployment Version Build ID (opt-in) |
| `worker_version` | **Deprecated.** Legacy Worker Build ID (opt-in). Use `temporal_worker_deployment_name` and `temporal_worker_build_id` instead |

**Type:** Value

### `temporal_cloud_v1_approximate_backlog_age`

The approximate age, in seconds, of the oldest task in a task queue backlog. Same accuracy limitations as `approximate_backlog_count`. Labels: `temporal_task_queue`, `task_type`, and opt-in `temporal_worker_deployment_name`, `temporal_worker_build_id`.

**Type:** Value

### `temporal_cloud_v1_poll_success_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:541-552 -->

Successfully matched tasks per second.

| Label | Description |
|---|---|
| `operation` | The poll operation name |
| `task_type` | Type of task: `workflow` or `activity` |
| `temporal_task_queue` | The task queue name |

**Type:** Rate

### `temporal_cloud_v1_poll_success_sync_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:554-564 -->

Tasks matched synchronously per second (no polling wait).

| Label | Description |
|---|---|
| `operation` | The poll operation name |
| `task_type` | Type of task: `workflow` or `activity` |
| `temporal_task_queue` | The task queue name |

**Type:** Rate

### `temporal_cloud_v1_poll_timeout_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:566-576 -->

The rate of poll requests that timed out without receiving a task.

| Label | Description |
|---|---|
| `operation` | The poll operation name |
| `task_type` | Type of task: `workflow` or `activity` |
| `temporal_task_queue` | The task queue name |

**Type:** Rate

### `temporal_cloud_v1_no_poller_tasks_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:578-587 -->

The rate of tasks added to queues with no active pollers.

| Label | Description |
|---|---|
| `temporal_task_queue` | The task queue name |
| `task_type` | Type of task: `workflow` or `activity` |

**Type:** Rate

---

## Namespace Metrics
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:589 -->

### `temporal_cloud_v1_namespace_open_workflows`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:591-594 -->

The current number of open workflows in a namespace.

**Type:** Value

### `temporal_cloud_v1_total_action_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:596-609 -->

The total number of actions performed per second. Actions with `is_background=false` are counted toward the `temporal_cloud_v1_action_limit`.

Does not include the `region` label. Actions are scoped to the Namespace level.

| Label | Description |
|---|---|
| `is_background` | Whether the action was background: `true` or `false`. Background actions (e.g., History export) do not count toward the action rate limit |
| `namespace_mode` | Indicates if actions are produced by an `active` or a `standby` Namespace |

**Type:** Rate

### `temporal_cloud_v1_billable_action_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:611-633 -->

The number of billable actions per second, broken down by action type and Workflow Type. Not all billable actions are included in this metric. This metric is currently in Public Preview. It is an estimate that can differ by up to 5% from the absolute Action counts recorded by metering.

This metric could have high cardinality depending on the number of action types and workflow types.

| Label | Description |
|---|---|
| `action_type` | The action type |
| `temporal_workflow_type` | The workflow type |

**Type:** Rate

### `temporal_cloud_v1_total_action_throttled_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:635-638 -->

The total number of actions throttled per second.

**Type:** Rate

### `temporal_cloud_v1_operations_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:640-651 -->

Operations performed per second.

| Label | Description |
|---|---|
| `operation` | The name of the operation |
| `is_background` | Whether the operation was background: `true` or `false`. Background operations do not count toward the operation rate limit |
| `namespace_mode` | Indicates if operations are produced by an `active` or a `standby` Namespace |

**Type:** Rate

### `temporal_cloud_v1_operations_throttled_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:653-663 -->

Operations throttled due to rate limits per second.

| Label | Description |
|---|---|
| `operation` | The name of the operation |
| `is_background` | Whether the operation was background: `true` or `false`. Background operations do not count toward the operation rate limit |
| `namespace_mode` | Indicates if actions are throttled in an `active` or a `standby` Namespace |

**Type:** Rate

---

## Schedule Metrics
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:665 -->

For Schedule throttling, prefer standard requests-per-second rate-limit monitoring. The legacy `temporal_cloud_v1_schedule_rate_limited_count` metric, which measures scheduled workflows delayed per second, is deprecated.

### `temporal_cloud_v1_schedule_action_success_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:667-669 -->

Successfully executed scheduled workflows per second.

**Type:** Rate

### `temporal_cloud_v1_schedule_buffer_overruns_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:671-674 -->

Executions dropped per second because the Schedule's internal Action buffer is full.

**Type:** Rate

### `temporal_cloud_v1_schedule_missed_catchup_window_count`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:676-679 -->

Executions permanently dropped per second outside the Catchup Window. Not emitted for backfills.

**Type:** Rate

### `temporal_cloud_v1_schedule_overlap_skipped_count`

Executions dropped per second by the overlap policy: `SKIP` when another execution is running or selected, `BUFFER_ONE` when its single buffered slot is occupied (also possible in backfills). Label: `schedule_overlap_policy`.

**Type:** Rate

### `temporal_cloud_v1_schedule_action_e2e_delay_p50` / `_p95` / `_p99`

Percentile delay in seconds from an execution's scheduled time to actual start. Includes overlap-policy wait. Not emitted for backfills.

**Type:** Latency

---

## Replication Metrics
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:690 -->

### `temporal_cloud_v1_replication_lag_p50`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:692-696 -->

The 50th percentile cross-region replication lag in seconds.

**Type:** Percentile (Latency)

### `temporal_cloud_v1_replication_lag_p95`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:698-702 -->

The 95th percentile cross-region replication lag in seconds.

**Type:** Percentile (Latency)

### `temporal_cloud_v1_replication_lag_p99`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:704-708 -->

The 99th percentile cross-region replication lag in seconds.

**Type:** Percentile (Latency)

---

## Limit Metrics
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:710 -->

### `temporal_cloud_v1_operations_limit`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:712-716 -->

The current configured operations per second limit for a namespace.

**Type:** Value

### `temporal_cloud_v1_action_limit`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:718-722 -->

The current configured actions per second limit for a namespace. Track utilization against this limit with `temporal_cloud_v1_total_action_count` and `is_background=false`.

**Type:** Value

### `temporal_cloud_v1_service_request_limit`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:724-728 -->

The current configured frontend service RPS limit for a namespace. Track utilization against this limit with `temporal_cloud_v1_service_request_count`.

**Type:** Value

### `temporal_cloud_v1_poller_limit`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:730-734 -->

The current configured poller limit for a namespace. Track utilization against this limit with `temporal_cloud_v1_service_pending_requests`.

**Type:** Value

### `temporal_cloud_v1_action_on_demand_envelope_limit`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:736-746 -->

The on-demand envelope limit for actions per second. For Namespaces in provisioned capacity mode, this shows what the action limit would be if operating in on-demand mode. For Namespaces already in on-demand mode, this tracks the same value as `temporal_cloud_v1_action_limit`.

Does not include the `region` label. Limits are scoped to the Namespace level.

**Type:** Value

### `temporal_cloud_v1_operations_on_demand_envelope_limit`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:748-758 -->

The on-demand envelope limit for operations per second. For Namespaces in provisioned capacity mode, this shows what the operations limit would be if operating in on-demand mode. For Namespaces already in on-demand mode, this tracks the same value as `temporal_cloud_v1_operations_limit`.

Does not include the `region` label. Limits are scoped to the Namespace level.

**Type:** Value

### `temporal_cloud_v1_service_request_on_demand_envelope_limit`
<!-- docs/cloud/metrics/openmetrics/metrics-reference.mdx:760-770 -->

The on-demand envelope limit for service requests per second. For Namespaces in provisioned capacity mode, this shows what the service request limit would be if operating in on-demand mode. For Namespaces already in on-demand mode, this tracks the same value as `temporal_cloud_v1_service_request_limit`.

Does not include the `region` label. Limits are scoped to the Namespace level.

**Type:** Value
