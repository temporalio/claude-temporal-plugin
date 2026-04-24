# Temporal Plugin for Claude Code

This repository provides a [Claude Code plugin](https://code.claude.com/docs/en/plugins) for working with [Temporal](https://temporal.io/) — developing applications, using the CLI, managing server, and working with Temporal Cloud.

> [!WARNING]
> This plugin is in Public Preview, and will continue to evolve and improve.
> We would love to hear your feedback - positive or negative - over in the [Community Slack](https://t.mp/slack), in the [#topic-ai channel](https://temporalio.slack.com/archives/C0818FQPYKY)

## Installation

From inside Claude Code, run:

1. `/plugin marketplace add temporalio/claude-temporal-plugin`
2. `/plugin install temporal@temporal-marketplace`

Then run `/reload-plugins` to activate the plugin in the current session.

### Alternative: interactive install

1. Run `/plugin` to open the plugin manager
2. Select **Marketplaces**
3. Choose `temporal-marketplace` from the list
4. Select **Enable auto-update** or **Disable auto-update**
5. Install the `temporal` plugin
6. Run `/reload-plugins`

## What's Included

- **temporal-developer** skill — Comprehensive guidance for developing Temporal applications: creating workflows, activities, and workers; handling signals, queries, and updates; debugging non-determinism errors; implementing saga patterns, versioning strategies, and testing approaches across Python, TypeScript, Go, and Java SDKs.

## Standalone Skill

The skill content is derived from [temporalio/skill-temporal-developer](https://github.com/temporalio/skill-temporal-developer). If you only need the skill without the plugin wrapper, you can install it directly from that repo.

## Other Coding Agents

- **Cursor**: See [temporalio/cursor-temporal-plugin](https://github.com/temporalio/cursor-temporal-plugin)
- **OpenAI Codex**: See [temporalio/codex-temporal-plugin](https://github.com/temporalio/codex-temporal-plugin)

## License

MIT
