# GCP Cloud Run — execution-model constraints

Consequences of Cloud Run's execution model: **Temporal resizes a pool of long-lived instances and can scale it to zero when its configured minimum is zero.** Temporal does *not* invoke your Worker per Task.

## Worker lifetime is an instance, not an invocation

Each pool instance runs **standard long-lived Worker code**: it connects, registers Workflows and Activities, and polls the Task Queue for its whole lifetime. There is no handler, no per-Task lifecycle, and **no serverless Worker package**. Some SDKs add optional conveniences, but none are required.

The WCI controls how many instances run; each instance manages its own polling and Task processing. For the shared WCI lifecycle, inputs, and inspection commands, see [Worker Controller Instance (WCI)](../wci.md). For Cloud Run-specific failure interpretation, see `diagnostics.md`.

## Timing and Activity limits

- **No invocation deadline.** Nothing bounds how long a Worker lives except scale-in.
- **No shutdown deadline buffer.** Cloud Run terminates instances through its own scale-in lifecycle.
- **Activities are not bounded by an invocation limit.** Their practical interruption boundary is scale-in.
- **Eager Activities are not disabled by the platform.** A pool instance holds its connection for its lifetime; confirm support against the selected SDK.

Cloud Run sends `SIGTERM` during scale-in and can send `SIGKILL` ten seconds later. Handle `SIGTERM` and configure the SDK's graceful-shutdown timeout below that window.

## What bounds an Activity instead: scale-in

**The WCI decides when to remove an instance from Task Queue activity, not from what any individual instance is doing.** It does not track how long an instance has been running or whether it is mid-Activity, so the instance Cloud Run stops may be one that is still executing work.

Graceful shutdown lets short work drain but cannot guarantee an Activity will finish. **Use Activity Heartbeats and set a Workflow-side Heartbeat Timeout** so an interrupted attempt is detected and retried promptly. Heartbeat calls without a Heartbeat Timeout do not provide timely recovery; the retry may wait until Start-to-Close expires. Set Start-to-Close above the longest expected attempt and configure a Retry Policy appropriate for the operation. Record the next unprocessed item only after processing succeeds, then resume from that Heartbeat detail on retry. The selected SDK reference includes the complete Activity options.

## Autoscaling behavior


The shared [WCI inputs](../wci.md#inputs) feed Cloud Run's rate-based pool-sizing algorithm, which combines two mechanisms:

- **Immediate** — bring up instances when a Task arrives and no Worker is free to take it (a sync match failure). Absorbs bursts without waiting for the evaluation cycle.
- **Periodic** — rate-based re-sizing. The WCI measures how fast Tasks arrive and how fast one Worker processes them, computes the instance count needed, and applies it through the Cloud Run admin API.

It sizes to a **target utilization of 80% by default** rather than loading every Worker fully, so there is headroom to take new Tasks immediately, and adds instances on top when a backlog exists.

**Scale-in is deliberately more conservative than scale-out:** it holds capacity while sync match failures are still occurring and applies a cooldown before reducing the pool. With no work, it can scale to zero; the next sync match failure or backlog scales it back up.

The scaler defaults are **minimum `0`, maximum `30`, initial count `0`, target utilization `0.8`, and scale-down stabilization duration `90s`**. Configure them in the version's Scaling and Lifecycle settings or with the Temporal CLI. The CLI couples these flags, so follow the canonical [compatibility and complete-group guidance](setup.md#step-6-register-the-worker-deployment-version).

The `90s` duration begins after the most recent sync-match failure and is only one gate in scale-in; it is not a promise that the pool reaches zero 90 seconds after registration or Workflow completion. To confirm scale-in, read the pool's requested instance count and the Worker's shutdown logs rather than waiting a fixed time.

An initial count and minimum of zero do not suppress registration. The rate-based algorithm temporarily requests at least one instance when the version is registered so its Task Queues can bind, then normal scaling can return the pool to zero. A pool that later stops growing under backlog is either at its configured maximum or at a regional Cloud Run quota.

## One Worker Pool per Worker Deployment Version

**The compute configuration names a project, region, and pool — not a revision.** Temporal runs whichever revision the pool serves at the time, which ties a pool to a single build. A new build needs a **new pool**, and the Build ID belongs in the pool name to keep that mapping visible.

Keep an older version's pool in place while Pinned Workflows are still running on it. It can sit at zero instances; its WCI scales it back up when a Task arrives for that version.

Do not deploy a new image into a pool used by a live Worker Deployment Version. Cloud Run promotes the new revision by default while the Temporal version remains unchanged, which can cause non-determinism errors for in-flight Workflows, including Pinned ones. → `versioning.md`.

## Do not share a Task Queue with long-lived Workers

**The pool scales up to cover the Task Queue's full workload even when independently managed Workers are already handling all of it**, so you run and pay for duplicate capacity.

The WCI sizes the pool from the rate of Tasks arriving on the version's Task Queues, and nothing in that measurement accounts for the long-lived Workers. Sync matching to a long-lived Worker suppresses the *immediate* scale-up, but the periodic re-sizing scales the pool up regardless. Fixing poller counts on the long-lived side does not help — use separate Task Queues.
