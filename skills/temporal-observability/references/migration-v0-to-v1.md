# PromQL to OpenMetrics Migration (v0 to v1)

<!-- Sources: docs/cloud/metrics/openmetrics/migration-guide.mdx, docs/cloud/metrics/reference.mdx, docs/cloud/metrics/general-setup.mdx, docs/cloud/metrics/promql.mdx -->

This reference covers migrating from the deprecated PromQL endpoint (`temporal_cloud_v0_*` metrics) to the OpenMetrics endpoint (`temporal_cloud_v1_*` metrics): timeline, what is changing, notable differences, migration steps, complete v0-to-v1 metric mapping tables, handling sparse metrics, high-cardinality management, and FAQ.

Query Cloud metrics in the monitoring platform that collects them: the OpenMetrics endpoint has no time-series query API and returns only the most recently completed aggregation window.

To treat an absent series as zero, configure the query in the monitoring platform that collects the metrics. For PromQL, use `sum(temporal_cloud_v1_workflow_failed_count) or vector(0)`.

## Migration Timeline
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:71-79 -->

- **April 2, 2026**: PromQL endpoint deprecated. No longer accepting new users. Existing users should begin migrating. <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:71-74 -->
- **October 5, 2026**: PromQL endpoint disabled for all users. All metrics consumption must use the OpenMetrics endpoint by this date. <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:76-79 -->

## What Is Changing
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:60-67 -->

| Aspect | PromQL Endpoint (Current) | OpenMetrics Endpoint (New) |
|---|---|---|
| **Protocol** | Prometheus Query API (`/api/v1/query`) | OpenMetrics scrape endpoint (`/v1/metrics`) |
| **Authentication** | mTLS certificates with customer-specific endpoints | API keys with global endpoint |
| **Metric Temporality** | Cumulative counters | Delta temporality (pre-computed rates) |
| **Query Requirement** | Direct queries supported | Requires observability platform |
| **Cardinality** | Limited labels | High-cardinality labels available |
| **Metric Naming** | `*_v0_*` metrics | `*_v1_*` metrics |

The PromQL endpoint retains raw metrics for seven days. <!-- docs/cloud/metrics/promql.mdx:34 -->

## Notable Differences

### 1. No `rate()` in Prometheus Queries
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:89-103 -->

Metrics are now pre-computed as per-second rates with delta temporality. <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:91 -->

**Before (PromQL endpoint):**
```promql
rate(temporal_cloud_v0_frontend_service_request_count[1m])
```

**After (OpenMetrics endpoint):**
```promql
temporal_cloud_v1_service_request_count
```

### 2. Functions That No Longer Apply
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:105-114 -->

Since metrics from OpenMetrics are already rates, certain Prometheus functions no longer make sense:

- `rate()` - Already computed <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:110 -->
- `increase()` - Increase of a rate is meaningless <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:111 -->
- `irate()` - Instant rate not applicable <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:112 -->
- `histogram_quantile()` - Not applicable (explicit percentiles provided instead) <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:113 -->
- `sum()`, `avg()`, `max()`, `min()` - Still work normally <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:114 -->

### 3. Percentile Metrics
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:116-138 -->

The new endpoint provides explicit percentile metrics (p50, p95, p99) rather than histogram buckets: <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:118 -->

**Before:** Calculate percentiles using `histogram_quantile()`: <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:120-124 -->
```promql
histogram_quantile(0.95, rate(temporal_cloud_v0_service_latency_bucket[5m]))
```

**After:** Use pre-calculated percentiles directly: <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:126-130 -->
```promql
temporal_cloud_v1_service_latency_p95
```

**Important tradeoff:** Pre-calculated percentiles are more accurate for individual time series but cannot be accurately aggregated: <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:132-138 -->
- Cannot sum or average p95 values across Namespaces to get a global p95
- Cannot aggregate p95 values across regions or Task Queues
- Can still view individual namespace/task queue percentiles accurately
- More accurate percentile calculations for individual series, especially with outliers

### 4. Authentication Change
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:140-156 -->

**Before:** mTLS certificates with customer-specific endpoint <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:142 -->
```shell
curl --cert /path/to/client.pem \
     --key /path/to/client.key \
     --cacert /path/to/ca.pem \
"https://<customer-specific>.tmprl.cloud/api/v1/query?query=rate(temporal_cloud_v0_frontend_service_request_count[5m])&time=2025-01-15T10:00:00Z"
```

**After:** API key with global endpoint <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:152 -->
```shell
curl -H "Authorization: Bearer <API_KEY>" https://metrics.temporal.io/v1/metrics
```

## Migration Steps

### Step 1: Create an API Key
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:160-177 -->

Create a service account within the Temporal Cloud UI settings with the "Metrics Read-Only" Account Level Role. As this is an account-level role, scoping it to specific namespaces has no effect; it will have access to the full account's metrics. <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:162-167 -->

Create an API key within the service account (it inherits the role). Save this API key in a secure location. <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:176-177 -->

Test with: <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:183-184 -->
```shell
curl -H "Authorization: Bearer <API_KEY>" https://metrics.temporal.io/v1/metrics
```

### Step 2: Configure Prometheus
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:196-216 -->

Add a new scrape job for the OpenMetrics endpoint: <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:200 -->

```yaml
scrape_configs:
  - job_name: temporal-cloud
    static_configs:
      - targets:
          - 'metrics.temporal.io'
    scheme: https
    metrics_path: '/v1/metrics'
    honor_timestamps: true
    scrape_interval: 30s
    scrape_timeout: 30s
    authorization:
      type: Bearer
      credentials: 'API_KEY'
```

This replaces the direct Grafana data source configuration used with the query endpoint. <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:220 -->

### Step 3: Install New Dashboards
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:224-229 -->

- Download the new Grafana dashboard: [temporal_cloud_openmetrics.json](https://github.com/temporalio/dashboards/blob/master/cloud/temporal_cloud_openmetrics.json) <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:227 -->
- Import alongside existing dashboards during transition <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:228 -->
- Update any custom alerts and queries to use new metrics and remove `rate()` functions <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:229 -->

### Other Observability Providers
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:231-240 -->

- [Datadog](https://docs.datadoghq.com/integrations/temporal-cloud-openmetrics/) <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:236 -->
- [NewRelic](https://docs.newrelic.com/docs/infrastructure/prometheus-integrations/install-configure-openmetrics/configure-prometheus-openmetrics-integrations/) <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:237 -->
- [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/configuration/#receivers) <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:238 -->

Examples for all integrations: https://github.com/temporal-community/cloud-metrics-scrape-examples <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:240 -->

## Metric Mapping Reference
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:242-297 -->

All metrics follow the pattern of `v0` to `v1` version change. The fundamental difference is the shift from cumulative counters to pre-computed rates for the majority of metrics. Labels below are only new labels added in v1. <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:244 -->

### Frontend Service Metrics
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:248-254 -->

| Old Metric (v0) | New Metric (v1) | New Labels |
|---|---|---|
| `temporal_cloud_v0_frontend_service_error_count` | `temporal_cloud_v1_service_error_count` | `region` |
| `temporal_cloud_v0_frontend_service_request_count` | `temporal_cloud_v1_service_request_count` | `region` |
| `temporal_cloud_v0_resource_exhausted_error_count` | `temporal_cloud_v1_resource_exhausted_error_count` | `region` |
| `temporal_cloud_v0_state_transition_count` | No direct equivalent | - |
| `temporal_cloud_v0_total_action_count` | `temporal_cloud_v1_total_action_count` | `region` |

**Note:** `temporal_cloud_v0_state_transition_count` does not have an equivalent metric in the OpenMetrics endpoint. To size workloads (e.g., when migrating from self-hosted), use action-based metrics (`temporal_cloud_v1_total_action_count`) and request-based metrics (`temporal_cloud_v1_service_request_count`) together instead. <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:258-259 -->

### Workflow Metrics
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:263-272 -->

| Old Metric (v0) | New Metric (v1) | New Labels |
|---|---|---|
| `temporal_cloud_v0_workflow_cancel_count` | `temporal_cloud_v1_workflow_cancel_count` | `region` `temporal_workflow_type` `temporal_task_queue` |
| `temporal_cloud_v0_workflow_continued_as_new_count` | `temporal_cloud_v1_workflow_continued_as_new_count` | `region` `temporal_workflow_type` `temporal_task_queue` |
| `temporal_cloud_v0_workflow_failed_count` | `temporal_cloud_v1_workflow_failed_count` | `region` `temporal_workflow_type` `temporal_task_queue` |
| `temporal_cloud_v0_workflow_success_count` | `temporal_cloud_v1_workflow_success_count` | `region` `temporal_workflow_type` `temporal_task_queue` |
| `temporal_cloud_v0_workflow_terminate_count` | `temporal_cloud_v1_workflow_terminate_count` | `region` `temporal_workflow_type` `temporal_task_queue` |
| `temporal_cloud_v0_workflow_timeout_count` | `temporal_cloud_v1_workflow_timeout_count` | `region` `temporal_workflow_type` `temporal_task_queue` |

### Poll Metrics
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:274-280 -->

| Old Metric (v0) | New Metric (v1) | New Labels |
|---|---|---|
| `temporal_cloud_v0_poll_success_count` | `temporal_cloud_v1_poll_success_count` | `region` `temporal_task_queue` |
| `temporal_cloud_v0_poll_success_sync_count` | `temporal_cloud_v1_poll_success_sync_count` | `region` `temporal_task_queue` |
| `temporal_cloud_v0_poll_timeout_count` | `temporal_cloud_v1_poll_timeout_count` | `region` `temporal_task_queue` |

### Latency Metrics
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:282-287 -->

| Old Metric (v0) | New Metric (v1) | New Labels |
|---|---|---|
| `temporal_cloud_v0_service_latency_bucket` / `_count` / `_sum` | `temporal_cloud_v1_service_latency_p99` / `_p95` / `_p50` | `region` |
| `temporal_cloud_v0_replication_lag_bucket` / `_count` / `_sum` | `temporal_cloud_v1_replication_lag_p99` / `_p95` / `_p50` | `region` |

### Schedule Metrics
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:289-296 -->

| Old Metric (v0) | New Metric (v1) | New Labels |
|---|---|---|
| `temporal_cloud_v0_schedule_action_success_count` | `temporal_cloud_v1_schedule_action_success_count` | `region` |
| `temporal_cloud_v0_schedule_buffer_overruns_count` | `temporal_cloud_v1_schedule_buffer_overruns_count` | `region` |
| `temporal_cloud_v0_schedule_missed_catchup_window_count` | `temporal_cloud_v1_schedule_missed_catchup_window_count` | `region` |
| `temporal_cloud_v0_schedule_rate_limited_count` | `temporal_cloud_v1_schedule_rate_limited_count` | `region` |

In addition to these mapped metrics, the OpenMetrics endpoint provides many new metrics not available in v0. See `cloud-metrics-catalog.md` for the complete catalog.

## Handling Missing Metrics (Sparse Reporting)
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:400-420 -->

The OpenMetrics endpoint only returns metrics that were generated during the one-minute aggregation window. This differs from the PromQL endpoint which might return zeros. <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:402-403 -->

This means: <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:406-409 -->
- If no workflows failed in the last minute, `temporal_cloud_v1_workflow_failed_count` will not appear in that scrape.
- If a specific task queue had no activity, its metrics will be absent.
- The set of metrics returned varies between scrapes based on system activity.

This is normal behavior. Use `or vector(0)` in queries to handle absent metrics: <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:416-418 -->

```promql
(temporal_cloud_v1_workflow_failed_count{namespace="production"} or vector(0))
```

## Managing High Cardinality
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:306-365 -->

The new endpoint provides access to high-cardinality labels: `temporal_task_queue` and `temporal_workflow_type`. <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:308-313 -->

### Namespace/Metric Filtering
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:317-330 -->

```
https://metrics.temporal.io/v1/metrics?namespaces=production-*
```

Can be combined with metric filtering: <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:325-329 -->
```
https://metrics.temporal.io/v1/metrics?metrics=temporal_cloud_v1_workflow_success_count?namespaces=production-*
```

### Relabeling in Prometheus
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:332-365 -->

Drop problematic labels post-scrape but pre-ingestion: <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:334-335 -->

```yaml
metric_relabel_configs:
- source_labels: [__name__]
  regex: 'temporal_cloud_v1_poll_success_count'
  action: labeldrop
  regex: 'temporal_task_queue'
```

Or relabel certain label values to reduce cardinality while retaining important ones: <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:348-349 -->

```yaml
metric_relabel_configs:
  - source_labels: [temporal_task_queue]
    regex: '(critical-queue|payment-queue)'
    target_label: __tmp_keep_original
    replacement: 'true'
  - source_labels: [__tmp_keep_original]
    regex: ''
    target_label: temporal_task_queue
    replacement: 'unknown'
  - regex: '__tmp_keep_original'
    action: labeldrop
```

## FAQ
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:371-420 -->

### Will metrics match between PromQL and OpenMetrics endpoints?
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:373-378 -->

No. Metrics will be approximately the same but due to aggregation differences and windowing, values likely will not match exactly. Some metrics may be consistently different; for example, `temporal_cloud_v1_total_action_count` includes History Export actions in the OpenMetrics endpoint. In case of consistent differences, the OpenMetrics endpoint is considered more accurate. <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:375-378 -->

### Can I still query metrics directly?
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:380-383 -->

Currently, the OpenMetrics endpoint requires an observability platform to collect and query metrics. Direct querying via API to return a time series of data is not supported. This is a future roadmap item. <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:382-383 -->

### What happens to existing dashboards and alerts?
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:385-387 -->

During the transition period, both endpoints remain active. <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:387 -->

### Will historical data be preserved?
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:389-394 -->

Historical data from the query endpoint will remain in your observability platform. To maintain continuity, combine old (`v0`) and new (`v1`) metrics in queries during transition using the PromQL `or` operator: `metric_v1 or metric_v0`. <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:391-394 -->

### Are there scrape frequency or data limits?
<!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:396-398 -->

See API limits in `openmetrics-endpoint.md` (30k datapoints per scrape; 180 requests per account per hour). <!-- docs/cloud/metrics/openmetrics/migration-guide.mdx:398 -->
