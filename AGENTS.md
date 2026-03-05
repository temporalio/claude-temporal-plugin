# Agent Collaboration Guide

This document describes protocols for agents working on this repository.

## Tracking Documents

The `tracking/` directory contains documents for coordinating work on reference files. These documents serve as shared state between sessions and agents.

### alignment_checking/ (directory)

**Purpose:** Track content alignment (do files have the right sections?) and style alignment (is prose level appropriate?) across reference files.

**Key principle:** Concepts go in `core/`, language-specific code goes in language files (e.g., `python/`, `typescript/`). Avoid duplicating conceptual content across languages.

**Structure:**
- `README.md` - Overview, legends, implementation status
- One file per tracked reference file (e.g., `patterns.md`, `versioning.md`)
- `language.md` - Tracks top-level `{language}.md` files (python.md, typescript.md, etc.)

**Each file contains:**
- **Section Inventory table** - Which sections exist per language (Core, Python, TypeScript, Go, etc.)
  - `✓` = present, `—` = missing intentional, empty = needs review
  - `Py#` / `TS#` / `Go#` = section order (should monotonically increase if aligned)
- **Style Compliance table** - Status per language (reference, aligned, needs work, not started)
- **Status section** - Intentionally missing, order alignment, style alignment notes

**When to update:**
- When adding or removing sections → update Section Inventory table in the relevant file
- When moving content between core and language-specific files → update table and status
- When completing alignment work → summarize in Style alignment (not in a separate list)
- When adding a new reference file → create a new tracking file in the directory

### correctness_checking/ (directory)

**Purpose:** Track verification of factual statements and code examples against official documentation.

**Structure:**
- `README.md` - Overview, summary table, verification workflow
- One file per tracked reference file (e.g., `patterns.md`, `versioning.md`)
- Within each file, sections organized by language (`## TypeScript`, `## Python`)

**Each file contains:**
- **Tracking table** per language with columns: `#`, `Section`, `Status`, `Fix Applied`, `Sources`
- **Detailed Notes** subsections documenting verification details

**Supported languages:** TypeScript, Python, Go (future)

**Status values:** `unchecked`, `all good`, `needs fixes`, `FIXED`

**When to update:**
- When verifying correctness → update tracking table and detailed notes
- When receiving SDK team feedback → update relevant file
- When adding a new language → add `## {Language}` section to each file, update README summary
- When adding a new reference file → create new tracking file

**Resume instructions:** Check README summary table, then find the first `unchecked` or `needs fixes` section.

## Avoiding Staleness

Tracking docs should reflect **current state**, not pending work. Stale TODO lists create confusion.

**Don't use:**
- `Sections marked DEL:` / `Sections marked TODO:` lists
- `Action items:` lists with checkboxes
- Any list of "things to do" that persists after completion

**Instead:**
- **Do the work first**, then update the tracking doc
- **Update inventory tables directly** - change `✓` to `—` when removing a section
- **Summarize completed changes** in the Style Alignment section (e.g., "Removed X and Y, added Z")
- **For correctness_checking.md** - update the Status column and Detailed Notes, then move on

**Example - wrong approach:**
```markdown
**Sections marked DEL:**
- OpenTelemetry: Remove (too detailed)

**Action items:** ✅ All completed
- ✅ Removed OpenTelemetry section
```

**Example - correct approach:**
```markdown
**Style alignment:** ✅ Complete. Removed OpenTelemetry (too detailed).
```

## Protocol Summary

| Situation | Update |
|-----------|--------|
| Reorganizing sections between files | alignment_checking/ |
| Removing duplicate conceptual content | alignment_checking/ |
| Adjusting prose style (code-first, minimal prose) | alignment_checking/ |
| Adding a new language (e.g., Go) | Both (alignment: add columns; correctness: add sections) |
| Fixing incorrect code example | correctness_checking.md |
| Receiving SDK team feedback | correctness_checking.md |
| Verifying content against official docs | correctness_checking.md |
| Adding new reference content | Both (alignment for structure, correctness for verification) |
