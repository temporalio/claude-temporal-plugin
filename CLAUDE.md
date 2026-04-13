# Claude Temporal Plugin

This repository is the Claude Code plugin for Temporal. It packages skill content from the canonical upstream skill repo (`temporalio/skill-temporal-developer`) for distribution via the Claude Code plugin marketplace.

## Repository Structure

```
claude-temporal-plugin/
├── .claude-plugin/
│   ├── plugin.json          ← plugin manifest
│   └── marketplace.json     ← marketplace entry
├── skills/
│   └── temporal-developer/  ← skill content (copied from upstream)
│       ├── SKILL.md
│       └── references/
├── .memory/                 ← alignment/correctness checking docs
├── test/                    ← integration tests
├── assets/
├── CLAUDE.md
├── LICENSE
└── README.md
```

## Editing Skills and Reference Files

When working on files inside `skills/` or `.memory/`, use the **edit-plugin-skills** skill — it contains the full workflow for editing reference files, updating memory documents, and avoiding staleness.

## Skill Content

The skill content in `skills/temporal-developer/` is copied from `temporalio/skill-temporal-developer`. It may diverge over time to optimize for Claude Code specifically. When upstream skill changes are significant, they should be reviewed and selectively merged in.

## Related Repos

- **Canonical skill**: `temporalio/skill-temporal-developer`
- **Cursor plugin**: `temporalio/cursor-temporal-plugin`
- **Codex plugin**: `temporalio/codex-temporal-plugin`

## Release Workflow

Use the `/release` skill to run the release pipeline. It is implemented as a Temporal workflow (`.claude/skills/release/`) with a CLI client for sending signals at human checkpoints. The `/release` skill has full instructions — do not manually perform these steps.

Version in `SKILL.md` frontmatter and `plugin.json` must always match.

## sdk-versions.json

Tracks SDK versions against which reference files were last verified. Updated during specific SDK-update PRs, not as part of general content work.
