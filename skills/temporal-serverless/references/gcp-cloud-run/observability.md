# GCP Cloud Run — observability

## OpenTelemetry on Cloud Run

**A Cloud Run Serverless Worker is an ordinary long-lived Worker, so OpenTelemetry remains optional.** Standard SDK logging and telemetry configuration still works. Do not add a Collector sidecar when the user has not asked for telemetry export.

When OpenTelemetry is required, prefer the SDK's Cloud Run OpenTelemetry helper where one is available. The Go, Python, Java, and .NET helpers configure Temporal SDK/Core metrics and traces for OTLP/gRPC export to a local Collector and provide a bounded shutdown flush. TypeScript currently uses the SDK's standard OpenTelemetry integration instead. See the selected `sdk-<language>.md` reference for the exact package and setup.

The recommended Cloud Run topology is:

1. The Worker exports OTLP over gRPC to `http://localhost:4317`.
2. A [Google-Built OpenTelemetry Collector](https://cloud.google.com/stackdriver/docs/instrumentation/opentelemetry-collector-cloud-run) runs as a sidecar in the same Worker Pool instance.
3. The Collector exports metrics to Google Managed Service for Prometheus and traces to the Google Cloud Telemetry API, using the runner service account's Application Default Credentials.

Deploy this topology with a multi-container Worker Pool YAML and `gcloud run worker-pools replace`; the single-container `deploy` command in `setup.md` is the basic path. The manifest must:

- make the Worker depend on the Collector with `run.googleapis.com/container-dependencies`;
- give the Collector a startup probe and pin its image to a tested version rather than `latest`;
- mount the Collector configuration from Secret Manager;
- set `OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317` when the SDK helper does not already default to it; and
- budget CPU and memory for both containers.

Start the Collector before the Worker. On `SIGTERM`, stop the Worker and close the Temporal client before flushing the SDK helper. Cloud Run can send `SIGKILL` about ten seconds after `SIGTERM`, and the flush runs after the Worker drains, so **the drain timeout, client close, and flush timeout must fit inside that window together**. With an eight-second drain, keep the flush to one second or less, or shorten the drain when telemetry matters more than in-flight work, for example a six-second drain and a two-second flush.

Use the Collector configuration from the Temporal Cloud Run sample as the baseline instead of inventing a provider-specific exporter pipeline. Keep batching on the traces pipeline only: batching Temporal's cumulative metrics can merge a shutdown flush with a recent periodic export and produce a duplicate Monitoring write. Take the Collector configuration from the [samples-go Cloud Run sample](https://github.com/temporalio/samples-go/tree/main/gcp/cloudrun) (`otel-collector-config.yaml`). Do not copy that sample's Worker Pool manifest: it runs an unversioned Worker with a minimum of one instance and a mutable image tag, so take the image digest, scaling, and environment from `setup.md` and add the Collector container to that. Do not put the Collector's full YAML in this skill; it changes independently and is easier to verify in the sample.

The runner needs additional roles and APIs only when this optional Collector path is enabled. → `iam.md`.

## Logs

Cloud Run collects `stdout` and `stderr` into [Cloud Logging](https://cloud.google.com/run/docs/logging) through its own infrastructure. **The runner service account needs no grant for this** — `roles/logging.logWriter` is required only if the Worker writes through the Cloud Logging API instead. → `iam.md`.

Read a pool's logs, including its resize audit entries, with the [pool log query](diagnostics.md#read-the-pool-logs). **A scaled-to-zero pool emits no new logs.**

## What to watch that is specific to this provider

Standard Worker metrics tell you about the Worker. Two Cloud Run-specific signals tell you about the *scaling*, and neither comes from the SDK:

- **`run.googleapis.com/manualInstanceCount`** on the pool — what the WCI has asked for. A value that remains `0` while a backlog exists indicates a scaling failure.
- **`serving.knative.dev/lastModifier`** on the pool — who most recently updated it. The invoker service account means the WCI made the latest update; another identity does not prove that the WCI has never updated the pool.

Both are read with `gcloud run worker-pools describe … --format=yaml`. → `diagnostics.md`.
