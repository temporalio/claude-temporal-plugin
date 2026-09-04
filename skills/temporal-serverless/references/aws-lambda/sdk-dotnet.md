# .NET SDK on AWS Lambda

Sources: [`Temporalio.Extensions.Aws.Lambda` 1.18.0](https://www.nuget.org/packages/Temporalio.Extensions.Aws.Lambda/1.18.0), [Lambda extension source](https://github.com/temporalio/sdk-dotnet/tree/1.18.0/src/Temporalio.Extensions.Aws.Lambda), [OpenTelemetry extension source](https://github.com/temporalio/sdk-dotnet/tree/1.18.0/src/Temporalio.Extensions.Aws.Lambda.OpenTelemetry), and the [maintained Lambda Worker sample](https://github.com/temporalio/samples-dotnet/tree/6aba4fb9ea08177e303352ec9a4c61e303cefb0e/src/LambdaWorker).

Use this reference for .NET SDK-specific package, entry-point, Worker configuration, tuned defaults, observability, and diagnostic details. For shared AWS Lambda deployment, observability infrastructure, and diagnostic flow, see `setup.md`, `observability.md`, and `diagnostics.md`.

## Package

Import: `using Temporalio.Extensions.Aws.Lambda;` plus `Temporalio.Common` (for `WorkerDeploymentVersion`) and `Amazon.Lambda.Core` (for `ILambdaContext`).

Install: `dotnet add package Temporalio.Extensions.Aws.Lambda` — a **separate NuGet package** from `Temporalio`, published in **lockstep** with it (both 1.18.0). Published versions: 1.17.0 and 1.18.0. The package targets `netstandard2.0` and declares `Temporalio` 1.18.0 and `Amazon.Lambda.Core` 3.1.0.

OpenTelemetry lives in a **second package**, `Temporalio.Extensions.Aws.Lambda.OpenTelemetry` (also 1.18.0). → Observability below.

- .NET: [.NET Lambda Worker sample](https://github.com/temporalio/samples-dotnet/tree/6aba4fb9ea08177e303352ec9a4c61e303cefb0e/src/LambdaWorker) — `Worker/`, `Starter/`, and `Deploy/` (deploy, IAM-role, execution-role, and telemetry scripts plus a CloudFormation template), with a test project under `tests/LambdaWorker`.

List the real public API of the resolved package before generating code — the `.nupkg` is a zip and ships full XML documentation:

```bash
curl -sO https://api.nuget.org/v3-flatcontainer/temporalio.extensions.aws.lambda/<ver>/temporalio.extensions.aws.lambda.<ver>.nupkg
unzip -p temporalio.extensions.aws.lambda.<ver>.nupkg \
  lib/netstandard2.0/Temporalio.Extensions.Aws.Lambda.xml
# the .nuspec lists the exact dependency versions:
unzip -p ...nupkg Temporalio.Extensions.Aws.Lambda.nuspec | grep dependency
```

If sources disagree, use the installed artifact's public API, followed by the maintained sample and the prose documentation.

## Entry point

**`TemporalLambdaWorker.CreateHandler(version, configure)`** — returns a `Func<object?, ILambdaContext, Task>` that your handler method delegates to. Overloads take either a synchronous `Action<TemporalLambdaWorkerOptions>` or an asynchronous `Func<TemporalLambdaWorkerOptions, Task>` for setup that must await.

## Configure callback

Receives a `TemporalLambdaWorkerOptions` with public `ClientOptions`, `WorkerOptions`, `ShutdownDeadlineBuffer`, and `AddShutdownHook(Func<CancellationToken, Task>)` members. The Task Queue and registrations go through `WorkerOptions` — an ordinary `TemporalWorkerOptions`, so `TaskQueue`, `AddWorkflow<T>()` and `AddActivity(...)` behave exactly as they do for a long-lived Worker. The callback runs **per invocation**.

## Versioning behavior

Per-Workflow via the `[Workflow]` attribute:

```csharp
[Workflow(VersioningBehavior = VersioningBehavior.Pinned)]
public class MyWorkflow
{
    [WorkflowRun]
    public async Task<string> RunAsync(string name) => /* ... */;
}
```

Or a Worker-level default through `DefaultVersioningBehavior` in `DeploymentOptions`.

**The .NET Worker-level default is `AutoUpgrade`.** Prefer setting the behavior explicitly per Workflow.

## Handler example

A plain class exposes an async method that delegates to the handler returned by `TemporalLambdaWorker.CreateHandler`.

```csharp
namespace MyCompany.Temporal.Worker;

using Amazon.Lambda.Core;
using Temporalio.Common;
using Temporalio.Extensions.Aws.Lambda;

public class LambdaFunction
{
    private static readonly Func<object?, ILambdaContext, Task> WorkerHandler =
        TemporalLambdaWorker.CreateHandler(
            new WorkerDeploymentVersion("my-app", "build-1"),
            config =>
            {
                config.WorkerOptions.TaskQueue =
                    Environment.GetEnvironmentVariable("TEMPORAL_TASK_QUEUE") ?? "my-task-queue";
                config.WorkerOptions
                    .AddWorkflow<MyWorkflow>()
                    .AddActivity(MyActivities.MyActivity);
            });

    public Task HandlerAsync(Stream input, ILambdaContext context) =>
        WorkerHandler(input, context);
}
```

Registrations go through `config.WorkerOptions`, an ordinary `TemporalWorkerOptions` — the same API a long-lived Worker uses. Use the `Func<TemporalLambdaWorkerOptions, Task>` overload when setup must await.

## Lambda-tuned defaults

<!-- docs/develop/dotnet/workers/serverless-workers/aws-lambda.mdx:125-137 -->

| Setting | Lambda default |
|---|---|
| `MaxConcurrentActivities` | 2 |
| `MaxConcurrentWorkflowTasks` | 10 |
| `MaxConcurrentLocalActivities` | 2 |
| `MaxConcurrentNexusTasks` | 5 |
| `MaxConcurrentWorkflowTaskPolls` | 2 |
| `MaxConcurrentActivityTaskPolls` | 1 |
| `MaxConcurrentNexusTaskPolls` | 1 |
| `MaxCachedWorkflows` | 30 |
| `GracefulShutdownTimeout` | 5 seconds |
| `ShutdownDeadlineBuffer` | 7 seconds |
| `DisableEagerActivityExecution` | Always `true`, cannot be overridden |

## Logging — set a LoggerFactory or Workflow logs vanish

`TemporalWorkerOptions.LoggerFactory` is unset by default and "defaults to the client logger factory", which is also unset — so `Workflow.Logger` output is discarded. Activity `Console.WriteLine` still reaches CloudWatch, which makes the gap look selective rather than total.

Install the console logging provider:

```bash
dotnet add package Microsoft.Extensions.Logging.Console
```

```csharp
using Microsoft.Extensions.Logging;

config.WorkerOptions.LoggerFactory =
    LoggerFactory.Create(b => b.AddSimpleConsole().SetMinimumLevel(LogLevel.Information));
```

## Connection configuration

Loaded automatically from environment variables and an optional TOML config file, in this resolution order:

1. `TEMPORAL_CONFIG_FILE` environment variable, if set.
2. `temporal.toml` in the Lambda task root (typically `/var/task`).
3. `temporal.toml` in the current working directory.

When using `temporal.toml`, copy it into the publish directory before zipping so it lands in the task root. Keep the API key in `TEMPORAL_API_KEY` rather than in the file; supplying an API key enables TLS automatically.

**TLS caveat specific to .NET — set `SSL_CERT_FILE` or the first invocation fails.** AWS's .NET 8 Lambda images force-override `SSL_CERT_FILE`, which prevents the SDK's Rust core from loading system root CAs. Set it explicitly on the function:

```
SSL_CERT_FILE=/etc/pki/tls/certs/ca-bundle.crt     # or /etc/ssl/certs/ca-certificates.crt
```

**This is server-certificate verification, not client credentials.** The API key is unaffected and is not the problem — an API key auto-enables TLS, and TLS requires verifying Temporal Cloud's certificate chain against root CAs. The connection fails before authentication is ever attempted. See `diagnostics.md` for the corresponding failure signature and recovery steps.

## Build and package

### Native dependency — publish must be RID-specific

The .NET SDK wraps a **native Rust core** (`libtemporalio_sdk_core_c_bridge.so`). For Lambda, publish for an explicit runtime identifier matching the function's architecture and confirm the native library is present before creating the zip:

| `--runtime` | `--architectures` |
|---|---|
| `linux-x64` | `x86_64` |
| `linux-arm64` | `arm64` |

Publish for an explicit Linux runtime identifier, then zip the publish output.

```bash
dotnet publish path/to/Worker.csproj \
  --configuration Release \
  --runtime linux-x64 \
  --self-contained false \
  --output ./publish

# Guard: the SDK's native Rust bridge must be in the output, or the function
# fails at FIRST INVOCATION, not at build time.
[[ -f ./publish/libtemporalio_sdk_core_c_bridge.so ]] || {
  echo "Publish output is missing the linux-x64 Temporal native bridge." >&2; exit 1; }

# Copy each optional configuration file that this deployment uses so it lands
# in the Lambda task root:
if [[ -f temporal.toml ]]; then
  cp temporal.toml ./publish/
fi
if [[ -f otel-collector-config.yaml ]]; then
  cp otel-collector-config.yaml ./publish/
fi

cd ./publish && zip -r ../function.zip . && cd ..
```

Keep the native-library check before zipping. `--self-contained false` is correct because the `dotnet8` managed runtime supplies the framework.

## Deploy the Lambda function

```bash
aws lambda create-function \
  --function-name my-temporal-worker \
  --runtime dotnet8 \
  --architectures x86_64 \
  --handler 'MyAssembly::MyCompany.Temporal.Worker.LambdaFunction::HandlerAsync' \
  --role <EXECUTION_ROLE_ARN> \
  --zip-file fileb://function.zip \
  --timeout 600 \
  --memory-size 256 \
  --environment file:///tmp/lambda-env.json
```

**The environment block for .NET must include `SSL_CERT_FILE`**, in addition to the usual `TEMPORAL_*` variables:

```json
{"Variables":{
  "TEMPORAL_ADDRESS":"...", "TEMPORAL_NAMESPACE":"...", "TEMPORAL_API_KEY":"...",
  "SSL_CERT_FILE":"/etc/pki/tls/certs/ca-bundle.crt"}}
```

Without it the **first invocation fails**, the Task Queue is never bound, and the Worker is never invoked again. AWS's .NET 8 Lambda images force-override `SSL_CERT_FILE`, which stops the SDK's Rust core from loading system root CAs. `/etc/ssl/certs/ca-certificates.crt` also works; try the other if one fails. This is server-certificate verification, unrelated to your API key. → `diagnostics.md`.

- `--runtime`: `dotnet8` for a `net8.0` build.
- `--handler`: **`ASSEMBLY::NAMESPACE.TYPE::METHOD` — three colon-separated parts.** Getting this wrong presents as a handler-not-found error at first invocation.
- `--timeout 600` / `--memory-size 256` are example values. The timeout must accommodate Worker startup and registration, Task and Activity processing, and graceful shutdown. Memory contributes directly to Lambda cost. → `setup.md` for how to choose both values.
- `--architectures` must match the publish RID (`linux-x64` → `x86_64`, `linux-arm64` → `arm64`).

## Observability

### OTel package

A **second NuGet package**, separate from the Lambda extension itself:

```bash
dotnet add package Temporalio.Extensions.Aws.Lambda.OpenTelemetry
```

Published in lockstep with `Temporalio` and `Temporalio.Extensions.Aws.Lambda` (all 1.18.0).

### OTel functions

The package contributes an extension method on the options object, applied inside the configure callback:

```csharp
using Temporalio.Extensions.Aws.Lambda.OpenTelemetry;

TemporalLambdaWorker.CreateHandler(
    new WorkerDeploymentVersion("my-app", "build-1"),
    config =>
    {
        config.ApplyOpenTelemetryDefaults();
        config.WorkerOptions.TaskQueue = "my-task-queue";
        config.WorkerOptions.AddWorkflow<MyWorkflow>().AddActivity(MyActivities.MyActivity);
    });
```

`ApplyOpenTelemetryDefaults()` configures metrics and tracing against the ADOT layer's collector. Telemetry must be exported before the invocation ends — keep any metrics export interval shorter than the Lambda timeout.

### ADOT layer setup

Attach an **ADOT Collector layer** for the target region and architecture. No language-specific auto-instrumentation layer is needed because the OpenTelemetry SDK arrives as an ordinary package dependency. Supply the collector layer ARN for the target region.

Set `OPENTELEMETRY_COLLECTOR_CONFIG_URI=/var/task/otel-collector-config.yaml` and copy `otel-collector-config.yaml` into the publish directory before zipping so it lands in the task root.

For the shared Collector configuration, X-Ray enablement, and execution-role permissions, see `observability.md`.

## Diagnostic signatures

| SDK | Cause | Fix |
|---|---|---|
| .NET | `TemporalWorkerOptions.LoggerFactory` is unset and "defaults to the client logger factory", which is also unset — so `Workflow.Logger` output is discarded. Activity `Console.WriteLine` still reaches CloudWatch, which makes the gap look selective rather than total | set `config.WorkerOptions.LoggerFactory` (e.g. `LoggerFactory.Create(b => b.AddSimpleConsole().SetMinimumLevel(LogLevel.Information))`) |

**.NET — `DllNotFoundException` / missing `libtemporalio_sdk_core_c_bridge.so` at first invocation.** Republish with an explicit runtime identifier matching the function's architecture (`--runtime linux-x64` for `x86_64`, `linux-arm64` for `arm64`) and check the native library is in the publish output before zipping. → Build and package above.

**.NET — `NativeCertsNotFound` at first invocation, despite a correct address, Namespace, and API key.**

```
System.InvalidOperationException: Connection failed: Server connection error:
  tonic::transport::Error(Transport, NativeCertsNotFound)
   at Temporalio.Bridge.Client.ConnectAsync(...)
   at Temporalio.Client.TemporalConnection.ConnectAsync(...)
```

*Cause:* AWS's .NET 8 Lambda images force-override `SSL_CERT_FILE`, so the SDK's Rust core cannot load system root CAs. *Fix:* set `SSL_CERT_FILE=/etc/pki/tls/certs/ca-bundle.crt` (or `/etc/ssl/certs/ca-certificates.crt`) on the function, then recover the binding as described under "Failed first invocation" in `diagnostics.md` — the failed validation invocation means no Task Queue was bound and Temporal will not retry on its own.

"Certs" here means the operating system's root CA store, not client credentials. An API key auto-enables TLS, and TLS requires verifying the server's certificate chain. The connection fails before authentication is attempted, so changing the API key, Namespace, invocation role, or External ID will not fix this error.

**.NET — handler not found at first invocation.** The handler string has **three** colon-separated parts, `ASSEMBLY::NAMESPACE.TYPE::METHOD`. Compare against the assembly name (not the project name, if they differ) and the fully-qualified type.
