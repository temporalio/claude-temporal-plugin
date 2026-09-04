# Go SDK on AWS Lambda

<!-- Source: docs/develop/go/workers/serverless-workers/aws-lambda.mdx -->

Use this reference for Go SDK-specific package, entry-point, Worker configuration, tuned defaults, and observability details. For shared AWS Lambda deployment and observability infrastructure, see `setup.md` and `observability.md`.

## Package

Import: `lambdaworker "go.temporal.io/sdk/contrib/aws/lambdaworker"` <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:50 -->

Install: `go get go.temporal.io/sdk/contrib/aws/lambdaworker` — **this is a separate Go module** from `go.temporal.io/sdk`, versioned independently (`v0.1.1` at the time of writing). Having the main SDK in `go.mod` does not make it importable; add it explicitly, then `go mod tidy`. Verify the installed surface with `go doc go.temporal.io/sdk/contrib/aws/lambdaworker` before generating code — the API is Public Preview and drifts.

- Go: [Go Lambda Worker sample](https://github.com/temporalio/samples-go/tree/main/lambda-worker) <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:54 -->

List the exported API of the installed module version before generating code:

```bash
go doc go.temporal.io/sdk/contrib/aws/lambdaworker
go doc go.temporal.io/sdk/contrib/aws/lambdaworker.Options
```

**Ordering when sources disagree:** the installed artifact first, the SDK's maintained samples second (they are built in CI, so they cannot reference a method that does not exist), the prose docs last. Entry-point names are not consistent across SDKs, so check rather than pattern-match from another language.

## Entry point

`lambdaworker.RunWorker` — starts a Lambda-based Worker. Pass a `WorkerDeploymentVersion` and a callback that registers Workflows and Activities. <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:39-40 -->

## Configure callback

The `Options` callback gives access to the same registration methods as a traditional Worker: `RegisterWorkflow`, `RegisterWorkflowWithOptions`, `RegisterActivity`, `RegisterActivityWithOptions`, and `RegisterNexusService`. <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:81 -->

Go, Python and TypeScript invoke it per invocation.

In Go it is a direct field on the options object (`opts.TaskQueue`).

## Versioning behavior

Set per-Workflow at registration time with `workflow.VersioningBehaviorPinned` or `workflow.VersioningBehaviorAutoUpgrade`. <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:78 -->
Or set a Worker-level default with `DefaultVersioningBehavior` in `DeploymentOptions`. <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:79 -->

**Worker Versioning is always on.** The run-worker entry point enables it, so the only remaining decision is `Pinned` vs `AutoUpgrade` per Workflow (or a Worker-level default).

## Handler example

Use the Go SDK's `lambdaworker` package. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:68 -->

```go
package main

import (
    lambdaworker "go.temporal.io/sdk/contrib/aws/lambdaworker"
    "go.temporal.io/sdk/worker"
    "go.temporal.io/sdk/workflow"
)

func main() {
    lambdaworker.RunWorker(worker.WorkerDeploymentVersion{
        DeploymentName: "my-app",
        BuildID:        "build-1",
    }, func(opts *lambdaworker.Options) error {
        opts.TaskQueue = "my-task-queue"

        opts.RegisterWorkflowWithOptions(MyWorkflow, workflow.RegisterOptions{
            VersioningBehavior: workflow.VersioningBehaviorPinned,
        })
        opts.RegisterActivity(MyActivity)

        return nil
    })
}
```
<!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:70-94 -->

## Lambda-tuned defaults

<!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:103-115 -->

| Setting | Lambda default |
|---|---|
| `MaxConcurrentActivityExecutionSize` | 2 |
| `MaxConcurrentWorkflowTaskExecutionSize` | 10 |
| `MaxConcurrentLocalActivityExecutionSize` | 2 |
| `MaxConcurrentNexusTaskExecutionSize` | 5 |
| `MaxConcurrentActivityTaskPollers` | 1 |
| `MaxConcurrentWorkflowTaskPollers` | 2 |
| `MaxConcurrentNexusTaskPollers` | 1 |
| `WorkerStopTimeout` | 5 seconds |
| `DisableEagerActivities` | Always true |
| Sticky cache size | 100 |
| `ShutdownDeadlineBuffer` | 7 seconds |

Note: Go sticky cache size is 100, while Python and TypeScript are 30. These values come from each SDK's own docs and are not interchangeable.

These are the same `worker.Options` available to any Temporal Worker, just with lower values for Lambda's constrained environment. Except for `ShutdownDeadlineBuffer`, which is specific to the `lambdaworker` package. <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:101,120 -->

`DisableEagerActivities` is always true and cannot be overridden. Eager Activities require a persistent connection, which Lambda invocations don't maintain. <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:117-118 -->

`ShutdownDeadlineBuffer` controls how much time before the Lambda deadline the Worker begins its graceful shutdown. The default is `WorkerStopTimeout` + 2 seconds. <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:120-122 -->

If your Worker handles long-running Activities, increase `WorkerStopTimeout`, `ShutdownDeadlineBuffer`, and the Lambda invocation deadline (`--timeout`) together. <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:124-125 -->

## Connection configuration

The `lambdaworker` package automatically loads Temporal client configuration from a TOML config file and environment variables (see the Environment Configuration docs, `/develop/environment-configuration`). <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:85 -->

TOML config file resolution order: <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:87-91 -->

1. `TEMPORAL_CONFIG_FILE` environment variable, if set.
2. `temporal.toml` in `$LAMBDA_TASK_ROOT` (typically `/var/task`).
3. `temporal.toml` in the current working directory.

The file is optional. If absent, only environment variables are used. <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:93 -->

## Build and package

Cross-compile for Lambda's Linux runtime: <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:191 -->

```bash
GOOS=linux GOARCH=amd64 go build -tags lambda.norpc -o bootstrap ./worker
```
<!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:194 -->

Package the binary into a zip file: <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:197 -->

```bash
zip function.zip bootstrap
```
<!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:200 -->

**Add `CGO_ENABLED=0`, and match the architecture you deploy.** The `provided.al2023` runtime expects a self-contained binary; building with cgo enabled links against host libraries that may not resolve inside the runtime. Set `CGO_ENABLED=0` for a statically linked binary, and keep `GOARCH` consistent with the function's `--architectures` (`amd64` ↔ `x86_64`, `arm64` ↔ `arm64`). Also adjust the trailing package path to your layout — `.` when `main` is in the repo root, `./worker` when it is in a `worker/` subdirectory. A reusable script:

```bash
#!/usr/bin/env bash
set -euo pipefail
go vet ./...     # catches a missing import before the cross-compile
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -tags lambda.norpc -o bootstrap .
zip -q function.zip bootstrap
file bootstrap   # expect: ELF 64-bit ... statically linked
```

Run `go vet` (or a plain `go build ./...`) before the packaging build. The three-package import block above — `lambdaworker`, `worker` for `WorkerDeploymentVersion`, and `workflow` for the versioning-behavior constants — is easy to write short by one entry, and catching that locally is faster than discovering it in the cross-compile step.

An architecture mismatch surfaces only at invocation time as an `Runtime.InvalidEntrypoint`/exec-format error, not at build or package time — the same failure class as the Python wheel mismatch described in `sdk-python.md`.

A typical Go Worker zip lands around 10–15 MB, well under the 50 MB direct-upload limit.

## Deploy the Lambda function

```bash
aws lambda create-function \
  --function-name my-temporal-worker \
  --runtime provided.al2023 \
  --handler bootstrap \
  --role <EXECUTION_ROLE_ARN> \
  --zip-file fileb://function.zip \
  --timeout 600 \
  --memory-size 256 \
  --environment '{"Variables":{"HOME":"/tmp","TEMPORAL_ADDRESS":"<your-temporal-address>:7233","TEMPORAL_NAMESPACE":"<your-namespace>","TEMPORAL_API_KEY":"<your-api-key>"}}'
```
<!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:250-260 -->

- `--runtime`: `provided.al2023` for custom Go binaries. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:265 -->
- `--handler`: `bootstrap` when using the `provided.al2023` custom runtime. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx:266 -->

| Variable | Description |
|---|---|
| `HOME` | Set to `/tmp` in the Go and TypeScript examples above. Lambda's filesystem is read-only outside `/tmp`, so anything the runtime or config loader resolves relative to the home directory needs a writable target. The docs omit it from the Python example; including it there is harmless. |

## Observability

Import: `otel "go.temporal.io/sdk/contrib/aws/lambdaworker/otel"` <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:145 -->

- `otel.ApplyDefaults` — configures both metrics and tracing. <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:157,172 -->
- `otel.ApplyMetrics` — configures metrics only. <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:240 -->
- `otel.ApplyTracing` — configures tracing only. <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:240 -->

Usage in the configure callback: <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:154-159 -->

```go
if err := otel.ApplyDefaults(opts, &opts.ClientOptions, otel.Options{}); err != nil {
    return err
}
```

By default, telemetry is sent to `localhost:4317`, which is the ADOT Lambda layer's default collector endpoint. <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:173 -->

Attach the ADOT Collector layer to your Lambda function. <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:175 -->
Go does not need a language-specific ADOT layer because the OTel SDK is compiled into the binary. <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:177 -->

`OPENTELEMETRY_COLLECTOR_CONFIG_URI=/var/task/otel-collector-config.yaml` <!-- docs/develop/go/workers/serverless-workers/aws-lambda.mdx:226 -->

For the shared Collector configuration, X-Ray enablement, and execution-role permissions, see `observability.md`.
