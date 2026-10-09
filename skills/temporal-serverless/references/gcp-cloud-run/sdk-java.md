# Java SDK on GCP Cloud Run


Use this reference for Java-specific Worker construction, versioning behavior, connection configuration, image packaging, and scale-in safety. For shared Cloud Run execution constraints, deployment lifecycle, permissions, versioning, observability, and diagnostics, see `constraints.md`, `setup.md`, `iam.md`, `versioning.md`, `observability.md`, and `diagnostics.md`. Scoping (Namespace, GCP project, region), the API-key hand-off, IAM, registration, and verification are the same for every SDK and are defined once in `SKILL.md` and `setup.md`; do not vary them per SDK. This guide's sample is one Workflow that takes a string and returns `Hello, <name>!`, which is what `setup.md` Step 8 verifies.

## Install and scaffold

Use Java 21 and the standard Maven layout. Every Java file starts with `package example;`:

```text
<APP_DIR>/
  pom.xml  Dockerfile  .gcloudignore
  src/main/java/example/Main.java
  src/main/java/example/GreetingWorkflow.java
  src/main/java/example/GreetingWorkflowImpl.java
  src/main/java/example/GreetingActivities.java
  src/main/java/example/GreetingActivitiesImpl.java
  src/main/resources/logback.xml
```

The complete `pom.xml`, with the SDK and logging provider pinned:

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>example</groupId>
  <artifactId>worker</artifactId>
  <version>1</version>

  <properties>
    <maven.compiler.release>21</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>

  <dependencies>
    <dependency>
      <groupId>io.temporal</groupId>
      <artifactId>temporal-sdk</artifactId>
      <version>1.40.0</version>
    </dependency>
    <dependency>
      <groupId>ch.qos.logback</groupId>
      <artifactId>logback-classic</artifactId>
      <version>1.5.38</version>
    </dependency>
  </dependencies>

  <build>
    <finalName>worker</finalName>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-shade-plugin</artifactId>
        <version>3.6.1</version>
        <executions>
          <execution>
            <phase>package</phase>
            <goals><goal>shade</goal></goals>
            <configuration>
              <createDependencyReducedPom>false</createDependencyReducedPom>
              <transformers>
                <transformer implementation="org.apache.maven.plugins.shade.resource.ServicesResourceTransformer" />
                <transformer implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
                  <mainClass>example.Main</mainClass>
                </transformer>
              </transformers>
            </configuration>
          </execution>
        </executions>
      </plugin>
    </plugins>
  </build>
</project>
```

The `temporal-serviceclient` classes used below are a transitive dependency of `temporal-sdk`; do not omit them when inspecting or shading the application.

## Inspect the versioning API before generating code

```bash
mvn -q dependency:get -Dartifact=io.temporal:temporal-sdk:1.40.0:jar:sources
mvn -q dependency:get -Dartifact=io.temporal:temporal-serviceclient:1.40.0:jar:sources
unzip -o ~/.m2/repository/io/temporal/temporal-sdk/1.40.0/temporal-sdk-1.40.0-sources.jar \
  'io/temporal/worker/WorkerDeploymentOptions.java' 'io/temporal/common/WorkerDeploymentVersion.java' -d <SCRATCH_DIR>/src
```

If the project intentionally uses another SDK version, substitute that exact version everywhere it appears in these commands and in `pom.xml`, and inspect its sources before generating code.

## Versioned Worker

Set `WorkerDeploymentOptions` on `WorkerOptions`. The Worker reads its connection settings and Task Queue from the environment so one image runs against any Namespace:

```java
package example;

import io.temporal.client.WorkflowClient;
import io.temporal.client.WorkflowClientOptions;
import io.temporal.common.VersioningBehavior;
import io.temporal.common.WorkerDeploymentVersion;
import io.temporal.serviceclient.WorkflowServiceStubs;
import io.temporal.serviceclient.WorkflowServiceStubsOptions;
import io.temporal.worker.Worker;
import io.temporal.worker.WorkerDeploymentOptions;
import io.temporal.worker.WorkerFactory;
import io.temporal.worker.WorkerOptions;
import java.util.concurrent.TimeUnit;

public final class Main {
  public static void main(String[] args) {
    String deploymentName = requireEnv("TEMPORAL_DEPLOYMENT_NAME");
    String buildId = requireEnv("TEMPORAL_BUILD_ID");
    String taskQueue = requireEnv("TEMPORAL_TASK_QUEUE");
    String apiKey = requireEnv("TEMPORAL_API_KEY");

    WorkflowServiceStubs service =
        WorkflowServiceStubs.newServiceStubs(
            WorkflowServiceStubsOptions.newBuilder()
                .setTarget(requireEnv("TEMPORAL_ADDRESS"))
                .setEnableHttps(true)
                .addApiKey(() -> apiKey)
                .build());

    WorkflowClient client =
        WorkflowClient.newInstance(
            service,
            WorkflowClientOptions.newBuilder()
                .setNamespace(requireEnv("TEMPORAL_NAMESPACE"))
                .build());

    WorkerFactory factory = WorkerFactory.newInstance(client);
    Worker worker =
        factory.newWorker(
            taskQueue,
            WorkerOptions.newBuilder()
                .setDeploymentOptions(
                    WorkerDeploymentOptions.newBuilder()
                        .setUseVersioning(true)
                        .setVersion(new WorkerDeploymentVersion(deploymentName, buildId))
                        .setDefaultVersioningBehavior(VersioningBehavior.PINNED)
                        .build())
                .build());

    worker.registerWorkflowImplementationTypes(GreetingWorkflowImpl.class);
    worker.registerActivitiesImplementations(new GreetingActivitiesImpl());

    Runtime.getRuntime().addShutdownHook(new Thread(() -> {
      factory.shutdown();
      factory.awaitTermination(8, TimeUnit.SECONDS);
    }));
    factory.start();
    System.out.printf(
        "Worker started deployment=%s build=%s taskQueue=%s%n",
        deploymentName, buildId, taskQueue);
  }

  private static String requireEnv(String name) {
    String value = System.getenv(name);
    if (value == null || value.isBlank()) {
      throw new IllegalStateException(name + " must be set");
    }
    return value;
  }
}
```

`WorkerDeploymentVersion`'s two arguments are the deployment name and the build ID, and both must match the version created with `temporal worker deployment create-version` exactly. → `setup.md` Step 6.

## Versioning behavior

Every Workflow needs `VersioningBehavior.PINNED` or `AUTO_UPGRADE`. `Main` sets `PINNED` as the default with `setDefaultVersioningBehavior`, so the sample needs no annotation. To override it for one Workflow, annotate its method, for example `run` in `GreetingWorkflowImpl` below, with `@WorkflowVersioningBehavior(VersioningBehavior.PINNED)`.

**A Version set with no behavior fails at runtime**, not at build time.

## Connection configuration

`addApiKey` takes a **supplier**, called on every request, so a key can be rotated by returning a new value instead of restarting the Worker — worth using on a long-lived pool instance, where a restart is not free.

Java uses gRPC/Netty and the JVM truststore, so it is unaffected by the `NativeCertsNotFound` failure the Rust-core SDKs hit.

## Image packaging

The `pom.xml` above builds an executable fat jar, `target/worker.jar`. Keep `ServicesResourceTransformer`: without it, the shaded gRPC providers disappear at runtime.

Build and run it in a Java 21 image:

```dockerfile
FROM maven:3.9.11-eclipse-temurin-21 AS build
WORKDIR /src
COPY pom.xml ./
RUN mvn -q dependency:go-offline
COPY src ./src
RUN mvn -q -DskipTests package

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /src/target/worker.jar ./worker.jar
CMD ["java", "-XX:MaxRAMPercentage=75", "-jar", "/app/worker.jar"]
```

Save the following alongside the Dockerfile as `.gcloudignore` so Cloud Build does not upload local build output or IDE metadata:

```gitignore
.git
.gitignore
.idea
target
*.iml
terraform/
.terraform/
*.tfstate*
```

Cloud Run Worker Pools run this image as `linux/amd64`. The Dockerfile's `-XX:MaxRAMPercentage=75` lets the heap use 75% of the instance's memory instead of the JVM's default quarter. Pools default to 512 MiB, which is enough for this sample; raise `--memory` (`setup.md` Step 4) for heavier Workers.

## Graceful shutdown on scale-in

Register the JVM shutdown hook before `factory.start()`, as in the versioned Worker example. Cloud Run's `SIGTERM` starts the hook; `factory.shutdown()` stops polling, and `awaitTermination` keeps the hook alive while received Tasks drain. `shutdown()` alone is asynchronous, so omitting the wait lets the JVM exit before draining. Do not use `shutdownNow()` as the normal signal path.

## Keep Activities safe across scale-in

Apply the Heartbeat-resume invariant from `constraints.md`. This is the sample's only Workflow: it takes one string and calls one Activity with Heartbeat and retry options.

Each type goes in its own file under `src/main/java/example/`, starting with `package example;`:

```java
package example;

import io.temporal.activity.ActivityInterface;
import io.temporal.activity.ActivityOptions;
import io.temporal.common.RetryOptions;
import io.temporal.workflow.Workflow;
import io.temporal.workflow.WorkflowInterface;
import io.temporal.workflow.WorkflowMethod;
import java.time.Duration;

@WorkflowInterface
public interface GreetingWorkflow {
  @WorkflowMethod
  String run(String name);
}

@ActivityInterface
public interface GreetingActivities {
  String process(String name);
}

public class GreetingWorkflowImpl implements GreetingWorkflow {
  private final GreetingActivities activities =
      Workflow.newActivityStub(
          GreetingActivities.class,
          ActivityOptions.newBuilder()
              .setStartToCloseTimeout(Duration.ofMinutes(10))
              .setHeartbeatTimeout(Duration.ofSeconds(10))
              .setRetryOptions(
                  RetryOptions.newBuilder()
                      .setInitialInterval(Duration.ofSeconds(1))
                      .setMaximumAttempts(5)
                      .build())
              .build());

  @Override
  public String run(String name) {
    return activities.process(name);
  }
}
```

The Workflow type is the interface's simple name, `GreetingWorkflow`.

The Activity records the next step to run, so a retry after scale-in resumes there instead of starting over. Each step must be safe to repeat:

```java
package example;

import io.temporal.activity.Activity;
import io.temporal.activity.ActivityExecutionContext;
import java.util.List;

public class GreetingActivitiesImpl implements GreetingActivities {
  @Override
  public String process(String name) {
    List<String> steps = List.of("validate", "compose", "record");
    ActivityExecutionContext context = Activity.getExecutionContext();
    int startIndex = context.getHeartbeatDetails(Integer.class).orElse(0);

    for (int i = startIndex; i < steps.size(); i++) {
      // ... run steps.get(i) for name
      context.heartbeat(i + 1);
    }
    return "Hello, " + name + "!";
  }
}
```

→ `constraints.md` for what else follows from the pool model.

## Logging and diagnostic signatures

If the application uses `logback-classic`, include an explicit `src/main/resources/logback.xml`. Without one, Logback's basic configuration sets the root logger to DEBUG; grpc-java's Netty transport has a DEBUG frame logger that can emit outbound HTTP/2 headers. Keep transport categories above DEBUG wherever bearer credentials are used:

```xml
<configuration>
  <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
    <encoder>
      <pattern>%date %-5level %logger{36} - %msg%n</pattern>
    </encoder>
  </appender>

  <logger name="io.grpc" level="WARN" />
  <logger name="io.netty" level="WARN" />
  <logger name="io.temporal" level="INFO" />

  <root level="INFO">
    <appender-ref ref="STDOUT" />
  </root>
</configuration>
```

The SDK logs through SLF4J. The `pom.xml` above pins `logback-classic` 1.5.38 as the provider: it brings `slf4j-api` 2.0.x, which Maven selects over the SDK's transitive 1.7.36, and with `temporal-sdk` 1.40.0 it binds and logs. Do not downgrade to logback 1.2.x to match the SDK's older SLF4J line.

| Log signature | Meaning / action |
|---|---|
| No log lines at all, not even the `Worker started` line | The container never started the Worker; check the pool's revision status and startup errors. |
| Only the `Worker started` line, even after Tasks run | Normal at INFO: a healthy Java Worker can complete Workflows and Activities without per-task SDK log lines. Confirm Task execution from the Workflow's event history. The startup line is printed to stdout, so it shows the container is running, not that SLF4J is bound; an unbound SLF4J prints `SLF4J(W): No SLF4J providers were found` at startup. |
| `StatusRuntimeException: UNAVAILABLE` in `main` at startup, then exit | `factory.start()` connects eagerly and could not reach Temporal, so Cloud Run keeps restarting the instance. Check `TEMPORAL_ADDRESS`, including `:7233`, and the pool's outbound network access. A second `UNAVAILABLE` from the shutdown hook follows from the first. |
| `NettyClientHandler ... OUTBOUND HEADERS`, or an `authorization` or `Bearer` value in Cloud Logging | Unsafe transport DEBUG logging is enabled. Raise `io.grpc` and `io.netty` to WARN, and rotate the exposed Temporal API key. |
| `UNAUTHENTICATED` | Check the Secret Manager mount and the key's Namespace permissions. |

## Observability

For the optional Cloud Run OpenTelemetry path, add the released helper alongside the same SDK version:

```xml
<dependency>
  <groupId>io.temporal</groupId>
  <artifactId>temporal-gcp-cloud-run-opentelemetry</artifactId>
  <version>1.40.0</version>
</dependency>
```

Register the plugin on the service stubs so it propagates to the client and Worker, and flush it in the shutdown hook after the Worker has drained. In `Main`, replace the service stubs and the shutdown hook with:

```java
CloudRunOpenTelemetryPlugin otelPlugin =
    CloudRunOpenTelemetryPlugin.newBuilder().build();
WorkflowServiceStubs service =
    WorkflowServiceStubs.newServiceStubs(
        WorkflowServiceStubsOptions.newBuilder()
            .setTarget(requireEnv("TEMPORAL_ADDRESS"))
            .setEnableHttps(true)
            .addApiKey(() -> apiKey)
            .setPlugins(otelPlugin)
            .build());

// ...

Runtime.getRuntime().addShutdownHook(new Thread(() -> {
  factory.shutdown();
  factory.awaitTermination(8, TimeUnit.SECONDS);
  otelPlugin.newFlushHook().run(Duration.ofSeconds(1));
  service.shutdown();
}));
```

The drain and flush together must fit Cloud Run's termination window; see `observability.md`.

Import `io.temporal.gcp.cloudrun.opentelemetry.CloudRunOpenTelemetryPlugin` and `java.time.Duration`. The helper defaults to the local OTLP/gRPC Collector endpoint. Use the multi-container topology, IAM, and shutdown order in `observability.md`; do not add the plugin unless that Collector path is enabled.
