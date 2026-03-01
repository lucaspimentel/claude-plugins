# lucasp-claude-plugins

Personal [Claude Code](https://claude.ai/code) plugin marketplace by Lucas Pimentel.

## Plugins

### lucas-dev-tools

Developer workflow utilities for day-to-day use inside Claude Code.

| Skill | Description |
|---|---|
| `git-commit` | Stage and commit changes with an auto-generated message |
| `address-pr-comments` | Walk through PR review comments one at a time and address them |
| `copy-pr-link` | Copy the current PR URL as a markdown link to the clipboard |
| `copy-pwd` | Copy the current working directory path to the clipboard |
| `update-docs` | Update project documentation based on recent changes |
| `update-pr-description` | Regenerate the PR description from recent commits |
| `review-pr` | Run a comprehensive code review on the current PR |

### chezmoi

Chezmoi dotfile management: diff resolution, file sync between source and destination.

| Skill | Description |
|---|---|
| `chezmoi-diff` | Resolve differences between chezmoi-managed dotfiles and local files |

### windows-notify

Sends Windows toast notifications when Claude Code needs your attention (e.g. permission prompts, idle prompts). No skills — works automatically once installed.

## Installation

1. Add the marketplace:
   ```sh
   /plugin marketplace add https://github.com/lucaspimentel/claude-plugins
   ```

2. Install a plugin:
   ```sh
   /plugin install lucas-dev-tools@lucasp-claude-plugins
   /plugin install chezmoi@lucasp-claude-plugins
   /plugin install windows-notify@lucasp-claude-plugins
   ```

For local development, use a local path instead:
```sh
/plugin marketplace add ./path/to/lucas-claude-plugins
```
