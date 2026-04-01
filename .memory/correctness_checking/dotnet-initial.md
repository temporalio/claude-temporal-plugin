# .NET Correctness Checking — Initial Pass

## Issues Found

| # | File | Section | Status | Issue | Proposed Fix |
|---|------|---------|--------|-------|-------------|
| 1 | patterns.md | Cancellation Handling | FIXED | Was using `catch (OperationCanceledException) when (...)`. Updated to `catch (Exception e) when (TemporalException.IsCanceledException(e))` with detached `CancellationTokenSource` for cleanup. Matches official SDK README. | Fixed during alignment pass |
| 2 | advanced-features.md | Schedules | FIXED | Constructor used lowercase `action:`/`spec:`. Fixed to PascalCase `Action:`/`Spec:` matching the `Schedule` record constructor signature. | Fixed param casing |
| 3 | advanced-features.md | Async Activity Completion | all good | Verified: `throw new CompleteAsyncException()` is correct, lives in `Temporalio.Activities` namespace. | — |
| 4 | advanced-features.md | DI | all good | Verified: `AddScopedActivities<T>()` and `AddSingletonActivities<T>()` are correct method names on `ITemporalWorkerServiceOptionsBuilder` in `Temporalio.Extensions.Hosting`. | — |
| 5 | versioning.md | Worker Versioning | all good | Verified: `WorkerDeploymentOptions` and `UseWorkerVersioning` confirmed in API docs. | — |
| 6 | data-handling.md | Search Attributes | FIXED | Was using static `SearchAttributeUpdate.ValueSet(key, value)`. Changed to preferred `key.ValueSet(value)` style per official docs. Both are valid but docs prefer the instance method. | Fixed to match official style |
| 7 | testing.md | Replay Testing | all good | Verified: `WorkflowReplayer` and `WorkflowReplayerOptions` are exact class names in `Temporalio.Worker`. `ReplayWorkflowAsync(WorkflowHistory.FromJson(...))` matches SDK README. | — |
| 8 | patterns.md | External Workflow Handle | all good | Verified: `Workflow.GetExternalWorkflowHandle<T>(id)` returns typed handle with `SignalAsync(wf => wf.Method())` and `CancelAsync()`. Matches API docs exactly. | — |
| 9 | patterns.md | Continue-as-New | all good | Verified: `Workflow.ContinueAsNewSuggested` property and `throw Workflow.CreateContinueAsNewException((T wf) => wf.RunAsync(state))`. Matches API docs exactly. | — |
| 10 | patterns.md | WaitConditionAsync | all good | Verified: `Workflow.WaitConditionAsync(() => condition, TimeSpan)` returns `Task<bool>`. `Workflow.AllHandlersFinished` is a `bool` property. Both match API docs. | — |
| 11 | patterns.md | ExecuteChildWorkflowAsync | all good | Verified: `Workflow.ExecuteChildWorkflowAsync((T wf) => wf.RunAsync(arg), ChildWorkflowOptions)`. Matches API. | — |
| 12 | patterns.md | Dynamic Handlers | all good | Verified: `[WorkflowSignal(Dynamic = true)]` with `(string name, IRawValue[] args)` params. Uses `Workflow.PayloadConverter.ToValue<T>()`. Matches docs exactly. | — |
| 13 | dotnet.md | Quick Start | all good | `AddAllActivities(new MyActivities())` and `AddWorkflow<T>()` patterns verified from samples. | — |

## Sources Consulted
- temporal-docs MCP: SDK README, API docs at dotnet.temporal.io, official .NET developer guide
- context7: sdk-dotnet release notes, samples
