# {language}.md (top-level files)

Tracks alignment for `python.md`, `typescript.md`, `java.md`, `go.md`, etc.

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Java | J# | Go |
|---------|------|--------|-----|------------|-----|------|----|----|
| Overview | — | ✓ | 1 | ✓ | 1 | TODO | 1 | |
| How Temporal Works: History Replay | — | — | — | — | — | — | — | |
| Understanding Replay | — | — | — | ✓ | 2 | TODO | 2 | |
| Quick Start / Quick Demo | — | ✓ | 2 | ✓ | 3 | TODO | 3 | |
| Key Concepts | — | ✓ | 3 | ✓ | 4 | TODO | 4 | |
| File Organization Best Practice | — | ✓ | 4 | ✓ | 5 | TODO | 5 | |
| Determinism Rules | — | — | — | ✓ | 6 | TODO | 6 | |
| Common Pitfalls | — | ✓ | 5 | ✓ | 7 | TODO | 7 | |
| Writing Tests | — | ✓ | 6 | ✓ | 8 | TODO | 8 | |
| Additional Resources | — | ✓ | 7 | ✓ | 9 | TODO | 9 | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Has Understanding Replay, Determinism Rules |
| Java | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Java column decisions:**
- Overview: Java SDK intro, interface+implementation pattern, requirements
- Understanding Replay: Brief section referencing core/determinism.md (like TS)
- Quick Start: Full tutorial — interface, implementation, activities, worker (WorkerFactory), client starter. Uses Gradle/Maven.
- Key Concepts: `@WorkflowInterface`/`@WorkflowMethod`, `@ActivityInterface`/`@ActivityMethod`, `Workflow.newActivityStub()`, worker setup with `WorkerFactory`
- File Organization: Less strict than Python/TS (no sandbox reload, no bundling), but still recommended to separate workflow and activity files
- Determinism Rules: Important for Java — NO sandbox, developer must follow conventions. `Workflow.sleep()`, `Workflow.currentTimeMillis()`, `Workflow.newRandom()`, `Workflow.randomUUID()`, `Async.function()`/`Promise` instead of Thread
- Common Pitfalls: Non-deterministic code, using Thread/locks, missing timeouts on activity stubs, forgetting to heartbeat, using mutable global state, not using `Workflow.getLogger()`, forgetting to await activity results

**Intentionally missing (`—`):**
- Core column: no core top-level file (these are language entry points)
- How Temporal Works: Removed from all languages (too detailed for entry point)
- Determinism Rules: TS and Java have separate section; Python has subsection in Key Concepts

**Order alignment:** ✓ Aligned — Java follows TS structure (includes Understanding Replay and Determinism Rules sections)

**Style alignment:** ✅ Complete (Python, TypeScript)
