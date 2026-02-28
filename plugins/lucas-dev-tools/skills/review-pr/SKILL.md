---
name: review-pr
description: "Review a pull request for issues and feedback. Use when the user says 'review this PR', 'check this PR', 'look at PR changes', 'review the diff', 'what do you think of this PR', 'post review comments', or any variation of wanting PR feedback."
disable-model-invocation: true
---

Review a pull request and provide detailed feedback on the changes.

## Modes

This skill has two modes:

- **Local mode** (default): Display review findings in the CLI only. DO NOT post anything to GitHub.
- **Post mode**: Post review comments to GitHub. Only use this mode when the user explicitly says "post", "post comments", "post to GitHub", or similar.

## Review Steps

1. Fetch PR details and full diff using `gh pr view` and `gh pr diff`
2. Skip generated/vendored files: lock files (`*.lock`, `package-lock.json`, `yarn.lock`), `*.designer.cs`, auto-generated code, vendored dependencies
3. For large PRs, prioritize the most-changed files first
4. Analyze changes for:
   - Logic errors and bugs
   - Security vulnerabilities (injection, XSS, etc.)
   - Performance issues
   - Code style inconsistencies
   - Missing error handling
   - Test coverage gaps
5. Focus on actionable issues, not positive feedback

## Comment Format

- Be specific and reference code directly with `file_path:line_number`
- Explain why something is an issue
- Suggest concrete fixes when possible

## Local Mode (default)

- DO NOT post any comments to GitHub
- DO NOT use `gh api` to create reviews or comments
- Display all review findings in the CLI output only
- Label each comment with severity: `[CRITICAL]`, `[HIGH]`, `[MEDIUM]`, `[LOW]`
- Sort comments by severity (most critical first), then by file path and line number:
  1. **CRITICAL**: Security vulnerabilities, data loss, crashes
  2. **HIGH**: Logic errors, bugs, incorrect behavior
  3. **MEDIUM**: Performance issues, missing error handling
  4. **LOW**: Code style, minor improvements, suggestions

## Post Mode

Only when the user explicitly requests posting comments to GitHub:

- Use `gh api` to create a review with specific line comments
- Endpoint: `repos/OWNER/REPO/pulls/PR_NUMBER/reviews`
- Each comment must specify: `path`, `line` (or `start_line`/`end_line`), `body`
- Include footer in review body: `"\n\n---\n*Review by Claude Code*"`
- ALWAYS use event type: `COMMENT`
- NEVER use `REQUEST_CHANGES` or `APPROVE` — human review required
- Group related comments under a single review
