# Correctness Checking

Track verification of factual statements and code examples in reference files for the **temporal-developer** skill.

**Skill location:** `plugins/temporal-developer/skills/temporal-developer/`
**Reference files:** `plugins/temporal-developer/skills/temporal-developer/references/`

## File Organization

Each file in this directory tracks correctness for a corresponding reference file. Within each file, sections are organized by language (e.g., `## TypeScript`, `## Python`).

**Supported languages:** TypeScript, Python, Go (future)

**Adding a new language:** Add a new `## {Language}` section to each relevant file with a Tracking table and Detailed Notes.

## Summary

| File | TypeScript | Python | Go |
|------|------------|--------|-----|
| patterns.md | ✅ | partial | — |
| testing.md | ✅ | partial | — |
| language.md | ✅ | partial | — |
| versioning.md | ✅ | partial | — |
| advanced-features.md | ✅ | partial | — |
| data-handling.md | ✅ | partial | — |
| determinism-protection.md | ✅ | partial | — |
| determinism.md | ✅ | partial | — |
| error-handling.md | ✅ | partial | — |
| gotchas.md | ✅ | partial | — |
| observability.md | ✅ | partial | — |
| ai-patterns.md | — | partial | — |
| sync-vs-async.md | — | ✅ | — |

**Legend:** ✅ = all sections verified, partial = some sections need fixes, unchecked = not yet verified, — = N/A

## Files

- [patterns.md](./patterns.md)
- [testing.md](./testing.md)
- [language.md](./language.md) — top-level `{language}.md` files
- [versioning.md](./versioning.md)
- [advanced-features.md](./advanced-features.md)
- [data-handling.md](./data-handling.md)
- [determinism-protection.md](./determinism-protection.md)
- [determinism.md](./determinism.md)
- [error-handling.md](./error-handling.md)
- [gotchas.md](./gotchas.md)
- [observability.md](./observability.md)
- [ai-patterns.md](./ai-patterns.md)
- [sync-vs-async.md](./sync-vs-async.md)

## Verification Workflow

1. Read the section from the reference file
2. Query documentation sources:
   - `mcp__context7__query-docs` with `/temporalio/sdk-typescript` or `/temporalio/sdk-python`
   - `mcp__temporal-docs__search_temporal_knowledge_sources` for conceptual verification
3. Compare code examples against official docs
4. Apply fixes to source file if needed
5. Update tracking table: Status, Fix Applied, Sources
6. Update Detailed Notes with verification details

## Status Values

- `unchecked` - Not yet verified
- `all good` - Verified correct, no changes needed
- `needs fixes` - Issues found but not yet corrected
- `FIXED` - Issues found and corrected

## Resume Instructions

Check Summary table for incomplete files, then find the first `unchecked` or `needs fixes` section.
