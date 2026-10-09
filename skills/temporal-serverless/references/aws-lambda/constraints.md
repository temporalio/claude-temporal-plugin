# AWS Lambda — Execution-model constraints


This reference describes the invocation-based AWS Lambda model. For concepts shared across compute providers, see [Serverless Workers — Concepts](../concepts.md).

## Worker model

A Serverless Worker is a Temporal Worker that runs on serverless compute instead of a long-lived process.
There is no always-on infrastructure to provision or scale. Temporal invokes the Worker when Tasks arrive on a Task Queue, and the Worker shuts down when the work is done.

A Serverless Worker uses the same Temporal SDKs as a traditional long-lived Worker. It registers Workflows and Activities the same way. The difference is in the lifecycle: instead of the Worker starting and polling continuously, Temporal invokes the Serverless Worker on demand, the Worker starts, processes available Tasks, and then shuts down.

Serverless Workers require Worker Versioning. Each Serverless Worker must be associated with a Worker Deployment Version that has a compute provider configured.

Each Workflow must have an `AutoUpgrade` or `Pinned` versioning behavior, set per-Workflow or as a Worker-level default.

## How Serverless invocation works

With long-lived Workers, the Worker process starts, connects to Temporal, and polls a Task Queue for work. Temporal does not need to know anything about the Worker's infrastructure.

With Serverless Workers, Temporal starts the Worker.

### Invocation flow

The invocation flow works as follows:

1. A Task is submitted (for example, `StartWorkflow` or `ScheduleActivity`).
2. The Matching Service attempts to route the Task directly to an available Worker (a sync match).
3. If a Worker is available, the Task is routed to that Worker.
4. If no Worker is available (sync match fails), the Matching Service pushes a signal to the WCI, and the WCI invokes the configured compute provider.
5. The Serverless Worker starts, creates a Temporal Client, and begins polling the Task Queue.
6. The Worker processes available Tasks until it exits (see Worker lifecycle).

Each invocation is independent. The Worker creates a fresh client connection on every invocation. There is no connection reuse or shared state across invocations.

## Autoscaling

The shared [WCI inputs](../wci.md#inputs) cause Lambda function invocations when Tasks need Workers. Each Worker exits when its invocation finishes, allowing the Lambda fleet to scale to zero.

## Scaling with long-lived Workers

Serverless Workers can share a Task Queue with long-lived Workers. Because Serverless Workers are only invoked on sync match failure, Serverless Workers only pick up Tasks that no long-lived Worker was available to handle. In practice, the Serverless Workers act as spillover capacity for the long-lived fleet.

**Warning:** If you configure Serverless and long-lived Workers on the same Task Queue, do not enable dynamic scaling on the long-lived Workers. The two groups cannot coordinate their scaling behavior. If both scale dynamically, the long-lived Workers may scale up to handle the same Tasks that Temporal is simultaneously invoking Serverless Workers for, leading to unnecessary invocations and unpredictable scaling.

## Worker lifecycle

A single Serverless Worker invocation has three phases: init, work, and shutdown.

### Init phase

The Worker initializes and establishes a client connection to Temporal.

### Work phase

The Worker polls the Task Queue and processes Tasks.

### Shutdown phase

The Worker stops polling, waits for in-flight Tasks to finish, and runs any shutdown hooks (for example, OpenTelemetry telemetry flushes). Shutdown begins before the invocation deadline so the Worker can exit cleanly before the compute provider forcibly terminates the execution environment.

### Tuning for long-running Activities

If your Worker handles long-running Activities, set these three values together:

- **Worker stop timeout > longest Activity runtime.** Gives in-flight Activities enough time to finish after polling stops.
- **Shutdown deadline buffer > Worker stop timeout + shutdown hook time.** Ensures the drain and any shutdown hooks complete before the compute provider terminates the environment.
- **Invocation deadline > longest Activity runtime + shutdown deadline buffer.** Set on the compute provider to give each invocation enough total runtime.

If your longest-running Activity runs longer than half the maximum invocation deadline, use Activity Heartbeats to record the state of the Activity execution so that the next retry can pick up where it left off.

Example: if your longest Activity runtime is 5 minutes, and your shutdown hooks take 3 seconds, set the Worker stop timeout to more than 5 minutes, and the shutdown deadline buffer to more than 303 seconds (5 minutes + 3 seconds). Set your invocation deadline to at least 10 minutes and 3 seconds.

The Worker stop timeout controls how long the Worker waits for in-flight Tasks to finish after it stops polling. The shutdown deadline buffer controls how much time before the invocation deadline the Worker stops polling for Tasks.

Raising only the shutdown deadline buffer makes the Worker stop polling earlier, but does not give in-flight Tasks any more time to complete.

Raising only the Worker stop timeout does not make the Worker stop polling earlier, which means the compute provider might terminate the Worker before the full stop timeout completes.

## Failure handling

Serverless Workers rely on Temporal's standard retry and timeout semantics to recover from failures.

### Worker crash

If a Worker invocation crashes (out of memory, unhandled exception, etc.):

- The Activity Timeout fires after the configured duration.
- Temporal retries the Activity on a different Worker invocation.
- No manual intervention is required.

### Provider concurrency limit

If the compute provider's concurrency limit is reached (for example, AWS Lambda account concurrency):

- Further invocations from the WCI fail.
- Tasks remain in the Task Queue backlog. No data loss occurs.
- Processing slows until concurrency frees up.

### Resource exhaustion across Activity slots

By default, a single Worker invocation may run multiple Activity slots. A crash or resource exhaustion in one Activity can affect other Activities running in the same invocation.

To isolate Activities from each other:

- Split Workflow and Activity Workers into separate compute functions.
- Set Activity slots to 1 per invocation.

With single-slot configuration, each Activity gets a dedicated execution environment.

## Constraints


| Constraint | Detail |
|---|---|
| Activity duration | Must complete within the compute provider's invocation limit (minus shutdown deadline buffer). For AWS Lambda, the maximum is 15 minutes. |
| Workflow duration | No limit. Workflows of any duration work, regardless of the invocation timeout. A Workflow runs across as many invocations as needed. |
| Worker code | Same Temporal SDK Worker code, using the serverless Worker package for your SDK. |
| Versioning | Worker Versioning is required. Each Workflow must have an `AutoUpgrade` or `Pinned` behavior, set per-Workflow or as a Worker-level default. |

## Worker Versioning with Serverless Workers

Serverless Workers require Worker Versioning, and the compute provider must invoke a stable, immutable build for each Worker Deployment Version. With AWS Lambda, this means aligning two versioning systems:

- **Temporal Worker Deployment Versions** — identified by deployment name and Build ID. Each Workflow runs against a specific Worker Deployment Version (Pinned) or moves between them on routing changes (Auto-Upgrade).
- **AWS Lambda function versions** — immutable numbered snapshots of your Lambda function code (`1`, `2`, `3`, ...).

For production workloads, map each Worker Deployment Version to exactly one Lambda function version, and configure the compute provider with the qualified versioned ARN for that Lambda version (for example, `arn:aws:lambda:us-east-1:123:function:my-worker:5`).

For development or non-critical workloads, you can use an unqualified ARN to iterate without publishing a new Lambda function version each time.

**Caution:** An unqualified ARN (no version suffix) points at `$LATEST`, which changes on every redeploy. Without a versioned ARN, deploying replay-unsafe code causes non-determinism errors for in-flight Workflows, even for Workflows annotated as Pinned.

The choice of Pinned or Auto-Upgrade controls how Workflows move between Worker Deployment Versions in Temporal. It does not change how a Worker Deployment Version targets Lambda. Both behaviors expect a versioned ARN that points at one immutable Lambda function version.

| Versioning Behavior | With versioned Lambda ARN | Without versioned Lambda ARN |
|---|---|---|
| **Pinned** | Existing Workflows stay on their original Lambda function version until they complete. | Existing Workflows stay on their original Worker Deployment Version, but the underlying Lambda code has already changed since `$LATEST` updated at redeploy. The new code must be replay-compatible. |
| **Auto-Upgrade** | Existing Workflows move to the new Worker Deployment Version and its new Lambda function version at the next Workflow Task after you move the Current Version. | The Lambda redeploy already changed the code for all versions. Setting the Current Version only changes routing, not which code runs. |

See `versioning.md` for the step-by-step `aws lambda publish-version` workflow and `setup.md` (Step 4) for how to configure the compute provider with a versioned ARN.

## Why use Serverless Workers?


- **Reduce operational overhead.** No always-on infrastructure to manage and no autoscaling policies to tune. Temporal and the compute provider handle invocation and scaling.
- **Get started faster.** Deploying a Worker is as simple as deploying a function. No Kubernetes, container orchestration, or scaling strategy required.
- **Scale automatically.** The compute provider handles scaling natively. When traffic drops, instances scale down. When there is no work, there is no compute running.
- **Pay only for what you use.** Workers run only when Tasks are available. For low or intermittent volume workloads, this pay-per-invocation model can significantly reduce compute costs.

## When to use Serverless Workers


Good fit when:

- Workloads are bursty or event-driven (order processing, notifications, webhook handlers).
- Traffic is low or intermittent.
- You want a simpler getting-started path.
- Your organization has standardized on serverless.
- You serve multiple tenants with infrequent workloads.

May not be ideal when:


- Activities are long-running and cannot be interrupted. AWS Lambda has a 15-minute execution limit. Activities that run longer and cannot be broken into smaller steps need a different hosting strategy or a provider with longer limits.
- Workloads require sustained high throughput. Long-lived Workers on dedicated compute may be more cost-effective and performant.
- You need persistent connections. Some features require a persistent connection between the Worker and Temporal, which serverless invocations do not maintain.

## How Serverless Workers compare to long-lived Workers


|                | Long-lived Worker | Serverless Worker |
|---|---|---|
| **Lifecycle** | Long-lived process that runs continuously. | Invoked on demand. Starts and stops per invocation. |
| **Scaling** | You manage scaling (Kubernetes HPA, instance count, etc.). | Temporal invokes additional instances as needed, within the compute provider's concurrency limits. |
| **Connection** | Persistent connection to Temporal. | Fresh connection on each invocation. |

