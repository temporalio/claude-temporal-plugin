# {language}.md (top-level files)

Tracks alignment for `python.md`, `typescript.md`, `dotnet.md`, etc.

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | .NET | DN# | Go |
|---------|------|--------|-----|------------|-----|------|-----|-----|
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
| .NET | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Intentionally missing (`—`):**
- Core column: no core top-level file (these are language entry points)
- Determinism Rules — TS has separate section; Python has subsection in Key Concepts; .NET should have separate section (Task determinism is critical for .NET)

**.NET alignment notes:**
- File will be `references/dotnet/dotnet.md`
- Understanding Replay: ✓ — follows TS pattern, brief reference to core/determinism.md
- Quick Start: Full tutorial with 4 files (Activities.cs, Workflow.cs, Worker/Program.cs, Starter/Program.cs), NuGet install, run instructions
- File Organization: Less critical than Python (no sandbox reloading) but still good practice. Standard .NET project structure.
- Determinism Rules: ✓ — IMPORTANT for .NET. Covers .NET Task determinism gotchas, since there's no sandbox. References determinism.md and determinism-protection.md for details.
- Common Pitfalls: .NET-specific (Task.Run, ConfigureAwait(false), non-ApplicationFailureException in workflows, dictionary iteration)

**Order alignment:** ✓ Aligned — .NET follows TS pattern (Overview, Understanding Replay, Quick Start, Key Concepts, File Organization, Determinism Rules, Common Pitfalls, Writing Tests, Additional Resources)

**Style alignment:** ✅ Complete (Python/TS)
- Removed "How Temporal Works" from TS (now brief "Understanding Replay" referencing core)
- Added "File Organization Best Practice" to TS
- Python Quick Demo and TypeScript Quick Start now match (full tutorial with 4 files, run instructions, expected output)
- Both Key Concepts and Common Pitfalls sections aligned
