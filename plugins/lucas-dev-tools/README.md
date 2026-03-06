# lucas-dev-tools v1.3.1

Developer workflow utilities for day-to-day use inside Claude Code.

## Skills

| Skill | Description |
|---|---|
| `git-commit` | Stage and commit changes with an auto-generated message |
| `address-pr-comments` | Walk through PR review comments one at a time and address them |
| `copy-pr-link` | Copy the current PR URL as a markdown link to the clipboard |
| `copy-pwd` | Copy the current working directory path to the clipboard |
| `update-docs` | Update project documentation based on recent changes |
| `update-pr-description` | Update the PR title and description to reflect the current changes |
| `review-pr` | Review a pull request for issues and feedback |

## Hooks

A PreToolUse hook validates Bash commands before execution:

| Rule | Action | Disable env var | Description |
|---|---|---|---|
| `gh-api-leading-slash` | Block | `DISABLE_GH_API_SLASH_RULE=1` | Reject `gh api /...` (leading slash is wrong) |
| `redundant-cd` | Block | `DISABLE_REDUNDANT_CD_RULE=1` | Reject `cd <path> &&` or `git -C <path>` when already in that directory |
| `1password-commit-retry` | Warn | `DISABLE_1PASSWORD_RULE=1` | Remind not to retry if `git commit` fails with a 1Password error |
