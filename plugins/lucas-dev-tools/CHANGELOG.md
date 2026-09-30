# Changelog

## [1.27.0] - 2026-09-30

### Removed
- Remove the add-todo, address-pr-comments, git-commit, ship, update-changelog, update-docs, update-github-actions, update-pr-description, and whats-next skills, which moved to the agent-skills repository

## [1.26.0] - 2026-09-10

### Changed
- Update address-pr-comments to assess each review comment before asking for a disposition, add a "No code change" outcome, and decouple pushing from replying to no-code-change threads

## [1.25.0] - 2026-08-26

### Removed
- Remove the review-pr and review-pr-ultra skills

## [1.24.0] - 2026-08-18

### Changed
- Restrict all skills to explicit `/skill-name` invocation instead of letting Claude auto-trigger them from conversation
- Drop the now-unused `when_to_use` trigger-phrase field from each skill's frontmatter

## [1.23.0] - 2026-08-07

### Removed
- Remove the `redundant-cd` PreToolUse rule that flagged `cd <path> && <command>` and `git -C <path> <command>` when already in the target directory

## [1.22.0] - 2026-05-15

### Changed
- Make whats-next print a sorted task list and stop, instead of using AskUserQuestion and starting work on the selected task
- Update whats-next description and when_to_use to reflect listing tasks rather than picking and working on one

## [1.21.0] - 2026-05-13

### Removed
- Remove get-open-prs, copy-pr-link, and copy-pwd skills (including the get-open-prs helper script)

## [1.20.0] - 2026-05-13

### Changed
- Simplify whats-next to stop after presenting the prioritized task list, dropping the plan/execute and wrap-up steps

## [1.19.0] - 2026-05-11

### Changed
- `address-pr-comments`: harden against prompt injection from untrusted PR comment bodies. Defer agent explanation and correctness evaluation until the user picks "Fix it"; pre-approval reads are limited to the cited file ±15 lines. Add an explicit treat-as-data preamble that lists scope-expanding directives (reading unrelated secrets/credentials, running unrequested shell/network commands, editing CI/auth files, injecting text into commits or replies) the skill must refuse.
- `address-pr-comments`: default reply draft is now the literal template `Fixed. <≤80 char diff summary>`; free-form replies require explicit "Edit". The agent only fills the diff-summary field.
- `address-pr-comments`: stop filtering review-thread comments by author. Automated reviewers (Codex, Copilot Code Review, CodeRabbit) are addressed alongside human comments. Replace the unreliable login-suffix bot heuristic with GraphQL `author.__typename`; bot-authored comments get a `[🤖]` prefix in the listing for visual distinction.

## [1.18.0] - 2026-04-28

### Changed
- Rewrite `review-pr-ultra` as a thin wrapper that dispatches `/code-review:code-review` and the `pr-review-toolkit` agents in parallel, presents findings side by side, then hands off to `review-pr` for the fix or post phase. Drops the redundant local review pass, the pre-fetch step, and the cross-source collation/dedup logic — the two upstream skills use different severity scales and filtering, so cross-source agreement is for the user to weigh
- Reference `review-pr`'s Fix Flow / Post Flow from `review-pr-ultra` instead of restating them, eliminating drift between the two skills
- Drop the generic analysis category list from `review-pr` review steps and fold the orphaned "Comment Format" guidance into Post Flow where it actually applies

### Fixed
- Stop early in both `review-pr` and `review-pr-ultra` when `gh pr diff` returns an empty diff

## [1.17.0] - 2026-04-27

### Changed
- Replace `review-pr` two-mode (local/post) split with three explicit modes selected by an optional argument: `findings` (read-only summary), `fix` (apply local fixes as commits), `post` (post comments to GitHub). When no argument is given, the skill runs the findings phase first, then asks whether to fix, post, or stop
- Apply the same three-mode argument and findings-first prompt to `review-pr-ultra`
- Add `argument-hint: "[findings|fix|post]"` to both skills so the CLI surfaces mode options in autocomplete

## [1.16.0] - 2026-04-24

### Added
- Add `review-pr-ultra` skill: runs three PR review passes in parallel (the `review-pr` logic, the `/code-review:code-review` workflow via a subagent, and the `/pr-review-toolkit:review-pr` specialized agents) and collates the findings into a single deduplicated, severity-sorted list before running the same interactive fix flow as `review-pr`

## [1.15.1] - 2026-04-23

### Fixed
- Mark `posttool-1password-retry.sh` hook script as executable so it runs on systems that honor the exec bit (macOS, Linux, WSL)
- Mark `get-open-prs.sh` as executable for consistency with its `#!/bin/bash` shebang

## [1.15.0] - 2026-04-23

### Changed
- Make `review-pr` local mode interactive: ask what to do for each issue, apply fixes in order, and commit after each code change
- Label `review-pr` severities with colored emoji (🔴 CRITICAL, 🟠 HIGH, 🟡 MEDIUM, 🟢 LOW)

## [1.14.10] - 2026-04-22

### Changed
- Fork the `review-pr` and `update-docs` skills into isolated subagents (Explore / general-purpose) so their read-heavy work doesn't pollute the main conversation context

## [1.14.9] - 2026-04-22

### Changed
- Split each skill's `description` into separate `description` + `when_to_use` frontmatter fields so action-focused text comes first and trigger phrases are scoped separately

## [1.14.8] - 2026-04-22

### Changed
- Colocate the `get-open-prs` helper script under its skill directory and reference it via `${CLAUDE_SKILL_DIR}`

## [1.14.7] - 2026-04-22

### Changed
- Move 1Password commit-retry guidance from PreToolUse to PostToolUseFailure so it only fires when a commit actually fails with that specific error, instead of on every commit attempt

## [1.14.6] - 2026-04-22

### Changed
- Scope PreToolUse Bash hook with per-rule `if:` matchers so the hook only fires on relevant commands (cd, git -C, gh api, git commit) instead of every bash call

## [1.14.3] - 2026-03-21

### Removed
- Revert model hints added in v1.14.2

## [1.14.1] - 2026-03-17

### Changed
- Improve whats-next skill: use `/plan` for planning, add fallback ordering, conditional wrap-up steps
- Improve add-todo skill: conditional research, duplicate detection, task granularity guidance
- Update descriptions for whats-next and add-todo skills for better triggering accuracy

## [1.14.0] - 2026-03-15

### Added
- Add `.ship.yml` config file for config-driven ship skill

### Changed
- Rename update-actions skill to update-github-actions

## [1.13.4] - 2026-03-15

### Added
- Add `release` action to ship skill for updating GitHub releases with changelog content after CI
- Add consistent formatting rules to update-changelog skill for CHANGELOG.md and GitHub releases

### Changed
- Improve ship skill auto-detect logic and release action delegation instructions
- Add edge case handling to update-changelog skill (ISO date format, new file writes, tag rationale)

## [1.13.3] - 2026-03-15

### Fixed
- Fix jq escape issue in update-actions skill: replace `\\.` with `[.]` to avoid misrendered escape sequences

## [1.13.2] - 2026-03-15

### Changed
- Add allowed-tools to update-actions skill

## [1.13.1] - 2026-03-15

### Changed
- Remove model override from ship, update-changelog, update-actions skills

## [1.13.0] - 2026-03-15

### Added
- Add update-changelog skill for managing CHANGELOG.md files and GitHub releases
- Integrate update-changelog with ship skill

## [1.12.0] - 2026-03-15

### Added
- Add update-actions skill for pinning GitHub Actions to commit SHAs

## [1.11.1] - 2026-03-15

### Changed
- Remove model override from git-commit skill

## [1.11.0] - 2026-03-14

### Removed
- Remove redundant plan-and-execute skill

## [1.10.1] - 2026-03-13

### Fixed
- Block $TMP/$TEMP in tmp-path rule

## [1.10.0] - 2026-03-13

### Changed
- Improve get-open-prs skill: clickable PR links, fix description and allowed-tools
- Add watch action to ship skill for CI workflow monitoring

## [1.9.0] - 2026-03-13

### Added
- Add tmp-path hook to block /tmp on Git Bash for Windows

## [1.8.6] - 2026-03-13

### Changed
- Add age/sort to get-open-prs

## [1.8.5] - 2026-03-13

### Changed
- Add review triggers, drop @ prefix in get-open-prs

## [1.8.4] - 2026-03-12

### Changed
- Simplify get-open-prs: approver names, no pagination, cap at 30

## [1.8.3] - 2026-03-12

### Changed
- Use owner/repo arg format, add imperative execution directive

## [1.8.2] - 2026-03-12

### Changed
- Extract get-open-prs into script, filter bots by default

## [1.8.1] - 2026-03-12

### Fixed
- Fix get-open-prs review dedup, add pagination and table format

## [1.8.0] - 2026-03-12

### Added
- Add get-open-prs skill

## [1.7.0] - 2026-03-11

### Added
- Add add-todo skill

## [1.6.2] - 2026-03-09

### Changed
- Add allowed-tools to ship skill

## [1.6.1] - 2026-03-09

### Changed
- Add auto-detect actions to ship skill

## [1.6.0] - 2026-03-09

### Changed
- Add argument-hint to ship, copy-pr-link, address-pr-comments skills
- Add push argument and argument-hint to git-commit skill

## [1.5.0] - 2026-03-09

### Added
- Add ship skill

### Removed
- Remove commit-and-push skill (replaced by ship)

## [1.4.1] - 2026-03-09

### Fixed
- Fix single-quote handling in redundant-cd hook

## [1.4.0] - 2026-03-07

### Added
- Add plan-and-execute, commit-and-push, whats-next skills

## [1.3.1] - 2026-03-06

### Fixed
- Fix redundant-cd hook for quoted paths

## [1.3.0] - 2026-03-06

### Added
- Move bash hook rules into lucas-dev-tools plugin

## [1.2.4] - 2026-03-05

### Changed
- Use Sonnet for git-commit skill

## [1.2.3] - 2026-03-04

### Changed
- Improve git-commit skill staging logic

## [1.2.2] - 2026-03-03

### Changed
- Add Windows path notes to git-commit skill

## [1.2.1] - 2026-03-03

### Changed
- Use haiku model for simple skills

## [1.2.0] - 2026-03-02

### Changed
- Simplify update-docs skill

## [1.0.2] - 2026-02-28

### Changed
- Improve skills and documentation

## [1.0.0] - 2026-02-27

### Added
- Initial release with 7 skills: git-commit, review-pr, update-docs, update-pr-description, address-pr-comments, copy-pr-link, copy-pwd
