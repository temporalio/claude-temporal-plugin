# Python SDK on GCP Cloud Run


Use this reference for Python-specific Worker construction, versioning behavior, connection configuration, image packaging, and scale-in safety. For shared Cloud Run execution constraints, deployment lifecycle, permissions, versioning, observability, and diagnostics, see `constraints.md`, `setup.md`, `iam.md`, `versioning.md`, `observability.md`, and `diagnostics.md`. Scoping (Namespace, GCP project, region), the API-key hand-off, IAM, registration, and verification are the same for every SDK and are defined once in `SKILL.md` and `setup.md`; do not vary them per SDK. This guide's sample is one Workflow that takes a string and returns `Hello, <name>!`, which is what `setup.md` Step 8 verifies.

## Install and scaffold

Create an isolated environment and pin the SDK version validated for this guide:

```bash
python3 -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install temporalio==1.34.0
.venv/bin/python -m pip freeze > requirements.txt
```

Run every local Python command through `.venv/bin/python`, so it uses the pinned SDK rather than the system interpreter. The examples assume this layout; the image runs the Worker with `python -m worker`:

```text
<APP_DIR>/
  requirements.txt
  worker.py          # main()
  my_workflows.py    # MyWorkflow
  my_activities.py   # my_activity
  Dockerfile  .gcloudignore
```

## Inspect the versioning API before generating code

```bash
.venv/bin/python -c "import temporalio.worker as w; print([n for n in dir(w) if 'Deployment' in n])"
.venv/bin/python -c "from temporalio.worker import WorkerDeploymentConfig; help(WorkerDeploymentConfig)"
.venv/bin/python -c "from temporalio.common import VersioningBehavior; print(list(VersioningBehavior))"
```

## Versioned Worker

Pass `deployment_config` to `Worker()`. The Worker reads its connection settings and Task Queue from the environment so one image runs against any Namespace:

```python
import asyncio
import logging
import os
import signal
from datetime import timedelta

from temporalio.client import Client
from temporalio.common import VersioningBehavior, WorkerDeploymentVersion
from temporalio.envconfig import ClientConfig
from temporalio.worker import Worker, WorkerDeploymentConfig

from my_activities import my_activity
from my_workflows import MyWorkflow


def require_env(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        raise SystemExit(f"{name} must be set")
    return value


async def main() -> None:
    logging.basicConfig(level=logging.INFO)
    deployment_name = require_env("TEMPORAL_DEPLOYMENT_NAME")
    build_id = require_env("TEMPORAL_BUILD_ID")
    task_queue = require_env("TEMPORAL_TASK_QUEUE")
    client = await Client.connect(**ClientConfig.load_client_connect_config())

    worker = Worker(
        client,
        task_queue=task_queue,
        workflows=[MyWorkflow],
        activities=[my_activity],
        deployment_config=WorkerDeploymentConfig(
            version=WorkerDeploymentVersion(
                deployment_name=deployment_name,
                build_id=build_id,
            ),
            use_worker_versioning=True,
            default_versioning_behavior=VersioningBehavior.PINNED,
        ),
        graceful_shutdown_timeout=timedelta(seconds=8),
    )
    stop = asyncio.Event()
    loop = asyncio.get_running_loop()
    for sig in (signal.SIGTERM, signal.SIGINT):
        loop.add_signal_handler(sig, stop.set)

    async with worker:
        logging.info(
            "Worker started deployment=%s build=%s taskQueue=%s",
            deployment_name,
            build_id,
            task_queue,
        )
        await stop.wait()


if __name__ == "__main__":
    asyncio.run(main())
```

`deployment_name` and `build_id` must match the version created with `temporal worker deployment create-version` exactly, or the Worker polls under a version the WCI does not manage. → `setup.md` Step 6.

## Versioning behavior

Every Workflow needs `VersioningBehavior.PINNED` or `AUTO_UPGRADE`. `default_versioning_behavior` on `WorkerDeploymentConfig` covers every Workflow; to set it per Workflow, pass `versioning_behavior` to the decorator.

```python
@workflow.defn(versioning_behavior=VersioningBehavior.PINNED)
class MyWorkflow:
    @workflow.run
    async def run(self, name: str) -> str:
        ...
```

**A Version set with no behavior fails at startup:** `Worker()` raises `ValueError: Workflow MyWorkflow must specify a versioning behavior …`, which on Cloud Run becomes a crash loop.

## Connection configuration

`temporalio.envconfig` loads client configuration from environment variables and an optional TOML file. The variables it reads include `TEMPORAL_ADDRESS`, `TEMPORAL_NAMESPACE`, `TEMPORAL_API_KEY`, `TEMPORAL_PROFILE`, `TEMPORAL_CONFIG_FILE`, and the `TEMPORAL_TLS_*` settings. **Setting an API key turns TLS on** with default options unless TLS is configured explicitly, so a Temporal Cloud Worker needs no separate TLS variable. Set non-secret values with `--set-env-vars` on the pool and mount the API key or TLS material from Secret Manager with `--set-secrets`. → `setup.md` Step 4.

`ClientConfig.load_client_connect_config()` returns keyword arguments for `Client.connect`, which is why it is unpacked with `**`. To inspect or override values first, load the profile instead:

```python
from temporalio.envconfig import ClientConfigProfile

profile = ClientConfigProfile.load()
connect_config = profile.to_client_connect_config()
client = await Client.connect(**connect_config)
```

## Image packaging

Cloud Run Worker Pools run this image as `linux/amd64`. Build wheels separately and install them into a slim runtime:

```dockerfile
FROM python:3.13-slim AS build
WORKDIR /src
COPY requirements.txt ./
RUN pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt

FROM python:3.13-slim
COPY --from=build /wheels /wheels
RUN pip install --no-cache-dir /wheels/* && rm -rf /wheels
WORKDIR /app
COPY . .
CMD ["python", "-m", "worker"]
```

Use this `.gcloudignore`:

```gitignore
.git
.gitignore
.idea
.venv
__pycache__
.pytest_cache
*.pyc
terraform/
.terraform/
*.tfstate*
```

Change `worker` only if the module containing `main()` has a different name. Python shares the Rust core, which reads TLS roots from the OS store. The official `python:*-slim` images already include `ca-certificates`; install it only when switching to a base image that lacks it. → `setup.md` Step 2.

## Graceful shutdown on scale-in

Cloud Run sends `SIGTERM` before stopping an instance. The example converts it into an `asyncio.Event`; leaving the `async with worker` block calls `worker.shutdown()` and waits for the SDK's shutdown sequence. `graceful_shutdown_timeout` gives received Activities up to eight seconds before cancellation. Prefer this explicit path over cancelling `worker.run()`, because cancellation can also cancel the shutdown operation.

## Keep Activities safe across scale-in

Apply the Heartbeat-resume invariant from `constraints.md`. This is the sample's only Workflow: it takes one string and calls one Activity with Heartbeat and retry options.

```python
from datetime import timedelta

from temporalio import workflow
from temporalio.common import RetryPolicy

with workflow.unsafe.imports_passed_through():
    from my_activities import my_activity


@workflow.defn
class MyWorkflow:
    @workflow.run
    async def run(self, name: str) -> str:
        return await workflow.execute_activity(
            my_activity,
            name,
            start_to_close_timeout=timedelta(minutes=10),
            heartbeat_timeout=timedelta(seconds=10),
            retry_policy=RetryPolicy(
                initial_interval=timedelta(seconds=1),
                maximum_attempts=5,
            ),
        )
```

Import Activities inside `workflow.unsafe.imports_passed_through()` in the Workflow module, so the Workflow sandbox does not re-import them on every run.

The Activity records the next step to run, so a retry after scale-in resumes there instead of starting over. Each step must be safe to repeat:

```python
from temporalio import activity


@activity.defn
async def my_activity(name: str) -> str:
    steps = ["validate", "compose", "record"]
    details = activity.info().heartbeat_details
    start_index = details[0] if details else 0

    for i in range(start_index, len(steps)):
        # ... run steps[i] for name
        activity.heartbeat(i + 1)
    return f"Hello, {name}!"
```

→ `constraints.md` for what else follows from the pool model.

## Logging and diagnostic signatures

Configure application logging before constructing the client or Worker. Cloud Run captures stdout and stderr automatically:

```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
logging.getLogger("temporalio").setLevel(logging.INFO)
```

Do not enable DEBUG logging globally in production without first verifying that dependency logs cannot contain credentials or payloads.

| Log signature | Meaning / action |
|---|---|
| `NativeCertsNotFound` | The runtime image lacks CA certificates. Install `ca-certificates` and rebuild. |
| `TransportError` during startup | Check the mounted API key, address including port, TLS, and Namespace. |
| No application `INFO` records | Configure the root logger before Worker construction; do not rely on an implicit handler. |

## Observability

For the optional Cloud Run OpenTelemetry path, install the SDK extra:

```bash
.venv/bin/python -m pip install 'temporalio[cloud-run-worker-otel]==1.34.0'
.venv/bin/python -m pip freeze > requirements.txt
```

Re-freeze after installing the extra: the image installs only what `requirements.txt` lists, so a stale file fails at startup with `ModuleNotFoundError: No module named 'opentelemetry'`.

Add the plugin to the same client used by the Worker and flush it after the Worker stops. The drain and the flush together must fit Cloud Run's roughly ten-second termination window; see `observability.md`. `shutdown(timeout)` bounds only the force-flush; the provider shutdown that follows waits on the OTLP exporter's own timeout, which defaults to 10 seconds. Set `OTEL_EXPORTER_OTLP_TIMEOUT=1` in the Worker container's `env` in the multi-container Worker Pool manifest (`observability.md`). This exporter reads the value in **seconds**, not the milliseconds the OpenTelemetry specification uses.

```python
from datetime import timedelta
from temporalio.contrib.gcp.cloud_run.opentelemetry import OpenTelemetryPlugin

plugin = OpenTelemetryPlugin(add_temporal_spans=True)
client = await Client.connect(
    **ClientConfig.load_client_connect_config(),
    plugins=[plugin],
)

# After the Worker context exits:
traces_flushed = await asyncio.to_thread(
    plugin.shutdown,
    timedelta(seconds=1),
)
```

The helper defaults to the local OTLP/gRPC Collector endpoint. Use the multi-container topology, IAM, and shutdown order in `observability.md`; do not add the plugin unless that Collector path is enabled.
