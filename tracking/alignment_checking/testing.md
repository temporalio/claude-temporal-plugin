# testing.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Java | J# | Go |
|---------|------|--------|-----|------------|-----|------|----|----|
| Overview | — | ✓ | 1 | ✓ | 1 | TODO | 1 | |
| Workflow Test Environment | — | ✓ | 2 | ✓ | 2 | TODO | 2 | |
| Time Skipping | — | — | — | — | — | — | — | |
| Mocking Activities | — | ✓ | 3 | ✓ | 3 | TODO | 3 | |
| Testing Signals and Queries | — | ✓ | 4 | ✓ | 4 | TODO | 4 | |
| Testing Failure Cases | — | ✓ | 5 | ✓ | 5 | TODO | 5 | |
| Workflow Replay Testing | — | ✓ | 6 | ✓ | 6 | TODO | 6 | |
| Activity Testing | — | ✓ | 7 | ✓ | 7 | TODO | 7 | |
| Best Practices | — | ✓ | 8 | ✓ | 8 | TODO | 8 | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Added failure/activity testing |
| Java | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Java column decisions:**
- Test Environment Setup: Java uses `TestWorkflowEnvironment` (manual setup) or `TestWorkflowExtension` (JUnit 5) / `TestWorkflowRule` (JUnit 4)
- Activity Mocking: Java uses Mockito (`mock(Activities.class, withSettings().withoutAnnotations())`)
- Testing Signals and Queries: Same pattern — start workflow, send signal/query, assert
- Testing Failure Cases: Same pattern — mock failing activities, expect `WorkflowException`
- Replay Testing: Java has `WorkflowReplayer` for replay compatibility tests
- Activity Testing: Java tests activities directly or with `TestActivityEnvironment`
- Time Skipping: — (mentioned inline, not separate section — same as Python/TS)

**Intentionally missing (`—`):**
- Core column: no core testing.md exists (implementation-specific)
- Time Skipping: mentioned inline (not a separate section)

**Order alignment:** ✅ Aligned — Java follows same order as Python and TypeScript

**Style alignment:** ✅ Complete (Python, TypeScript). Java will follow same structure.
