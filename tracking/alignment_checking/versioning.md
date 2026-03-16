# versioning.md

## Section Inventory

| Section | Core | Core# | Python | Py# | TypeScript | TS# | Java | J# | Go |
|---------|------|-------|--------|-----|------------|-----|------|----|----|
| Overview | ✓ | 1 | — | — | — | — | — | — | |
| Why Versioning is Needed | ✓ | 2 | — | — | — | — | — | — | |
| Patching API | ✓ | 3 | ✓ | 1 | ✓ | 1 | TODO | 1 | |
| Workflow Type Versioning | ✓ | 4 | ✓ | 2 | ✓ | 2 | TODO | 2 | |
| Worker Versioning | ✓ | 5 | ✓ | 3 | ✓ | 3 | TODO | 3 | |
| Choosing a Strategy | ✓ | 6 | — | — | — | — | — | — | |
| Best Practices | ✓ | 7 | ✓ | 4 | ✓ | 4 | TODO | 4 | |
| Finding Workflows by Version | ✓ | 8 | — | — | — | — | — | — | |
| Common Mistakes | ✓ | 9 | — | — | — | — | — | — | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Core | ✓ reference | Conceptual content |
| Python | ✓ aligned | Code only, refs core |
| TypeScript | ✓ aligned | Code only, refs core |
| Java | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Java column decisions:**
- Patching API: Java uses `Workflow.getVersion(changeId, minVersion, maxVersion)` — returns version int, branch on it. Note: Java does NOT auto-record `TemporalChangeVersion` search attribute (must be done manually).
- Workflow Type Versioning: Same concept — create new workflow type for incompatible changes
- Worker Versioning: Java has `WorkerDeploymentOptions` with `WorkerDeploymentVersion` (available since SDK v1.29)
- Best Practices: Same general guidance, code examples in Java

**Intentionally missing (`—`):**
- Overview: Core-only (conceptual; languages reference core)
- Why Versioning is Needed: Core-only (conceptual; languages reference core)
- Choosing a Strategy: Core-only (conceptual; languages reference core)
- Finding Workflows by Version: Core-only section (languages cover in Query Filters subsections)
- Common Mistakes: Core-only section

**Order alignment:** ✓ Aligned — all languages focus on code: Patching API, Type Versioning, Worker Versioning, Best Practices

**Style alignment:** ✅ Complete — Aligned to core-concepts/language-code pattern
- Core: Conceptual explanations with decision guidance (Overview, Why Versioning, Choosing a Strategy, Common Mistakes)
- Python/TypeScript: Code examples only, reference core for concepts
- Removed duplicate Overview, Why Versioning, and Choosing a Strategy from Python and TypeScript
- Eliminates duplicate conceptual content across files
