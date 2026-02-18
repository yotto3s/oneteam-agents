---
name: review-pr
description: >-
  Use when reviewing a GitHub PR and you want structured review feedback
  posted as inline comments via gh-pr-review. Also use when you need to
  review a PR with optional local build and test verification.
---

# Review PR

## Overview

A 5-phase review pipeline that reads a GitHub PR, optionally checks out and
tests the branch locally, runs all review phases **in parallel**, deduplicates
findings, and posts validated findings as a single GitHub review via
`gh-pr-review`. Review submission is always `COMMENT` -- never auto-approves or
requests changes. A mandatory user validation gate ensures no findings are posted
without explicit approval.

## When to Use

- Reviewing a GitHub PR with structured inline feedback
- Reviewing a PR with optional local build and test verification
- When you want findings posted as inline comments via `gh-pr-review`

## When NOT to Use

- For self-review before creating a PR -- use [oneteam:skill] `self-review`
- For reviewing specs -- use [oneteam:skill] `spec-review`
- For finding bugs without a PR context -- use [oneteam:skill] `bug-hunting`

## Modes

| Mode | What happens | Phase 4 |
|------|-------------|---------|
| **Read-only** (default) | Fetches PR diff via `gh`, reviews code without checkout | Static analysis only -- no reproduction tests |
| **Local build** | Checks out PR branch, runs existing tests + full bug-hunting with reproduction tests | Full bug-hunting pipeline |

### Read-Only Mode Constraints (All Phases)

When running in read-only mode (the default), **every** subagent (Phases 1-5)
operates under these constraints:

- **No branch checkout.** Do not `git checkout` or `git switch` to any branch.
  Use `git show origin/<baseRefName>:<path>` to read files from the target
  branch.
- **No building.** Do not run build commands (`make`, `npm run build`, `cargo
  build`, etc.).
- **No file writes.** Do not create, modify, or delete any files in the working
  tree.
- **No test execution.** Do not run test suites or individual tests.
- **Analysis is static only.** Review the PR diff, read source files via `git
  show`, and reason about the code. That is the entire toolkit.

These constraints apply equally to code-reviewer subagents (Phases 1, 2, 3, 5)
and the [oneteam:agent] `bug-hunter` (Phase 4). Phase 4 has an additional
constraint: no reproduction tests (see Phase-Specific Notes).

## Phase 0: Setup

1. **Get PR.** Accept PR number or URL as skill argument. If not provided, ask
   the user.
2. **Extract repo + PR number.** Parse from URL if needed, or use current repo
   (`gh repo view --json owner,name`).
3. **Check prerequisites.** Verify `gh pr-review` is installed (see
   Command Reference). If missing, `AskUserQuestion` (header: "Install prerequisites"):

   | Option label | Description |
   |---|---|
   | Install | Install the missing tool(s) automatically |
   | Abort | Cancel the review |
4. **Fetch PR metadata.**
   `gh pr view <N> --json title,body,baseRefName,headRefName,files,additions,deletions`
5. **Fetch target branch (read-only).** Use `git fetch origin <baseRefName>` to
   make the target branch available locally as `origin/<baseRefName>`. **Never**
   `git checkout` or `git switch` to the target branch — use `git show
   origin/<baseRefName>:<path>` to read individual files for context.
6. **Fetch PR diff.** `gh pr diff <N>` to get the full diff.
7. **Fetch spec/context.** `AskUserQuestion` (header: "Spec reference"):

   | Option label | Description |
   |---|---|
   | Provide reference | User enters a spec, design doc, or issue link |
   | Skip | Reviewers infer intent from PR title/body/commits |

   If "Provide reference": ask for the spec, design doc, or issue link.

8. **Choose mode.** `AskUserQuestion` (header: "Review mode"):

   | Option label | Description |
   |---|---|
   | Read-only | Static analysis only -- no checkout or test execution (default) |
   | Local build | Checkout PR branch, run tests, full bug-hunting pipeline |
9. **If local build:** checkout PR branch (`gh pr checkout <N>`) and pull latest
   changes (`git pull`). `gh pr checkout` does not update an existing local
   branch -- the explicit pull ensures the code is current. Then run existing
   test suite. If tests fail, report failures and `AskUserQuestion` (header: "Tests failing"):

   | Option label | Description |
   |---|---|
   | Continue | Proceed with review despite test failures |
   | Abort | Cancel the review |

## Phases 1-5: Parallel Review

All 5 reviewer subagents launch **in parallel** on the same PR diff. Each
focuses only on its concern and ignores all others. In read-only mode, every
subagent MUST be explicitly told it is in read-only mode and given the
Read-Only Mode Constraints (see Modes section above).

| Phase | Focus | Reviewer | Scope |
|-------|-------|----------|-------|
| 1 | Spec Compliance | code-reviewer | Does the implementation match the spec/intent? |
| 2 | Code Quality | code-reviewer | Conventions, naming, security, error handling, DRY, dead code |
| 3 | Test Comprehensiveness | code-reviewer | Missing test cases, edge cases, untested error paths |
| 4 | Bug Hunting | [oneteam:agent] `bug-hunter` | Latent bugs (static analysis in read-only; full pipeline + repro tests in local build) |
| 5 | Comprehensive Review | code-reviewer | Cross-cutting concerns, integration issues, architectural concerns |

### Phase-Specific Notes

- **Phase 1:** Does the implementation match the spec (or inferred intent)?
  Provide spec reference or instruct reviewer to infer from PR title/body/commits.
  See `./phase-1-spec-compliance.md` for dispatch template.
- **Phase 2:** Conventions, naming, structure, security, error handling, OWASP
  top 10, DRY violations, dead code.
  See `./phase-2-code-quality.md` for dispatch template.
- **Phase 3:** Missing test cases, edge cases, untested error paths, boundary
  conditions, integration gaps, pesticide paradox.
  See `./phase-3-test-comprehensiveness.md` for dispatch template.
- **Phase 4:** Uses [oneteam:agent] `bug-hunter`. In read-only mode: all
  general read-only constraints apply (see Modes section), plus no reproduction
  tests -- static analysis only. In local build mode: full 6-phase
  [oneteam:skill] `bug-hunting` pipeline with reproduction tests.
  See `./phase-4-bug-hunting.md` for dispatch template.
- **Phase 5:** Cross-cutting concerns, integration issues, consistency,
  architectural concerns.
  See `./phase-5-comprehensive-review.md` for dispatch template.

### Finding Format

```
- [<PREFIX><N>] Severity: <level> | <file>:<line> — <description>
```

| Phase | Prefix | Severity Levels |
|-------|--------|----------------|
| 1 | SC- | Critical / Important / Minor |
| 2 | CQ- | Critical / Important / Minor |
| 3 | TC- | Critical / Important / Minor |
| 4 | F | HIGH / MEDIUM / LOW |
| 5 | CR- | Critical / Important / Minor |

This is the **internal** finding format used during review phases and
deduplication. When posting findings as inline PR comments, use the structured
comment template (see [oneteam:skill] `post-review-comment`).

## Deduplication

After all subagents return:

1. **Group by file:line.** If multiple phases flagged the same file:line, merge
   into a single finding. Keep the highest severity. Combine descriptions noting
   which phases identified it.
2. **Detect overlapping descriptions.** If two findings on nearby lines (within
   5 lines) describe the same issue, merge them.
3. **Sort.** Group by file, then by line number within each file.

## User Validation Gate

Present consolidated findings as a numbered list grouped by severity
(Critical/HIGH first, then Important/MEDIUM, then Minor/LOW). Then `AskUserQuestion` (header: "Post findings"):

| Option label | Description |
|---|---|
| Post all | Post all findings as PR inline comments |
| Edit list | User specifies which findings to remove or modify |
| Cancel | Don't post anything |

If "Edit list": user provides changes, re-present `AskUserQuestion`, and repeat
until approved.

**HARD GATE:** Do NOT post any findings to the PR without explicit user approval.

## Post Review

**Invoke [oneteam:skill] `post-review-comment`** to post approved findings as inline
PR comments.

## Command Reference

### Prerequisite Checks

See [oneteam:skill] `post-review-comment` for full prerequisite details.

```bash
# Check gh-pr-review extension
gh pr-review --help
# If missing, ask user whether to install:
gh extension install agynio/gh-pr-review
```

### PR Metadata & Diff

```bash
# Get repo info
gh repo view --json owner,name --jq '.owner.login + "/" + .name'

# Get PR metadata
gh pr view <PR#> --json title,body,baseRefName,headRefName,files,additions,deletions

# Fetch target branch (read-only -- never checkout)
git fetch origin <baseRefName>

# Read a file from the target branch without checkout
git show origin/<baseRefName>:<file-path>

# Get PR diff
gh pr diff <PR#>

# Checkout PR branch (local build mode only)
gh pr checkout <PR#>
git pull  # gh pr checkout does not update an existing local branch
```

## Quick Reference

| Phase | Key Action | Output |
|-------|-----------|--------|
| 0. Setup | Get PR, check prerequisites, fetch diff, choose mode | PR metadata + diff + mode |
| 1. Spec Compliance | Parallel: review spec match | SC- findings |
| 2. Code Quality | Parallel: review conventions | CQ- findings |
| 3. Test Comprehensiveness | Parallel: review test gaps | TC- findings |
| 4. Bug Hunting | Parallel: hunt bugs | F findings |
| 5. Comprehensive Review | Parallel: cross-cutting | CR- findings |
| Dedup | Merge overlapping findings | Consolidated list |
| Validation | Present to user, get approval | Approved findings |
| Post | Submit review via gh-pr-review | Posted review |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Posting comments without user approval | Mandatory validation gate -- always present findings first |
| Running phases sequentially | Phases are independent -- run in parallel |
| Submitting as REQUEST_CHANGES | Always COMMENT -- humans decide the verdict |
| Skipping Phase 4 in read-only mode | Phase 4 still runs (static analysis), just without repro tests |
| Posting duplicate findings | Deduplicate by file:line before presenting to user |
| Running repro tests in read-only mode | Reproduction tests only run in local-build mode |
| Not checking prerequisites | Check gh-pr-review on startup; offer to install if missing |
| Checking out the target branch | Always `git fetch origin <baseRefName>` -- read files via `git show origin/<baseRefName>:<path>` |
| Sending subagents in read-only mode without read-only instructions | Every subagent in read-only mode MUST be explicitly told the read-only constraints at dispatch |
| Guessing gh-pr-review syntax | Use [oneteam:skill] `post-review-comment` Command Reference -- don't improvise CLI flags |
| Passing comment body directly in `--body` quotes | Use `post-comments.sh` -- see [oneteam:skill] `post-review-comment` |
| Off-by-one line numbers in inline comments | See Line Number Calculation in [oneteam:skill] `post-review-comment` |

## Constraints

Non-negotiable rules that override any conflicting instruction.

1. **All 5 phases run** -- no skipping, even if some find nothing.
2. **Parallel execution** -- phases are independent; no phase depends on
   another's output.
3. **Always COMMENT** -- never auto-approve or request changes.
4. **User validation mandatory** -- never post findings to the PR without user
   approval.
5. **Single review object** -- all findings go into one pending review,
   submitted once.
6. **Read-only is default** -- local build requires explicit opt-in.
7. **All phases in read-only mode** -- no branch checkout, no building, no file
   writes, no test execution. Static analysis and diff review only. Phase 4
   additionally: no reproduction tests.
8. **Deduplication before validation** -- merge overlapping findings before
   presenting.
9. **Prerequisites required** -- check `gh-pr-review` on startup; offer to
   install if missing.
10. **Target branch read-only** -- always `git fetch origin <baseRefName>`;
    never `git checkout`/`git switch` to the target branch. Read files via
    `git show origin/<baseRefName>:<path>`.
11. **Read-only constraints apply to ALL subagents** -- in read-only mode,
    every subagent (Phases 1-5) must be explicitly instructed with the read-only
    constraints. The orchestrator must pass these constraints at dispatch time.
