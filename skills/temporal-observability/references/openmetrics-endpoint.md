# OpenMetrics Endpoint Setup and API

<!-- Sources: docs/cloud/metrics/openmetrics/api-reference.mdx, docs/cloud/metrics/openmetrics/index.mdx -->

This reference covers the Temporal Cloud OpenMetrics endpoint: authentication, API endpoints, query parameters, rate limits, data latency, scrape best practices, and high-cardinality management.

## Quick Answers

- **Multiple values for `namespaces` or `metrics`:** repeat the key once per value, e.g. `/v1/metrics?namespaces=prod-payments&namespaces=prod-orders&metrics=temporal_cloud_v1_workflow_success_count&metrics=temporal_cloud_v1_approximate_backlog_count`.
- **Scrape account role:** a Service Account with the account-level **Metrics Read-Only** role. It grants read access to the endpoint and nothing else; only an Account Owner or Global Admin can grant it or manage the account's API keys.
- **Worker labels:** opt in with `labels=temporal_worker_deployment_name` and `labels=temporal_worker_build_id` (repeated `labels` keys).
- **Integration setup (Datadog, Elastic, Grafana Cloud, SigNoz, Parseable, ...):** see `integrations.md`.

## Overview
<!-- docs/cloud/metrics/openmetrics/index.mdx:41 -->

Temporal Cloud OpenMetrics exposes 50+ metrics covering workflow lifecycles, task queue operations, service performance, and system limits. All metrics are aggregated over one-minute windows and available for scraping within three minutes. Each scrape returns only the most recently completed one-minute window; configure your monitoring system to retain what it scrapes.

## Global Endpoint
<!-- docs/cloud/metrics/openmetrics/index.mdx:51 -->

A single endpoint at `metrics.temporal.io` serves all metrics across an entire account with API key authentication and standard HTTPS. <!-- docs/cloud/metrics/openmetrics/api-reference.mdx:142 -->

## Authentication
<!-- docs/cloud/metrics/openmetrics/api-reference.mdx:34-58 -->

Temporal uses API keys for integrating with the OpenMetrics endpoint. An API key is owned by a Service Account and inherits the permissions granted to the owner.

### Creating API Keys
<!-- docs/cloud/metrics/openmetrics/api-reference.mdx:39-46 -->

API keys can be created using the Temporal Cloud UI:

1. Navigate to Settings -> Service Accounts
2. Create a service account with the **"Metrics Read-Only"** Account Level Role <!-- docs/cloud/metrics/openmetrics/api-reference.mdx:44 -->
3. Generate an API key within the service account

### Using API Keys
<!-- docs/cloud/metrics/openmetrics/api-reference.mdx:54-59 -->

All API requests must be made over HTTPS. Calls made over plain HTTP will fail. API requests without authentication will also fail.

```shell
curl -H "Authorization: Bearer <API_KEY>" https://metrics.temporal.io/v1/metrics
```

## Endpoints

### Get Metrics
<!-- docs/cloud/metrics/openmetrics/api-reference.mdx:148 -->

`GET /v1/metrics` <!-- docs/cloud/metrics/openmetrics/api-reference.mdx:148 -->

Returns metrics in OpenMetrics format suitable for scraping by Prometheus-compatible systems.

#### Timestamp Offset
<!-- docs/cloud/metrics/openmetrics/api-reference.mdx:152-154 -->

To account for metric data latency, the endpoint returns metrics from the current timestamp minus a fixed offset. The current offset is 3 minutes rounded down to the start of the minute. To accommodate this offset, timestamps in the response should be honored when importing metrics. For example, in Prometheus this can be controlled using the `honor_timestamps` flag. <!-- docs/cloud/metrics/openmetrics/api-reference.mdx:154 -->

#### Query Parameters
<!-- docs/cloud/metrics/openmetrics/api-reference.mdx:158-162 -->

| Parameter | Type | Description |
|---|---|---|
| `namespaces` | string array | Filter to specific Namespaces. Supports wildcards (e.g., `production-*`) |
| `metrics` | string array | Filter to specific metrics |

Array parameters use repeated keys (one `namespaces=` or `metrics=` per value).

Opt-in labels are enabled via an additional `labels` query parameter (see cloud-metrics-catalog.md for details on available opt-in labels).

#### Response Headers
<!-- docs/cloud/metrics/openmetrics/api-reference.mdx:164-168 -->

| Header | Description |
|---|---|
| `X-Completeness` | Indicates the response status: `complete`, `limited`, or `unknown` |
| `Content-Type` | `application/openmetrics-text` |

**`X-Completeness` values:** <!-- docs/cloud/metrics/openmetrics/api-reference.mdx:120-124 -->
- `complete`: The response contains all metrics requested.
- `limited`: Response truncated due to size limits (30k metric data points max). Use namespace or metric filtering to reduce the response size.
- `unknown`: Completeness cannot be determined (possibly due to regional issues or timeouts). Clients are encouraged to retry.

#### Example Request
<!-- docs/cloud/metrics/openmetrics/api-reference.mdx:174-177 -->

```shell
curl -H "Authorization: Bearer <API_KEY>" \
  "https://metrics.temporal.io/v1/metrics?namespaces=production-*"
```

### List Metric Descriptors
<!-- docs/cloud/metrics/openmetrics/api-reference.mdx:200-202 -->

`GET /v1/descriptors` <!-- docs/cloud/metrics/openmetrics/api-reference.mdx:202 -->

Lists all metric descriptors including metadata, data types, and available dimensions (labels).

#### Query Parameters
<!-- docs/cloud/metrics/openmetrics/api-reference.mdx:208-211 -->

| Parameter | Type | Description |
|---|---|---|
| `limit` | integer | Page size (1-100, default: 100) |
| `offset` | integer | Page offset |

#### Example Request
<!-- docs/cloud/metrics/openmetrics/api-reference.mdx:216-219 -->

```shell
curl -H "Authorization: Bearer <API_KEY>" \
  "https://metrics.temporal.io/v1/descriptors"
```

Example response includes a `meta.pagination` object with `total`, `limit`, `offset` and a `descriptors` array with `name`, `help`, and `dimensions` for each metric. <!-- docs/cloud/metrics/openmetrics/api-reference.mdx:224-246 -->

## Rate Limits
<!-- docs/cloud/metrics/openmetrics/api-reference.mdx:98-117 -->

When a rate limit is breached, an HTTP `429 Too Many Requests` error is returned with a `Retry-After` header indicating the time in seconds until the rate limit window resets. <!-- docs/cloud/metrics/openmetrics/api-reference.mdx:102-106 -->

| Scope | Limit |
|---|---|
| Account | `180 requests per hour` | <!-- docs/cloud/metrics/openmetrics/api-reference.mdx:116 -->

Rate limit scopes are subject to change. <!-- docs/cloud/metrics/openmetrics/api-reference.mdx:110 -->

## API Limits
<!-- docs/cloud/metrics/openmetrics/api-reference.mdx:367-373 -->

| Limit | Impact | Mitigation |
|---|---|---|
| `30k total datapoints per scrape` | Response may be truncated | Use namespace/metric filtering |
| `180 requests per account per hour` (~3 requests per minute) | HTTP 429 returned | Set scrape interval to 30s |

## Data Latency
<!-- docs/cloud/metrics/openmetrics/api-reference.mdx:132 -->

Metric data points are available for query within 3 minutes of their origination. This latency should be accounted for when setting up monitoring alerts.

## Scrape Window
<!-- docs/cloud/metrics/openmetrics/api-reference.mdx:136 -->

The endpoint exposes only the most recently completed one-minute aggregation window. Each scrape returns a snapshot of that window. There is no query interface for historical data; configure your monitoring system to store what it scrapes.

## Scrape Best Practices
<!-- docs/cloud/metrics/openmetrics/api-reference.mdx:193-198 -->

- **Honor timestamps:** Set `honor_timestamps: true` in Prometheus. <!-- docs/cloud/metrics/openmetrics/api-reference.mdx:195 -->
- **Scrape interval:** Use `30s`. Intervals longer than 60s may skip datapoints because metrics update once per minute. <!-- docs/cloud/metrics/openmetrics/api-reference.mdx:196 -->
- **Timeout:** Set scrape timeout to `10 seconds` for large responses. <!-- docs/cloud/metrics/openmetrics/api-reference.mdx:197 -->
- **Filtering:** Use query parameters to reduce response size. <!-- docs/cloud/metrics/openmetrics/api-reference.mdx:198 -->

## Retry Logic
<!-- docs/cloud/metrics/openmetrics/api-reference.mdx:128 -->

Implement retry logic in your client to gracefully handle transient API failures. Use exponential backoff with jitter to avoid retry storms with reasonable retry intervals to avoid reaching rate limits.

## Managing High Cardinality
<!-- docs/cloud/metrics/openmetrics/api-reference.mdx:250-365 -->

High-cardinality labels like `temporal_task_queue` and `temporal_workflow_type` can significantly increase metric volume and impact performance of your monitoring system.

### Cardinality Estimation
<!-- docs/cloud/metrics/openmetrics/api-reference.mdx:259-278 -->

```
Total series = Base metrics x Namespaces x Task queues x Workflow types
```

Example: 6 workflow metrics x 10 namespaces x 50 task queues x 20 workflow types = 60,000 time series, which exceeds the 30,000 data points per scrape limit.

### Filtering at Scrape Time
<!-- docs/cloud/metrics/openmetrics/api-reference.mdx:282-295 -->

```shell
# Only specific namespaces matching a wildcard pattern
/v1/metrics?namespaces=production-*

# Only specific metrics
/v1/metrics?metrics=temporal_cloud_v1_workflow_success_count

# Combined filtering
/v1/metrics?namespaces=prod-*&metrics=temporal_cloud_v1_approximate_backlog_count
```

Prometheus equivalent using `params` config: <!-- docs/cloud/metrics/openmetrics/api-reference.mdx:301-312 -->

```yaml
scrape_configs:
- job_name: 'temporal-cloud'
  ...
  static_configs:
    - targets: ['metrics.temporal.io']
  metrics_path: '/v1/metrics'
  params:
    namespaces: ['prod-*']
    metrics: ['temporal_cloud_v1_approximate_backlog_count']
```

### Label Management with Prometheus
<!-- docs/cloud/metrics/openmetrics/api-reference.mdx:319-338 -->

Use `metric_relabel_configs` to drop or consolidate high-cardinality labels:

```yaml
metric_relabel_configs:
# Consolidate non-critical task queues
- source_labels: [temporal_task_queue]
  regex: '(critical-queue|payment-queue)'
  target_label: __tmp_keep_original
  replacement: 'true'

- source_labels: [__tmp_keep_original]
  regex: ''
  target_label: temporal_task_queue
  replacement: 'other'

- regex: '__tmp_keep_original'
  action: labeldrop
```

### Label Management with OpenTelemetry Collector
<!-- docs/cloud/metrics/openmetrics/api-reference.mdx:340-353 -->

Use a filter processor:

```yaml
processors:
  filter:
    metrics:
      include:
        match_type: regexp
        expressions:
          - Label("temporal_task_queue") == nil or IsMatch(Label("temporal_task_queue"), "^(critical-queue|payment-queue)$")
```

### Monitoring Cardinality
<!-- docs/cloud/metrics/openmetrics/api-reference.mdx:357-365 -->

PromQL queries to monitor cardinality:

```promql
# Count the total number of series
count({__name__=~"temporal_cloud_v1_.*"})

# Count the total number of series by metric
count({__name__=~"temporal_cloud_v1_.*"}) by (__name__)
```
