# Contributing

Thanks for your interest in contributing to the Temporal Developer skill!

## Where to make changes

Skill content (the skill definition and reference files) is maintained in the canonical upstream repo: [temporalio/skill-temporal-developer](https://github.com/temporalio/skill-temporal-developer). Changes to skill content should be made there, not in this plugin repo.

This repo (`claude-temporal-plugin`) packages that content for distribution via the Claude Code plugin marketplace. Changes here should be limited to plugin configuration, marketplace metadata, tests, and Claude Code-specific adaptations.

## Branching

The default branch for development is `dev`, not `main`. Please branch from `dev` and open PRs against `dev`.

PRs to `main` will not be accepted — `main` is updated only during releases by merging `dev`.

## Making a PR

### Skill content (references, SKILL.md)

1. Fork or clone [temporalio/skill-temporal-developer](https://github.com/temporalio/skill-temporal-developer)
2. Create a feature branch from `dev`
3. Make your changes
4. Open a PR targeting `dev`

### Plugin configuration (plugin.json, marketplace.json, tests, docs)

1. Fork or clone this repo
2. Create a feature branch from `dev`
3. Make your changes
4. Open a PR targeting `dev`

## What to contribute

- Fix incorrect code examples or outdated API usage
- Improve clarity of explanations
- Add coverage for missing SDK features

## Questions?

Open an issue on the [skill-temporal-developer](https://github.com/temporalio/skill-temporal-developer) repo.
