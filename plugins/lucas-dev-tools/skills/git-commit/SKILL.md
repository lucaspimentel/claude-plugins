---
name: git-commit
description: "Commit pending changes to git. Use when the user says 'commit', 'commit my changes', 'commit all', 'commit everything', 'save my work to git', 'stage and commit', or any variation of wanting to create a git commit. Accepts an optional argument describing what to commit (e.g. 'all changes', 'staged only', specific file names, etc.)."
---

Commit pending changes to git.
Do not push these new commits unless also asked to do so.

## Determining what to stage

Interpret the user's argument (if any) naturally:
- If the user mentions specific files or paths → stage only those files
- If the user says "all", "everything", "all changes", or similar → stage all changes (`git add -A`)
- If the user says "staged", "staged only", "only staged", or similar → commit only what is already staged; if nothing is staged, inform the user and stop
- If no argument is given:
  1. Check if anything is already staged (`git status`)
  2. If yes → commit only what is staged
  3. If nothing is staged → stage all changes (`git add -A`) and commit

## Instructions
- Keep commit message concise and in a single line (subject line ≤ 50 chars recommended)
- Write in imperative mood (e.g., "Add feature" not "Added feature")
- If there are many unrelated changes, split into multiple logical commits
- Each commit should represent a single logical change

## Critical Error Handling
- If `git commit` fails with "1Password: agent returned an error", STOP immediately
- DO NOT retry without signing - user is AFK and 1Password awaits authentication
- Inform user and wait for them to authenticate
