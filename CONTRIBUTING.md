# Contributing

Thanks for your interest in contributing to the Temporal Developer skill!

## Where to make changes

All skill content lives in the submodule at `plugins/temporal-developer/skills/temporal-developer/`. This is a separate repo ([temporalio/skill-temporal-developer](https://github.com/temporalio/skill-temporal-developer)) included here as a Git submodule.

**Work within the submodule.** The outer repo (`agent-skills`) contains coordination and tracking files managed by maintainers. Contributors should focus on the submodule, where the skill definition (`SKILL.md`) and reference files (`references/`) live.

## Branching

The default branch for development is `dev`, not `main`. Please branch from `dev` and open PRs against `dev`.

PRs to `main` will not be accepted — `main` is updated only during releases by merging `dev`.

## Making a PR

1. Fork or clone the submodule repo
2. Create a feature branch from `dev`
3. Make your changes
4. Open a PR targeting `dev`

## What to contribute

- Fix incorrect code examples or outdated API usage
- Improve clarity of explanations
- Add coverage for missing SDK features

## Questions?

Open an issue on the [skill-temporal-developer](https://github.com/temporalio/skill-temporal-developer) repo.
