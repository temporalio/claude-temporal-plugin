# Performance Bottleneck Troubleshooting via Metrics

<!-- Source: docs/troubleshooting/performance-bottlenecks.mdx -->

This reference covers diagnosing performance bottlenecks using Temporal SDK metrics: schedule-to-start latency spikes (workflow and activity), end-to-end latency spikes, workflow task execution latency, replay latency, activity execution latency spikes, task slot depletion (workflow and activity workers), network request failures, and caching issues. Each section includes root causes, diagnostic steps, and relevant Prometheus queries.

## `temporal_workflow_task_schedule_to_start_latency` Spike
<!-- docs/troubleshooting/performance-bottlenecks.mdx:31-47 -->

High `temporal_workflow_task_schedule_to_start_latency` (P95 higher than one second) represents the time between when a Workflow Task is scheduled (enqueued) and when it is picked up by a Worker for processing. <!-- docs/troubleshooting/performance-bottlenecks.mdx:33-34 -->

### Root Causes
<!-- docs/troubleshooting/performance-bottlenecks.mdx:36-39 -->

- **Insufficient Worker capacity:** Not enough Workers or overloaded Workers cannot pick up Tasks quickly enough, leading to Tasks waiting longer in the queue. <!-- docs/troubleshooting/performance-bottlenecks.mdx:36 -->
- **Worker configuration issues:** Too few pollers or Task slots. <!-- docs/troubleshooting/performance-bottlenecks.mdx:37 -->
- **High Workflow lock latency:** Many updates to a single execution can cause Workflow lock latency. Reduce the rate of Signals. <!-- docs/troubleshooting/performance-bottlenecks.mdx:38 -->
- **Network latency:** Workers in a different region from the Temporal cluster, or large payload size. <!-- docs/troubleshooting/performance-bottlenecks.mdx:39 -->

### Diagnostic Steps
<!-- docs/troubleshooting/performance-bottlenecks.mdx:43-46 -->

1. Check Worker CPU and memory usage.
2. Review Worker configuration (number of pollers, Task slots, etc.).
3. Look for any spikes in Workflow or Activity starts that might be overwhelming the system.
4. Ensure Workers are in the same region as the Temporal cluster if possible.

## `temporal_activity_schedule_to_start_latency` Spike
<!-- docs/troubleshooting/performance-bottlenecks.mdx:48-64 -->

High `temporal_activity_schedule_to_start_latency` (P95 higher than one second) represents the time between when an Activity Task is scheduled and when it is picked up by a Worker. <!-- docs/troubleshooting/performance-bottlenecks.mdx:50-51 -->

### Root Causes
<!-- docs/troubleshooting/performance-bottlenecks.mdx:53-57 -->

- **Insufficient Worker capacity:** Not enough Workers or overloaded Workers. <!-- docs/troubleshooting/performance-bottlenecks.mdx:54 -->
- **Worker configuration issues:** Too few pollers or Task slots. <!-- docs/troubleshooting/performance-bottlenecks.mdx:55 -->
- **Task Queue configuration:** Setting `TaskQueueActivitiesPerSecond` too low can limit the rate at which Activities are started. <!-- docs/troubleshooting/performance-bottlenecks.mdx:56 -->
- **Network latency:** Workers in a different region or large payload size. <!-- docs/troubleshooting/performance-bottlenecks.mdx:57 -->

### Diagnostic Steps
<!-- docs/troubleshooting/performance-bottlenecks.mdx:61-64 -->

1. Check Worker CPU and memory usage.
2. Review Worker configuration (number of pollers, Task slots, etc.).
3. Look for any spikes in Workflow or Activity starts.
4. Ensure Workers are in the same region as the Temporal cluster if possible.

## `temporal_workflow_endtoend_latency` Spike
<!-- docs/troubleshooting/performance-bottlenecks.mdx:66-83 -->

This metric represents total Workflow Execution time from Schedule to closure for a single Workflow Run. <!-- docs/troubleshooting/performance-bottlenecks.mdx:68 -->

### Root Causes
<!-- docs/troubleshooting/performance-bottlenecks.mdx:71-75 -->

- **Complex Workflows:** Many Activities or long-running Activities. <!-- docs/troubleshooting/performance-bottlenecks.mdx:71 -->
- **Workflow and Activity retries:** Frequent failures with retry delays increase end-to-end latency. <!-- docs/troubleshooting/performance-bottlenecks.mdx:72 -->
- **Worker capacity and configuration:** Overloaded Workers or insufficient capacity leads to Tasks waiting in the queue. <!-- docs/troubleshooting/performance-bottlenecks.mdx:73 -->
- **External dependencies:** Slow or unreliable databases, APIs, or services. <!-- docs/troubleshooting/performance-bottlenecks.mdx:74 -->
- **Network latency:** Workers in a different region from the Temporal cluster. <!-- docs/troubleshooting/performance-bottlenecks.mdx:75 -->

### Diagnostic Steps
<!-- docs/troubleshooting/performance-bottlenecks.mdx:79-82 -->

1. Review Workflow and Activity designs for efficiency.
2. Monitor Workers for sufficient capacity (CPU and memory).
3. Monitor external dependencies for performance.
4. Ensure Workers are in the same region as the Temporal cluster if possible.

## High `temporal_workflow_task_execution_latency`
<!-- docs/troubleshooting/performance-bottlenecks.mdx:84-104 -->

This metric represents the time taken by a Worker to execute a Workflow Task. The Temporal SDK raises a "Deadlock detected during Workflow run" error or TMPRL1101 when a Workflow Task takes more than one or two seconds to complete. <!-- docs/troubleshooting/performance-bottlenecks.mdx:86-87 -->

### Root Causes
<!-- docs/troubleshooting/performance-bottlenecks.mdx:90-95 -->

- **CPU-intensive work:** Performing CPU-intensive operations in Workflow Task. <!-- docs/troubleshooting/performance-bottlenecks.mdx:90 -->
- **Slow local Activities:** Workflow Task execution time includes Local Activity execution time. <!-- docs/troubleshooting/performance-bottlenecks.mdx:91 -->
- **Slow Workflow replay:** Workflow Task execution time includes Workflow Replay time; check `workflow_task_replay_latency`. <!-- docs/troubleshooting/performance-bottlenecks.mdx:92 -->
- **Worker resource constraints:** High CPU usage on Worker pods can slow execution. <!-- docs/troubleshooting/performance-bottlenecks.mdx:93 -->
- **Infinite loops or blocking calls:** Workflow code with infinite loops or blocking external API calls. <!-- docs/troubleshooting/performance-bottlenecks.mdx:94 -->
- **Slow data conversion:** Custom Data Converter taking too long (e.g., talking to a remote encryption service). <!-- docs/troubleshooting/performance-bottlenecks.mdx:95 -->

### Diagnostic Steps
<!-- docs/troubleshooting/performance-bottlenecks.mdx:99-103 -->

1. Monitor Worker CPU and memory utilization.
2. Ensure Workers have adequate resources and are properly scaled.
3. Consider running Workflow code in a profiler using a replayer to see where CPU cycles are spent.
4. Review Workflow code for potential optimizations or to remove blocking operations.
5. Disable deadlock detection for Data Converter: In Go, wrap with `workflow.DataConverterWithoutDeadlockDetection`. In Java, surround Data Converter code with `WorkflowUnsafe.deadlockDetectorOff`. <!-- docs/troubleshooting/performance-bottlenecks.mdx:103 -->

## High `temporal_workflow_task_replay_latency`
<!-- docs/troubleshooting/performance-bottlenecks.mdx:105-127 -->

Workflow Task replay reconstructs the Workflow's state by re-executing Workflow code from the beginning using the recorded Event History. High if it exceeds a few milliseconds. <!-- docs/troubleshooting/performance-bottlenecks.mdx:107-109 -->

### Root Causes
<!-- docs/troubleshooting/performance-bottlenecks.mdx:112-117 -->

- **Large Event Histories:** Workflows with long histories take more time to replay. <!-- docs/troubleshooting/performance-bottlenecks.mdx:112 -->
- **Data Converter performance:** Slow Data Converters, especially those that perform encryption or interact with external services. <!-- docs/troubleshooting/performance-bottlenecks.mdx:113 -->
- **Large payloads:** Activities or Signals with large payloads slow the replay process. <!-- docs/troubleshooting/performance-bottlenecks.mdx:114 -->
- **Complex Workflow logic:** Computationally intensive operations like scheduling many concurrent child Workflows or Activities. <!-- docs/troubleshooting/performance-bottlenecks.mdx:115 -->
- **Frequent cache evictions:** Workers often evicting Workflow Executions from cache leads to more replays. <!-- docs/troubleshooting/performance-bottlenecks.mdx:116 -->
- **Worker resource constraints:** High CPU or memory pressure on Worker nodes. <!-- docs/troubleshooting/performance-bottlenecks.mdx:117 -->

### Diagnostic Steps
<!-- docs/troubleshooting/performance-bottlenecks.mdx:121-126 -->

1. Monitor `temporal_workflow_task_replay_latency` metric.
2. Analyze Workflow History size; consider using Continue-As-New for long-running Workflows.
3. Optimize Data Converters.
4. Review payload sizes.
5. Profile Workflow code for CPU-intensive parts.
6. Manage Worker cache: tune cache size and eviction policies.

## `temporal_activity_execution_latency` Spike
<!-- docs/troubleshooting/performance-bottlenecks.mdx:128-144 -->

Measures time from when a Worker starts processing an Activity Task until it reports completion or failure. <!-- docs/troubleshooting/performance-bottlenecks.mdx:130 -->

### Root Causes
<!-- docs/troubleshooting/performance-bottlenecks.mdx:133-136 -->

- **Activity implementation:** Time-consuming operations or slow external API calls. <!-- docs/troubleshooting/performance-bottlenecks.mdx:133 -->
- **External dependencies:** Constrained external resource or service accessed by all Activities. <!-- docs/troubleshooting/performance-bottlenecks.mdx:134 -->
- **Worker resource constraints:** Under-resourced Worker nodes or high CPU utilization. <!-- docs/troubleshooting/performance-bottlenecks.mdx:135 -->
- **Network latency:** High latency between Workers and external services or the Temporal service. <!-- docs/troubleshooting/performance-bottlenecks.mdx:136 -->

### Diagnostic Steps
<!-- docs/troubleshooting/performance-bottlenecks.mdx:140-143 -->

1. Monitor `activity_execution_latency` metric, filtering by Activity type and Task Queue.
2. Optimize Activity implementation, especially external service or database interactions.
3. Check Worker CPU and memory utilization.
4. Examine Worker configuration: `(Max)ConcurrentActivityExecutionSize` and `(Max)WorkerActivitiesPerSecond`. <!-- docs/troubleshooting/performance-bottlenecks.mdx:143 -->

## Depletion of `temporal_worker_task_slots_available` for WorkflowWorker
<!-- docs/troubleshooting/performance-bottlenecks.mdx:145-157 -->

The `temporal_worker_task_slots_available{worker_type="WorkflowWorker"}` metric indicates available slots for executing Workflow Tasks on a Worker. <!-- docs/troubleshooting/performance-bottlenecks.mdx:147 -->

### Root Causes
<!-- docs/troubleshooting/performance-bottlenecks.mdx:150-152 -->

- **High Workflow Task Load:** More Tasks than the Worker can handle concurrently. <!-- docs/troubleshooting/performance-bottlenecks.mdx:150 -->
- **Worker Configuration:** `MaxConcurrentWorkflowTaskExecutionSize` set too low. <!-- docs/troubleshooting/performance-bottlenecks.mdx:151 -->
- **High `temporal_workflow_task_execution_latency` and `workflow_task_replay_latency`.** <!-- docs/troubleshooting/performance-bottlenecks.mdx:152 -->

### Remediation
<!-- docs/troubleshooting/performance-bottlenecks.mdx:156-157 -->

1. Monitor Worker CPU and Memory usage while increasing `(Max)ConcurrentWorkflowTaskExecutionSize` to add more execution slots.
2. Scale up Workers both vertically (increasing CPU and Memory) and horizontally (increasing Worker instances).

## Depletion of `temporal_worker_task_slots_available` for ActivityWorker
<!-- docs/troubleshooting/performance-bottlenecks.mdx:159-173 -->

The `temporal_worker_task_slots_available{worker_type="ActivityWorker"}` metric indicates available slots for executing Activity Tasks. <!-- docs/troubleshooting/performance-bottlenecks.mdx:161 -->

### Root Causes
<!-- docs/troubleshooting/performance-bottlenecks.mdx:164-167 -->

- **Blocked Activities and Zombie Activities:** Activities blocked or not returning on time. Zombie Activities occur when an Activity times out (hits its `StartToClose` or `HeartbeatTimeout` timeout) and has stopped Heartbeating but continues to run, occupying slots as more retries occur. This happens if the Activity code blocks on a downstream service call or an infinite loop, or there is a mismatch between the Activity's `StartToClose` timeout and client-side timeouts for external calls. <!-- docs/troubleshooting/performance-bottlenecks.mdx:164-166 -->
- **Resource Utilization:** High CPU or memory usage on Workers can cause Activities to block and not release slots. <!-- docs/troubleshooting/performance-bottlenecks.mdx:167 -->

### Remediation
<!-- docs/troubleshooting/performance-bottlenecks.mdx:171-173 -->

1. Monitor Worker CPU and Memory usage while increasing `(Max)ConcurrentActivityExecutionSize` to add more execution slots.
2. Add client-side timeout to downstream API client.
3. Review Task code to ensure Tasks complete within a reasonable time measured by `temporal_activity_execution_latency`.

## Network Request Issues

### High `temporal_long_request_failure`
<!-- docs/troubleshooting/performance-bottlenecks.mdx:181-193 -->

Counts failed RPC long poll requests for `PollWorkflowTaskQueue`, `PollActivityTaskQueue`, and `GetWorkflowExecutionHistory` (when polling new events). <!-- docs/troubleshooting/performance-bottlenecks.mdx:183 -->

Root causes: network issues (firewalls, proxies), rate limiting (`ResourceExhausted` status code), server errors. <!-- docs/troubleshooting/performance-bottlenecks.mdx:185-187 -->

Diagnostic steps: <!-- docs/troubleshooting/performance-bottlenecks.mdx:191-193 -->
1. Check the operation and status/code tag of the metric.
2. If `ResourceExhausted`, review rate limits.
3. Check network connection between Client and Server.

### High `temporal_request_failure`
<!-- docs/troubleshooting/performance-bottlenecks.mdx:195-212 -->

Counts failed RPC requests made by the Temporal Client. <!-- docs/troubleshooting/performance-bottlenecks.mdx:197 -->

Root causes: network issues, client errors (misconfiguration, resource exhaustion), operation errors (acting on closed Workflow Executions), rate limiting (`ResourceExhausted`), request size limit (2MB blob size limit), server errors. <!-- docs/troubleshooting/performance-bottlenecks.mdx:200-205 -->

### High `temporal_request_latency`
<!-- docs/troubleshooting/performance-bottlenecks.mdx:214-231 -->

Measures latency of gRPC requests made by the Temporal Client. <!-- docs/troubleshooting/performance-bottlenecks.mdx:216 -->

Root causes: network latency (physical distance, network conditions), network transfer time (large payloads in `RespondWorkflowTaskCompleted`), resource exhaustion, client configuration issues, server load. <!-- docs/troubleshooting/performance-bottlenecks.mdx:219-223 -->

## Caching Issues

### `temporal_sticky_cache_size`
<!-- docs/troubleshooting/performance-bottlenecks.mdx:259-278 -->

Represents the number of Workflow executions currently cached in a Worker's memory. There is a direct relationship between sticky cache size and Worker memory consumption. <!-- docs/troubleshooting/performance-bottlenecks.mdx:261-266 -->

Monitor alongside Worker memory usage. A sudden increase in `sticky_cache_size` can correlate with increased memory consumption. If memory consumption is too high, reduce the maximum sticky cache size. If available memory exists and performance improvement is desired, increase it. <!-- docs/troubleshooting/performance-bottlenecks.mdx:274-278 -->

### `temporal_sticky_cache_hit` and `temporal_sticky_cache_miss`
<!-- docs/troubleshooting/performance-bottlenecks.mdx:280-292 -->

A "hit" means the Worker finds the Workflow in its cache, allowing immediate processing without fetching the full Event History and Replaying. A "miss" means it must fetch the Event History and Replay. A high rate of cache hits with low misses indicates efficient scheduling. <!-- docs/troubleshooting/performance-bottlenecks.mdx:288-292 -->

### `temporal_sticky_cache_total_forced_eviction`
<!-- docs/troubleshooting/performance-bottlenecks.mdx:294-305 -->

A "forced eviction" means a Workflow Execution was removed from the cache before it completed, typically because the cache was full. A high rate of forced evictions could indicate that cache size is too small for the workload; increase the `WorkflowCacheSize` setting if Worker resources allow. <!-- docs/troubleshooting/performance-bottlenecks.mdx:301-305 -->

## Worker Log Signals

### `[TMPRL1104]` slow Workflow Task warning

Workers log a `[TMPRL1104]` warning when a Workflow Task takes longer than a threshold, 5 seconds by default.
`TEMPORAL_WORKFLOW_TASK_DURATION_WARN_SECONDS` overrides the default; an unparsable value falls back to 5 (Go, Rust).

### Persistent poll error warning (autoscaling pollers)

Workers using autoscaling pollers log `Task polling has encountered errors continuously; the worker will continue retrying` once poll errors have lasted 60 seconds.
Repeat warnings back off exponentially (factor 2) up to a 15 minute cap, and a successful poll resets the timer.
The warning is only emitted for `PollerBehavior::Autoscaling`.

