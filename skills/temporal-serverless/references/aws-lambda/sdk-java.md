# Java SDK on AWS Lambda

<!-- Sources: io.temporal:temporal-aws-lambda:1.38.0 sources jar and samples-java@main -->

Use this reference for Java SDK-specific package, entry-point, Worker configuration, tuned defaults, observability, and diagnostic details. For shared AWS Lambda deployment, observability infrastructure, and diagnostic flow, see `setup.md`, `observability.md`, and `diagnostics.md`.

## Package

Import: `io.temporal.aws.lambda.LambdaWorker`, `io.temporal.aws.lambda.LambdaWorkerOptions`, `io.temporal.common.WorkerDeploymentVersion` <!-- verified against io.temporal:temporal-aws-lambda:1.38.0 sources jar -->

Install: `io.temporal:temporal-aws-lambda` — a **separate Maven artifact** from `io.temporal:temporal-sdk`, but published on the **same version line** (both 1.38.0). This is a third packaging pattern: unlike Go and TypeScript it is not independently versioned, and unlike Python it does not ship inside the main SDK. Use `io.temporal:temporal-bom` in `dependencyManagement` to keep them aligned.

```xml
<dependencyManagement>
  <dependencies>
    <dependency>
      <groupId>io.temporal</groupId><artifactId>temporal-bom</artifactId>
      <version>1.38.0</version><type>pom</type><scope>import</scope>
    </dependency>
  </dependencies>
</dependencyManagement>
```

`aws-lambda-java-core` (1.4.0) arrives transitively from `temporal-aws-lambda`; declare it explicitly if you compile against `RequestHandler`/`Context`.

- Java: [Java Lambda Worker sample](https://github.com/temporalio/samples-java/tree/main/lambda-worker) — three Gradle subprojects (`worker/` handler + greeting Workflow/Activity, `starter/` local client, `deploy/` IAM and deploy scripts plus a CloudFormation template) <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx (line unverified) -->

List the real public API of the resolved artifact before generating code:

```bash
javap -cp ~/.m2/repository/io/temporal/temporal-aws-lambda/<ver>/temporal-aws-lambda-<ver>.jar \
  io.temporal.aws.lambda.LambdaWorker
javap -cp <same jar> 'io.temporal.aws.lambda.LambdaWorkerOptions$Builder'
# or read the source directly — Maven Central publishes a sources jar:
#   curl -O https://repo1.maven.org/maven2/io/temporal/temporal-aws-lambda/<ver>/temporal-aws-lambda-<ver>-sources.jar
```

**A useful ordering when sources disagree:** the installed artifact first, the SDK's maintained samples second (they are built in CI, so they cannot reference a method that does not exist), the prose docs last. Entry-point names are not consistent across SDKs — Java's is `define`, not "run"-shaped like the others — so check rather than pattern-match from another language.

## Entry point

**`LambdaWorker.define(version, configure)`** — returns a `RequestHandler<Object, Void>` that your handler class delegates to. There are four public overloads: `define` (2- and 3-arg) and `newHandler` (2- and 3-arg, taking a pre-built `LambdaWorkerOptions`).

Note that Java's entry point is not "run"-shaped like the other SDKs' (`RunWorker`, `run_worker`, `runWorker`) — confirm the method name against the version you install. <!-- verified against io.temporal:temporal-aws-lambda:1.37.0 and 1.38.0, and samples-java@main -->

## Configure callback — two phases, unlike the other SDKs

Java splits configuration in a way no other SDK does, and the distinction matters:

- The `Consumer<LambdaWorkerOptions.Builder>` passed to `define` is *"invoked once while the Lambda handler is constructed"* — i.e. at **cold start**, once per container, **not** per invocation.
- Per-invocation configuration is a **separate** callback, `LambdaWorker.InvocationConfigurator`, taking `(LambdaWorkerOptions.Builder, com.amazonaws.services.lambda.runtime.Context)`, *"invoked for each Lambda invocation before Temporal service stubs, client, and worker are created."* Use the 3-arg `define` overload for it.

Contrast Python, whose `configure` runs **once per invocation**. Do not describe them as equivalent, and do not carry per-invocation logic into Java's cold-start callback.

Registration methods on `LambdaWorkerOptions.Builder`: `setTaskQueue`, `registerWorkflowImplementationTypes`, `registerDynamicWorkflowImplementationType`, `registerWorkflowImplementationFactory` (3 overloads), `registerActivitiesImplementations`, `registerDynamicActivityImplementation`, `registerNexusServiceImplementation`, `addShutdownHook`, plus `getWorkerOptionsBuilder()` / `getWorkflowClientOptionsBuilder()` / `getWorkflowServiceStubsOptionsBuilder()` for lower-level tuning.

## Versioning behavior

Per-Workflow via the **annotation** `io.temporal.workflow.WorkflowVersioningBehavior` on the workflow method, taking `io.temporal.common.VersioningBehavior.PINNED` or `.AUTO_UPGRADE`:

```java
public class GreetingWorkflowImpl implements GreetingWorkflow {
  @Override
  @WorkflowVersioningBehavior(VersioningBehavior.PINNED)
  public String getGreeting(String name) { ... }
}
```

Or a Worker-level default with `DefaultVersioningBehavior` in `DeploymentOptions`.

**Worker Versioning is always on.** The run-worker entry point enables it, so the only remaining decision is `Pinned` vs `AutoUpgrade` per Workflow (or a Worker-level default).

Versioning behavior: annotate the Workflow **method** in the implementation class with `io.temporal.workflow.WorkflowVersioningBehavior`, or set a Worker-level default with `DefaultVersioningBehavior` in `DeploymentOptions`.

```java
public class MyWorkflowImpl implements MyWorkflow {
  @Override
  @WorkflowVersioningBehavior(VersioningBehavior.PINNED)
  public String getGreeting(String name) { ... }
}
```

## Handler example

Use the `temporal-aws-lambda` module. The handler class implements `RequestHandler<Object, Void>` and delegates to the handler returned by `LambdaWorker.define`. <!-- verified against io.temporal:temporal-aws-lambda:1.38.0 -->

```java
package com.example.temporal;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import io.temporal.aws.lambda.LambdaWorker;
import io.temporal.common.WorkerDeploymentVersion;

public final class LambdaFunction implements RequestHandler<Object, Void> {

  // The callback below runs ONCE, at cold start, when the handler is constructed --
  // not per invocation. Use the 3-arg define(...) overload with an
  // InvocationConfigurator for anything that must run per invocation.
  private static final RequestHandler<Object, Void> WORKER =
      LambdaWorker.define(
          new WorkerDeploymentVersion("my-app", "build-1"),
          builder -> {
            builder.setTaskQueue("my-task-queue");
            builder.registerWorkflowImplementationTypes(MyWorkflowImpl.class);
            builder.registerActivitiesImplementations(new MyActivitiesImpl());
          });

  @Override
  public Void handleRequest(Object input, Context context) {
    return WORKER.handleRequest(input, context);
  }
}
```

The entry point is `define` (or `newHandler` for pre-built options) — not a "run"-shaped name like the other SDKs use. Temporal's [sample handler](https://github.com/temporalio/samples-java/blob/main/lambda-worker/worker/src/main/java/io/temporal/samples/lambdaworker/LambdaFunction.java) is the reference implementation.

## Lambda-tuned defaults

<!-- verified in io.temporal:temporal-aws-lambda:1.38.0, LambdaWorkerOptions.java:40-53 -->

| Setting | Lambda default |
|---|---|
| `MaxConcurrentActivityExecutionSize` | 2 |
| `MaxConcurrentWorkflowTaskExecutionSize` | 10 |
| `MaxConcurrentLocalActivityExecutionSize` | 2 |
| `MaxConcurrentNexusExecutionSize` | 5 |
| `MaxConcurrentWorkflowTaskPollers` | 2 |
| `MaxConcurrentActivityTaskPollers` | 1 |
| `MaxConcurrentNexusTaskPollers` | 1 |
| `WorkflowCacheSize` | 30 |
| `MaxWorkflowThreadCount` | 30 |
| `GracefulShutdownTimeout` | 5 seconds |
| `ShutdownDeadlineBuffer` | 7 seconds |

`MaxWorkflowThreadCount` has no counterpart in the other SDKs — Java runs Workflow code on real threads.

Eager Activities are disabled: `builder.setDisableEagerExecution(true)` (`LambdaWorkerOptions.java:258`). `ShutdownDeadlineBuffer` defaults to `GracefulShutdownTimeout` + 2s, the same relationship as the other SDKs.

## Logging — the binding must be SLF4J 1.7.x

The Java SDK compiles against `org.slf4j:slf4j-api:1.7.36`. A 2.x provider (`slf4j-simple:2.x`, Logback 1.3+) **will not bind to a 1.7 API**, and the Worker runs with no logs at all — the same silent outcome as Python's `logging.basicConfig()` no-op, by a different mechanism. Use a 1.7.x provider:

```xml
<dependency>
  <groupId>org.slf4j</groupId><artifactId>slf4j-simple</artifactId><version>1.7.36</version>
</dependency>
```

With a correct binding the module logs its own lifecycle unprompted, which is more than the other SDKs give you by default:

```
[main] INFO io.temporal.aws.lambda.LambdaWorker - Temporal Lambda worker started
  awsRequestId=<id> invokedFunctionArn=<arn> taskQueue=<tq> identity=<id>@<arn>
```

## Connection configuration

Loaded automatically from environment variables and an optional TOML config file. Public constants on `LambdaWorkerOptions`: `TEMPORAL_TASK_QUEUE`, `TEMPORAL_CONFIG_FILE`, `LAMBDA_TASK_ROOT`.

Resolution order (`LambdaWorkerOptions.resolveConfigFilePath`):

1. `TEMPORAL_CONFIG_FILE` environment variable, if set.
2. `temporal.toml` in `$LAMBDA_TASK_ROOT` (typically `/var/task`).
3. `temporal.toml` in the current working directory.

**`HOME=/tmp` is not required for Java** — unlike the Go and TypeScript examples. The module never reads `HOME`; when no file is found it passes a null path to `ClientConfig.load`, which falls back to `<user.home>/.config/temporalio/temporal.toml` and treats both a missing home directory and a `FileNotFoundException` as "empty config, no error". It is a read, not a write, so Lambda's read-only filesystem is not involved. Note also that Java reads the `user.home` **system property**, not the `HOME` environment variable, so setting `HOME` is not even the right lever — use `-Duser.home` via `JAVA_TOOL_OPTIONS` if you ever need to steer it.

## Build and package

Build an uber-jar with all dependencies bundled. A JAR is a valid zip, so it uploads directly with no extra packaging step.

**Gradle** (what the official sample uses): `./gradlew shadowJar` → `build/libs/<name>-all.jar`. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx -->

**Maven**: `maven-shade-plugin`, bound to `package` → `target/<finalName>.jar`.

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-shade-plugin</artifactId>
  <version>3.6.0</version>
  <executions>
    <execution>
      <phase>package</phase>
      <goals><goal>shade</goal></goals>
      <configuration>
        <createDependencyReducedPom>false</createDependencyReducedPom>
        <transformers>
          <transformer implementation="org.apache.maven.plugins.shade.resource.ServicesResourceTransformer"/>
        </transformers>
        <filters>
          <filter>
            <artifact>*:*</artifact>
            <excludes>
              <exclude>META-INF/*.SF</exclude>
              <exclude>META-INF/*.DSA</exclude>
              <exclude>META-INF/*.RSA</exclude>
              <exclude>module-info.class</exclude>
            </excludes>
          </filter>
        </filters>
      </configuration>
    </execution>
  </executions>
</plugin>
```

**`ServicesResourceTransformer` is mandatory, not hygiene.** The Temporal client is gRPC-based, and gRPC discovers channel providers, name resolvers, and load balancers through `META-INF/services` files that several jars each contribute to. Without merging, later copies overwrite earlier ones and the client fails at the **first invocation** with a "no functional channel service provider found"-class error — never at build time. Verify the merge before uploading:

```bash
unzip -p target/<name>.jar META-INF/services/io.grpc.ManagedChannelProvider
# expect MORE THAN ONE provider line, e.g.:
#   io.grpc.netty.shaded.io.grpc.netty.NettyChannelProvider
#   io.grpc.netty.shaded.io.grpc.netty.UdsNettyChannelProvider
```

Excluding the signature files matters too: signed-jar signatures are invalid inside an uber-jar and produce a `SecurityException` at class load.

**Match the bytecode target to the runtime.** Compiling on a newer JDK than the function's runtime needs an explicit target — `<maven.compiler.release>17</maven.compiler.release>` for `--runtime java17`. This is the Java form of the architecture/wheel mismatch: it fails at invocation, not at build.

**Watch the artifact size — Java hits the 50 MB direct-upload ceiling early.** A hello-world Worker (one Workflow, one Activity, `slf4j-simple`) measured **41 MB**, versus ~14 MB for the equivalent Python package and 10–15 MB for Go. Anything with real dependencies will exceed 50 MB and must be uploaded via S3 (`--code S3Bucket=…,S3Key=…`) rather than `--zip-file fileb://`. Check before deploying:

```bash
ls -lh target/<name>.jar
```

## Deploy the Lambda function

```bash
aws lambda create-function \
  --function-name my-temporal-worker \
  --runtime java17 \
  --architectures x86_64 \
  --handler com.example.temporal.LambdaFunction::handleRequest \
  --role <EXECUTION_ROLE_ARN> \
  --zip-file fileb://target/my-worker.jar \
  --timeout 90 \
  --memory-size 1024 \
  --environment file:///tmp/lambda-env.json
```

- `--runtime`: `java17` (or another supported Java version). <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx (line unverified) -->
- `--handler`: `fully.qualified.Class::method` — **a different format from every other SDK**, which use `module.function` / `module.export`. Point it at the method that delegates to the `LambdaWorker.define` handler. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx (line unverified) -->
- `--zip-file`: the shaded jar directly; no separate zip step. Switch to `--code S3Bucket=…,S3Key=…` once the jar exceeds 50 MB, which happens early in Java (see packaging above).
- **`HOME=/tmp` is not needed** — unlike the Go and TypeScript examples. Verified: the Java module never reads `HOME`, and a missing config file is non-fatal. → Connection configuration above.
- `--memory-size`: the docs recommend starting at `1024` because "Java Workers typically need more memory than other runtimes," then adjusting from CloudWatch. <!-- docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx (line unverified) --> A measured hello-world used **240 MB of 1024** (`Max Memory Used` in the invocation's REPORT line), so `512` is usually ample for small Workers — and since Lambda bills GB-seconds, halving memory halves the bill. Start at 1024, read the metric, then cut. <!-- measured, not documented -->

<!-- Java create-function parameters above: docs/production-deployment/worker-deployments/serverless-workers/aws-lambda.mdx (line numbers unverified); --architectures, the S3 note, and the HOME finding are from a verified deployment, not the docs. -->

**`--timeout` is a cost setting once it clears startup.** The per-SDK examples differ deliberately — 600 for Go, Python and TypeScript; 90 for Java — and both clear startup easily: a measured Java Worker bound its Task Queue **~10s** after `create-version`, JVM cold start included, against the 83s of polling a 90s deadline allows. Lambda's 3-second default is what fails this; 90 does not.

Measured cold starts are ~1s for Python and Java alike (`Init Duration` in the REPORT line).

| SDK example | Memory | Full invocation | GB-seconds |
|---|---|---|---|
| Java 90s / 1024 MB | 1 GB | ~84 s billed | ~84 |

**Memory is the multiplier, not the deadline.** 1024 MB costs 4× per second at *any* deadline; the deadline only sets how many idle seconds you buy. That is the likeliest reason Java's example caps the tail at 90s, though it is inference rather than a documented rationale. Right-sizing beats it either way — the measured Worker used **240 MB of 1024**, so read `Max Memory Used` and cut. And `Init Duration` is billed, so a shorter deadline buys proportionally more billed inits.

## Observability

No extra dependency is required: `temporal-aws-lambda` already depends on `io.temporal:temporal-opentelemetry`, `io.opentelemetry:opentelemetry-api` (BOM 1.25.0), and `io.opentelemetry.contrib:opentelemetry-aws-xray`. The helper class ships inside the module. <!-- verified in io.temporal:temporal-aws-lambda:1.38.0 pom + jar -->

Import: `io.temporal.aws.lambda.OtelLambdaWorkerConfigurationHelper`

<!-- verified with javap against io.temporal:temporal-aws-lambda:1.38.0 -->

- `configure(LambdaWorkerOptions.Builder)` — configures metrics and tracing with defaults.
- `configure(LambdaWorkerOptions.Builder, Consumer<Builder>)` — same, with customization.
- `configureMetrics(LambdaWorkerOptions.Builder, OpenTelemetry)` — metrics only (an overload also takes a service name and a `Duration` report interval).
- `configureTracing(LambdaWorkerOptions.Builder, OpenTelemetry)` — tracing only.
- `configureFlushHook(LambdaWorkerOptions.Builder, OpenTelemetry, Duration)` — registers a flush before the invocation ends.

Its own `newBuilder()` exposes `setOpenTelemetry`, `setEndpoint`, `setServiceName`, `setMetricsReportInterval`, `setFlushTimeout`, and `setFlushHook`.

```java
LambdaWorker.define(
    new WorkerDeploymentVersion("my-app", "build-1"),
    builder -> {
      builder.setTaskQueue("my-task-queue");
      builder.registerWorkflowImplementationTypes(MyWorkflowImpl.class);
      builder.registerActivitiesImplementations(new MyActivitiesImpl());
      OtelLambdaWorkerConfigurationHelper.configure(builder);
    });
```

Defaults come from the constants `DEFAULT_OTLP_ENDPOINT` and `DEFAULT_SERVICE_NAME`, and the helper reads `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_SERVICE_NAME`, and `AWS_LAMBDA_FUNCTION_NAME` from the environment. As with the other SDKs, the default endpoint is the ADOT layer's collector on `localhost:4317`.

**Flush before the deadline.** A Serverless Worker's invocation ends on a deadline rather than after a request, so telemetry buffered past that point is lost. Use `configureFlushHook` (or a report interval shorter than the invocation deadline) so metrics and spans are exported before shutdown. This matters more on Java's shorter recommended deadline (90s) than on the 600s used elsewhere.

Attach the ADOT Collector layer. Because the OpenTelemetry SDK arrives as an ordinary Maven dependency of `temporal-aws-lambda`, no language-specific auto-instrumentation layer is required for the Worker's own telemetry — the same situation as Go. <!-- inferred from the artifact's dependency graph (temporal-aws-lambda:1.38.0 pom), not stated in the docs; confirm against a deployed function before relying on it -->

`OPENTELEMETRY_COLLECTOR_CONFIG_URI=/var/task/otel-collector-config.yaml` — the `_URI` form, as with Go and TypeScript. The official Java sample packages `otel-collector-config.template.yaml` into the artifact root as `otel-collector-config.yaml` during `shadowJar`; with Maven, add it under `src/main/resources`.

For the shared Collector configuration, X-Ray enablement, and execution-role permissions, see `observability.md`.

## Diagnostic signatures

| SDK | Cause | Fix |
|---|---|---|
| Java | The SDK compiles against `slf4j-api` **1.7.36**; a 2.x provider (`slf4j-simple:2.x`, Logback 1.3+) does not bind to a 1.7 API and nothing is emitted | use a 1.7.x provider, e.g. `org.slf4j:slf4j-simple:1.7.36` |

**Java — `NullPointerException` in `ShutdownManager` on every invocation (benign).** As of `temporal-aws-lambda` 1.38.0, a normal graceful shutdown logs a `WARN` with a full stack trace:

```
[main] WARN io.temporal.internal.worker.ShutdownManager - Exception during waiting for termination
java.lang.NullPointerException: Cannot invoke "SuspendableWorker.awaitTermination(long, TimeUnit)"
  because "this.workerCommandWorker" is null
  at io.temporal.worker.WorkerFactory.lambda$awaitTermination$12(WorkerFactory.java:519)
  at io.temporal.aws.lambda.DefaultLambdaWorkerRuntime$DefaultInvocation.awaitTermination(...:82)
  at io.temporal.aws.lambda.LambdaWorker$Handler.shutdownInvocation(LambdaWorker.java:323)
```

This is **not** a failure. It appears *after* Tasks have completed, is followed by `Temporal Lambda worker stopped`, a clean `END`/`REPORT`, and no timeout; Workflows complete correctly. Do not change configuration, IAM, or timeouts in response to it. Confirm it is benign by checking that the Workflow completed and that `REPORT` shows a duration below the deadline, then ignore it.

**Java — `ClassNotFoundException` / `NoClassDefFoundError` at first invocation.** The uber-jar was built without merging `META-INF/services`, or the handler string is wrong. Check the handler format first: Java uses `fully.qualified.Class::method`, not the `module.function` form every other SDK uses. Then verify the services merge — `unzip -p <jar> META-INF/services/io.grpc.ManagedChannelProvider` should list more than one provider. → Build and package above.

**Java — exec-format or `UnsupportedClassVersionError` at first invocation.** Bytecode targets a newer JDK than the runtime. Set `<maven.compiler.release>` (or the Gradle toolchain) to match `--runtime`.
