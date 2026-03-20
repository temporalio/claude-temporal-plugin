# Agent Skills Repository

This repository contains plugin skills (in `plugins/`) and agent memory documents (in `.memory/`) for coordinating work on reference files.

## Editing Skills and Reference Files

When working on files inside `plugins/` or `.memory/`, use the **edit-plugin-skills** skill — it contains the full workflow for editing reference files, updating memory documents, and avoiding staleness.

## Repository Structure

This is a two-repo setup:
- **Outer repo** (`temporalio/agent-skills`): Plugin wrapper, `.memory/` tracking documents, `sdk-versions.json`, coordination files.
- **Submodule** (`temporalio/skill-temporal-developer`) at `plugins/temporal-developer/skills/temporal-developer/`: The actual skill content — `SKILL.md` and `references/`.

## Branch / Development Workflow

Both repos use `dev` as the primary working branch. Feature branches branch from and merge into `dev`, never directly into `main`.

1. Branch from `dev`, do feature work, merge feature branch → `dev` (in the submodule)
2. Bump outer repo's submodule pointer on outer `dev` to point to latest submodule `dev` (can push directly, PR not necessary)
3. Dogfood test on `dev`

## Release Workflow

Use the `/release` skill to run the release pipeline. It is implemented as a Temporal workflow (`.claude/skills/release/`) with a CLI client for sending signals at human checkpoints. The `/release` skill has full instructions — do not manually perform these steps.

For reference, the release has three stages:

- **Phase 1 (Internal):** Version bump in submodule, update outer repo `dev` (submodule pointer + `plugin.json`). Optional dogfood testing.
- **Phase 2 (External):** Merge submodule `dev` → `main` (via PR, requires human review), then merge outer `dev` → `main`. Fast-forward `dev` to `main` in both repos afterward.
- **Codex (after Phase 2):** Sync fork, copy plugin to `temporalio/openai-plugins:temporal`, open/update PR to `openai/plugins`. Can also be run standalone via `--codex-only`.

Version in `SKILL.md` frontmatter and `plugin.json` must always match.

Codex review feedback: content changes go through the full pipeline; `.codex-plugin/`-only changes can use `--codex-only`.

## sdk-versions.json

Tracks SDK versions against which reference files were last verified. Updated during specific SDK-update PRs, not as part of general content work.
