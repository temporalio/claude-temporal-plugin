# testing.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Ruby | Rb# | Go |
|---------|------|--------|-----|------------|-----|------|-----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | TODO | 1 | |
| Test Environment Setup | — | ✓ | 2 | ✓ | 2 | TODO | 2 | |
| Time Skipping | — | — | — | — | — | — | — | |
| Activity Mocking | — | ✓ | 3 | ✓ | 3 | TODO | 3 | |
| Testing Signals and Queries | — | ✓ | 4 | ✓ | 4 | TODO | 4 | |
| Testing Failure Cases | — | ✓ | 5 | ✓ | 5 | TODO | 5 | |
| Replay Testing | — | ✓ | 6 | ✓ | 6 | TODO | 6 | |
| Activity Testing | — | ✓ | 7 | ✓ | 7 | TODO | 7 | |
| Best Practices | — | ✓ | 8 | ✓ | 8 | TODO | 8 | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Added failure/activity testing |
| Ruby | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created
- Ruby column: all TODO — Ruby files not yet created

**Intentionally missing (`—`):**
- Core column: no core testing.md exists (implementation-specific)

**Ruby notes:**
- Test Environment: `Temporalio::Testing::WorkflowEnvironment.start_local` (same dev server as other SDKs)
- Activity Mocking: Write fake activity classes with `activity_name :RealActivityName` to override
- Activity Testing: `Temporalio::Testing::ActivityEnvironment` for isolated activity tests
- Replay Testing: `Temporalio::Worker::WorkflowReplayer` with `replay_workflow`/`replay_workflows`
- Compatible with any test framework (minitest commonly used in samples)
- Ruby uses `Temporalio::Worker::WorkflowExecutor::ThreadPool.default` for test workers

**Order alignment:** ✅ Aligned — Reordered TS sections to match Python order; Ruby follows same order

**Style alignment:** ✅ Complete (Python/TypeScript). Ruby should follow same 8-section structure.
