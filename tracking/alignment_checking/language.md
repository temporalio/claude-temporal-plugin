# {language}.md (top-level files)

Tracks alignment for `python.md`, `typescript.md`, `java.md`, `go.md`, etc.

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Java | J# | Go |
|---------|------|--------|-----|------------|-----|------|----|----|
| Overview | — | ✓ | 1 | ✓ | 1 | ✓ | 1 | |
| How Temporal Works: History Replay | — | — | — | — | — | — | — | |
| Understanding Replay | — | — | — | ✓ | 2 | — | — | |
| Quick Start / Quick Demo | — | ✓ | 2 | ✓ | 3 | ✓ | 2 | |
| Key Concepts | — | ✓ | 3 | ✓ | 4 | ✓ | 3 | |
| File Organization Best Practice | — | ✓ | 4 | ✓ | 5 | ✓ | 4 | |
| Determinism Rules | — | — | — | ✓ | 6 | ✓ | 5 | |
| Common Pitfalls | — | ✓ | 5 | ✓ | 7 | ✓ | 6 | |
| Writing Tests | — | ✓ | 6 | ✓ | 8 | ✓ | 7 | |
| Additional Resources | — | ✓ | 7 | ✓ | 9 | ✓ | 8 | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Has Understanding Replay, Determinism Rules |
| Java | ✓ aligned | No Understanding Replay (covered in Overview); has Determinism Rules |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Java column decisions:**
- Overview: Java SDK intro, interface+implementation pattern, requirements
- Understanding Replay: — (omitted; Java Overview already notes no sandbox — adding a dedicated replay section would be redundant. TS has it as a bridge from its sandbox-heavy docs.)
- Quick Start: Full tutorial — interface, implementation, activities, worker (WorkerFactory), client starter. Uses Gradle/Maven.
- Key Concepts: `@WorkflowInterface`/`@WorkflowMethod`, `@ActivityInterface`/`@ActivityMethod`, `Workflow.newActivityStub()`, worker setup with `WorkerFactory`
- File Organization: Separate workflow and activity files is good practice; no need to mention sandbox/performance rationale
- Determinism Rules: Important for Java — NO sandbox, developer must follow conventions. `Workflow.sleep()`, `Workflow.currentTimeMillis()`, `Workflow.newRandom()`, `Workflow.randomUUID()`, `Async.function()`/`Promise` instead of Thread
- Common Pitfalls: Non-deterministic code, using Thread/locks, missing timeouts on activity stubs, forgetting to heartbeat, using mutable global state, not using `Workflow.getLogger()`, forgetting to await activity results

**Intentionally missing (`—`):**
- Core column: no core top-level file (these are language entry points)
- How Temporal Works: Removed from all languages (too detailed for entry point)
- Understanding Replay: Java-specific omission — overview already mentions determinism requirement; no dedicated section needed
- Determinism Rules: TS and Java have separate section; Python has subsection in Key Concepts

**Order alignment:** ✓ Aligned — Java structure matches TS minus Understanding Replay (J# numbers contiguous)

**Style alignment:** ✅ Complete (Python, TypeScript, Java)
- No cross-language comparisons within reference files (e.g., don't say "unlike Python, Java has no sandbox" in File Organization)
- No editorializing ("This is a common source of confusion" etc.) — state facts directly
