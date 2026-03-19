# Tracking/Memory Document Formats

Detailed format specifications for the two memory/tracking systems used in this repository.

## Alignment Checking

**Location:** `.memory/alignment_checking/`

Each file tracks one reference topic (e.g., `patterns.md` tracks all `references/*/patterns.md` files).

### Section Inventory Table

```markdown
| Section | Core | Python | Py# | TypeScript | TS# | Go | Go# |
|---------|------|--------|-----|------------|-----|-----|-----|
| Signals | ✓ | ✓ | 1 | ✓ | 1 | | |
| Dynamic Handlers | — | ✓ | 2 | ✓ | 2 | | |
```

**Column meanings:**
- `Core` / `Python` / `TypeScript` / `Go` — presence: `✓` = present, `—` = intentionally missing, empty = needs review, `TODO` = should add, `DEL` = should remove
- `Py#` / `TS#` / `Go#` — section order number (should monotonically increase if aligned with reference)

### Style Compliance Table

```markdown
| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | Defines the target style |
| TypeScript | ✓ aligned | Matches reference |
| Go | — | Not started |
```

**Status values:** `✓ reference`, `✓ aligned`, `⚠️ needs work`, `—` (not started)

### Status Section

Document three things:
1. **Sections needing review** — empty cells, with explanation
2. **Intentionally missing** — why certain `—` entries exist
3. **Order alignment** — whether language order numbers increase monotonically
4. **Style alignment** — summary of completed style work (not TODO lists)

---

## Correctness Checking

**Location:** `.memory/correctness_checking/`

Each file tracks one reference topic, organized by language sections (`## TypeScript`, `## Python`).

### Tracking Table

```markdown
| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Signals | all good | | context7 sdk-typescript |
| 2 | Dynamic Handlers | FIXED | Used setDefaultSignalHandler | context7 sdk-typescript |
| 3 | Queries | needs fixes | | context7 sdk-typescript |
```

**Status values:**
- `unchecked` — not yet verified
- `all good` — verified correct, no changes needed
- `needs fixes` — issues found but not yet corrected
- `FIXED` — issues found and corrected

**Fix Applied:** Brief description of what was changed (empty if no fix needed)

**Sources:** Which documentation sources were consulted (e.g., `context7 sdk-typescript`, `temporal-docs`, `SDK team feedback`)

### Detailed Notes

Below each tracking table, include a subsection per row with:

```markdown
#### 1. Section Name
**Status:** all good | needs fixes | FIXED

**Verified:** (for all good)
- Specific fact checked ✓

**Issues:** (for needs fixes / FIXED)
- Description of the problem
- What the correct behavior should be

**Before/After:** (for FIXED, include code snippets)

**Source:** URL or reference
```

### Verification Sources

Use these MCP tools for verification:
- `mcp__context7__query-docs` — SDK-specific code verification (use with library IDs like `/temporalio/sdk-typescript` or `/temporalio/sdk-python`)
- `mcp__temporal-docs__search_temporal_knowledge_sources` — conceptual verification against Temporal documentation

### Summary Table (README.md)

The `.memory/correctness_checking/README.md` contains a summary table:

```markdown
| File | TypeScript | Python | Go |
|------|------------|--------|-----|
| patterns.md | ✅ | partial | — |
```

**Legend:** `✅` = all sections verified, `partial` = some sections need fixes/unchecked, `unchecked` = not yet verified, `—` = N/A

Update this table whenever a file's overall status changes.
