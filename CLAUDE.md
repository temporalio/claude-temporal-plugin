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

There is no package publishing — merging to `main` IS the release.

1. Bump the skill version in the submodule via PR merged to submodule `dev`. Ask the user whether major, minor, or patch (semver). Update both places (must always match):
   - `plugins/temporal-developer/skills/temporal-developer/SKILL.md` (frontmatter `version:`)
   - `plugins/temporal-developer/.claude-plugin/plugin.json` (`"version"`)
2. Merge submodule `dev` → `main`
3. Bump outer repo's submodule pointer (on outer `dev`) to point to latest submodule `main`
4. Merge outer `dev` → `main`

## sdk-versions.json

Tracks SDK versions against which reference files were last verified. Updated during specific SDK-update PRs, not as part of general content work.
