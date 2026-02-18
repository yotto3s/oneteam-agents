---
name: post-review-comment
description: >-
  Use when a review skill needs to post findings as inline PR comments via
  gh-pr-review. Covers prerequisites, JSON input format, line number
  calculation, and command reference.
---

# Post Review Comment

## Overview

Mechanical utility for posting review comments to GitHub PRs via `gh-pr-review`.
Review submission is always `COMMENT` -- never `APPROVE` or `REQUEST_CHANGES`.
This skill does not own any user approval UX; callers are responsible for
confirming user approval before invoking posting.

## When to Use

- When a review skill needs to post findings as inline PR comments
- When building the JSON input for `post-comments.sh`
- When calculating line numbers from unified diff hunks

## When NOT to Use

- When posting a single review comment (use `gh pr review --body` directly)
- When the caller has not confirmed user approval yet -- get approval first,
  then use this skill

## Prerequisites

Required tools:

| Tool | Check command | Install command |
|------|--------------|-----------------|
| `gh` CLI | `gh --version` | [cli.github.com](https://cli.github.com/) |
| `gh-pr-review` extension | `gh pr-review --help` | `gh extension install agynio/gh-pr-review` |
| `jq` | `jq --version` | [jqlang.github.io/jq](https://jqlang.github.io/jq/) |

If any prerequisite is missing, `AskUserQuestion` (header: "Install prerequisites"):

| Option label | Description |
|---|---|
| Install | Install the missing tool(s) automatically |
| Abort | Cancel posting |

## JSON Input Format

The agent builds a single JSON file and passes it to `./post-comments.sh`. Schema:

```json
{
  "repo": "owner/repo",
  "pr": 42,
  "summary": "## Review Summary\n\n3 findings across 2 files ...",
  "comments": [
    {
      "path": "src/auth.ts",
      "line": 15,
      "body": "**[CQ-1] Severity: Important**\n\n**What:** ..."
    },
    {
      "path": "src/auth.ts",
      "line": 25,
      "start_line": 20,
      "body": "**[CQ-2] Severity: Important**\n\n**What:** ..."
    }
  ]
}
```

### Top-Level Fields

| Field | Required | Description |
|-------|----------|-------------|
| `repo` | yes | GitHub repository in `owner/repo` format |
| `pr` | yes | Pull request number |
| `summary` | yes | Markdown review summary submitted with the review |
| `comments` | yes | Array of inline comment objects |

### Comment Fields

| Field | Required | Description |
|-------|----------|-------------|
| `path` | yes | File path relative to repo root |
| `line` | yes | End line number for the comment (new-file line number) |
| `start_line` | no | Start line for multi-line comments / suggestions |
| `body` | yes | Comment body using the comment template format (see `./comment-template.md`) |

## Comment Format

See `./comment-template.md` for the full comment body template, including:
- Suggestion block format (for concrete code changes)
- Plain-text suggestion format (for non-code recommendations)
- Field reference table
- GitHub suggestion block rules

## Report Format

See `./report-template.md` for the review summary template used as the
`--body` argument when submitting the review via `gh-pr-review review --submit`.

## Line Number Calculation

The `line` field in inline comments refers to the line number in the **new file
version** (right side of the diff). To derive it from a unified diff hunk:

1. Read the hunk header: `@@ -old,count +new,count @@`. The `new` value is the
   starting line number for the new file.
2. The **first line** in the hunk body (immediately after the `@@` header)
   corresponds to that starting line number.
3. Count forward: context lines (` `) and added lines (`+`) each consume one
   new-file line number. Removed lines (`-`) do **not** consume a new-file line
   number -- skip them.
4. **Verify** the target line before posting: run
   `git show <PR-HEAD>:<path> | sed -n '<line>p'` and confirm the content
   matches the intended target.

Common off-by-one cause: miscounting leading context lines (e.g., counting a
blank context line twice or counting the hunk header itself as a line). Always
start counting from the `+new` value in the hunk header.

## Command Reference

### Review Workflow

**Recommended: use `post-comments.sh`** to avoid shell escaping issues.
See `./post-comments.sh` for input JSON format and usage.

```bash
# Post all comments + submit review in one step
./post-comments.sh <input.json>
```

**Manual commands** (use temp files to avoid escaping issues with special
characters in `--body`):

```bash
# 1. Start a pending review -- returns PRR_... node ID
gh pr-review review --start -R <owner/repo> <PR#>

# 2. Add inline comment (repeat per finding)
#    Write comment body to temp file using ./comment-template.md format,
#    then pass via command substitution to avoid escaping issues.
gh pr-review review --add-comment \
  --review-id <PRR_...> \
  --path <file-path> \
  --line <line-number> \
  --body "$(cat /tmp/comment-body.md)" \
  -R <owner/repo> <PR#>

# 3. Submit review (always COMMENT)
gh pr-review review --submit \
  --review-id <PRR_...> \
  --event COMMENT \
  --body "$(cat /tmp/review-summary.md)" \
  -R <owner/repo> <PR#>
```

### Viewing & Managing Reviews

```bash
# View all review threads on a PR
gh pr-review review view -R <owner/repo> --pr <PR#>

# View unresolved threads only
gh pr-review review view -R <owner/repo> --pr <PR#> --unresolved

# Reply to a thread
gh pr-review comments reply <PR#> -R <owner/repo> \
  --thread-id <PRRT_...> \
  --body "reply text"

# Resolve a thread
gh pr-review threads resolve --thread-id <PRRT_...> -R <owner/repo> <PR#>
```

## Quick Reference

| Step | Action | Detail |
|------|--------|--------|
| 1 | Check prerequisites | `gh pr-review --help`, `jq --version` |
| 2 | Build JSON input | Follow JSON Input Format schema above |
| 3 | Calculate line numbers | Hunk header method + verify with `git show` |
| 4 | Run `./post-comments.sh` | Pass JSON file as argument |
| 5 | Report result | Confirm review posted with PR link |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Passing comment body directly in `--body` quotes | Use `post-comments.sh` or write body to temp file and use `--body "$(cat file)"` |
| Off-by-one line numbers in inline comments | Derive line numbers from the `+new` value in the hunk header; verify with `git show <HEAD>:<path> \| sed -n '<line>p'` before posting |
| Guessing gh-pr-review syntax | Use the Command Reference above -- don't improvise CLI flags |
| Submitting as APPROVE or REQUEST_CHANGES | Always COMMENT -- callers decide the verdict |
| Posting without caller approval | This skill does not own the approval UX -- callers must confirm first |

## Constraints

Non-negotiable rules that override any conflicting instruction.

1. **Always `COMMENT`** -- never `APPROVE` or `REQUEST_CHANGES`.
2. **Never post without caller confirming user approval** -- this skill does
   not own the approval UX; it trusts the caller to have obtained approval.
3. **Single review object per posting call** -- all findings go into one
   pending review, submitted once.
4. **Verify line numbers before posting** -- always run
   `git show <PR-HEAD>:<path> | sed -n '<line>p'` to confirm the target line.
5. **Use `post-comments.sh` or temp files** -- never pass comment bodies
   directly in `--body` quotes due to shell escaping issues.
