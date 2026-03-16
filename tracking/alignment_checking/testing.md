# testing.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | .NET | DN# | Go |
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
| .NET | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Intentionally missing (`—`):**
- Core column: no core testing.md exists (implementation-specific)
- Time Skipping: Mentioned inline in Test Environment Setup (all languages)

**.NET alignment notes:**
- Test Environment Setup: `WorkflowEnvironment.StartLocalAsync()` and `WorkflowEnvironment.StartTimeSkippingAsync()`
- Activity Mocking: .NET uses `[Activity("OriginalName")]` attribute on mock function, registered with `AddActivity()`. No mocking library needed.
- Activity Testing: `ActivityEnvironment` class for unit testing activities in isolation
- Replay Testing: `WorkflowReplayer` class
- Framework: Compatible with any testing framework; samples use xUnit

**Order alignment:** ✅ Aligned — DN# monotonically increases, matching Python/TS order

**Style alignment:** ✅ Complete (Python/TS). .NET not started.
