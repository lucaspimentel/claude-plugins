# lucas-dev-tools v1.27.0

Developer workflow hooks for day-to-day use inside Claude Code. The workflow skills (commit, PR, changelog, release, TODO) now live in the agent-skills repository.

See [installation instructions](../../README.md#installation).

## Hooks

A PreToolUse hook validates Bash commands before execution:

| Rule | Action | Disable env var | Description |
|---|---|---|---|
| `gh-api-slash` | Block | `DISABLE_GH_API_SLASH_RULE=1` | Reject `gh api /...` (leading slash is wrong) |
| `tmp-path` | Block | `DISABLE_TMP_PATH_RULE=1` | Reject `/tmp` usage on Git Bash for Windows; suggest real Windows temp path via `cygpath -w $TMP` |
| `1password-commit-retry` | Warn | `DISABLE_1PASSWORD_RULE=1` | Remind not to retry if `git commit` fails with a 1Password error |
