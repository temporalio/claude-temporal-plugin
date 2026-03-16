---
name: translate-skill-to
description: Translates the skill to another language
disable-model-invocation: true
---

The skill at @plugins/temporal-developer/skills/temporal-developer/ currently supports Python and TypeScript. Your task is to add
support for $ARGUMENTS. 

First, make sure that we are working off of a fresh branch for both this repo and the git submodule at plugins/temporal-developer/skills/temporal-developer. The branch should be branched from `dev`. If the user is already on a feature branch or has non-clean Git state, communicate with the user, DON'T just nuke their git state.

You will then add support for $ARGUMENTS in phases:

1) Create/update alignment docs for the $ARGUMENTS content, to determine * what is appropriate for $ARGUMENTS *. Many things in core/python/typescript
  will be directly relevant for $ARGUMENTS. But somethings might not be (sandboxing, etc.). You must determine these case-by-case, using the
  temporal docs mcp server. Expected output of this step: updated/new alignment tracking docs. Do not yet write actual content / code
  examples. Make sure not to remove/overwrite all the existing notes (Python, TypeScript, etc.) as those are important to keep. Once approved, commit it.

2) Create all the code examples for $ARGUMENTS, that are specified in the alignment tracking docs you just wrote. They should follow
  stylistic guidelines that generally match the Python and TypeScript content, but obviously should be appropriate for $ARGUMENTS. You should likely use the temporal docs MCP server to lookup code samples. This step is potentially massively parallizable. When done, commit it.

3) Do a detailed self-review pass for *alignment* level issues for $ARGUMENTS, compared to Python/TypeScript. Don't yet worry about correctnss, just presence/lack of content, and more/less verbosity. Mistakes you likely made: a) Python had a section who's content is merely just "See ... for more info". In $ARGUMENTS you incorrectly filled that out with full content. b) Missing section/subsections. c) Slightly differently named sections for no reason. As you work through this self-review, you may find that the alignment tracking docs were unclear/ambiguous. If that is the case, up them for clarity. When all done, commit this.

4) Do a correctness checking pass, to look for issues. Do not yet fix any issues, just identify them and update the correctness
  tracking doc with reserach on what the appropriate fix is. This step is potentially massively parallizable. Make sure not to remove/overwrite all the existing notes (Python, TypeScript, etc.) as those are important to keep. Ask for review from user about all correctness issues and your ideas for fixes. When approved, commit this.

5) Apply the correctness edits to the actual content files. This step is potentially massively parallizable. When done, commit this.

6) Update all files that reference supported languages to include $ARGUMENTS:
  - `SKILL.md` frontmatter `description` field: add trigger phrases like "Temporal $ARGUMENTS"
  - `SKILL.md` Overview: update the list of supported languages
  - `SKILL.md` Getting Started > Read All Relevant References: add entry for $ARGUMENTS
  - `references/core/determinism.md` SDK Protection Mechanisms: add $ARGUMENTS entry describing its determinism enforcement approach
  - Any other `core/` files that enumerate languages explicitly
  When done, commit this.

Do these steps one at a time, asking for human review after each step.

Make sure to use the /edit-plugin-skills skill to have an understanding of how to work with the alignment and correctness tracking docs.

As a general rule, prefer the temporal-docs server over context7, as it is generally more accurate. Use context7 to fill in information you can't otherwise get.
