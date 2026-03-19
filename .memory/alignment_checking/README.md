# Alignment Checking

Track content alignment (do files have the right sections?) and style alignment (is prose level appropriate?) across reference files for the **temporal-developer** skill.

**Skill location:** `plugins/temporal-developer/skills/temporal-developer/`
**Reference files:** `plugins/temporal-developer/skills/temporal-developer/references/`

## Style Target

Python is the reference style (code-first, minimal prose). All languages should match.

**Style compliance legend:**
- `✓ reference` = defines the target style
- `✓ aligned` = matches reference style
- `⚠️ needs work` = has style issues to address
- `—` = not started

## Section Inventory Legend

- `✓` = present
- ` ` (empty) = missing, unknown if intentional (needs review)
- `—` = missing, intentional (language doesn't need this)
- `TODO` = missing, should add
- `DEL` = present, should remove or merge
- `Py#` / `TS#` / `DN#` / `Go#` = section order in file (should monotonically increase if order is aligned)

## Implementation Status

**Python/TypeScript:** ✅ COMPLETE (2026-02-25) — All TODO/DEL/BUG items implemented.

**Go:** ✅ COMPLETE (2026-03-17) — All Go reference files created and aligned.

**.NET:** ⏳ IN PROGRESS (2026-03-16) — Alignment tracking docs created with TODO markers.

## Files

Each file in this directory tracks alignment for a corresponding reference file:

- [patterns.md](./patterns.md)
- [data-handling.md](./data-handling.md)
- [error-handling.md](./error-handling.md)
- [gotchas.md](./gotchas.md)
- [observability.md](./observability.md)
- [testing.md](./testing.md)
- [versioning.md](./versioning.md)
- [language.md](./language.md) — top-level `{language}.md` files (python.md, typescript.md, etc.)
- [determinism-protection.md](./determinism-protection.md)
- [determinism.md](./determinism.md)
- [advanced-features.md](./advanced-features.md)
