# Temporal Cloud Service Health Monitoring

<!-- Source: docs/cloud/service-health.mdx -->

This reference covers patterns for monitoring Temporal Cloud service health: availability monitoring, Workflow execution latency, service error rate queries, activity/workflow failure detection, replication lag monitoring, resource exhaustion detection, and limit monitoring.

## Availability Monitoring
<!-- docs/cloud/service-health.mdx:20-30 -->

When you see a sudden drop in Worker resource utilization, verify whether Temporal Cloud's API is showing increased latency and error rates.

### Key Metric: `temporal_cloud_v1_service_latency_p99`
<!-- docs/cloud/service-health.mdx:26-29 -->

This metric measures latency for `SignalWithStartWorkflowExecution`, `SignalWorkflowExecution`, `StartWorkflowExecution` operations. These operations are mission critical and never throttled. This metric is a good indicator of the lowest possible latency for the 99th percentile of requests. <!-- docs/cloud/service-health.mdx:28-29 -->

## Workflow Execution Latency
<!-- docs/cloud/service-health.mdx:33-40 -->

To monitor end-to-end Workflow execution time (not just service API latency), use the workflow schedule-to-close latency metrics: <!-- docs/cloud/service-health.mdx:34 -->

- `temporal_cloud_v1_workflow_schedule_to_close_latency_p50` <!-- docs/cloud/service-health.mdx:36 -->
- `temporal_cloud_v1_workflow_schedule_to_close_latency_p95` <!-- docs/cloud/service-health.mdx:37 -->
- `temporal_cloud_v1_workflow_schedule_to_close_latency_p99` <!-- docs/cloud/service-health.mdx:38 -->

These measure the time from when a Workflow is scheduled until it closes, including all Activity execution time. A sudden increase may indicate Worker capacity issues, downstream service degradation, or retry storms. <!-- docs/cloud/service-health.mdx:40 -->

## Service Error Rate
<!-- docs/cloud/service-health.mdx:42-73 -->

Check for Temporal Service gRPC API errors. Service API errors are not equivalent to guarantees in the Temporal Cloud SLA. <!-- docs/cloud/service-health.mdx:44-45 -->

### Key Metrics
<!-- docs/cloud/service-health.mdx:49-50 -->

- `temporal_cloud_v1_service_error_count` <!-- docs/cloud/service-health.mdx:49 -->
- `temporal_cloud_v1_service_request_count` <!-- docs/cloud/service-health.mdx:50 -->

### Query: Daily Average Success Rate Over 10-Minute Windows
<!-- docs/cloud/service-health.mdx:54-73 -->

OpenMetrics v1 metrics are pre-computed rates. Use `sum()` to aggregate across dimensions rather than `increase()` or `rate()`. <!-- docs/cloud/service-health.mdx:56 -->

```promql
avg_over_time((
    (
        (
            sum(temporal_cloud_v1_service_request_count{temporal_namespace=~"$namespace", operation=~"StartWorkflowExecution|SignalWorkflowExecution|SignalWithStartWorkflowExecution|RequestCancelWorkflowExecution|TerminateWorkflowExecution"})
            -
            sum(temporal_cloud_v1_service_error_count{temporal_namespace=~"$namespace", operation=~"StartWorkflowExecution|SignalWorkflowExecution|SignalWithStartWorkflowExecution|RequestCancelWorkflowExecution|TerminateWorkflowExecution"})
        )
        /
        sum(temporal_cloud_v1_service_request_count{temporal_namespace=~"$namespace", operation=~"StartWorkflowExecution|SignalWorkflowExecution|SignalWithStartWorkflowExecution|RequestCancelWorkflowExecution|TerminateWorkflowExecution"})
    )

    or vector(1)

    )[1d:1m])
```

## Detecting Activity and Workflow Failures
<!-- docs/cloud/service-health.mdx:75-116 -->

The metrics `temporal_cloud_v1_activity_fail_count` and `temporal_cloud_v1_workflow_failed_count` together provide failure detection for Temporal applications, giving both component-level visibility and high-level workflow health insights. <!-- docs/cloud/service-health.mdx:77 -->

### Activity Failure Cascade
<!-- docs/cloud/service-health.mdx:79-89 -->

If not using infinite retry policies, Activity failures can lead to Workflow failures:

```
Activity Failure --> Retry Logic --> More Activity Failures --> Workflow Decision --> Potential Workflow Failure
```

Activity failures are often recoverable and expected. Workflow failures represent terminal states requiring immediate attention. A spike in activity failures may precede workflow failures. <!-- docs/cloud/service-health.mdx:87-88 -->

Temporal recommends that Workflows should be designed to always succeed. If an Activity fails more than its retry policy allows, the Workflow should handle Activity failure and take action to notify a human or be aware of the error. <!-- docs/cloud/service-health.mdx:89 -->

### Ratio-Based Monitoring
<!-- docs/cloud/service-health.mdx:91-112 -->

#### Failure Conversion Rate
<!-- docs/cloud/service-health.mdx:93-104 -->

Monitor the ratio of workflow failures to activity failures:

```promql
workflow_failure_rate = temporal_cloud_v1_workflow_failed_count / temporal_cloud_v1_activity_fail_count
```

What to watch for: <!-- docs/cloud/service-health.mdx:101-104 -->
- High ratio (greater than 0.1): Poor error handling - activities failing are causing workflow failures
- Low ratio (less than 0.01): Good resilience - activities fail but workflows recover
- Sudden spikes: May indicate systematic issues

#### Activity Success Rate
<!-- docs/cloud/service-health.mdx:106-112 -->

```promql
activity_success_rate = temporal_cloud_v1_activity_success_count / (temporal_cloud_v1_activity_success_count + temporal_cloud_v1_activity_fail_count)
```

Target: >95% for most applications. Lower success rate can be a sign of system troubles. <!-- docs/cloud/service-health.mdx:112 -->

## Replication Lag Monitoring
<!-- docs/cloud/service-health.mdx:118-145 -->

Replication lag refers to the transmission delay of Workflow updates and history events from the primary Namespace to the replica. Always check replication lag before initiating a failover. A forced failover when there is a large replication lag has a higher likelihood of rolling back Workflow progress. <!-- docs/cloud/service-health.mdx:120-122 -->

### Key Metrics
<!-- docs/cloud/service-health.mdx:143-145 -->

- `temporal_cloud_v1_replication_lag_p99` <!-- docs/cloud/service-health.mdx:143 -->
- `temporal_cloud_v1_replication_lag_p95` <!-- docs/cloud/service-health.mdx:144 -->
- `temporal_cloud_v1_replication_lag_p50` <!-- docs/cloud/service-health.mdx:145 -->

### Guidance
<!-- docs/cloud/service-health.mdx:124-136 -->

Temporal owns replication lag. There is no SLA for replication lag. Temporal recommends that customers do not trigger failovers except for testing or emergency situations. Customers who decide to trigger failovers should examine this metric before proceeding. Contact Temporal support if you have a pressing need. <!-- docs/cloud/service-health.mdx:125-136 -->

### Detecting a Failover or Regional Outage

With some Worker deployment patterns, notably Active/Passive, detecting an outage is your responsibility: Workflows make no progress until you detect it and bring up Workers in the new active region.

- A failover is signaled by the Namespace's active region changing, and by a `"operation": "FailoverNamespace"` entry in the audit log.
- To detect a regional outage directly, before or independently of a failover, watch for:
  - A spike in replication lag between the primary and the replica (`temporal_cloud_v1_replication_lag_p50`/`p95`/`p99`, labeled `temporal_namespace`).
  - A drop in Workflow throughput, such as the rate of Workflows started, completed, or Tasks processed.
  - A spike in errors, or a drop in throughput, across your overall stack, not just Temporal.
  - Errors or failovers in other cloud systems you depend on, such as databases, queues, or other regional services.
- Temporal Cloud strives for a P95 replication lag under 1 minute.
- If the replica is unhealthy, Temporal Cloud disables the "Trigger a failover" option in the UI.
- With a replica, `temporal_cloud_v1_total_action_count` is 2x its pre-replica value, because Actions occur on both primary and replica; don't read that as a usage spike.

## Detecting Resource Exhaustion
<!-- docs/cloud/service-health.mdx:147-153 -->

The metric `temporal_cloud_v1_resource_exhausted_error_count` is the primary indicator for Cloud-side throttling, signaling system limits are exceeded and `ResourceExhausted` gRPC errors are occurring. This generally does not break workflow processing due to how resources are prioritized. <!-- docs/cloud/service-health.mdx:149-150 -->

Persistent non-zero values of this metric are unexpected. <!-- docs/cloud/service-health.mdx:152 -->

## Monitoring Trends Against Limits
<!-- docs/cloud/service-health.mdx:154-186 -->

The limit metrics provide a time series of values for limits. Use these with their corresponding count metrics to monitor general trends against limits and set alerts. Use the corresponding throttle metrics to determine the severity of any active rate limiting. <!-- docs/cloud/service-health.mdx:156-158 -->

### Limit / Count / Throttle Triads
<!-- docs/cloud/service-health.mdx:159-163 -->

| Limit Metric | Count Metric | Throttle Metric |
|---|---|---|
| `temporal_cloud_v1_action_limit` | `temporal_cloud_v1_total_action_count` | `temporal_cloud_v1_total_action_throttled_count` |
| `temporal_cloud_v1_service_request_limit` | `temporal_cloud_v1_service_request_count` | `temporal_cloud_v1_service_request_throttled_count` |
| `temporal_cloud_v1_operations_limit` | `temporal_cloud_v1_operations_count` | `temporal_cloud_v1_operations_throttled_count` |

### On-Demand Envelope Limits
<!-- docs/cloud/service-health.mdx:165-176 -->

For Namespaces using provisioned capacity, the following metrics show what limits would be under on-demand mode. Compare against current provisioned limits to evaluate capacity mode choices: <!-- docs/cloud/service-health.mdx:167-168 -->

| On-Demand Envelope Metric | Equivalent Limit Metric |
|---|---|
| `temporal_cloud_v1_action_on_demand_envelope_limit` | `temporal_cloud_v1_action_limit` |
| `temporal_cloud_v1_operations_on_demand_envelope_limit` | `temporal_cloud_v1_operations_limit` |
| `temporal_cloud_v1_service_request_on_demand_envelope_limit` | `temporal_cloud_v1_service_request_limit` |

For Namespaces already in on-demand mode, these metrics track the same values as their equivalent limit metrics. <!-- docs/cloud/service-health.mdx:176 -->

### Alerting Guidance
<!-- docs/cloud/service-health.mdx:181-186 -->

The limit, throttle, and count metrics are directly comparable as per-second rates. Each `count` metric is a per-second rate averaged over each minute; to get the total count (e.g., of Actions), multiply by 60. <!-- docs/cloud/service-health.mdx:181-182 -->

When setting alerts against limits, consider workload characteristics: <!-- docs/cloud/service-health.mdx:183-186 -->
- **Latency-sensitive workloads:** Alert when `temporal_cloud_v1_total_action_count` reaches 50% of `temporal_cloud_v1_action_limit`.
- **Latency-insensitive workloads:** Alert at 90% of the threshold, or directly when throttling is detected (value greater than zero for `temporal_cloud_v1_total_action_throttled_count`).
- This logic can also be used to automatically scale Temporal Resource Units up or down as needed.
- Some workloads choose to exceed limits and accept throttling because they are not latency sensitive.

A [Grafana dashboard example](https://github.com/grafana/jsonnet-libs/blob/master/temporal-mixin/dashboards/temporal-overview.json) includes a Usage & Quotas section with demo charts for limits and count metrics. <!-- docs/cloud/service-health.mdx:178-179 -->

### Grafana Action Cost Dashboard and Alert Rules

`temporalio/observability-examples` ships a Grafana dashboard, "Temporal Cloud - Actions MTD & Spike Detection" (`cloud/temporal_cloud_action_costs.json`), and sample alert rules for it (`cloud/temporal_cloud_action_costs_alerts.yaml`).

- The YAML is a Grafana unified-alerting provisioning file, imported separately from the dashboard JSON. Replace every `PROM_DS_UID` with your Prometheus data source UID before import.
- Rules link back to the dashboard through `__dashboardUid__` annotations (the two spike rules also set `__panelId__`), which only work while the dashboard uid stays `temporal-cloud-action-costs`; update the annotations if you re-key it.
- Three per-namespace rules (`sum by (temporal_namespace)` over `temporal_cloud_v1_total_action_count`), evaluated every 5m in group `temporal-cloud-action-spikes`:
  - `tcloud-action-spike-24h`: warning, fires when the rate is more than 50% above the same time 24h ago (`offset 1d`), for 10m.
  - `tcloud-action-spike-7d`: warning, more than 75% above 7 days ago (`offset 7d`), for 10m; looser because week-over-week varies more.
  - `tcloud-action-limit-approaching`: critical, `total_action_count{is_background="false"}` over its own `temporal_cloud_v1_action_limit` above 80%, for 5m.
- Spike rules catch increases only, not drops (for example Workers going down).
- The 50%, 75% and 80% thresholds are starting points: watch for a week or two and adjust the `params` values to your traffic.
