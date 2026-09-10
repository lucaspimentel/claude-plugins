# lucasp-claude-plugins

Personal [Claude Code](https://claude.ai/code) plugin marketplace by Lucas Pimentel.

## Plugins

| Plugin | Version | Description |
|---|---|---|
| [atlassian-cli](plugins/atlassian-cli/README.md) | 1.0.0 | Atlassian CLI (`acli`) usage for Jira and Confluence |
| [chezmoi](plugins/chezmoi/README.md) | 1.0.5 | Chezmoi dotfile management and diff resolution |
| [linters](plugins/linters/README.md) | 1.2.0 | Auto-lint edited files via PostToolUse hooks |
| [lucas-dev-tools](plugins/lucas-dev-tools/README.md) | 1.26.0 | Developer workflow utilities for day-to-day use |
| [windows-notify](plugins/windows-notify/README.md) | 1.4.0 | Windows toast notifications *(Windows / WSL only)* |
| [windows-terminal](plugins/windows-terminal/README.md) | 1.1.1 | Windows Terminal pane and tab management *(Windows / WSL only)* |

## Installation

### From the CLI

1. Add the marketplace:
   ```sh
   claude plugin marketplace add https://github.com/lucaspimentel/claude-plugins
   ```

2. Install a plugin:
   ```sh
   claude plugin install lucas-dev-tools@lucasp-claude-plugins
   claude plugin install atlassian-cli@lucasp-claude-plugins
   claude plugin install chezmoi@lucasp-claude-plugins
   claude plugin install windows-notify@lucasp-claude-plugins
   claude plugin install linters@lucasp-claude-plugins
   claude plugin install windows-terminal@lucasp-claude-plugins
   ```

### From inside Claude Code

1. Add the marketplace:
   ```
   /plugin marketplace add https://github.com/lucaspimentel/claude-plugins
   ```

2. Install a plugin:
   ```
   /plugin install lucas-dev-tools@lucasp-claude-plugins
   /plugin install atlassian-cli@lucasp-claude-plugins
   /plugin install chezmoi@lucasp-claude-plugins
   /plugin install windows-notify@lucasp-claude-plugins
   /plugin install linters@lucasp-claude-plugins
   /plugin install windows-terminal@lucasp-claude-plugins
   ```

### Local development

For local development, use a local path instead of the GitHub URL:

From the CLI:
```sh
claude plugin marketplace add ./path/to/lucas-claude-plugins
```

From inside Claude Code:
```
/plugin marketplace add ./path/to/lucas-claude-plugins
```

## License

This project is licensed under the [MIT License](LICENSE).

## Development

This project was developed with help from [Claude Code](https://claude.ai/code) 🤖
