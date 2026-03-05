---
name: git-commit
description: "Commit pending changes to git. Use when the user says 'commit', 'commit my changes', 'commit all', 'commit everything', 'save my work to git', 'stage and commit', or any variation of wanting to create a git commit. Accepts an optional argument describing what to commit (e.g. 'all changes', 'staged only', specific file names, etc.)."
model: claude-sonnet-4-6
---

Commit pending changes to git.
Do not push these new commits unless also asked to do so.

## Workflow

Start by running `git status` to check the current state.

### If anything is already staged

Commit exactly what is staged as a **single commit**. Do not split it into multiple commits, do not stage additional files, and do not unstage anything. The user has curated the staging area intentionally — respect it.

If the user provided an argument mentioning specific files but something different is staged, tell the user about the mismatch and ask how to proceed rather than silently changing the staging area.

### If nothing is staged

Analyze all pending changes (unstaged modifications, untracked files) and determine how to group them into logical commits. Consider:

- **File proximity**: changes in the same module/directory often belong together
- **Semantic cohesion**: related changes (e.g., a feature + its tests + its docs) should be one commit
- **Independence**: unrelated changes (e.g., a bug fix and a new feature) should be separate commits

Then stage and commit each group in sequence. If the user's argument narrows the scope (specific files, "all", etc.), honor that:
- Specific files or paths → stage and commit only those files (single commit)
- "all", "everything" → stage everything (`git add -A`) and split into logical commits if warranted
- If all changes are cohesive → a single commit is fine; don't split for the sake of splitting

## Commit messages
- Keep subject line concise (≤ 50 chars recommended)
- Write in imperative mood (e.g., use "Add feature", not "Added feature" or "Adds feature")
- Each commit should represent a single logical change

## Windows path handling
- If you are already in the correct directory, run `git` commands directly — don't prepend `cd <path> &&`.
- In git bash on Windows, these path forms are equivalent: `D:\foo`, `D:/foo`, `/d/foo`. Don't try to cd between them.

## Critical Error Handling
- If `git commit` fails with "1Password: agent returned an error", STOP immediately
- DO NOT retry without signing - user is AFK and 1Password awaits authentication
- Inform user and wait for them to authenticate
