---
name: self-review
description: >-
  Use before creating a PR or merging to run a thorough multi-phase review
  pipeline that validates code changes for spec compliance, code quality, test
  coverage, latent bugs, and cross-cutting concerns.
---

# Self-Review

## Overview

A 5-phase sequential review pipeline that spawns specialized reviewer and
engineer subagents. Each phase follows a review-fix-re-review cycle. Produces a
Self-Review Report with a PASS/FAIL verdict. This is a pre-review quality pass;
external code review is still required before merge.

## When to Use

- Before creating a PR or merging (quality gate)
- On-demand for a thorough review of the current branch

## When NOT to Use

- For external code review — self-review is a pre-filter, not a replacement
- For reviewing specs — use [oneteam:skill] `spec-review`

## Phase 0: Setup

1. **Diff scope.** If the caller provided a base branch, use it. Otherwise,
   detect it: examine git log to find the most likely base branch. Present the
   result for confirmation:
   `1. <detected-branch> (Recommended)  2. Other branch`
   If the user picks "Other", ask for the branch name.
   Default diff: `git diff <base-branch>...HEAD`
2. **Spec reference.** Use caller-provided spec/design doc/issue link or ask.
   User may skip — intent inferred from commits in Phase 1.
3. **Capture initial diff.** Store for Phase 1. Subsequent phases re-capture to
   include fixes from earlier phases.

## Pipeline

### Review-Fix-Re-Review Cycle

Each phase follows this cycle:

1. Spawn reviewer subagent for the phase focus
2. If findings: spawn engineer ([oneteam:agent] `senior-engineer` for
   Critical/Important/HIGH/MEDIUM, [oneteam:agent] `junior-engineer` for
   Minor/LOW). See `./engineer-fix-findings.md` for dispatch
   template.
3. Re-review once with updated diff
4. Proceed to the next phase regardless of re-review outcome

### Phases

| Phase | Focus | Reviewer | Finding Prefix | Severity Map |
|-------|-------|----------|----------------|--------------|
| 1 | Spec Compliance | code-reviewer | SC- | Critical / Important / Minor |
| 2 | Code Quality | code-reviewer | CQ- | Critical / Important / Minor |
| 3 | Test Comprehensiveness | code-reviewer | TC- | Critical / Important / Minor |
| 4 | Bug Hunting | [oneteam:agent] `bug-hunter` | F | HIGH / MEDIUM / LOW |
| 5 | Comprehensive Review | code-reviewer | CR- | Critical / Important / Minor |

### Phase-Specific Notes

**Phases 1-3, 5** each instruct the reviewer to focus ONLY on that phase's
concern and ignore all others. Specific review scopes:

- **Phase 1:** Does the implementation match the spec (or inferred intent)?
  Provide spec reference or instruct reviewer to infer from commits.
  See `./phase-1-spec-compliance.md` for dispatch template.
- **Phase 2:** Conventions, naming, structure, security, error handling, OWASP
  top 10, DRY violations, dead code.
  See `./phase-2-code-quality.md` for dispatch template.
- **Phase 3:** Missing test cases, edge cases, untested error paths, boundary
  conditions, integration gaps, pesticide paradox.
  See `./phase-3-test-comprehensiveness.md` for dispatch template.
- **Phase 5:** Cross-cutting concerns, integration issues, consistency,
  architectural concerns. Provide summaries of all prior phase findings.
  See `./phase-5-comprehensive-review.md` for dispatch template.

**Phase 4 exceptions:** Uses [oneteam:agent] `bug-hunter` with the full 6-phase
[oneteam:skill] `bug-hunting` pipeline instead of code-reviewer. Re-verification
runs reproduction tests only, not the full pipeline. Findings without
reproduction tests still count toward the verdict — HIGH or MEDIUM untested
findings trigger FAIL the same as unresolved tested findings.
See `./phase-4-bug-hunting.md` for dispatch template.

### Finding Format

```
- [<PREFIX>1] Severity: <level> | <file>:<line> — <description>
```

Each reviewer also produces a summary with total counts and PASS/ISSUES FOUND.

## Report

See `./report-template.md` for the complete Self-Review Report template and
verdict logic.

## Constraints

Non-negotiable rules that override any conflicting instruction.

1. **Strictly sequential** — Phase N+1 starts only after Phase N completes
   (including its fix loop).
2. **One fix cycle per phase** — Engineer fixes, reviewer re-checks once. If
   still failing, log unresolved issues and proceed. Do NOT loop further.
3. **Severity-based engineer selection** — Critical/Important/HIGH/MEDIUM use
   [oneteam:agent] `senior-engineer`; Minor/LOW use [oneteam:agent]
   `junior-engineer`.
4. **Re-review uses updated diff** — Re-review and subsequent phases operate on
   the latest code state, not a stale diff.
5. **Self-review does not replace external review** — This is a pre-review
   quality pass. External code review is still required before merge.
6. **No skipping phases** — All 5 phases run even if earlier phases found
   nothing.
7. **No fixing during review** — Reviewers identify issues only. Engineers fix
   issues only. Roles do not overlap.

## Quick Reference

| Phase | Focus | Reviewer | Key Question |
|-------|-------|----------|--------------|
| 0 | Setup | -- | What is the diff scope and spec reference? |
| 1 | Spec Compliance | code-reviewer | Does the implementation match the spec? |
| 2 | Code Quality | code-reviewer | Does the code follow conventions and best practices? |
| 3 | Test Comprehensiveness | code-reviewer | Are there missing test cases or edge cases? |
| 4 | Bug Hunting | bug-hunter | Are there latent bugs in the changed code? |
| 5 | Comprehensive Review | code-reviewer | Are there cross-cutting or integration issues? |

## Common Mistakes

If you catch yourself thinking any of these, stop and apply the correction.

| Rationalization | Correction |
|---|---|
| "Phase 1 found nothing, skip Phase 5" | Each phase has a different lens; comprehensive review catches cross-cutting issues |
| "Only minor issues, skip the fix" | Minor issues compound; fix while context is fresh |
| "Self-review passed, skip external review" | Self-review is a pre-filter, not a replacement |
| "The fix is trivial, skip re-review" | Trivial fixes can introduce new issues; always re-verify |
| "Tests already exist, skip Phase 3" | Existing tests may have gaps; review catches what is missing |
| "Bug-hunter found nothing, Phase 4 is done" | Verify bug-hunter completed all 6 sub-phases; partial runs miss bugs |
| "Re-review found new issues, fix those too" | One fix cycle per phase; log new issues as unresolved and proceed |
