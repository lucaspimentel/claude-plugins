---
name: copy-pr-link
description: "Copies a GitHub PR link as markdown to the clipboard. Use when the user says 'copy pr link', 'pr markdown', 'copy pr url', 'link to pr', 'pr link', or any variation of wanting a GitHub PR link formatted as markdown. Accepts an optional PR number argument; defaults to the current branch's PR."
model: haiku
allowed-tools: Bash(gh *), Bash(echo * | clip)
---

# Copy PR Link as Markdown

Generates a markdown link for a GitHub PR and copies it to the clipboard.

## Arguments

- Optional: PR number (e.g., `/copy-pr-link 7806`)
- Optional: repo in `owner/repo` format (e.g., `/copy-pr-link 7806 DataDog/dd-trace-dotnet`)
- If no PR number is provided, use the current branch's PR
- If no repo is provided, `gh` infers it from the current git repo
- If the `gh` command fails because repo or PR cannot be determined, ask the user

## Steps

1. Get the PR number, title, and URL using `gh pr view ... --json number,title,url`
   - Add `--repo <owner/repo>` if a repo argument was provided
   - Add `<number>` if a PR number was provided

2. Format the markdown link as: `[#<number> <title>](<url>)`
   - Replace square brackets in the title with the word followed by a colon, e.g. `[tracing]` becomes `tracing:`
   - This avoids breaking markdown link syntax

3. Copy to clipboard: `echo -n '<markdown>' | clip`

4. Show the formatted markdown to the user
