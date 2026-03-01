---
name: update-docs
description: "Update project documentation based on recent changes and current codebase state. Use when the user says 'update docs', 'update readme', 'sync docs', 'docs are stale', 'update CLAUDE.md', 'refresh documentation', or any variation of wanting documentation updated."
---

Verify and update project documentation so it accurately reflects the current state of the codebase.
Do not commit or push the changes to git unless also asked to do so.
Do not include volatile metrics (test counts, coverage percentages, line counts) that become stale quickly.

## Phase 1 — Audit (Explore subagent)

Spawn an Explore subagent (subagent_type: "Explore", thoroughness: "very thorough") to perform a read-only audit of all documentation. The subagent cannot edit files, so its job is purely to investigate and report back.

Give the subagent these instructions (adapt paths to the current project):

> Audit every documentation file in this project. The goal is to find everything that is wrong, missing, or outdated so someone else can fix it.
>
> **Step 1 — Find all doc files.** Glob for `**/*.md` and also check for common doc locations: `./CLAUDE.md`, `./.claude/CLAUDE.md`, `./AGENTS.md`, `./README.md`, `./TODO.md`, and any `README.md` files in subdirectories.
>
> **Step 2 — Read each doc file.** For every doc file found, read it and extract every verifiable claim: file paths, directory structures, command examples, architecture descriptions, setup steps, dependency lists, feature lists, convention descriptions.
>
> **Step 3 — Verify claims against the codebase.** For each claim, use Glob, Grep, Read, and Bash to check whether it is still accurate. Examples:
> - A documented file path → does the file exist?
> - A listed set of features/skills/modules → does it match what actually exists?
> - A command example → do the referenced scripts/tools exist?
> - An architecture description → does the actual directory structure match?
>
> Also use `git log --oneline -20` and `git diff` as supplementary signals to find areas that may have drifted recently.
>
> **Step 4 — Check for undocumented items.** Look for important things that exist in the codebase but are not mentioned in any doc file (e.g., a plugin that has no README entry, a config file with no explanation).
>
> **Step 5 — Return a structured report** with these sections:
>
> ### Inaccuracies
> Items where the docs say one thing but the codebase says another. For each: which file, which claim, what's wrong, what the correct state is.
>
> ### Missing Documentation
> Important things in the codebase that have no documentation. For each: what it is, where it lives, what should be documented.
>
> ### Stale References
> Paths, commands, or names that no longer exist. For each: which file, which line, what to remove or replace.
>
> ### Confirmed Correct
> A brief summary of claims that were verified and are still accurate (so the editor knows what not to touch).

## Phase 2 — Apply fixes (main agent)

Once the subagent returns its report, work through the findings and apply edits:

### AI-Optimized Documentation
- Check if CLAUDE.md exists (look in: `./CLAUDE.md`, `./.claude/CLAUDE.md`, `./CLAUDE.MD`)
- If CLAUDE.md only references AGENTS.md, leave CLAUDE.md alone and update AGENTS.md instead
- Otherwise, update CLAUDE.md with relevant context, commands, and conventions
- Keep instructions clear, imperative, and optimized for AI consumption
- Include file paths, command examples, and error handling patterns

### Human-Readable Documentation
- README.md in project root — overview, setup, usage
- TODO.md if present — task tracking and priorities
- README.md files in subdirectories — component-specific docs
- Focus on clarity, completeness, and current accuracy
- Remove outdated information that no longer matches the codebase
