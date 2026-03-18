# {language}.md (top-level files)

Tracks alignment for `python.md`, `typescript.md`, `go.md`, etc.

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Go |
|---------|------|--------|-----|------------|-----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | |
| How Temporal Works: History Replay | — | — | — | — | — | |
| Understanding Replay | — | — | — | ✓ | 2 | |
| Quick Start / Quick Demo | — | ✓ | 2 | ✓ | 3 | |
| Key Concepts | — | ✓ | 3 | ✓ | 4 | |
| File Organization Best Practice | — | ✓ | 4 | ✓ | 5 | |
| Determinism Rules | — | — | — | ✓ | 6 | |
| Common Pitfalls | — | ✓ | 5 | ✓ | 7 | |
| Writing Tests | — | ✓ | 6 | ✓ | 8 | |
| Additional Resources | — | ✓ | 7 | ✓ | 9 | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | Has Understanding Replay, Determinism Rules |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Intentionally missing (`—`):**
- Core column: no core top-level file (these are language entry points)
- Determinism Rules — TS has separate section; Python has subsection in Key Concepts

**Order alignment:** ✓ Aligned — Both have similar structure (Overview, Quick Start, Key Concepts, File Organization, Common Pitfalls, Writing Tests, Additional Resources)

**Style alignment:** ✅ Complete
- Removed "How Temporal Works" from TS (now brief "Understanding Replay" referencing core)
- Added "File Organization Best Practice" to TS
- Python Quick Demo and TypeScript Quick Start now match (full tutorial with 4 files, run instructions, expected output)
- Both Key Concepts and Common Pitfalls sections aligned
