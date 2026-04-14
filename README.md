# Temporal Developer Plugin for Claude Code

This repository provides a [Claude Code plugin](https://code.claude.com/docs/en/plugins) for developing [Temporal](https://temporal.io/) applications.

> [!WARNING]
> This plugin is in Public Preview, and will continue to evolve and improve.
> We would love to hear your feedback - positive or negative - over in the [Community Slack](https://t.mp/slack), in the [#topic-ai channel](https://temporalio.slack.com/archives/C0818FQPYKY)

## Installation

**Step 1:** Marketplace Installation

1. Run `/plugin marketplace add temporalio/claude-temporal-plugin`
2. Run `/plugin` to open the plugin manager
3. Select **Marketplaces**
4. Choose `temporal-marketplace` from the list
5. Select **Enable auto-update** or **Disable auto-update**

**Step 2:** Plugin Installation
1. Run `/plugin install temporal-developer@temporal-marketplace`
2. Restart Claude Code

## What's Included

- **temporal-developer** skill — Comprehensive guidance for developing Temporal applications: creating workflows, activities, and workers; handling signals, queries, and updates; debugging non-determinism errors; implementing saga patterns, versioning strategies, and testing approaches across Python, TypeScript, Go, and Java SDKs.

## Standalone Skill

The skill content is derived from [temporalio/skill-temporal-developer](https://github.com/temporalio/skill-temporal-developer). If you only need the skill without the plugin wrapper, you can install it directly from that repo.

## Other Coding Agents

- **Cursor**: See [temporalio/cursor-temporal-plugin](https://github.com/temporalio/cursor-temporal-plugin)
- **OpenAI Codex**: See [temporalio/codex-temporal-plugin](https://github.com/temporalio/codex-temporal-plugin)

## License

MIT
