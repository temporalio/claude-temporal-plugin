# .NET Correctness Checking — Initial Pass

## Issues Found

| # | File | Section | Status | Issue | Proposed Fix |
|---|------|---------|--------|-------|-------------|
| 1 | patterns.md | Cancellation Handling | needs fixes | Uses `catch (OperationCanceledException) when (Workflow.CancellationToken.IsCancellationRequested)`. Official docs use `catch (Exception e) when (TemporalException.IsCanceledException(e))` with `using var detachedCancelSource = new CancellationTokenSource()` + `CancellationToken = detachedCancelSource.Token` for cleanup activities. | Update to match official cancellation pattern from SDK README |
| 2 | advanced-features.md | Schedules | needs fixes | Constructor uses `new Schedule(action: ..., spec: ...)` with lowercase named params. Records in C# use PascalCase: `new Schedule(Action: ..., Spec: ...)`. Also, `ScheduleActionStartWorkflow.Create` second param is `WorkflowOptions` object, not `new(id:..., taskQueue:...)`. | Fix param casing and use proper `WorkflowOptions` syntax: `new(id: "...", taskQueue: "...")` which is actually fine as target-typed new for WorkflowOptions. But fix Schedule constructor casing. |
| 3 | advanced-features.md | Async Activity Completion | needs fixes | Uses `throw new CompleteAsyncException()`. Need to verify this is the correct class name. The Python SDK uses `activity.raise_complete_async()`. | Verify class name from API docs. It should be `throw new CompleteAsyncException()` from `Temporalio.Exceptions`. |
| 4 | advanced-features.md | DI | needs fixes | Uses `AddScopedActivities<T>()` and `AddSingletonActivities<T>()`. Need to verify exact method names from `Temporalio.Extensions.Hosting`. | Verify method names from docs/samples. |
| 5 | versioning.md | Worker Versioning | needs fixes | Uses `DeploymentOptions = new WorkerDeploymentOptions(...)` and `UseWorkerVersioning = true`. Need to verify exact property names as the API may have changed between versions. | Verify against latest SDK release (1.11.0 GA'd deployment versioning). |
| 6 | data-handling.md | Search Attributes | needs fixes | Uses `SearchAttributeUpdate.ValueSet(SearchAttributeKey.CreateKeyword("OrderStatus"), "completed")` for upsert. Need to verify this matches the `UpsertTypedSearchAttributes` API. | Verify against official docs example. |
| 7 | testing.md | Replay Testing | needs fixes | Uses `WorkflowReplayer` class and `WorkflowReplayerOptions`. Need to verify exact class names. | Verify from SDK README. |
| 8 | patterns.md | External Workflow Handle | all good | Verified: `Workflow.GetExternalWorkflowHandle<T>(id)` returns typed handle with `SignalAsync(wf => wf.Method())` and `CancelAsync()`. Matches API docs exactly. | — |
| 9 | patterns.md | Continue-as-New | all good | Verified: `Workflow.ContinueAsNewSuggested` property and `throw Workflow.CreateContinueAsNewException((T wf) => wf.RunAsync(state))`. Matches API docs exactly. | — |
| 10 | patterns.md | WaitConditionAsync | all good | Verified: `Workflow.WaitConditionAsync(() => condition, TimeSpan)` returns `Task<bool>`. `Workflow.AllHandlersFinished` is a `bool` property. Both match API docs. | — |
| 11 | patterns.md | ExecuteChildWorkflowAsync | all good | Verified: `Workflow.ExecuteChildWorkflowAsync((T wf) => wf.RunAsync(arg), ChildWorkflowOptions)`. Matches API. | — |
| 12 | patterns.md | Dynamic Handlers | all good | Verified: `[WorkflowSignal(Dynamic = true)]` with `(string name, IRawValue[] args)` params. Uses `Workflow.PayloadConverter.ToValue<T>()`. Matches docs exactly. | — |
| 13 | dotnet.md | Quick Start | all good | `AddAllActivities(new MyActivities())` and `AddWorkflow<T>()` patterns verified from samples. | — |

## Sources Consulted
- temporal-docs MCP: SDK README, API docs at dotnet.temporal.io, official .NET developer guide
- context7: sdk-dotnet release notes, samples
