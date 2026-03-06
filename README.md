# lucasp-claude-plugins

Personal [Claude Code](https://claude.ai/code) plugin marketplace by Lucas Pimentel.

## Plugins

| Plugin | Version | Description |
|---|---|---|
| [lucas-dev-tools](plugins/lucas-dev-tools/README.md) | 1.3.0 | Developer workflow utilities for day-to-day use |
| [chezmoi](plugins/chezmoi/README.md) | 1.0.4 | Chezmoi dotfile management and diff resolution |
| [windows-notify](plugins/windows-notify/README.md) | 1.2.5 | Windows toast notifications *(Windows / WSL only)* |
| [linters](plugins/linters/README.md) | 1.0.2 | Auto-lint edited files via PostToolUse hooks |
| [windows-terminal](plugins/windows-terminal/README.md) | 1.1.1 | Windows Terminal pane and tab management *(Windows / WSL only)* |

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
   /plugin install linters@lucasp-claude-plugins
   /plugin install windows-terminal@lucasp-claude-plugins
   ```

For local development, use a local path instead:
```sh
/plugin marketplace add ./path/to/lucas-claude-plugins
```

## License

This project is licensed under the [MIT License](LICENSE).

## Development

This project was developed with help from [Claude Code](https://claude.ai/code) 🤖
