# testing.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Ruby | Rb# | Go | Go# |
|---------|------|--------|-----|------------|-----|------|-----|-----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | TODO | 1 | ✓ | 1 |
| Test Environment Setup | — | ✓ | 2 | ✓ | 2 | TODO | 2 | ✓ | 2 |
| Time Skipping | — | — | — | — | — | — | — | — | — |
| Activity Mocking | — | ✓ | 3 | ✓ | 3 | TODO | 3 | ✓ | 3 |
| Testing Signals and Queries | — | ✓ | 4 | ✓ | 4 | TODO | 4 | ✓ | 4 |
| Testing Failure Cases | — | ✓ | 5 | ✓ | 5 | TODO | 5 | ✓ | 5 |
| Replay Testing | — | ✓ | 6 | ✓ | 6 | TODO | 6 | ✓ | 6 |
| Activity Testing | — | ✓ | 7 | ✓ | 7 | TODO | 7 | ✓ | 7 |
| Best Practices | — | ✓ | 8 | ✓ | 8 | TODO | 8 | ✓ | 8 |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Added failure/activity testing |
| Ruby | — | Not started |
| Go | ✓ aligned | testsuite package, testify, mock activities, TestWorkflowEnvironment |

## Status

**Ruby notes:**
- Test Environment: `Temporalio::Testing::WorkflowEnvironment.start_local` (same dev server as other SDKs)
- Activity Mocking: Write fake activity classes with `activity_name :RealActivityName` to override
- Activity Testing: `Temporalio::Testing::ActivityEnvironment` for isolated activity tests
- Replay Testing: `Temporalio::Worker::WorkflowReplayer` with `replay_workflow`/`replay_workflows`
- Compatible with any test framework (minitest commonly used in samples)
- Ruby uses `Temporalio::Worker::WorkflowExecutor::ThreadPool.default` for test workers

**Go-specific notes:**
- Test Environment: `testsuite.WorkflowTestSuite` + `testsuite.TestWorkflowEnvironment` from `go.temporal.io/sdk/testsuite`
- Uses testify library (`suite.Suite`, `assert`, `mock`)
- Activity Mocking: `env.OnActivity(ActivityFunc, mock.Anything, ...).Return(result, nil)` — can use function replacement
- Testing Signals: `env.RegisterDelayedCallback` to send signals; `env.SignalWorkflow`
- Testing Queries: `env.QueryWorkflow("queryName")` returns `converter.EncodedValue`
- Testing Failure: `env.GetWorkflowError()` + `errors.As(err, &applicationErr)`
- Replay Testing: `worker.ReplayWorkflowHistory` with JSON history
- Activity Testing: `testsuite.TestActivityEnvironment` for isolated activity tests
- Time Skipping: built into TestWorkflowEnvironment (timers fire immediately)

**Intentionally missing (`—`):**
- Core column: no core testing.md exists (implementation-specific)
- Time Skipping: mentioned inline (built into test environment)

**Order alignment:** ✅ Aligned — Ruby and Go sections match Python/TypeScript order

**Style alignment:** ✅ Complete (Python, TypeScript, Go). Ruby should follow same 8-section structure.
