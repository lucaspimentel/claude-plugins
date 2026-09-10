# lucas-dev-tools v1.26.0

Developer workflow utilities for day-to-day use inside Claude Code.

See [installation instructions](../../README.md#installation).

## Skills

| Skill | Description |
|---|---|
| `git-commit` | Stage and commit changes with an auto-generated message |
| `address-pr-comments` | Walk through PR review comments one at a time and address them |
| `update-docs` | Update project documentation based on recent changes |
| `update-pr-description` | Update the PR title and description to reflect the current changes |
| `ship` | Run release actions: version, changelog, docs, commit, tag, push, watch, release |
| `update-github-actions` | Update and pin GitHub Actions in workflow files to commit SHAs |
| `update-changelog` | Manage CHANGELOG.md files and GitHub releases |
| `whats-next` | Show a sorted list of incomplete tasks from TODO.md |
| `add-todo` | Add new tasks to TODO.md with research context |

## Hooks

A PreToolUse hook validates Bash commands before execution:

| Rule | Action | Disable env var | Description |
|---|---|---|---|
| `gh-api-slash` | Block | `DISABLE_GH_API_SLASH_RULE=1` | Reject `gh api /...` (leading slash is wrong) |
| `tmp-path` | Block | `DISABLE_TMP_PATH_RULE=1` | Reject `/tmp` usage on Git Bash for Windows; suggest real Windows temp path via `cygpath -w $TMP` |
| `1password-commit-retry` | Warn | `DISABLE_1PASSWORD_RULE=1` | Remind not to retry if `git commit` fails with a 1Password error |
