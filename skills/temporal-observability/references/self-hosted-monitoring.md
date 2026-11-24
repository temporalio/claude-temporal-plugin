# Self-Hosted Temporal Service Monitoring

<!-- Sources: docs/production-deployment/self-hosted-guide/monitoring.mdx, docs/references/cluster-metrics.mdx -->

This reference covers monitoring a self-hosted Temporal Service with Prometheus and Grafana: scrape configuration, metrics port setup, SDK metrics endpoints, Docker setup, Grafana data source and dashboard configuration, health checks, Helm chart metrics, Datadog integration, and key cluster metrics.

## Prometheus Configuration
<!-- docs/production-deployment/self-hosted-guide/monitoring.mdx:28-58 -->

Create a `prometheus.yml` configuration file with target ports for collecting Temporal Service and SDK metrics. The following example scrapes the Temporal Service on port 8000 and SDK metrics on two application targets:

```yaml
global:
  scrape_interval: 10s
scrape_configs:
  - job_name: 'temporalmetrics'
    metrics_path: /metrics
    scheme: http
    static_configs:
      # Temporal Service metrics target
      - targets:
          - 'host.docker.internal:8000'
        labels:
          group: 'server-metrics'

      # Local app targets (set in SDK code)
      - targets:
          - 'host.docker.internal:8077'
          - 'host.docker.internal:8078'
        labels:
          group: 'sdk-metrics'
```

The SDK metrics ports (`8077`, `8078`) must be configured in application code via the preferred SDK. <!-- docs/production-deployment/self-hosted-guide/monitoring.mdx:61 -->

## Server Metrics and Configuration

Check the deployed Server version before applying version-specific metric or configuration guidance.

- `tasks_dropped` counts backlog tasks dropped by matching, per Task Queue, with a `reason` tag: `not_found`, `internal_error`, `data_loss`, `expired_read`, `expired_memory`, `invalid`. Use it in place of `tasks_expired`, which is unavailable from Server v1.32.0.
- `poller_scale_decision` counter is opt-in: set dynamic config `matching.enablePollerScalingDecisionMetrics` to `true` (default `false`; scopable by Namespace and Task Queue). Tags: `decision` (`scale_up`, `scale_down`, `hold`) and `reason` (`idle`, `backlog`, `task_rate`, `rate_limited`).
- The server `metrics` config supports only `statsd` and `prometheus`; there is no `m3` provider.
- When embedding the server, pass a custom handler with `WithCustomMetricsHandler(metrics.Handler)`.

## Temporal Dev Server Metrics Port
<!-- docs/production-deployment/self-hosted-guide/monitoring.mdx:76-79 -->

Launch the Temporal dev server with metrics enabled using the `--metrics-port` flag: <!-- docs/production-deployment/self-hosted-guide/monitoring.mdx:76-79 -->

```bash
temporal server start-dev --metrics-port 8000
```

For production Temporal Service deployments, refer to the Temporal Cluster configuration reference (`/references/configuration#global`) to expose metrics. <!-- docs/production-deployment/self-hosted-guide/monitoring.mdx:84 -->

## Running Prometheus with Docker
<!-- docs/production-deployment/self-hosted-guide/monitoring.mdx:70-73 -->

```bash
docker run -p 9090:9090 -v /path/to/prometheus.yml /etc/prometheus/prometheus.yml prom/prometheus
```

## SDK Metrics Setup for Self-Hosted

Workers and Clients emit SDK metrics only after application code enables an exporter. To enable one, use the [temporal-developer skill](https://github.com/temporalio/skill-temporal-developer).

Add each Worker's metrics endpoint to the Prometheus scrape config above.

### Verifying Prometheus Configuration
<!-- docs/production-deployment/self-hosted-guide/monitoring.mdx:116-118 -->

Visit `http://localhost:9090/targets` to verify that Prometheus is scraping the configured endpoints.

## Grafana Setup
<!-- docs/production-deployment/self-hosted-guide/monitoring.mdx:128-182 -->

### Running Grafana with Docker
<!-- docs/production-deployment/self-hosted-guide/monitoring.mdx:132-136 -->

```bash
docker run -d -p 3000:3000 grafana/grafana-enterprise
```

Default credentials: `admin`/`admin`. <!-- docs/production-deployment/self-hosted-guide/monitoring.mdx:138 -->

### Configuring Prometheus Data Source
<!-- docs/production-deployment/self-hosted-guide/monitoring.mdx:147-154 -->

From the Grafana sidebar, click "Add new data source" under the "Connections" menu and add Prometheus. If using Docker, set the Prometheus address to `http://host.docker.internal:9090`. <!-- docs/production-deployment/self-hosted-guide/monitoring.mdx:151-152 -->

### Dashboard Setup
<!-- docs/production-deployment/self-hosted-guide/monitoring.mdx:162-165 -->

Community-driven Grafana dashboards for monitoring Temporal Server and SDK metrics are available in the [dashboards repository](https://github.com/temporalio/dashboards/). Follow the instructions in that repo's README to import dashboards to Grafana.

## Health Checks
<!-- docs/production-deployment/self-hosted-guide/monitoring.mdx:185-211 -->

The Frontend Service supports TCP or gRPC health checks on port `7233`. <!-- docs/production-deployment/self-hosted-guide/monitoring.mdx:187 -->

### TCP Health Check (Nomad example)
<!-- docs/production-deployment/self-hosted-guide/monitoring.mdx:189-199 -->

```
service {
  check {
    type     = "tcp"
    port     = 7233
    interval = "10s"
    timeout  = "2s"
  }
```

### gRPC Health Check (Nomad example, requires Consul >= 1.0.5)
<!-- docs/production-deployment/self-hosted-guide/monitoring.mdx:201-211 -->

```
service {
  check {
    type         = "grpc"
    port         = 7233
    interval     = "10s"
    timeout      = "2s"
  }
```

## Helm Chart Metrics
<!-- docs/production-deployment/self-hosted-guide/monitoring.mdx:213-215 -->

When installing Temporal via the [Helm chart](https://github.com/temporalio/helm-charts), additional parameters can be provided to populate and explore a Grafana dashboard out of the box. See the [Helm chart documentation](https://github.com/temporalio/helm-charts?tab=readme-ov-file#exploring-metrics-via-grafana) for details.

## Datadog Integration
<!-- docs/production-deployment/self-hosted-guide/monitoring.mdx:217-222 -->

Datadog has a Temporal integration for collecting Temporal Service metrics. Once Prometheus is configured, configure the [Datadog Agent](https://docs.datadoghq.com/integrations/temporal/). For Temporal Cloud, Datadog can also integrate directly without Prometheus: https://docs.datadoghq.com/integrations/temporal-cloud/ <!-- docs/production-deployment/self-hosted-guide/monitoring.mdx:222 -->

---

## Key Self-Hosted Cluster Metrics
<!-- docs/references/cluster-metrics.mdx -->

All OSS Temporal Service metrics are listed in [`metric_defs.go`](https://github.com/temporalio/temporal/blob/main/common/metrics/metric_defs.go). <!-- docs/references/cluster-metrics.mdx:27 -->

Community-driven Grafana dashboard templates are available in the [dashboards repository](https://github.com/temporalio/dashboards). <!-- docs/references/cluster-metrics.mdx:30 -->

Common tags available on cluster metrics: `type`, `operation`, `namespace`, `service_name`. <!-- docs/references/cluster-metrics.mdx:39-44 -->

### Common Metrics

#### `service_requests`
<!-- docs/references/cluster-metrics.mdx:54-58 -->

Shows service requests received per Task Queue. Tags: `operation`, `service_name`, `namespace`.

Example: Service requests by operation on the Frontend Service:
```promql
sum by (operation) (rate(service_requests{service_name="frontend"}[2m]))
```

#### `service_latency`
<!-- docs/references/cluster-metrics.mdx:60-65 -->

Shows latencies for all Client request operations. Starting point for investigating high-latency issues.

Example: P95 service latency by operation for the Frontend Service:
```promql
histogram_quantile(0.95, sum(rate(service_latency_bucket{service_name="frontend"}[5m])) by (operation, le))
```

#### `service_error_with_type`
<!-- docs/references/cluster-metrics.mdx:67-71 -->

Identifies errors encountered by the service (available only in v1.17.0+). Contains `error_type` tag.

Example: Service errors by type for the Frontend Service:
```promql
sum(rate(service_error_with_type{service_name="frontend"}[5m])) by (error_type)
```

#### `client_errors`
<!-- docs/references/cluster-metrics.mdx:73-77 -->

An indicator for connection issues between different Server roles.

Example: Client errors between frontend and history:
```promql
sum(rate(client_errors{service_name="frontend",service_role="history"}[5m]))
```

### Matching Service Metrics

#### `poll_success`
<!-- docs/references/cluster-metrics.mdx:84-87 -->

Tasks successfully matched to a poller.

#### `poll_timeouts`
<!-- docs/references/cluster-metrics.mdx:89-92 -->

When no Tasks are available for the poller within the poll timeout.

#### `asyncmatch_latency`
<!-- docs/references/cluster-metrics.mdx:94-98 -->

Time from creation to delivery for async matched Tasks. Larger latency means Tasks are sitting in the queue waiting for Workers. This is a histogram metric.

#### `no_poller_tasks`
<!-- docs/references/cluster-metrics.mdx:100-103 -->

Emitted whenever a task is added to a task queue that has no poller. Usually indicates Workers or starters are using the wrong Task Queue. This is a counter metric.

### History Service Metrics

#### `task_requests`
<!-- docs/references/cluster-metrics.mdx:111-114 -->

Emitted on every Task process request.

#### `task_errors`
<!-- docs/references/cluster-metrics.mdx:116-119 -->

Emitted on every Task process error.

#### `task_attempt`
<!-- docs/references/cluster-metrics.mdx:121-125 -->

Number of attempts on each Task Execution. A Task is retried forever, and each retry increases the attempt count. This is a histogram metric.

#### `task_latency_processing`
<!-- docs/references/cluster-metrics.mdx:127-130 -->

Processing latency per attempt. This is a histogram metric.

#### `task_latency`
<!-- docs/references/cluster-metrics.mdx:132-134 -->

In-memory latency across multiple attempts.

#### `task_latency_queue`
<!-- docs/references/cluster-metrics.mdx:136-138 -->

Duration end-to-end from when the Task should be executed (from the time it was fired) to when the Task is done.

#### `task_latency_load`
<!-- docs/references/cluster-metrics.mdx:140-142 -->

Duration from Task generation to Task loading (Task schedule to start latency for persistence queue). Available only in v1.18.0+.

#### `task_latency_schedule`
<!-- docs/references/cluster-metrics.mdx:144-146 -->

Duration from Task submission to processing (Task schedule to start latency for in-memory queue). Available only in v1.18.0+.

### Persistence Metrics

#### `persistence_requests`
<!-- docs/references/cluster-metrics.mdx:167-175 -->

Emitted on every persistence request.

Example: Total persistence requests by operation for History Service:
```promql
sum by (operation) (rate(persistence_requests{service_name="history"}[1m]))
```

#### `persistence_errors`
<!-- docs/references/cluster-metrics.mdx:177-184 -->

All persistence errors. Good indicator for connection issues between the Temporal Service and the persistence store.

#### `persistence_error_with_type`
<!-- docs/references/cluster-metrics.mdx:186-191 -->

All errors related to the persistence store with type. Contains `error_type` tag.

#### `persistence_latency`
<!-- docs/references/cluster-metrics.mdx:193-199 -->

Latency on persistence operations. This is a histogram metric.

Example: Latency by percentile for History Service:
```promql
histogram_quantile(0.95, sum(rate(persistence_latency_bucket{service_name="history"}[1m])) by (operation, le))
```

### Schedule Metrics

#### `schedule_action_success`
<!-- docs/references/cluster-metrics.mdx:234-241 -->

Successful execution of Workflows as per their schedules or through manual triggers.

#### `schedule_buffer_overruns`
<!-- docs/references/cluster-metrics.mdx:207-215 -->

Buffer for holding Scheduled Workflows exceeds maximum capacity. Occurs when schedules with `buffer_all` overlap policy have average run length exceeding average schedule interval.

#### `schedule_missed_catchup_window`
<!-- docs/references/cluster-metrics.mdx:217-223 -->

System failed to execute a Scheduled Action within the defined catchup window.

#### `schedule_rate_limited`
<!-- docs/references/cluster-metrics.mdx:225-232 -->

Creation of Workflows by a Schedule is throttled due to rate limiting policies within a Namespace.

### Workflow Metrics

#### `workflow_cancel`
<!-- docs/references/cluster-metrics.mdx:248-249 -->
Number of Workflows canceled before completing execution.

#### `workflow_continued_as_new`
<!-- docs/references/cluster-metrics.mdx:251-253 -->
Number of Workflow Executions that were Continued-As-New from a past execution.

#### `workflow_failed`
<!-- docs/references/cluster-metrics.mdx:255-257 -->
Number of Workflows that failed before completion.

#### `workflow_success`
<!-- docs/references/cluster-metrics.mdx:259-261 -->
Number of Workflows that successfully completed.

#### `workflow_timeout`
<!-- docs/references/cluster-metrics.mdx:263-265 -->
Number of Workflows that timed out before completing execution.
