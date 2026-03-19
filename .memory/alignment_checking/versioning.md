# versioning.md

## Section Inventory

| Section | Core | Core# | Python | Py# | TypeScript | TS# | Go | Go# |
|---------|------|-------|--------|-----|------------|-----|-----|-----|
| Overview | ✓ | 1 | — | — | — | — | — | — |
| Why Versioning is Needed | ✓ | 2 | — | — | — | — | — | — |
| Patching API / GetVersion API | ✓ | 3 | ✓ | 1 | ✓ | 1 | ✓ | 1 |
| Workflow Type Versioning | ✓ | 4 | ✓ | 2 | ✓ | 2 | ✓ | 2 |
| Worker Versioning | ✓ | 5 | ✓ | 3 | ✓ | 3 | ✓ | 3 |
| Choosing a Strategy | ✓ | 6 | — | — | — | — | — | — |
| Best Practices | ✓ | 7 | ✓ | 4 | ✓ | 4 | ✓ | 4 |
| Finding Workflows by Version | ✓ | 8 | — | — | — | — | — | — |
| Common Mistakes | ✓ | 9 | — | — | — | — | — | — |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Core | ✓ reference | Conceptual content |
| Python | ✓ aligned | Code only, refs core |
| TypeScript | ✓ aligned | Code only, refs core |
| Go | ✓ aligned | Uses `workflow.GetVersion` (not patching); code only, refs core |

## Status

**Go-specific notes:**
- Go uses `workflow.GetVersion(ctx, changeID, minSupported, maxSupported)` — returns a `Version` (int)
- Different from Python/TS `patched()`/`deprecatePatch()` — Go uses a version number approach
- Three-step lifecycle: add GetVersion branch -> increase minSupported -> collapse to single branch
- `workflow.DefaultVersion` constant (-1) represents pre-versioned code
- TemporalChangeVersion search attribute set automatically
- Worker Versioning works the same across all SDKs (server-side feature)
- Query filters for finding workflows by version are available

**Intentionally missing (`—`):**
- Overview: Core-only (conceptual; languages reference core)
- Why Versioning is Needed: Core-only (conceptual; languages reference core)
- Choosing a Strategy: Core-only (conceptual; languages reference core)
- Finding Workflows by Version: Core-only section (languages cover in Query Filters subsections)
- Common Mistakes: Core-only section

**Order alignment:** ✓ Aligned — languages focus on code: Patching/GetVersion API, Type Versioning, Worker Versioning, Best Practices

**Style alignment:** ✅ Complete (Python, TypeScript, Go)
