# Python SDK on AWS Lambda

<!-- Source: docs/develop/python/workers/serverless-workers/aws-lambda.mdx -->

Use this reference for Python SDK-specific package, entry-point, Worker configuration, tuned defaults, observability, and diagnostic details. For shared AWS Lambda deployment, observability infrastructure, and diagnostic flow, see `setup.md`, `observability.md`, and `diagnostics.md`.

## Package

Import: `from temporalio.contrib.aws.lambda_worker import LambdaWorkerConfig, run_worker` <!-- docs/develop/python/workers/serverless-workers/aws-lambda.mdx:47 -->

Install: `pip install temporalio` — the contrib module ships inside the main package here (unlike Go and TypeScript, which need a separate dependency). Use `temporalio[lambda-worker-otel]` for OpenTelemetry support.

- Python: [Python Lambda Worker sample](https://github.com/temporalio/samples-python/tree/main/lambda_worker) <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:55 -->

Read the installed API before generating code:

```bash
python -c "import temporalio.contrib.aws.lambda_worker as m; help(m.LambdaWorkerConfig)"
```

**Ordering when sources disagree:** the installed artifact first, the SDK's maintained samples second (they are built in CI, so they cannot reference a method that does not exist), the prose docs last. Entry-point names are not consistent across SDKs, so check rather than pattern-match from another language.

**Fastest path:** start from the language sample linked above — it has a working Worker, Workflow, and Activity already wired together. The handler example below imports the Workflow and Activity from separate modules (`my_workflows`, `my_activities`). When writing from scratch, create those modules with at least one registered Workflow (declaring a versioning behavior) and one Activity, and name the entry-point file to match the `--handler` you deploy (for example, `lambda_function.py` → `--handler lambda_function.lambda_handler`).

## Entry point

`run_worker` — takes a `WorkerDeploymentVersion` and a configure callback, returns a Lambda handler. <!-- docs/develop/python/workers/serverless-workers/aws-lambda.mdx:39-40,66 -->

## Configure callback

The `configure` callback receives a `LambdaWorkerConfig` dataclass with fields pre-populated with Lambda-appropriate defaults. Set the Task Queue, Workflows, and Activities through `worker_config`, which accepts the same keyword arguments as the `Worker` constructor. <!-- docs/develop/python/workers/serverless-workers/aws-lambda.mdx:71-72 -->

Go, Python and TypeScript invoke it per invocation.

Python and TypeScript pass Workflow and Activity collections into the worker config.

## Versioning behavior

Set per-Workflow in the `@workflow.defn` decorator: `VersioningBehavior.PINNED` or `VersioningBehavior.AUTO_UPGRADE`. <!-- docs/develop/python/workers/serverless-workers/aws-lambda.mdx:74-75 -->
Or set a Worker-level default with `default_versioning_behavior` in the worker config. <!-- docs/develop/python/workers/serverless-workers/aws-lambda.mdx:75 -->

**Worker Versioning is always on.** The run-worker entry point enables it, so the only remaining decision is `Pinned` vs `AutoUpgrade` per Workflow (or a Worker-level default).

## Handler example

Use the Python SDK's `lambda_worker` contrib package. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:106 -->

```python
from temporalio.common import WorkerDeploymentVersion
from temporalio.contrib.aws.lambda_worker import LambdaWorkerConfig, run_worker

from my_workflows import MyWorkflow
from my_activities import my_activity


def configure(config: LambdaWorkerConfig) -> None:
    config.worker_config["task_queue"] = "my-task-queue"
    config.worker_config["workflows"] = [MyWorkflow]
    config.worker_config["activities"] = [my_activity]


lambda_handler = run_worker(
    WorkerDeploymentVersion(
        deployment_name="my-app",
        build_id="build-1",
    ),
    configure,
)
```
<!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:108-129 -->

Versioning behavior: set per-Workflow in the `@workflow.defn` decorator with `VersioningBehavior.PINNED` or `VersioningBehavior.AUTO_UPGRADE`, or set a Worker-level default with `default_versioning_behavior` in the worker config. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:131-133 -->

```python
from temporalio import workflow
from temporalio.common import VersioningBehavior


@workflow.defn(versioning_behavior=VersioningBehavior.PINNED)
class MyWorkflow:
    @workflow.run
    async def run(self, input: str) -> str:
        ...
```
<!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:135-145 -->

## Lambda-tuned defaults

<!-- docs/develop/python/workers/serverless-workers/aws-lambda.mdx:108-120 -->

| Setting | Lambda default |
|---|---|
| `max_concurrent_activities` | 2 |
| `max_concurrent_workflow_tasks` | 10 |
| `max_concurrent_local_activities` | 2 |
| `max_concurrent_nexus_tasks` | 5 |
| `workflow_task_poller_behavior` | `SimpleMaximum(2)` |
| `activity_task_poller_behavior` | `SimpleMaximum(1)` |
| `nexus_task_poller_behavior` | `SimpleMaximum(1)` |
| `graceful_shutdown_timeout` | 5 seconds |
| `max_cached_workflows` | 30 |
| `disable_eager_activity_execution` | Always `True` |
| `shutdown_deadline_buffer` | 7 seconds |

`disable_eager_activity_execution` is always `True` and cannot be overridden. Eager Activities require a persistent connection, which Lambda invocations don't maintain. <!-- docs/develop/python/workers/serverless-workers/aws-lambda.mdx:122-123 -->

`shutdown_deadline_buffer` is specific to the `lambda_worker` package. It controls how much time before the Lambda deadline the Worker begins its graceful shutdown. The default is `graceful_shutdown_timeout` + 2 seconds. <!-- docs/develop/python/workers/serverless-workers/aws-lambda.mdx:125-127 -->

If your Worker handles long-running Activities, increase `graceful_shutdown_timeout`, `shutdown_deadline_buffer`, and the Lambda invocation deadline (`--timeout`) together. <!-- docs/develop/python/workers/serverless-workers/aws-lambda.mdx:129-130 -->

## Connection configuration

The `lambda_worker` package automatically loads Temporal client configuration from a TOML config file and environment variables (see the Environment Configuration docs, `/develop/environment-configuration`). <!-- docs/develop/python/workers/serverless-workers/aws-lambda.mdx:91 -->

TOML config file resolution order: <!-- docs/develop/python/workers/serverless-workers/aws-lambda.mdx:93-97 -->

1. `TEMPORAL_CONFIG_FILE` environment variable, if set.
2. `temporal.toml` in `$LAMBDA_TASK_ROOT` (typically `/var/task`).
3. `temporal.toml` in the current working directory.

The file is optional. If absent, only environment variables are used. <!-- docs/develop/python/workers/serverless-workers/aws-lambda.mdx:99 -->

## Build and package

Install dependencies into a local directory for packaging, using `--platform` for Linux-compatible binaries: <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:206-207 -->

```bash
pip install --target ./package --platform manylinux2014_x86_64 --only-binary=:all: temporalio
```
<!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:210 -->

**Pin the download to the Lambda runtime's Python version and architecture, not your local interpreter's.** If they differ (e.g. local `3.14` vs the function's `python3.13`), add `--python-version 3.13` alongside `--only-binary=:all:` so pip fetches runtime-matching wheels, and keep `--platform` (`manylinux2014_x86_64` for `x86_64`, `manylinux2014_aarch64` for `arm64`) consistent with the function's `--architectures`. Mismatches surface as import errors only at invocation time, not at package time.

To include OpenTelemetry support, install `temporalio[lambda-worker-otel]` instead. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:213-214 -->

Package dependencies and application code: <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:216 -->

```bash
cd package && zip -r ../function.zip . && cd ..
zip function.zip lambda_function.py my_workflows.py my_activities.py
```
<!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:218-220 -->

## Deploy the Lambda function

```bash
aws lambda create-function \
  --function-name my-temporal-worker \
  --runtime python3.13 \
  --handler lambda_function.lambda_handler \
  --role <EXECUTION_ROLE_ARN> \
  --zip-file fileb://function.zip \
  --timeout 600 \
  --memory-size 256 \
  --environment '{"Variables":{"TEMPORAL_ADDRESS":"<your-temporal-address>:7233","TEMPORAL_NAMESPACE":"<your-namespace>","TEMPORAL_API_KEY":"<your-api-key>"}}'
```
<!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:271-281 -->

- `--runtime`: `python3.13` (or another supported Python version). <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:286 -->
- `--handler`: `lambda_function.lambda_handler` (entry point in `module.function` format, must point to the handler returned by `run_worker`). <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:287 -->

| SDK example | Memory | Full invocation | GB-seconds |
|---|---|---|---|
| Python 600s / 256 MB | 0.25 GB | ~594 s billed | ~149 |

Measured cold starts are ~1s for Python and Java alike (`Init Duration` in the REPORT line).

The `--environment` examples above pass `TEMPORAL_API_KEY` inline for brevity — **that is acceptable for development only.** For production, store the API key (or TLS private key) in AWS Secrets Manager or SSM Parameter Store, grant the *execution* role `secretsmanager:GetSecretValue` (or `ssm:GetParameter`), and load it at cold start before the Worker initializes — for example, at module scope in the handler file, fetch the secret and set `os.environ["TEMPORAL_API_KEY"]` so the serverless Worker package reads it at startup. Do not commit key values into the `--environment` block for production functions.

## Observability

Import: `from temporalio.contrib.aws.lambda_worker.otel import apply_defaults` <!-- docs/develop/python/workers/serverless-workers/aws-lambda.mdx:147 -->

To install with OTel support: `pip install temporalio[lambda-worker-otel]` <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:214 -->

- `apply_defaults` — configures both metrics and tracing. <!-- docs/develop/python/workers/serverless-workers/aws-lambda.mdx:155,165 -->
- `build_metrics_telemetry_config` — configures metrics only. <!-- docs/develop/python/workers/serverless-workers/aws-lambda.mdx:232 -->
- `apply_tracing` — configures tracing only. <!-- docs/develop/python/workers/serverless-workers/aws-lambda.mdx:232 -->

Usage in the configure callback: <!-- docs/develop/python/workers/serverless-workers/aws-lambda.mdx:151-155 -->

```python
def configure(config: LambdaWorkerConfig) -> None:
    config.worker_config["task_queue"] = TASK_QUEUE
    config.worker_config["workflows"] = [SampleWorkflow]
    config.worker_config["activities"] = [hello_activity]
    apply_defaults(config)
```

By default, telemetry is sent to `localhost:4317`, which is the ADOT Lambda layer's default collector endpoint. <!-- docs/develop/python/workers/serverless-workers/aws-lambda.mdx:166 -->

Attach the ADOT Python Lambda layer to your Lambda function. The layer includes both auto-instrumentation and an OpenTelemetry Collector that receives telemetry on `localhost:4317` and forwards traces to AWS X-Ray and metrics to Amazon CloudWatch. <!-- docs/develop/python/workers/serverless-workers/aws-lambda.mdx:168-169 -->

`OPENTELEMETRY_COLLECTOR_CONFIG_FILE=/var/task/otel-collector-config.yaml` <!-- docs/develop/python/workers/serverless-workers/aws-lambda.mdx:218 -->

Note: Python uses `_FILE` while Go and TypeScript use `_URI`.

For Python, the `AWSXRayDaemonWriteAccess` managed policy can be attached instead. <!-- docs/develop/python/workers/serverless-workers/aws-lambda.mdx:229 -->

For the shared Collector configuration, X-Ray enablement, and execution-role permissions, see `observability.md`.

## Diagnostic signatures

| SDK | Cause | Fix |
|---|---|---|
| Python | `logging.basicConfig()` is a no-op when a root handler already exists, and the Lambda runtime installs one before your module is imported — so the level never changes and `INFO` records are filtered out | `logging.getLogger().setLevel(logging.INFO)` |
