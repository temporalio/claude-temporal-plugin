# Observability for AWS Lambda Serverless Workers

## Overview

Each SDK provides an OpenTelemetry integration package with defaults configured for the AWS Distro for OpenTelemetry (ADOT) Lambda layer. When enabled, the Worker emits SDK metrics and distributed traces for Workflow and Activity executions. The ADOT Lambda layer collects this telemetry and can forward traces to AWS X-Ray and metrics to Amazon CloudWatch. <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:129-131 -->

Load the selected SDK reference's **Observability** section:

| SDK | Observability reference |
|---|---|
| Go | `sdk-go.md` → Observability |
| Python | `sdk-python.md` → Observability |
| TypeScript | `sdk-typescript.md` → Observability |
| Java | `sdk-java.md` → Observability |
| .NET | `sdk-dotnet.md` → Observability |

The remaining steps in this file are shared across SDKs.

## Custom Collector configuration required

The default ADOT Collector configuration does not route OpenTelemetry Protocol (OTLP) data to the traces pipeline. You must provide a custom Collector configuration that wires the OTLP receiver to both the traces and metrics pipelines. <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:179-180 -->

Example `otel-collector-config.yaml` (bundle in your Lambda deployment package): <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:181 -->

For the Collector configuration environment variable, see the selected SDK reference.

```yaml
receivers:
    otlp:
        protocols:
            grpc:
                endpoint: "localhost:4317"
            http:
                endpoint: "localhost:4318"

exporters:
    debug:
    awsxray:
        region: us-west-2
    awsemf:
        namespace: TemporalWorkerMetrics
        log_group_name: /aws/lambda/<your-function-name>
        region: us-west-2
        dimension_rollup_option: NoDimensionRollup
        resource_to_telemetry_conversion:
            enabled: true

service:
    pipelines:
        traces:
            receivers: [otlp]
            exporters: [awsxray, debug]
        metrics:
            receivers: [otlp]
            exporters: [awsemf]
    telemetry:
        logs:
            level: debug
        metrics:
            address: localhost:8888
```
<!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:185-221 -->

## Enable X-Ray active tracing

```bash
aws lambda update-function-configuration \
  --function-name <your-function-name> \
  --tracing-config Mode=Active
```
<!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:230-234 -->

## Required IAM permissions

The Lambda execution role must have permissions to write to X-Ray and CloudWatch: <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:236 -->

- `xray:PutTraceSegments` <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:237 -->
- `xray:PutTelemetryRecords` <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:237 -->
- `cloudwatch:PutMetricData` <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:237 -->

Without these permissions, the Collector fails silently and no telemetry appears. <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:238 -->

For language-specific IAM notes, see the selected SDK reference.
