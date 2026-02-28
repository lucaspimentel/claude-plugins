---
name: update-docs
description: "Update project documentation based on recent changes and current codebase state. Use when the user says 'update docs', 'update readme', 'sync docs', 'docs are stale', 'update CLAUDE.md', 'refresh documentation', or any variation of wanting documentation updated."
---

Update project documentation based on recent changes and current codebase state.
Do not commit or push the changes to git unless also asked to do so.
Do not include volatile metrics (test counts, coverage percentages, line counts) that become stale quickly.

## Detecting Recent Changes

Identify what changed by comparing against the default branch:
- `git diff main...HEAD --name-only` (or the repo's default branch if not `main`)
- `git log main..HEAD --oneline`

## AI-Optimized Documentation

Update files that provide context and instructions for AI agents:
- Check if CLAUDE.md exists (look in: `./CLAUDE.md`, `./.claude/CLAUDE.md`, `./CLAUDE.MD`)
- If CLAUDE.md only references AGENTS.md, leave CLAUDE.md alone and update AGENTS.md instead
- Otherwise, update CLAUDE.md with relevant context, commands, and conventions
- Keep instructions clear, imperative, and optimized for AI consumption
- Include file paths, command examples, and error handling patterns

## Human-Readable Documentation

Update files intended for human developers:
- README.md in project root — overview, setup, usage
- TODO.md if present — task tracking and priorities
- README.md files in subdirectories — component-specific docs
- Focus on clarity, completeness, and current accuracy
- Remove outdated information

## Accuracy Check

- Verify that existing documentation is still accurate, not just add content for new changes
- Remove or correct statements that are no longer true
