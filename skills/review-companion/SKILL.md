---
name: review-companion
description: >-
  Use when a human reviewer wants AI-assisted walkthrough of a GitHub PR,
  to understand changes before providing feedback, or when reviewing a large
  or complex PR with AI assistance while the human drives the review.
---

# Review Companion

## Overview

A 5-phase interactive skill that helps human reviewers understand and navigate
GitHub pull requests. It pre-analyzes the entire PR, presents a summary and
checklist, then walks through each change with explanations and risk highlights
— pausing for discussion at every stop.

**Key difference from `review-pr`:** `review-pr` automates the review (AI finds
issues, posts comments). `review-companion` assists a human reviewer — it
explains, highlights, and tracks concerns while the human makes the judgment
calls.

## When to Use

- Reviewing someone else's PR and wanting a guided walkthrough
- Understanding a large or complex PR before providing feedback
- When the human reviewer wants to drive the review with AI assistance

## When NOT to Use

- For automated AI review — use [oneteam:skill] `review-pr`
- For self-review before creating a PR — use [oneteam:skill] `self-review`
- For reviewing specs — use [oneteam:skill] `spec-review`

## Modes

| Mode | What happens | File writes |
|------|-------------|-------------|
| **Read-only** (default) | All analysis from diff and `gh api` only; no checkout, no builds | Concern tracking file only |
| **Local checkout** | `git fetch` + checkout PR branch for full file context | Concern tracking file only |

## Phase 0: Setup

1. **Get PR.** Accept PR number, URL, or detect from current branch. If not
   provided, ask the user.
2. **Extract repo + PR number.** Parse from URL if needed, or use current repo
   (`gh repo view --json owner,name`).
3. **Fetch PR metadata.**
   `gh pr view <N> --json title,body,author,baseRefName,headRefName,files,additions,deletions`
4. **Fetch full diff.** `gh pr diff <N>`
5. **Present quick overview:** title, author, stats (files changed, +/- lines).
6. **Spec reference.** `AskUserQuestion` (header: "Spec reference"):

   | Option label | Description |
   |---|---|
   | Provide reference | User enters a spec, design doc, or issue link |
   | Skip | Infer intent from PR title/body/commits |

   If "Provide reference": ask for the spec, design doc, or issue link. This
   helps the pre-analysis subagent understand context beyond the PR body.

7. **Choose mode.** `AskUserQuestion` (header: "Review mode"):

   | Option label | Description |
   |---|---|
   | Read-only | All analysis from diff and `gh api` only; no checkout, no builds (default) |
   | Local checkout | `git fetch` + checkout PR branch for full file context |

8. **If local checkout:** `gh pr checkout <N>` and `git pull` to ensure the
   branch is current.

## Phase 1: Pre-Analysis

Dispatch a subagent (read-only) with the full PR diff and metadata. The
subagent produces a structured analysis containing:

1. **High-level summary** — What the PR does and why, in 2-3 sentences.
2. **Logical change groups** — Cluster related changes into reviewable units:
   - A single function change (if substantial)
   - A whole file (if changes are small/cohesive)
   - A group of related files (e.g., handler + test + type definition)
3. **Per-unit analysis:**
   - What changed and why (intent)
   - Risk flags: potential bugs, edge cases, missing error handling, security
     concerns, style issues
   - Complexity: LOW / MEDIUM / HIGH
   - Related context: affected callers, tests, or types
4. **Cross-cutting concerns** — Things spanning multiple units (API contract
   changes, migration risks, breaking changes).
5. **Recommended review order** — Logical sequence (e.g., types first, then core
   logic, then tests).

The analysis is stored in-session (not written to disk). Neither mode writes
the analysis to disk — only the concern tracking file is written.

## Phase 2: Summary & Checklist

Present to the reviewer:

**A. Big-picture summary** — 2-3 sentence overview of what the PR accomplishes.

**B. Change checklist** — Numbered list of all change units in recommended
review order:

```
## PR #42: Add user authentication

**Summary:** Adds JWT-based auth with login/logout endpoints, middleware, and tests.

### Review Checklist
- [ ] 1. `types/auth.ts` -- New auth types (LOW risk)
- [ ] 2. `middleware/auth.ts` -- JWT verification middleware (HIGH risk)
- [ ] 3. `routes/login.ts` + `routes/logout.ts` -- Auth endpoints (MEDIUM risk)
- [ ] 4. `tests/auth.test.ts` -- Test coverage (LOW risk)

Cross-cutting: JWT secret handling spans middleware and routes.
```

**HARD GATE:** `AskUserQuestion` (header: "Walkthrough"):

| Option label | Description |
|---|---|
| Start walkthrough | Begin reviewing items in the recommended order |
| Jump to item | Skip ahead to a specific checklist item |

Wait for the reviewer to confirm before starting the walkthrough. If "Jump to
item": ask for the item number; the walkthrough begins at that item.

## Phase 3: Interactive Walkthrough

### Concern File Setup

At walkthrough start, create the concern tracking file:
`yyyy-mm-dd_PR-[PR_NUMBER]_review.md`

This file persists locally regardless of posting choice.

### Per-Item Walkthrough

For each checklist item, in order:

1. **Show the diff** — Present the relevant diff hunk(s), syntax highlighted.
2. **Explain** — What changed and why (from pre-analysis).
3. **Highlight risks** — Flag potential issues with severity (bugs, edge cases,
   security, style).
4. **Pause for review** — `AskUserQuestion` (header: "Review"):

   | Option label | Description |
   |---|---|
   | Looks good | Mark item as reviewed and advance to next item |
   | Raise concern | Log a concern for this change |
   | Ask question | Ask a question about this code |
   | Done reviewing | End walkthrough early, go to completion |

   **Behavior:**
   - **"Looks good"** — Mark item reviewed, show progress (step 5), auto-advance
     to next item.
   - **"Raise concern"** — Reviewer describes concern via the built-in "Other"
     text field. Append to concern file with file:line, description, severity.
     Then re-show the same `AskUserQuestion` so the reviewer can raise more
     concerns, ask questions, or advance.
   - **"Ask question"** — Reviewer asks via "Other" text field. Answer the
     question. Then re-show the `AskUserQuestion`.
   - **"Done reviewing"** — End walkthrough early, proceed to Phase 4 completion.
   - **Jump to item** — Available via built-in "Other" (reviewer types "jump 3"
     or similar).

   The pause **loops** until the reviewer selects "Looks good" or "Done
   reviewing."

5. **Show updated checklist** — Mark item as reviewed, display progress:
   `[3/7 reviewed] Next: middleware/auth.ts (HIGH risk)`

### Concern File Format

```markdown
# Review Concerns -- PR #42

## middleware/auth.ts:23
**Severity:** HIGH
**Concern:** JWT expiry not checked before token refresh

## routes/login.ts:45
**Severity:** MEDIUM
**Concern:** Missing rate limiting on login endpoint

## routes/login.ts (file-level)
**Severity:** LOW
**Concern:** No structured error responses for auth failures
```

### Handling Reviewer Questions

If the reviewer asks about something the pre-analysis does not cover (e.g.,
"what calls this function?"), perform live analysis:
- **Read-only mode:** Read relevant code via `gh api` or
  `git show origin/<baseRefName>:<path>`
- **Local checkout:** Read local files directly

## Phase 4: Completion

Triggered when all items are reviewed or the reviewer says "done."

### Final Summary

1. Items reviewed out of total.
2. All concerns from the concern file, grouped by severity.
3. Overall assessment: any blocking issues?

### Posting Options

`AskUserQuestion` (header: "Post to PR?"):

| Option label | Description |
|---|---|
| Post as inline comments | Use `./post-comments.sh` to post each concern as an inline comment on the relevant file:line; submit review as `COMMENT` |
| Post as single review comment | Format all concerns into one structured review body; submit as `COMMENT` |
| Skip | Keep the concern file local only; do not post anything |

**HARD GATE:** Do NOT post any comments to the PR without explicit reviewer
approval.

### Prerequisite Check (before posting)

When the reviewer chooses to post (either option), check prerequisites first:

- **Inline comments:** Verify `gh pr-review` extension is installed
  (`gh pr-review --help`). If missing, `AskUserQuestion` (header: "Install prerequisites"):

  | Option label | Description |
  |---|---|
  | Install | Run `gh extension install agynio/gh-pr-review` automatically |
  | Skip posting | Keep the concern file local only; do not post |

- **Single review comment:** Verify `gh` CLI is available (`gh --version`).
  If missing, inform the reviewer that posting is not possible and fall back to
  keeping the concern file local only.

### Done

Report the concern file path and PR link (if posted).

## Command Reference

### PR Metadata & Diff

```bash
# Get repo info
gh repo view --json owner,name --jq '.owner.login + "/" + .name'

# Get PR metadata
gh pr view <PR#> --json title,body,author,baseRefName,headRefName,files,additions,deletions

# Get PR diff
gh pr diff <PR#>

# Read a file from the base branch without checkout
git fetch origin <baseRefName>
git show origin/<baseRefName>:<file-path>
```

### Local Checkout (optional)

```bash
# Checkout PR branch
gh pr checkout <PR#>
git pull  # gh pr checkout does not update an existing local branch
```

### Posting Review

```bash
# Post all comments + submit review in one step (recommended)
./post-comments.sh <input.json>
```

For manual posting commands, see [oneteam:skill] `review-pr` Command Reference.

## Quick Reference

| Phase | Key Action | Output |
|-------|-----------|--------|
| 0. Setup | Get PR, fetch metadata + diff, choose mode | PR overview + mode selection |
| 1. Pre-Analysis | Dispatch subagent to analyze full diff | Structured analysis document |
| 2. Summary & Checklist | Present big-picture summary + numbered checklist | Checklist with risk levels |
| 3. Interactive Walkthrough | Per-item: show diff, explain, highlight risks, looping AskUserQuestion | Concern file + reviewed checklist |
| 4. Completion | Final summary, posting options, hard gate | Posted review or local concern file |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Advancing past an item without waiting for "Looks good" or "Done reviewing" | The AskUserQuestion loops -- stay on the current item until the reviewer explicitly advances |
| Posting without reviewer approval | Hard gate -- always ask before posting anything to the PR |
| Submitting as APPROVE or REQUEST_CHANGES | Always COMMENT -- the human reviewer makes the verdict |
| Skipping checklist items silently | Every item must be presented; reviewer can say "done" to exit early |
| Writing files in read-only mode | Only the concern tracking file is written; no other file writes |
| Skipping pre-analysis and going straight to walkthrough | Always run Phase 1 before presenting the checklist |
| Starting walkthrough without reviewer confirmation | Hard gate after Phase 2 -- wait for the reviewer to select a walkthrough option |
| Not tracking concerns in the file | Append every concern raised during discussion to the concern file |
| Posting without checking prerequisites | Check `gh pr-review` (inline) or `gh` (single comment) before attempting to post |

## Constraints

Non-negotiable rules that override any conflicting instruction.

1. **Never post `APPROVE` or `REQUEST_CHANGES`** -- always `COMMENT`.
2. **Never post without explicit reviewer approval** -- hard gate before any
   posting to the PR.
3. **Read-only is the default mode** -- no checkout, no builds, no file writes
   except the concern tracking file.
4. **Every change unit must be covered** -- no skipping items in the checklist.
   The reviewer can say "done" to exit early, but items are never silently
   skipped.
5. **Looping pause per item** -- the `AskUserQuestion` in step 4 loops until
   the reviewer selects "Looks good" or "Done reviewing". Never auto-advance
   without explicit reviewer action.
6. **Concern file always persists locally** -- regardless of posting choice, the
   concern file stays on disk.
7. **Reuse `review-pr` posting infrastructure** -- post via symlinked
   `post-comments.sh` and `comment-template.md`.
8. **Pre-analyze before walkthrough** -- always dispatch the subagent in Phase 1
   before presenting the checklist or starting the walkthrough.
