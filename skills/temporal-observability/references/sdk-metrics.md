# SDK Metrics Overview

<!-- Sources: docs/references/sdk-metrics.mdx, docs/cloud/metrics/sdk-metrics-setup.mdx -->

This reference covers SDK metrics: how they differ from Cloud metrics, Prometheus configuration for SDK scrape, Grafana data source setup, the key SDK metrics for observability, and metric unit differences across SDKs.

## SDK Metrics vs Cloud Metrics

SDK metrics are emitted by SDK Clients used to start Workers and to start, signal, or query Workflow Executions. Unlike Temporal Cloud metrics (exposed through the OpenMetrics HTTP API endpoint at `metrics.temporal.io`), SDK metrics require setting up a Prometheus scrape endpoint in application code for Prometheus to collect and aggregate. <!-- docs/cloud/metrics/sdk-metrics-setup.mdx:25-26 -->

All SDK metrics are prefixed with `temporal_` before being exported to their configured destination. <!-- docs/references/sdk-metrics.mdx:38 -->

Prometheus suffixes, as the docs give the names to query: counters gain `_total` (`temporal_request_failure_total`); histograms gain `_seconds_bucket` on the bucket series (`temporal_workflow_task_schedule_to_start_latency_seconds_bucket`); gauges take no suffix (`temporal_num_pollers`, `temporal_worker_task_slots_available`, `temporal_sticky_cache_size`), so adding `_total` returns nothing. Use these names unless an exporter's options change them; in Core-based SDKs such as TypeScript, the Prometheus exporter adds `_total` and unit suffixes only when the Worker enables them. Exporter options are covered by the [temporal-developer skill](https://github.com/temporalio/skill-temporal-developer).

SDK metrics are distinct from Cloud metrics (`temporal_cloud_v1_*`) and self-hosted cluster metrics (e.g., `service_requests`). They are emitted by the application-side SDK, not the Temporal Service.

## Metric Unit Differences Across SDKs
<!-- docs/references/sdk-metrics.mdx:55-65 -->

The unit of measurement for Histogram metrics varies by SDK:

- **Core-based SDKs** (TypeScript, Python, .NET): Histogram metrics are measured in **milliseconds** by default. This can be customized to use seconds. <!-- docs/references/sdk-metrics.mdx:59-61 -->
- **Java and Go SDKs**: Histogram metrics are measured in **seconds**. <!-- docs/references/sdk-metrics.mdx:63 -->

The Core SDK is a shared common core library used by TypeScript, Python, and .NET SDKs. <!-- docs/references/sdk-metrics.mdx:61 -->

## Emitting SDK Metrics

A Worker or Client emits SDK metrics only after its process enables an exporter, such as a Prometheus endpoint or OTLP. To enable one, use the [temporal-developer skill](https://github.com/temporalio/skill-temporal-developer).

## Prometheus Configuration for SDK Scrape
<!-- docs/cloud/metrics/sdk-metrics-setup.mdx:68-91 -->

Prometheus must be configured to listen on the scrape endpoints exposed in application code. The following example assumes the scrape endpoint is on port 8077: <!-- docs/cloud/metrics/sdk-metrics-setup.mdx:70-74 -->

```yaml
global:
  scrape_interval: 30s

scrape_configs:
  - job_name: 'temporalsdkmetrics'
    metrics_path: /metrics
    scheme: http
    static_configs:
      - targets:
          - localhost:8077
```

To verify Prometheus is receiving SDK metrics, navigate to `http://localhost:9090` and check **Status > Targets** for the target endpoint status. <!-- docs/cloud/metrics/sdk-metrics-setup.mdx:95-96 -->

## Grafana Data Source Setup
<!-- docs/cloud/metrics/sdk-metrics-setup.mdx:98-120 -->

To add the SDK metrics Prometheus endpoint as a Grafana data source:

1. Go to **Configuration > Data sources**. <!-- docs/cloud/metrics/sdk-metrics-setup.mdx:106 -->
2. Select **Add data source > Prometheus**. <!-- docs/cloud/metrics/sdk-metrics-setup.mdx:107 -->
3. Enter a name (e.g., "Temporal SDK metrics"). <!-- docs/cloud/metrics/sdk-metrics-setup.mdx:108 -->
4. In the **HTTP** section, enter the Prometheus endpoint URL (e.g., `http://localhost:9090`). <!-- docs/cloud/metrics/sdk-metrics-setup.mdx:109-110 -->
5. Enable **Skip TLS Verify** in the **Auth** section (for local setups). <!-- docs/cloud/metrics/sdk-metrics-setup.mdx:111 -->
6. Click **Save and test** to verify. <!-- docs/cloud/metrics/sdk-metrics-setup.mdx:112 -->

Community-driven example dashboards for Temporal SDKs are available at: https://github.com/temporalio/dashboards/tree/master/sdk <!-- docs/cloud/metrics/sdk-metrics-setup.mdx:128-129 -->

## Common Tags on SDK Metrics
<!-- docs/references/sdk-metrics.mdx:67-84 -->

Each metric may have some combination of the following tags:

| Tag | Description |
|---|---|
| `task_queue` | Task Queue that the Worker Entity is polling |
| `namespace` | Namespace the Worker is bound to |
| `poller_type` | One of: `workflow_task`, `activity_task`, `nexus_task` (Go and Java only), `sticky_workflow_task` |
| `worker_type` | One of: `ActivityWorker`, `WorkflowWorker`, `LocalActivityWorker` (Go and Java only), `NexusWorker` (Go and Java only) |
| `activity_type` | The name of the Activity Function |
| `workflow_type` | The name of the Workflow Function |
| `operation` | RPC method name; available for metrics related to Temporal Client gRPC requests |

Some tags may not be available in every SDK, and Histogram metrics may have different buckets in each SDK. <!-- docs/references/sdk-metrics.mdx:85 -->

## Key SDK Metrics for Observability

The following are the most important SDK metrics for operational monitoring. The full list is in `docs/references/sdk-metrics.mdx`.

### Schedule-to-Start Latency

#### `temporal_workflow_task_schedule_to_start_latency`
<!-- docs/references/sdk-metrics.mdx:550-557 -->

The Schedule-To-Start time of a Workflow Task.

- Type: Histogram
- Available in: Core, Go, Java
- Tags: `namespace`, `task_queue`

#### `temporal_activity_schedule_to_start_latency`
<!-- docs/references/sdk-metrics.mdx:171-182 -->

The Schedule-To-Start time of an Activity Task in seconds. Useful for ensuring Activity Tasks are being processed from the queue in a timely manner. <!-- docs/references/sdk-metrics.mdx:173-177 -->

- Type: Histogram
- Available in: Core, Go, Java
- Tags: `namespace`, `task_queue`

### Execution Latency

#### `temporal_workflow_task_execution_latency`
<!-- docs/references/sdk-metrics.mdx:518-524 -->

Workflow Task Execution time.

- Type: Histogram
- Available in: Core, Go, Java
- Tags: `namespace`, `task_queue`, `workflow_type`

#### `temporal_activity_execution_latency`
<!-- docs/references/sdk-metrics.mdx:155-161 -->

Time to complete an Activity Execution, from the time the Activity Task is generated to the time the language SDK responded with a completion (failure or success).

- Type: Histogram
- Available in: Core, Go, Java
- Tags: `activity_type`, `namespace`, `task_queue`

#### `temporal_workflow_endtoend_latency`
<!-- docs/references/sdk-metrics.mdx:489-495 -->

Total Workflow Execution time from schedule to completion for a single Workflow Run. A retried Workflow Execution is a separate Run.

- Type: Histogram
- Available in: Core, Go, Java
- Tags: `namespace`, `task_queue`, `workflow_type`

### Replay Latency

#### `temporal_workflow_task_replay_latency`
<!-- docs/references/sdk-metrics.mdx:543-548 -->

Time to catch up on replaying a Workflow Task.

- Type: Histogram
- Available in: Core, Go, Java
- Tags: `namespace`, `task_queue`, `workflow_type`

### Task Slots

#### `temporal_worker_task_slots_available`
<!-- docs/references/sdk-metrics.mdx:437-445 -->

The total number of Workflow, Activity, Local Activity, or Nexus Task execution slots that are currently available. Use the `worker_type` tag to differentiate execution slots.

- Type: Gauge
- Available in: Core, Go, Java
- Tags: `namespace`, `task_queue`, `worker_type`

#### `temporal_worker_task_slots_used`
<!-- docs/references/sdk-metrics.mdx:448-456 -->

The total number of Workflow, Activity, Local Activity, or Nexus Task execution slots in current use. Use the `worker_type` tag to differentiate execution slots.

- Type: Gauge
- Available in: Core, Go, Java
- Tags: `namespace`, `task_queue`, `worker_type`

### Sticky Cache

#### `temporal_sticky_cache_hit`
<!-- docs/references/sdk-metrics.mdx:388-394 -->

A Workflow Task found a cached Workflow Execution to run against.

- Type: Counter
- Available in: Core, Go, Java
- Tags: `namespace`, `task_queue`

#### `temporal_sticky_cache_miss`
<!-- docs/references/sdk-metrics.mdx:396-402 -->

A Workflow Task did not find a cached Workflow Execution to run against.

- Type: Counter
- Available in: Core, Go, Java
- Tags: `namespace`, `task_queue`

#### `temporal_sticky_cache_size`
<!-- docs/references/sdk-metrics.mdx:404-410 -->

Current cache size, expressed in number of Workflow Executions.

- Type: Gauge
- Available in: Core, Go, Java
- Tags: `namespace` (TypeScript, Java), `task_queue` (TypeScript)

### Poll Metrics

#### `temporal_workflow_task_queue_poll_succeed`
<!-- docs/references/sdk-metrics.mdx:534-540 -->

A Workflow Worker polled a Task Queue and successfully picked up a Workflow Task.

- Type: Counter
- Available in: Core, Go, Java
- Tags: `namespace`, `task_queue`

#### `temporal_workflow_task_queue_poll_empty`
<!-- docs/references/sdk-metrics.mdx:526-532 -->

A Workflow Worker polled a Task Queue and timed out without picking up a Workflow Task.

- Type: Counter
- Available in: Core, Go, Java
- Tags: `namespace`, `task_queue`

#### `temporal_activity_poll_no_task`
<!-- docs/references/sdk-metrics.mdx:163-169 -->

An Activity Worker poll for an Activity Task timed out, and no Activity Task is available.

- Type: Counter
- Available in: Core, Go, Java
- Tags: `namespace`, `task_queue`

### Failure Metrics

#### `temporal_workflow_task_execution_failed`
<!-- docs/references/sdk-metrics.mdx:505-517 -->

A Workflow Task Execution failed.

- Type: Counter
- Available in: Core, Go, Java
- Tags: `namespace`, `task_queue`, `workflow_type`, `failure_reason`

Valid values for `failure_reason`:
- `NonDeterminismError`: The Workflow Task failed because of a non-determinism error.
- `GrpcMessageTooLarge`: The Workflow Task response exceeded the gRPC message size limit and couldn't be delivered. The Temporal Service terminates the Workflow Execution in response.
- `PayloadsTooLarge`: A Payload or Memo in the Workflow Task response exceeded the Namespace size limit, so the Worker failed the Workflow Task as retryable before sending it.
- `RequestTooLarge`: The whole Workflow Task completion exceeded the Namespace limit on the size of a single request. The Worker failed the Workflow Task instead of sending it, and the Temporal Service retries it.
- `ExternalStorageError`: The Workflow Task failed on an External Storage error, so storage faults are separate from other Worker failures. Core-based SDKs only count this from Core 0.11.0 (Python 1.36.0); before that these failures were counted as `WorkflowError`.
- `WorkflowError`: The Workflow Task failed for any other reason.

This counter is recorded for every failed Workflow Task attempt, including later attempts whose failure Core does not report to the server (Core 0.10.0; Ruby v1.10.0, Python 1.34.0, TypeScript v1.25.0). One stuck Workflow Task therefore increments it on each attempt, so it is not a count of distinct Workflow Executions.

With `GrpcMessageTooLarge` the Temporal Service terminates the Workflow Execution; `PayloadsTooLarge` and `RequestTooLarge` fail the Workflow Task as retryable.

#### `temporal_activity_execution_failed`
<!-- docs/references/sdk-metrics.mdx:148-153 -->

An Activity Execution failed. Does not include local Activity Failures in Go and Java SDKs.

- Type: Counter
- Available in: Core, Go, Java
- Tags: `activity_type`, `namespace`, `task_queue`, `workflow_type`, `failure_reason`

Valid values for `failure_reason`:
- `PayloadsTooLarge`: A Payload in the Activity Task response exceeded the Namespace size limit, so the Worker failed the Activity Task as retryable before sending it.
- `ExternalStorageError`: Core-based SDKs report this when the Activity Task failed on an External Storage error.
- `ActivityError`: The Activity Task failed for any other reason.

To track failures in Activity code and its dependencies, the docs suggest filtering on `failure_reason=ActivityError`, and alerting on any occurrence of `PayloadsTooLarge`.

#### `temporal_local_activity_execution_failed`

A Local Activity Execution failed.

- Type: Counter
- Available in: Core, Go, Java
- Tags: `activity_type`, `namespace`, `task_queue`, `workflow_type`, `failure_reason`

Valid values for `failure_reason`:
- `timeout`: The Local Activity exceeded its Schedule-To-Close Timeout or Start-To-Close Timeout.
- `ActivityError`: The Local Activity failed for any other reason.

## Complete Metric List

For the full table of all SDK metrics, their types, and SDK availability, see `docs/references/sdk-metrics.mdx:87-137`. <!-- docs/references/sdk-metrics.mdx:87-137 -->

SDK metric definitions are maintained in the following source locations: <!-- docs/references/sdk-metrics.mdx:49-53 -->
- [Core SDK Worker metrics](https://github.com/temporalio/sdk-core/blob/master/crates/sdk-core/src/telemetry/metrics.rs)
- [Core SDK Client metrics](https://github.com/temporalio/sdk-core/blob/master/crates/client/src/metrics.rs)
- [Java SDK Worker metrics](https://github.com/temporalio/sdk-java/blob/master/temporal-sdk/src/main/java/io/temporal/worker/MetricsType.java)
- [Java SDK Client metrics](https://github.com/temporalio/sdk-java/blob/master/temporal-serviceclient/src/main/java/io/temporal/serviceclient/MetricsType.java)
- [Go SDK Worker and Client metrics](https://github.com/temporalio/sdk-go/blob/c32b04729cc7691f80c16f80eed7f323ee5ce24f/internal/common/metrics/constants.go)
