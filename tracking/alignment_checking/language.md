# {language}.md (top-level files)

Tracks alignment for `python.md`, `typescript.md`, `go.md`, etc.

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Ruby | Rb# | Go |
|---------|------|--------|-----|------------|-----|------|-----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | TODO | 1 | |
| How Temporal Works: History Replay | — | — | — | — | — | — | — | |
| Understanding Replay | — | — | — | ✓ | 2 | — | — | |
| Quick Start / Quick Demo | — | ✓ | 2 | ✓ | 3 | TODO | 2 | |
| Key Concepts | — | ✓ | 3 | ✓ | 4 | TODO | 3 | |
| File Organization Best Practice | — | ✓ | 4 | ✓ | 5 | TODO | 4 | |
| Determinism Rules | — | — | — | ✓ | 6 | — | — | |
| Common Pitfalls | — | ✓ | 5 | ✓ | 7 | TODO | 5 | |
| Writing Tests | — | ✓ | 6 | ✓ | 8 | TODO | 6 | |
| Additional Resources | — | ✓ | 7 | ✓ | 9 | TODO | 7 | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Has Understanding Replay, Determinism Rules |
| Ruby | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created
- Ruby column: all TODO — Ruby files not yet created

**Intentionally missing (`—`):**
- Core column: no core top-level file (these are language entry points)
- Determinism Rules — TS has separate section; Python has subsection in Key Concepts; Ruby should handle like Python (in Key Concepts)
- Understanding Replay — TS-specific separate section; Ruby should reference core like Python

**Ruby notes:**
- Overview: gem installation (`gem 'temporalio'`), Ruby 3.3+, macOS/Linux only
- Quick Start: Full tutorial with activity class, workflow class, worker, client (4 files like Python/TS)
- Key Concepts: Workflows as classes (`< Temporalio::Workflow::Definition`), Activities as classes (`< Temporalio::Activity::Definition`), `Temporalio::Workflow.execute_activity`, determinism via Illegal Call Tracing
- File Organization: Ruby class-based approach (one class per file convention)
- Common Pitfalls: Using `sleep` instead of `Temporalio::Workflow.sleep`, using `Time.now` instead of `Temporalio::Workflow.now`, non-deterministic gems in workflows
- Writing Tests: minitest with `Temporalio::Testing::WorkflowEnvironment`
- Additional Resources: ruby.temporal.io API docs, samples-ruby repo, Temporal 101 Ruby course

**Order alignment:** ✓ Aligned — Ruby follows Python order (no Understanding Replay or Determinism Rules sections)

**Style alignment:** ✅ Complete (Python/TypeScript)
- Removed "How Temporal Works" from TS (now brief "Understanding Replay" referencing core)
- Added "File Organization Best Practice" to TS
- Python Quick Demo and TypeScript Quick Start now match (full tutorial with 4 files, run instructions, expected output)
- Both Key Concepts and Common Pitfalls sections aligned
