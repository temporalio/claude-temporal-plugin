---
name: temporal-observability
description: 'Collect, query, dashboard, and alert on Temporal metrics across Temporal Cloud and self-hosted deployments, and diagnose problems from them. Covers the Cloud OpenMetrics endpoint, self-hosted Temporal Service metrics, scraping and querying SDK metrics, third-party integrations (Datadog, Grafana, New Relic, Prometheus, OTel Collector, ClickStack), worker fleet health, and PromQL v0-to-v1 migration. Use when the user mentions: "Temporal metrics", "Temporal monitoring", "Temporal observability", "Temporal alerting", "Datadog Temporal", "Grafana Temporal", "Cloud metrics endpoint", "metrics.temporal.io", "SDK metrics", "OTel Collector", "worker backlog", "scrape Temporal metrics", "OpenMetrics", "PromQL migration". Not for SDK code or SDK changes other than new or renamed metrics (temporal-developer), serverless Worker OpenTelemetry (temporal-serverless), Worker tuning (temporal-workertuning), or Cloud admin (temporal-cloud/temporal-ops).'
---

# Skill: temporal-observability

## Overview

Work in one of three modes:

- **Setup** — generating scrape configs and integration configs. Always end setup with a validation step: prompt the user to confirm metrics are arriving and queryable in their platform.
- **Query** — writing PromQL/DQL queries for dashboards and alerts.
- **Diagnosis** — systematic, metrics-driven diagnosis using the USE methodology (Utilization, Saturation, Errors). Follow the Diagnosis Protocol below.

You produce configs, queries, and code snippets. You do not have access to live metric data, dashboards, or alerting systems. When the user describes symptoms, provide the diagnostic queries and explain what to look for in the results. This skill owns Temporal telemetry after it leaves a Worker or Client process. When the user needs to act on metric signals (scale workers, change tuning parameters, rotate credentials, administer namespaces), hand off to the appropriate sibling skill and provide the metric evidence gathered so far.

### Observability scope

This skill covers Temporal telemetry after it leaves a Worker or Client: the Temporal Cloud metrics endpoint, self-hosted Temporal Service metrics, scraping SDK metrics, what each SDK metric means, queries, dashboards, alerts, and metric-driven diagnosis.

This skill starts at the metrics endpoint a Worker already exposes; changing how a Worker exports telemetry is not one of its tasks. In the Temporal SDK repositories, this skill covers only changes that add, rename, or remove an SDK metric. In the documentation, it covers `docs/cloud/metrics/`, `docs/production-deployment/cloud/metrics/`, `docs/references/sdk-metrics.mdx`, and `docs/production-deployment/self-hosted-guide/monitoring.mdx`.

Not covered here:

- Any other SDK change, including exporters and their naming options such as suffixes or histogram aggregation, custom-metric APIs, tracing plugins such as `contrib/opentelemetry`, logging options, and Worker heartbeat contents or settings: use [temporal-developer](https://github.com/temporalio/skill-temporal-developer).
- The serverless Worker packages `temporalio.contrib.aws.lambda_worker`, `temporalio.contrib.gcp.cloud_run`, `go.temporal.io/sdk/contrib/aws/lambdaworker`, and `go.temporal.io/sdk/contrib/gcp/cloudrun`, including their OpenTelemetry helpers: use [temporal-serverless](https://github.com/temporalio/skill-temporal-serverless).

## How to Use This Skill

### Step 1: Determine the metric source

Before answering any metrics question, establish which of the three sources the user is asking about. This determines which reference files apply, which query functions are valid, and which auth/scrape patterns to use:

- **Cloud metrics** (`temporal_cloud_v1_*` only) — from `metrics.temporal.io`, API key auth. Never use `rate()`. Never recommend deprecated `temporal_cloud_v0_*` metrics.
- **SDK metrics** (`temporal_*` without `cloud`) — emitted by Workers/Clients, scraped from app endpoints. `rate()` is correct here.
- **Self-hosted cluster metrics** (`service_requests`, `persistence_latency`, etc.) — emitted by the Temporal Service itself. `rate()` is correct here.

If the source is ambiguous, ask before writing queries.

### Step 2: Determine the deployment context

Cloud, self-hosted, or dev server. This affects scrape configs, auth mechanisms, and which metrics are available.

### Step 3: Determine the observability platform

Prometheus, Datadog, Grafana Cloud, New Relic, ClickStack, or OTel Collector. This affects config format, query language, and available features.

### Step 4: For SDK metric queries, determine the SDK language

Histogram units differ: milliseconds for Core-based SDKs (TypeScript, Python, .NET) vs seconds for Go and Java. Getting this wrong produces thresholds that are off by 1000x.

### Multi-file routing for common questions

Most real questions require 2-3 reference files:

- **"Set up monitoring for my Temporal Cloud namespace"** → `openmetrics-endpoint.md` (auth + scrape) + `integrations.md` (platform config) + `service-health-monitoring.md` (what to alert on) + `worker-health-monitoring.md` (worker fleet).
- **"My workers seem slow / tasks are backing up / activities failing"** (diagnosis) → Follow the **Diagnosis Protocol** below. Consult `ops-diagnostics-reference.md` (USE framework, decision trees, metric mappings) + `worker-health-monitoring.md` (thresholds, queries) + `service-health-monitoring.md` (failure rates, limits) + `troubleshooting.md` (per-bottleneck root causes). For worked examples: `diagnosis-examples.md`. If they need to act on findings: hand off to `skill-temporal-workertuning`.
- **"Scrape/filter the endpoint, repeated query params, scrape role, Elastic/SigNoz/Parseable/Grafana tile"** → `openmetrics-endpoint.md` § Quick Answers + `integrations.md`.
- **"Migrate from v0 to v1"** → `migration-v0-to-v1.md` (mapping table + auth changes). Only relevant for users already on v0 — never suggest v0 to new users. v0 is deprecated and unavailable to new accounts.
- **"What metrics should I watch?"** → `service-health-monitoring.md` + `worker-health-monitoring.md` for the essential observation set.

## Diagnosis Protocol (USE Methodology)

When the user describes a symptom (slow workflows, growing backlog, activity failures, high latency), follow this systematic process. Never diagnose without metrics data.

### Step D1: Classify the Symptom

Map the user's description to a category:

| User says... | Category |
|---|---|
| "workflows slow to start", "backlog growing", "schedule-to-start high", "tasks queuing up" | **Throughput/Backlog** |
| "activities failing", "workflow failures spiking", "retries not working", "error rate high" | **Failure/Error** |
| "workflows taking too long end-to-end", "execution slow", "replay latency" | **Latency** |
| "resource exhausted errors", "throttling", "hitting limits", "provisioned capacity metrics" | **Resource Pressure** (read `references/capacity-throttling.md`) |
| "can't connect", "auth error", "certificate expired" | **Not this skill** — hand off to `skill-temporal-cloud` |
| "need to tune workers", "autoscaling", "slot sizing" | **Not this skill** — hand off to `skill-temporal-workertuning` |

If the symptom doesn't clearly map, ask what behavior they're seeing, when it started, and what changed.

### Step D2: Detect the Environment

Use context clues to determine:
- **Deployment**: Cloud, self-hosted, or dev server
- **SDK language**: Go, Java, TypeScript, Python, .NET (affects metric units)
- **Observability platform**: Prometheus, Datadog, Grafana Cloud, New Relic, etc.

See `references/ops-diagnostics-reference.md` § Environment Detection for clue table. If confidence is below 95%, ask.

### Step D3: Establish Metrics Access

You do not have access to live metrics. Establish how to get values:

1. **MCP tool** — if the user has a Datadog or Grafana MCP server connected, use it to query metrics directly.
2. **Screenshots** — ask the user to capture specific dashboard panels. Tell them which panels based on the symptom category:
   - Throughput/Backlog: schedule-to-start latency, backlog count, task slots available, sync match rate
   - Failure/Error: activity failure count (by type if possible), workflow failure count, activity execution latency
   - Include the time axis and legend in screenshots
3. **Manual values** — provide the exact query for their platform and ask them to run it and report values.

Always provide queries in the user's platform syntax. See `references/ops-diagnostics-reference.md` § Query Examples by Platform for Datadog and New Relic translations. For PromQL, see `references/worker-health-monitoring.md` and `references/service-health-monitoring.md`.

**Do not proceed with diagnosis without metrics data.**

### Step D4: Run USE Diagnostic

For each Temporal resource relevant to the symptom, check all three USE dimensions:

- **Utilization**: How busy is the resource? (slots used, poll success rate, action count vs limit)
- **Saturation**: Is work queuing up? (backlog count, schedule-to-start latency, cache evictions)
- **Errors**: Is work failing? (activity_fail_count, workflow_failed_count, resource_exhausted)

Consult `references/ops-diagnostics-reference.md`:
- § USE Resource Inventory — maps Temporal resources to their U/S/E metrics
- § Metric Name Mapping — which metric name to use for Cloud vs SDK
- § Decision Trees — follow the appropriate scenario tree based on symptom category

Cross-reference thresholds and detailed metric descriptions from:
- `references/worker-health-monitoring.md` — backlog, sync match, poll success, task slots, sticky cache
- `references/service-health-monitoring.md` — failure rates, error rates, limits, replication lag, detecting a failover or regional outage
- `references/troubleshooting.md` — per-bottleneck root causes and diagnostic steps; worker log signals (`[TMPRL1104]`, autoscaling poll-error warnings)

### Step D5: Explain Then Prescribe

Structure every diagnosis response using this format:

**What's Happening**: Plain-language explanation of the mechanics. Connect the user's metrics to the behavior they're seeing. Explain how Temporal's internals work in this situation so the user builds a mental model.

**USE Analysis**:

| Resource | Utilization | Saturation | Errors |
|---|---|---|---|
| (resource) | (metric: value + interpretation) | (metric: value) | (metric: value) |

**Why**: Root cause grounded in metric evidence. Explain the causal chain ("X is high because Y, caused by Z"). If multiple factors interact, show how.

**Fix**: Ordered list, most impactful first. For each action, explain **why it helps** in one sentence.
- Worker tuning → hand off to `skill-temporal-workertuning`
- Infrastructure changes → hand off to `skill-temporal-ops`
- Code changes → hand off to `skill-temporal-developer`

**Monitor After**: Which metrics to watch, target values, and expected timeline for improvement.

**If Not Resolved**: What persistence of the issue would indicate, and next diagnostic step or skill handoff.

For fully worked examples of this protocol in action, see `references/diagnosis-examples.md`.

### Diagnosis Common Pitfalls

| Pitfall | Correct Behavior |
|---|---|
| Applying `rate()` to `temporal_cloud_v1_*` metrics in queries | v1 metrics are pre-computed rates — use directly. `rate()` is only valid for SDK and self-hosted metrics. |
| Confusing SDK metric units across SDKs | Go/Java use seconds, TypeScript/Python/.NET use milliseconds. A 200ms threshold is `0.2` in Go/Java and `200` in Core SDKs. |
| Assuming `approximate_backlog_count = 0` means no backlog | This metric resets to zero on idle queues. Confirm with schedule-to-start latency. |
| Jumping to "add more workers" without checking slots | First check if existing workers have available slots. Slot depletion with low host CPU = configuration issue, not capacity. |
| Diagnosing without knowing the environment | Cloud vs self-hosted changes which metrics exist. Always establish environment first. |
| Ignoring the failure conversion rate | High activity failures with low workflow failures = healthy error handling. Always compute the ratio in failure scenarios. |
| Prescribing without explaining | Users who understand the mechanics make better decisions. Explain before recommending. |

## Key Facts

- OpenMetrics endpoint: `metrics.temporal.io`, API key auth, 30s recommended scrape interval, 30k datapoints per scrape, 180 requests/hour rate limit, ~3-minute data latency.
- PromQL/v0 endpoint is deprecated and unavailable to new users. Sunset date October 5, 2026. Never recommend v0 metrics — always use v1.
- v1 metrics are pre-computed per-second rates with delta temporality. Never apply `rate()`, `increase()`, `irate()`, or `histogram_quantile()`.
- SDK histogram units: milliseconds (TypeScript, Python, .NET) vs seconds (Go, Java).
- v1 pre-calculated percentiles (p50, p95, p99) cannot be accurately aggregated across dimensions.
- `temporal_cloud_v1_approximate_backlog_count` is approximate — can overcount and resets to zero on idle queues.
- Self-hosted Frontend Service health checks: port 7233, not 8080.
- `worker_version` label is deprecated — use `temporal_worker_deployment_name` and `temporal_worker_build_id`.

## Intent Decision Table

| User intent | Action |
|---|---|
| Wants to know which Cloud metrics exist, their types, or labels (including Nexus, Schedule, backlog age, billable actions) | Consult `references/cloud-metrics-catalog.md` for the complete `temporal_cloud_v1_*` catalog |
| Needs to set up or configure the OpenMetrics endpoint (auth, scrape config, rate limits) | Consult `references/openmetrics-endpoint.md` |
| Wants to integrate metrics with Datadog, Grafana Cloud, Elastic, SigNoz, Parseable, ClickStack, New Relic, Prometheus, or OTel Collector | Consult `references/integrations.md` |
| Needs to scrape SDK metrics endpoints with Prometheus or Grafana, or understand SDK metric units | Consult `references/sdk-metrics.md` |
| Setting up monitoring for a self-hosted Temporal Service, or server metrics/config changes (`tasks_dropped`, `tasks_expired`, `poller_scale_decision`, m3, `WithCustomMetricsHandler`) | Consult `references/self-hosted-monitoring.md` |
| Needs to interpret provisioned capacity, throttle metrics, or BusyWorkflow lock contention | Consult `references/capacity-throttling.md` |
| Wants to monitor Temporal Cloud service health (latency, error rates, failures, limits) | Consult `references/service-health-monitoring.md` |
| Needs to monitor Worker fleet health (backlog, greedy workers, misconfigured workers, sticky cache) | Consult `references/worker-health-monitoring.md` |
| Migrating from PromQL/v0 to OpenMetrics/v1 | Consult `references/migration-v0-to-v1.md` |
| Troubleshooting performance bottlenecks using metrics | Consult `references/troubleshooting.md` |
| Describing a symptom that needs systematic diagnosis (slow workflows, backlog, failures, latency) | Follow the **Diagnosis Protocol** above. Consult `references/ops-diagnostics-reference.md` for USE framework and decision trees |
| Wants a worked example of a diagnostic workflow | Consult `references/diagnosis-examples.md` |
| Wants to write Worker or Client code, including enabling SDK metrics export, tracing, or logging | Defer to `skill-temporal-developer` |
| Wants to emit or configure telemetry in Worker or Client code, or set up OpenTelemetry on serverless Workers | See [Observability scope](#observability-scope) |
| Wants to tune Worker performance (slot suppliers, tuners, cache sizing) | Defer to `skill-temporal-workertuning` -- this skill owns collection/query layer only |
| Wants to administer or diagnose Temporal Cloud/self-hosted environments | Defer to `skill-temporal-ops` -- this skill provides metric queries for diagnosis |
| Wants Cloud connectivity, auth, or namespace config (not metrics) | Defer to `skill-temporal-cloud` |

## Critical Rules

### Never Recommend v0 Metrics
- The `temporal_cloud_v0_*` metrics and the PromQL endpoint are deprecated and no longer available to new users. **Never recommend v0 metrics for any purpose.** Do not include v0 metric names in configs, queries, dashboards, or examples. Always use the `temporal_cloud_v1_*` equivalents.
- The only context where v0 metrics should be mentioned is when a user explicitly asks about migrating away from them. In that case, consult `references/migration-v0-to-v1.md` and guide them to the v1 replacements.
- If a user references a v0 metric name (e.g., `temporal_cloud_v0_frontend_service_request_count`), respond with the v1 equivalent and note that v0 is deprecated and being shut down.

### v0 and v1 Names Are Not Interchangeable
- v0 and v1 names differ beyond the version prefix (e.g., `temporal_cloud_v0_frontend_service_request_count` → `temporal_cloud_v1_service_request_count` — note the dropped `frontend_`). When helping users migrate, consult the mapping table in `references/migration-v0-to-v1.md`; do not attempt to guess v1 names by swapping the version prefix.

### Post-Setup Validation
- Setup is not complete until metrics are confirmed arriving and queryable **in the user's destination platform**. Verifying that the source endpoint returns data is not sufficient — the data must be flowing end-to-end into the platform where the user will actually query it. After providing any scrape or integration config, always end with a validation step.
- **Validate at the destination, not the source.** Tailor the check to where the data needs to land:
  - **Prometheus**: Query the Prometheus API to confirm data arrived — e.g., `curl -s "http://localhost:9090/api/v1/query?query=temporal_cloud_v1_service_request_count"` should return results with recent timestamps.
  - **Datadog, Grafana Cloud, New Relic, ClickStack**: These don't have local CLI query access — prompt the user to check the platform UI. Tell them exactly what to search for (e.g., "In Datadog Metrics Explorer, search for `temporal_cloud_v1` — do matching metrics appear with recent values?").
- For Cloud metrics, account for ~3-minute data latency — if the destination shows no data yet, wait a few minutes and check again.
- Do not assume setup succeeded just because the config looks correct. Verify at the destination or ask the user to verify.

### Authentication
- OpenMetrics endpoint: API key (Bearer token) with a service account having "Metrics Read-Only" Account Level Role.
- PromQL endpoint (deprecated): mTLS certificates with customer-specific endpoints (`<account-id>.tmprl.cloud/prometheus`).
- Never mix these authentication methods or endpoint URLs.

