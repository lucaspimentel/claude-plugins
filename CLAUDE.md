# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture

This repo is a Claude Code plugin marketplace. The root `.claude-plugin/marketplace.json` declares the marketplace and points to `./plugins/` as the plugin root.

Each plugin lives under `plugins/<plugin-name>/` and contains:
- `.claude-plugin/plugin.json` — plugin metadata
- `skills/<skill-name>/SKILL.md` — one skill per subdirectory; the frontmatter `name` and `description` fields control how Claude triggers the skill

## Adding a Skill

1. Create `plugins/<plugin>/skills/<skill-name>/SKILL.md`
2. Add YAML frontmatter with `name` and `description`
3. Write the skill instructions in the body (markdown)

Skills are auto-discovered from the `skills/` directory — no registration in `plugin.json` needed.

## Installing the Marketplace Locally

```sh
/plugin marketplace add ./path/to/lucas-claude-plugins
/plugin install lucas-dev-tools@lucas-plugins
```

To test a skill after changes, reinstall the plugin or reload Claude Code.

## Reference Docs

- [Plugins](https://code.claude.com/docs/en/plugins.md) — overview, plugin structure, skills, hooks, subagents
- [Plugins Reference](https://code.claude.com/docs/en/plugins-reference.md) — full schema for `plugin.json`, `SKILL.md`, and other plugin files
- [Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces.md) — `marketplace.json` format and how marketplaces work

## Creating and Improving Skills

Use the `skill-creator` skill when creating new skills or iteratively improving existing ones. It guides you through drafting, running test cases, evaluating outputs, and optimizing the skill description for triggering accuracy.
