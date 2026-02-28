---
name: address-pr-comments
description: "Interactively walk through and address PR review comments one at a time. Use when the user says 'address PR comments', 'handle PR feedback', 'go through PR comments', 'fix review comments', 'what did reviewers say', 'let's fix the review feedback', 'address review threads', 'work through PR feedback', or any variation of wanting to systematically address pull request review comments. NOT for reviewing code (use review-pr) or just fetching comments (use get-pr-feedback). Accepts an optional PR number argument; defaults to the current branch's PR."
---

Interactively walk through PR review comments one at a time, asking the user what to do for each, committing after each change, and optionally replying on GitHub.

## Arguments

- Optional: PR number (default: current branch's PR)

## Phase 1 — Fetch & Filter

1. Get PR number from argument or `gh pr view --json number,url`
2. Get repository owner and name from `gh repo view --json owner,name`
3. Fetch review threads using the GitHub GraphQL API:

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      url
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          startLine
          comments(first: 50) {
            nodes {
              id
              author { login }
              body
              createdAt
              url
            }
          }
        }
      }
    }
  }
}' -F owner="$OWNER" -F repo="$REPO" -F pr="$PR_NUMBER"
```

4. Filter out:
   - Bot accounts (author login ending in `[bot]` or `bot`), **except** `chatgpt-codex-connector` — keep its comments
   - Resolved threads (`isResolved == true`)
   - Keep outdated threads — user may have pushed a fix but still needs to reply
5. Show summary: "Found N comments from X reviewers across Y files"
6. List a preview of each comment: `[index] @author — file:line — first ~80 chars of body`

If no comments remain after filtering, say so and stop.

## Phase 2 — Address Comments (interactive, one at a time)

For each unresolved thread, in order:

1. Show the full thread:
   - Header: `@author — file:line`
   - Full comment body (and any reply context in the thread)
2. Read the relevant code around that line (±15 lines of context)
3. Show the user the filename, line numbers, and a code snippet (±5-10 lines around the commented line) so they have immediate context without needing to ask
4. Briefly explain what the reviewer is asking or suggesting
5. Evaluate whether the comment/suggestion is correct — state your assessment clearly (e.g. "The suggestion is correct because..." or "I disagree because...")
4. Use `AskUserQuestion` to ask what to do. Offer these options (adjust based on context):
   - **"Apply suggestion"** — only if the comment contains a GitHub suggestion block (` ```suggestion `)
   - **"Fix it"** — investigate and implement the requested change
   - **"Skip"** — move to the next comment without changes
5. If changes are made:
   - Stage and commit the change (follow git-commit skill conventions: imperative mood, concise subject, ≤ 50 chars)
   - If `git commit` fails with "1Password: agent returned an error", STOP immediately — user is AFK
6. Track the outcome: `{thread_id, action taken, short summary}`

Continue until all threads are processed.

## Phase 3 — Push, Reply & Resolve

### Push

1. If any changes were committed, use `AskUserQuestion`: "Want to push the commits?"
2. If **yes**, push. If **no**, skip replies entirely (replies should reference pushed code).

### Replies

Replies are only offered **after pushing** — replying "fixed" to a comment should reference code the reviewer can actually see.

1. After pushing, use `AskUserQuestion`: "Want to reply to the addressed comments on GitHub?"
2. If **yes**, for each thread that was addressed (not skipped):
   - Draft a concise reply describing what was done
   - Show the draft to the user via `AskUserQuestion` with options:
     - **"Post as-is"**
     - **"Edit"** — let the user provide revised text
     - **"Skip reply"**
   - Also ask whether to resolve the thread (default: yes for fixed items)
   - Post the reply using the REST API:
     ```bash
     gh api repos/OWNER/REPO/pulls/PR_NUMBER/comments -f body="REPLY" -F in_reply_to=COMMENT_ID
     ```
   - If resolving, use GraphQL mutation:
     ```bash
     gh api graphql -f query='
     mutation($threadId: ID!) {
       resolveReviewThread(input: {threadId: $threadId}) {
         thread { isResolved }
       }
     }' -f threadId="THREAD_ID"
     ```
3. If **no**, skip all replies.

## Key Behaviors

- **Interactive**: Always ask the user before taking action on each comment
- **Push before replying**: Replies should reference pushed code — always push first, then reply
- **Never auto-push**: Always ask before pushing
- **Never post replies without per-comment user approval**
- **Commit per comment**: Each addressed comment gets its own commit
- **1Password error**: If git commit fails with 1Password agent error, STOP and inform user
