# .NET SDK on GCP Cloud Run


Use this reference for .NET-specific Worker construction, versioning behavior, connection configuration, image packaging, and scale-in safety. For shared Cloud Run execution constraints, deployment lifecycle, permissions, versioning, observability, and diagnostics, see `constraints.md`, `setup.md`, `iam.md`, `versioning.md`, `observability.md`, and `diagnostics.md`. Scoping (Namespace, GCP project, region), the API-key hand-off, IAM, registration, and verification are the same for every SDK and are defined once in `SKILL.md` and `setup.md`; do not vary them per SDK. This guide's sample is one Workflow that takes a string and returns `Hello, <name>!`, which is what `setup.md` Step 8 verifies.

## Install and scaffold

Create the project directly in `<APP_DIR>` with the same target framework used by the runtime image, then pin the packages validated for this guide:

```bash
dotnet new console --framework net9.0 --name MyWorker --output <APP_DIR>
dotnet add <APP_DIR>/MyWorker.csproj package Temporalio --version 1.20.0
dotnet add <APP_DIR>/MyWorker.csproj package Microsoft.Extensions.Logging.Console --version 9.0.0
```

`--output` keeps the project file at the root of `<APP_DIR>`, which `setup.md` Step 2 submits as the build context; without it, `dotnet new` creates a `MyWorker/` subdirectory and the Dockerfile's `COPY MyWorker.csproj ./` fails with `"/MyWorker.csproj": not found`. The examples assume this layout:

```text
<APP_DIR>/
  MyWorker.csproj
  Program.cs              # versioned Worker (top-level statements)
  GreetingWorkflow.cs
  GreetingActivities.cs
  Dockerfile  .gcloudignore
```

Do not rely on the locally installed SDK's default framework. For example, a .NET 10 SDK creates `net10.0` unless `--framework net9.0` is explicit, and that output cannot run in the 9.0 runtime image below.

## Inspect the versioning API before generating code

```bash
dotnet list <APP_DIR>/MyWorker.csproj package
unzip -p ~/.nuget/packages/temporalio/<version>/temporalio.<version>.nupkg \
  'lib/netstandard2.0/Temporalio.xml' \
  | grep -n -A12 -E 'T:Temporalio\.(Worker\.WorkerDeploymentOptions|Common\.WorkerDeploymentVersion)'
```

Run `dotnet restore` first so the `.nupkg` and XML documentation exist locally.

**Without a local .NET SDK**, run the install-and-scaffold commands in the SDK image instead. The image sets `NUGET_XMLDOC_MODE=skip`, which drops the XML documentation this inspection reads, so override it, and mount the NuGet cache so the package stays on the host:

```bash
docker run --rm -e NUGET_XMLDOC_MODE=none \
  -v <APP_DIR>:/src -v <NUGET_CACHE>:/root/.nuget/packages -w /src \
  mcr.microsoft.com/dotnet/sdk:9.0 sh -c '
    dotnet new console --framework net9.0 --name MyWorker --output . &&
    dotnet add MyWorker.csproj package Temporalio --version 1.20.0 &&
    dotnet add MyWorker.csproj package Microsoft.Extensions.Logging.Console --version 9.0.0 &&
    dotnet build MyWorker.csproj'
```

Then run the `unzip` inspection above on the host against `<NUGET_CACHE>/temporalio/1.20.0/temporalio.1.20.0.nupkg`. On Apple Silicon, add `--platform linux/arm64` to avoid running the image under emulation. Cloud Build still compiles the image you deploy.

## Versioned Worker

Set `DeploymentOptions` on `TemporalWorkerOptions`. The Worker reads its connection settings and Task Queue from the environment so one image runs against any Namespace:

```csharp
using System.Runtime.InteropServices;
using Microsoft.Extensions.Logging;
using Temporalio.Client;
using Temporalio.Common;
using Temporalio.Worker;

var deploymentName = Environment.GetEnvironmentVariable("TEMPORAL_DEPLOYMENT_NAME")
    ?? throw new InvalidOperationException("TEMPORAL_DEPLOYMENT_NAME must be set");
var buildId = Environment.GetEnvironmentVariable("TEMPORAL_BUILD_ID")
    ?? throw new InvalidOperationException("TEMPORAL_BUILD_ID must be set");
var taskQueue = Environment.GetEnvironmentVariable("TEMPORAL_TASK_QUEUE")
    ?? throw new InvalidOperationException("TEMPORAL_TASK_QUEUE must be set");

var address = Environment.GetEnvironmentVariable("TEMPORAL_ADDRESS")
    ?? throw new InvalidOperationException("TEMPORAL_ADDRESS must be set");
var temporalNamespace = Environment.GetEnvironmentVariable("TEMPORAL_NAMESPACE")
    ?? throw new InvalidOperationException("TEMPORAL_NAMESPACE must be set");
var apiKey = Environment.GetEnvironmentVariable("TEMPORAL_API_KEY")
    ?? throw new InvalidOperationException("TEMPORAL_API_KEY must be set");

using var loggerFactory = LoggerFactory.Create(builder =>
{
    builder.AddSimpleConsole(options => options.SingleLine = true);
    builder.SetMinimumLevel(LogLevel.Information);
    builder.AddFilter("Grpc", LogLevel.Warning);
});

var connectOptions = new TemporalClientConnectOptions(address)
{
    Namespace = temporalNamespace,
    ApiKey = apiKey,
    Tls = new(),
    LoggerFactory = loggerFactory,
};
var client = await TemporalClient.ConnectAsync(connectOptions);

var options = new TemporalWorkerOptions(
    taskQueue)
{
    DeploymentOptions = new(new(deploymentName, buildId), useWorkerVersioning: true)
    {
        DefaultVersioningBehavior = VersioningBehavior.Pinned,
    },
    GracefulShutdownTimeout = TimeSpan.FromSeconds(8),
};
options.AddWorkflow<GreetingWorkflow>();
options.AddAllActivities(typeof(GreetingActivities), null);

using var shutdown = new CancellationTokenSource();
using var sigterm = PosixSignalRegistration.Create(
    PosixSignal.SIGTERM,
    context =>
    {
        context.Cancel = true;
        shutdown.Cancel();
    });
Console.CancelKeyPress += (_, eventArgs) =>
{
    eventArgs.Cancel = true;
    shutdown.Cancel();
};

using var worker = new TemporalWorker(client, options);
Console.WriteLine(
    $"Worker started deployment={deploymentName} build={buildId} taskQueue={taskQueue}");
try
{
    await worker.ExecuteAsync(shutdown.Token);
}
catch (OperationCanceledException) when (shutdown.IsCancellationRequested)
{
    // Expected during Cloud Run scale-in or an interactive stop.
}
```

`WorkerDeploymentVersion`'s two arguments are the deployment name and the build ID, and both must match the version created with `temporal worker deployment create-version` exactly. → `setup.md` Step 6.

Use the ordinary publish for the image's platform; it includes the native Rust bridge. Cloud Run needs no provider-specific handler or artifact format.

## Versioning behavior

Every Workflow needs `VersioningBehavior.Pinned` or `AutoUpgrade`. `DefaultVersioningBehavior` covers every Workflow; to set it per Workflow, set it on the `[Workflow]` attribute. Neither is set implicitly, so one of the two must be set explicitly.

```csharp
using Temporalio.Common;
using Temporalio.Workflows;

[Workflow(VersioningBehavior = VersioningBehavior.Pinned)]
public class GreetingWorkflow
{
    [WorkflowRun]
    public async Task<string> RunAsync(string name) => // ...
}
```

**A Version set with no behavior fails at startup:** `new TemporalWorker(...)` throws `ArgumentException: Workflow named GreetingWorkflow must specify a versioning behavior, since the worker has no default.`, which on Cloud Run becomes a crash loop.

## Connection configuration

Read `TEMPORAL_ADDRESS`, `TEMPORAL_NAMESPACE`, `TEMPORAL_API_KEY`, and `TEMPORAL_TASK_QUEUE` from the environment set on the pool, and mount the key from Secret Manager rather than passing it in plaintext. → `setup.md` Step 4.

To load them through the shared config format instead, use `ClientEnvConfig.LoadClientConnectOptions()` from `Temporalio.Common.EnvConfig`.

**No `SSL_CERT_FILE` override is needed.** The Debian-based `mcr.microsoft.com/dotnet/runtime` images ship a certificate store the Rust core can read.

## Image packaging

Publish and run on a .NET runtime image:

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build

WORKDIR /src
COPY MyWorker.csproj ./
RUN dotnet restore
COPY . .
RUN dotnet publish MyWorker.csproj -c Release -o /out \
    --runtime linux-x64 --self-contained false

FROM mcr.microsoft.com/dotnet/runtime:9.0

WORKDIR /app
COPY --from=build /out ./
CMD ["dotnet", "MyWorker.dll"]
```

`MyWorker.dll` must match the project's `<AssemblyName>` (or the project filename when `AssemblyName` is unset), and `<TargetFramework>` must remain `net9.0` for this image. Cloud Run Worker Pools run it as `linux/amd64`.

Save the following alongside the Dockerfile as `.gcloudignore`. The Dockerfile uses `COPY . .`, so excluding local `bin/` and `obj/` prevents stale restore or build output from entering the Cloud Build context:

```gitignore
.git
.gitignore
.idea
bin
obj
TestResults
terraform/
.terraform/
*.tfstate*
```

The Debian-based runtime image above includes CA certificates. Verify that any alternative runtime image also provides a readable CA bundle. → `setup.md` Step 2.

## Graceful shutdown on scale-in

Cloud Run sends `SIGTERM`, which is distinct from the `SIGINT` raised by Ctrl+C. The example registers both paths and cancels the token passed to `ExecuteAsync`. That stops polling and starts the Temporal Worker's shutdown sequence.

`GracefulShutdownTimeout` defaults to zero. Keep a non-zero value below the termination window described in `constraints.md`, leaving time for cancellation and final completions to propagate. Activities should observe `ActivityExecutionContext.Current.WorkerShutdownToken` or `CancellationToken` and record Heartbeats.

## Keep Activities safe across scale-in

Apply the Heartbeat-resume invariant from `constraints.md`. This is the sample's only Workflow: it takes one string and calls one Activity with Heartbeat and retry options.

```csharp
using Temporalio.Common;
using Temporalio.Workflows;

[Workflow]
public class GreetingWorkflow
{
    [WorkflowRun]
    public async Task<string> RunAsync(string name) =>
        await Workflow.ExecuteActivityAsync(
            () => GreetingActivities.ProcessAsync(name),
            new ActivityOptions
            {
                StartToCloseTimeout = TimeSpan.FromMinutes(10),
                HeartbeatTimeout = TimeSpan.FromSeconds(10),
                RetryPolicy = new RetryPolicy
                {
                    InitialInterval = TimeSpan.FromSeconds(1),
                    MaximumAttempts = 5,
                },
            });
}
```

The Activity records the next step to run, so a retry after scale-in resumes there instead of starting over. Each step must be safe to repeat:

```csharp
using Temporalio.Activities;

public static class GreetingActivities
{
    [Activity]
    public static async Task<string> ProcessAsync(string name)
    {
        string[] steps = ["validate", "compose", "record"];
        var context = ActivityExecutionContext.Current;
        var info = context.Info;
        var startIndex = info.HeartbeatDetails.Count > 0
            ? await info.HeartbeatDetailAtAsync<int>(0)
            : 0;

        for (var i = startIndex; i < steps.Length; i++)
        {
            // ... run steps[i] for name
            context.Heartbeat(i + 1);
        }
        return $"Hello, {name}!";
    }
}
```

To log from an Activity, use `ActivityExecutionContext.Current.Logger.LogInformation(...)`. It needs `using Microsoft.Extensions.Logging;`, which a console project's implicit usings do not include.

→ `constraints.md` for what else follows from the pool model.

## Logging and diagnostic signatures

The .NET SDK defaults to `NullLoggerFactory`, which drops every SDK log. The versioned Worker example creates a console `LoggerFactory` before connecting and assigns it to the connect options; keep it when adapting the example.

Do not enable DEBUG logging globally in production without first verifying that dependency logs cannot contain credentials or payloads.

| Log signature | Meaning / action |
|---|---|
| No SDK logs | The default null logger is still in use; pass an `ILoggerFactory` to the client. |
| `NativeCertsNotFound` | The runtime image lacks a readable CA store. Use the Debian runtime image or install CA certificates. |
| `OperationCanceledException` immediately after SIGTERM | Expected when it is caught by the shutdown path shown above. |

## Observability

For the optional Cloud Run OpenTelemetry path, add the released extension matching the SDK version:

```bash
dotnet add <APP_DIR>/MyWorker.csproj package Temporalio.Extensions.Gcp.CloudRun.OpenTelemetry --version 1.20.0
```

Apply its defaults to the versioned Worker example's `connectOptions` before connecting, retain the returned handle, and flush after the Worker stops. The one-second flush keeps the eight-second drain, client close, and flush inside Cloud Run's roughly ten-second termination window together; see `observability.md`.

```csharp
using Temporalio.Extensions.Gcp.CloudRun.OpenTelemetry;

// Between building connectOptions and connecting:
using var telemetry = connectOptions.ApplyGoogleCloudRunOpenTelemetryDefaults();
var client = await TemporalClient.ConnectAsync(connectOptions);

// After worker.ExecuteAsync returns:
await telemetry.FlushAsync(TimeSpan.FromSeconds(1));
```

The helper defaults to the local OTLP/gRPC Collector endpoint. Use the multi-container topology, IAM, and shutdown order in `observability.md`; do not add the extension unless that Collector path is enabled.
