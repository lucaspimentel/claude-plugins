---
name: update-docs
description: "Update project documentation based on recent changes and current codebase state. Use when the user says 'update docs', 'update readme', 'sync docs', 'docs are stale', 'update CLAUDE.md', 'refresh documentation', or any variation of wanting documentation updated."
---

Verify and update project documentation so it accurately reflects the current state of the codebase.
Do not commit or push the changes to git unless also asked to do so.
Do not include volatile metrics (test counts, coverage percentages, line counts) that become stale quickly.

## Approach

The goal is documentation that is correct *right now*, not just patched for recent commits. Treat every claim in the docs as potentially stale and verify it against the actual code, file structure, and configuration.

1. **Read the existing docs** — identify all claims: file paths, command examples, architecture descriptions, setup steps, conventions, dependency lists.
2. **Verify each claim against the codebase** — spot-check referenced paths, commands, and patterns. Flag anything outdated, missing, or wrong.
3. **Fix inaccuracies** — correct or remove statements that no longer hold. Add documentation for important things that are undocumented.

Use `git diff` and `git log` as *supplementary* signals to find areas likely to have drifted, but do not rely on them as the sole source of what needs updating.

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
- Remove outdated information that no longer matches the codebase
