---
name: git-commit
description: "Commit pending changes to git. Use when the user says 'commit', 'commit my changes', 'commit all', 'commit everything', 'save my work to git', 'stage and commit', or any variation of wanting to create a git commit. Accepts an optional argument: 'all' (stage everything) or 'staged' (default, commit only staged changes)."
---

Commit pending changes to git.
Do not push these new commits unless also asked to do so.

## Arguments

- Optional: `all` or `staged` (default: `staged`)
  - `staged` — only commit already-staged changes. If nothing is staged, inform the user and stop.
  - `all` — stage all changes (`git add -A`) before committing.

## Instructions
- Keep commit message concise and in a single line (subject line ≤ 50 chars recommended)
- Write in imperative mood (e.g., "Add feature" not "Added feature")
- If there are many unrelated changes, split into multiple logical commits
- Each commit should represent a single logical change

## Critical Error Handling
- If `git commit` fails with "1Password: agent returned an error", STOP immediately
- DO NOT retry without signing - user is AFK and 1Password awaits authentication
- Inform user and wait for them to authenticate
