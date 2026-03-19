# {language}.md (top-level files)

Tracks alignment for `python.md`, `typescript.md`, `go.md`, etc.

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | PHP | PHP# | Go | Go# |
|---------|------|--------|-----|------------|-----|-----|------|----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | ✓ | 1 | ✓ | 1 |
| How Temporal Works: History Replay | — | — | — | — | — | | | — | — |
| Understanding Replay | — | — | — | ✓ | 2 | — | — | — | — |
| Quick Start / Quick Demo | — | ✓ | 2 | ✓ | 3 | ✓ | 2 | ✓ | 2 |
| Key Concepts | — | ✓ | 3 | ✓ | 4 | ✓ | 3 | ✓ | 3 |
| File Organization Best Practice | — | ✓ | 4 | ✓ | 5 | ✓ | 4 | ✓ | 4 |
| Determinism Rules | — | — | — | ✓ | 6 | ✓ | 5 | — | — |
| Common Pitfalls | — | ✓ | 5 | ✓ | 7 | ✓ | 6 | ✓ | 5 |
| Writing Tests | — | ✓ | 6 | ✓ | 8 | ✓ | 7 | ✓ | 6 |
| Additional Resources | — | ✓ | 7 | ✓ | 9 | ✓ | 8 | ✓ | 7 |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Has Understanding Replay, Determinism Rules |
| PHP | ✓ aligned | Has Determinism Rules, RoadRunner-specific file org |
| Go | ✓ aligned | Function-based (no decorators), workflowcheck, struct activities |

## Status

**Section content notes:**
- Writing Tests: all languages should be a brief link to `references/<lang>/testing.md`, NOT inline code examples

**Go-specific notes:**
- Go uses exported functions (not decorators) for workflows/activities
- Activities commonly defined as struct methods for dependency injection
- Worker setup: `worker.New(client, taskQueue, options)` + `w.RegisterWorkflow` / `w.RegisterActivity`
- Determinism rules included in Key Concepts subsection (like Python), not separate section
- Understanding Replay: TS-specific section; Go references core like Python
- `workflowcheck` static analysis tool mentioned in Key Concepts (Go-specific)
- File organization: Go uses separate packages (workflows/, activities/, worker/)

**Intentionally missing (`—`):**
- Core column: no core top-level file (these are language entry points)
- Determinism Rules — TS has separate section; Python/Go have subsection in Key Concepts
- Understanding Replay — TS-specific; Python/Go reference core

**Order alignment:** ✓ Aligned — All languages have similar structure (Overview, Quick Start, Key Concepts, File Organization, Common Pitfalls, Writing Tests, Additional Resources)

**Style alignment:** ✅ Complete (Python, TypeScript)
- Removed "How Temporal Works" from TS (now brief "Understanding Replay" referencing core)
- Added "File Organization Best Practice" to TS
- Python Quick Demo and TypeScript Quick Start now match (full tutorial with 4 files, run instructions, expected output)
- Both Key Concepts and Common Pitfalls sections aligned
