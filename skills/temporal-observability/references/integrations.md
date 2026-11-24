# Third-Party Metrics Integrations

<!-- Source: docs/cloud/metrics/openmetrics/metrics-integrations.mdx -->

This reference covers third-party integrations for exporting metrics from the Temporal Cloud OpenMetrics endpoint. For advanced configuration such as label management and high-cardinality scenarios, see `openmetrics-endpoint.md`.

Prerequisite for every integration: a Service Account with the **Metrics Read-Only** role and an API key, created by an Account Owner or Global Admin (a Namespace Admin cannot grant it).

Platform index: Datadog, Grafana Cloud, Elastic, New Relic, ClickStack, SigNoz, Parseable, Prometheus, OTel Collector.
Spend/Action cost views: Datadog Cost Management (below) and the Grafana Action Costs dashboard and alerts (`service-health-monitoring.md` § Grafana Action Cost Dashboard and Alert Rules).

## Serverless Integrations

These integrations are fully managed by the third-party vendor. They handle scraping, storage, and provide default dashboards.

### Datadog
<!-- docs/cloud/metrics/openmetrics/metrics-integrations.mdx:33-35 -->

Datadog provides a serverless integration with the OpenMetrics endpoint. This integration scrapes metrics, stores them in Datadog, and provides a default dashboard with some built-in monitors. See the [Datadog integration page](https://docs.datadoghq.com/integrations/temporal-cloud-openmetrics/) for setup details.

Datadog Cost Management is a separate integration from the one above: it sends Temporal Cloud billing data to Datadog Cloud Cost Management for spend attribution by namespace and service type. See the [Cost Management page](https://docs.datadoghq.com/integrations/temporal-cloud-costs/).

### Grafana Cloud
<!-- docs/cloud/metrics/openmetrics/metrics-integrations.mdx:38-41 -->

Grafana provides a serverless integration with the OpenMetrics endpoint for Grafana Cloud. This integration scrapes metrics, stores them in Grafana Cloud, and provides a default dashboard for visualizing the metrics. See the [Grafana Cloud integration page](https://grafana.com/docs/grafana-cloud/monitor-infrastructure/integrations/integration-reference/integration-temporal/) for setup details.

Grafana Cloud setup: Connections -> **Temporal Cloud** tile -> Configuration -> add a scrape job (name, API key, scrape interval; default 1 minute). Use one scrape job per account.

### Elastic

The Elastic Temporal integration scrapes the OpenMetrics endpoint and installs dashboards, alert templates and SLO templates in Kibana. In Kibana go to Management -> Integrations, search for Temporal (OpenTelemetry), add it (default endpoint `metrics.temporal.io:443` and path `/v1/metrics` are pre-set), enter the API key, and verify in Discover with `data_stream.dataset: "temporal.cloud_metrics.otel"`.

### ClickStack
<!-- docs/cloud/metrics/openmetrics/metrics-integrations.mdx:44-46 -->

ClickHouse provides an integration with the OpenMetrics endpoint for ClickStack. This integration uses an OpenTelemetry collector to read from the OpenMetrics endpoint, ingests data into ClickHouse, and includes a default dashboard to visualize the data with HyperDX. See the [ClickStack integration page](https://clickhouse.com/docs/use-cases/observability/clickstack/integrations/temporal-metrics) for setup details.

### New Relic
<!-- docs/cloud/metrics/openmetrics/metrics-integrations.mdx:49-50 -->

New Relic integrates with Temporal Cloud via the infrastructure agent using a flex integration that pulls data from the OpenMetrics endpoint. See the [New Relic integration page](https://docs.newrelic.com/docs/infrastructure/host-integrations/host-integrations-list/temporal-cloud-integration/) for setup details.

### SigNoz

Run an OpenTelemetry Collector with a Prometheus receiver against `metrics.temporal.io` (Bearer API key) and an OTLP exporter to SigNoz (ingestion key and region). Use the template and dashboard JSON from the [SigNoz integration page](https://signoz.io/docs/integrations/temporal-cloud-metrics/), then confirm `temporal_cloud_v1_*` metrics appear in Metrics Explorer.

### Parseable

Parseable uses an OpenTelemetry Collector to scrape the endpoint and export over OTLP/HTTP. See the [Parseable guide](https://www.parseable.com/docs/ingest-data/ai-agents/temporal?tab=temporal-cloud-metrics).

## Self-Hosted Integrations

### Prometheus + Grafana
<!-- docs/cloud/metrics/openmetrics/metrics-integrations.mdx:52-73 -->

Self-hosted Prometheus can scrape the OpenMetrics endpoint directly.

**Step 1:** Add a scrape job for the OpenMetrics endpoint with your API key: <!-- docs/cloud/metrics/openmetrics/metrics-integrations.mdx:56-71 -->

```yaml
scrape_configs:
  - job_name: 'temporal-cloud'
    scrape_interval: 30s
    scrape_timeout: 30s
    honor_timestamps: true
    scheme: https
    authorization:
      type: Bearer
      credentials: '<API_KEY>'
    static_configs:
      - targets: ['metrics.temporal.io']
    metrics_path: '/v1/metrics'
```

**Step 2:** Import the [Grafana dashboard](https://github.com/grafana/jsonnet-libs/blob/master/temporal-mixin/dashboards/temporal-overview.json) and configure your Prometheus data source. <!-- docs/cloud/metrics/openmetrics/metrics-integrations.mdx:73 -->

### OpenTelemetry Collector
<!-- docs/cloud/metrics/openmetrics/metrics-integrations.mdx:75-111 -->

Collect metrics with a self-hosted OpenTelemetry Collector to ingest into the system of your choosing.

Add a prometheus receiver for the OpenMetrics endpoint with your API key: <!-- docs/cloud/metrics/openmetrics/metrics-integrations.mdx:79 -->

```yaml
receivers:
  prometheus:
    config:
      scrape_configs:
      - job_name: 'temporal-cloud'
        scrape_interval: 30s
        scrape_timeout: 30s
        honor_timestamps: true
        scheme: https
        authorization:
          type: Bearer
          credentials_file: <API_KEY_FILE>
        static_configs:
          - targets: ['metrics.temporal.io']
        metrics_path: '/v1/metrics'

processors:
  batch:

exporters:
  otlphttp:
    endpoint: <ENDPOINT>

service:
  pipelines:
    metrics:
      receivers: [prometheus]
      processors: [batch]
      exporters: [otlphttp]
```

Note: The OTel Collector config uses `credentials_file` to reference an API key file, whereas the direct Prometheus config uses `credentials` for the inline key value. <!-- docs/cloud/metrics/openmetrics/metrics-integrations.mdx:67,93 -->

## Additional Examples
<!-- docs/cloud/metrics/openmetrics/metrics-integrations.mdx:115 -->

Community-contributed examples for these integrations and more are available at: https://github.com/temporal-community/cloud-metrics-scrape-examples
