# versioning.md

## Section Inventory

| Section | Core | Core# | Python | Py# | TypeScript | TS# | .NET | DN# | Go |
|---------|------|-------|--------|-----|------------|-----|------|-----|-----|
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
| .NET | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Intentionally missing (`—`):**
- Overview: Core-only (conceptual; languages reference core)
- Why Versioning is Needed: Core-only (conceptual; languages reference core)
- Choosing a Strategy: Core-only (conceptual; languages reference core)
- Finding Workflows by Version: Core-only section (languages cover in Query Filters subsections)
- Common Mistakes: Core-only section

**.NET alignment notes:**
- Patching API: `Workflow.Patched("patch-id")` / `Workflow.DeprecatePatch("patch-id")` — similar pattern to Python/TS
- Worker Versioning: GA in SDK 1.11.0. Uses `[Workflow(VersioningBehavior = ...)]` attribute with `Pinned` or `AutoUpgrade`.
- Workflow Type Versioning: Same pattern as Python/TS — separate workflow types with routing

**Order alignment:** ✓ Aligned — languages now focus on code: Patching API, Type Versioning, Worker Versioning, Best Practices

**Style alignment:** ✅ Complete (Python/TS) — Aligned to core-concepts/language-code pattern
- Core: Conceptual explanations with decision guidance (Overview, Why Versioning, Choosing a Strategy, Common Mistakes)
- Python/TypeScript: Code examples only, reference core for concepts
- .NET: Will follow same pattern — code examples only, reference core for concepts
