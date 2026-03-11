---
name: edit-plugin-skills
description: This skill should be used when the user asks to "edit a skill", "update reference files", "fix a reference", "check alignment", "check correctness", "verify code examples", "update tracking", "add a new language", "edit plugin content", "modify skill references", "resume correctness verification", "check tracking status", "run alignment checks", or mentions working on files inside plugins/ or tracking/ directories.
version: 0.1.0
---

# Editing Plugin Skills

## Overview

This repository contains plugin skills with reference files organized by topic and language. Edits to these files must be tracked through two systems: **alignment checking** (structure and style) and **correctness checking** (factual accuracy). The tracking documents in `tracking/` serve as shared state between sessions and agents.

## Repository Structure

```
plugins/<plugin-name>/skills/<skill-name>/
├── SKILL.md
└── references/
    ├── core/          # Conceptual content (language-agnostic)
    ├── python/        # Python-specific code and guidance
    ├── typescript/    # TypeScript-specific code and guidance
    └── go/            # Go-specific (future)

tracking/
├── alignment_checking/   # Structure and style tracking
│   ├── README.md
│   └── <topic>.md        # One file per reference topic
└── correctness_checking/ # Factual accuracy tracking
    ├── README.md
    └── <topic>.md        # One file per reference topic
```

**Key principle:** Concepts belong in `core/`, language-specific code belongs in language directories. Avoid duplicating conceptual content across languages.

## Workflow: Editing Reference Files

### Step 1: Identify What to Edit

Determine the scope of the change:
- Which reference file(s) to modify
- Whether the change affects structure, content, or both
- Which languages are impacted

### Step 2: Read Current Tracking State

Before making edits, read the relevant tracking files to understand current state:
- `tracking/alignment_checking/<topic>.md` for structure/style status
- `tracking/correctness_checking/<topic>.md` for verification status

For alignment work, also read `tracking/alignment_checking/README.md` for the style target and legends. For correctness work, read `tracking/correctness_checking/README.md` for the verification workflow and status values.

See `references/tracking-formats.md` for detailed table formats and field descriptions.

### Step 3: Make the Edit

Edit the reference file(s) in `plugins/`. Complete all changes before updating tracking.

### Step 4: Update Tracking Documents

After completing edits, update the relevant tracking documents. Refer to the protocol table below.

| Situation | Update |
|-----------|--------|
| Reorganizing sections between files | alignment_checking/ |
| Removing duplicate conceptual content | alignment_checking/ |
| Adjusting prose style (code-first, minimal prose) | alignment_checking/ |
| Adding a new language (e.g., Go) | Both directories |
| Fixing incorrect code example | correctness_checking/ |
| Receiving SDK team feedback | correctness_checking/ |
| Verifying content against official docs | correctness_checking/ |
| Adding new reference content | Both directories |

### Step 5: Verify No Staleness

Tracking docs must reflect **current state**, not pending work.

**Do:**
- Complete the work first, then update the tracking doc
- Update inventory tables directly (change `✓` to `—` when removing a section)
- Summarize completed changes in the Style Alignment section

**Do not:**
- Leave `Sections marked DEL:` or `Sections marked TODO:` lists
- Leave `Action items:` lists with checkboxes
- Leave any list of "things to do" that persists after completion

**Correct example:**
```markdown
**Style alignment:** ✅ Complete. Removed OpenTelemetry (too detailed).
```

**Incorrect example:**
```markdown
**Action items:** ✅ All completed
- ✅ Removed OpenTelemetry section
```

## Correctness Verification Workflow

When verifying factual accuracy of code examples and statements:

1. Read the section from the reference file
2. Query documentation sources using MCP tools (see `references/tracking-formats.md` for tool names and library IDs)
3. Compare code examples against official docs
4. Apply fixes to source file if needed
5. Update tracking table: Status, Fix Applied, Sources columns
6. Update Detailed Notes with verification details

See `references/tracking-formats.md` for status values and detailed table format.

**To resume correctness work:** Check the summary table in `tracking/correctness_checking/README.md`, then find the first `unchecked` or `needs fixes` section.

## Alignment Checking

**Style target:** Python is the reference style (code-first, minimal prose). All languages should match.

When checking or adjusting alignment:
1. Read the Section Inventory table in `tracking/alignment_checking/<topic>.md`
2. Verify sections exist where expected (`✓`), are intentionally missing (`—`), or need review
3. Check section ordering numbers (`Py#` / `TS#` / `Go#`) increase monotonically
4. Review Style Compliance status per language

See `references/tracking-formats.md` for the complete legend and table format.

## Adding a New Language

When adding a new language (e.g., Go):
1. Create `references/<language>/` directory with language-specific files
2. Update alignment tracking: add column to Section Inventory tables in each `tracking/alignment_checking/<topic>.md`
3. Update correctness tracking: add `## {Language}` section to each `tracking/correctness_checking/<topic>.md`
4. Update summary tables in both README files

## References

- **`references/tracking-formats.md`** — Detailed format specifications for alignment and correctness tracking tables
