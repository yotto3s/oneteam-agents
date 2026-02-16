---
name: self-review
description: >-
  Use before creating a PR or merging to run a thorough 5-phase sequential
  review pipeline. Spawns specialized reviewer and [oneteam:agent] bug-hunter
  subagents for each phase and, if issues are found, spawns [oneteam:agent]
  junior-engineer or [oneteam:agent] senior-engineer to fix them.
  Each phase follows a review-fix-re-review cycle. Produces a Self-Review Report
  with a PASS/FAIL verdict. This is a pre-review quality pass; external code
  review is still required before merge.
---

# Self-Review

## Overview

A 5-phase sequential review pipeline that thoroughly validates code changes
before merge. Each phase spawns specialized reviewer subagents and, if issues
are found, spawns [oneteam:agent] `junior-engineer` or [oneteam:agent]
`senior-engineer` to fix them.

**When to use:**
- Before creating a PR or merging (quality gate)
- On-demand for a thorough review of the current branch

## Phase 0: Setup

Before beginning the review pipeline, establish the review scope and spec
reference.

### Steps

1. **Determine diff scope.** If the caller provided a diff scope (e.g., a
   specific commit range or file list), use it. If not provided, ask the user
   for the diff scope.
   Default: `git diff <base-branch>...HEAD`
   Template: `"What diff scope should I review? Default: git diff <base-branch>...HEAD"`

2. **Determine spec reference.** If the caller provided a spec, design doc, or
   issue link, use it. If not provided, ask the user. The user may choose to
   skip; if skipped, intent will be inferred from commit messages and code
   context in Phase 1.
   Template: `"Do you have a spec, design doc, or issue link for this work? (Enter to skip — intent will be inferred from commits)"`

3. **Capture the initial diff.** Run the diff command and store the output for
   Phase 1. All subsequent phases will re-capture the diff to include any fixes
   applied during earlier phases.

## Pipeline

Each phase follows the same pattern:

1. **Review** — Spawn a subagent to review the current diff
2. **Fix** (if issues found) — Spawn an engineer subagent to fix issues
3. **Re-review once** — Spawn the reviewer again to verify fixes
4. **Proceed** — Move to the next phase regardless of re-review outcome

### Phase 1: Spec Compliance Review

**Goal:** Verify the implementation matches the spec (or inferred intent).

#### Steps

1. **Spawn a code-reviewer subagent** focused on spec compliance only.
   Provide:
   - The current diff (re-captured: `git diff <base-branch>...HEAD`)
   - The spec reference (or instruction to infer intent from commit messages
     and code context if no spec was provided)
   - Instruction: review ONLY for spec compliance — does the implementation
     match what the spec requires? Ignore code quality, test coverage, and
     style concerns.
   - Instruction: produce findings with severities (Critical / Important /
     Minor) using this format:

   ```
   ## Spec Compliance Review

   ### Findings
   - [SC-1] Severity: Critical | <file>:<line> — <description>
   - [SC-2] Severity: Important | <file>:<line> — <description>
   - [SC-3] Severity: Minor | <file>:<line> — <description>

   ### Summary
   - X findings (C critical, I important, M minor)
   - Verdict: PASS (no findings) / ISSUES FOUND
   ```

2. **If findings exist, enter the fix loop:**
   - Critical or Important findings present: spawn a **[oneteam:agent]
     `senior-engineer`** subagent with the findings and instruct it to fix all
     issues.
   - Only Minor findings present: spawn a **[oneteam:agent]
     `junior-engineer`** subagent with the findings and instruct it to fix all
     issues.
   - After the engineer completes fixes: spawn the code-reviewer subagent
     again (re-review once) with the updated diff. Record the re-review
     results.

3. **If no findings exist:** Record Phase 1 as PASS with zero findings.

4. **Record phase results.** Log the number of findings, how many were fixed,
   how many remain unresolved, the engineer tier used (or "none"), and the
   phase status (PASS / ISSUES REMAINING).

5. **Proceed to Phase 2** regardless of re-review outcome.

### Phase 2: Code Quality Review

**Goal:** Check code quality, conventions, security, and structure.

#### Steps

1. **Spawn a code-reviewer subagent** focused on code quality only.
   Provide:
   - The current diff (re-captured: `git diff <base-branch>...HEAD`)
   - Instruction: review ONLY for code quality — conventions, naming,
     structure, security, error handling, OWASP top 10 concerns, DRY
     violations, dead code. Ignore spec compliance and test coverage.
   - Instruction: produce findings with severities (Critical / Important /
     Minor) using this format:

   ```
   ## Code Quality Review

   ### Findings
   - [CQ-1] Severity: Critical | <file>:<line> — <description>
   - [CQ-2] Severity: Important | <file>:<line> — <description>
   - [CQ-3] Severity: Minor | <file>:<line> — <description>

   ### Summary
   - X findings (C critical, I important, M minor)
   - Verdict: PASS (no findings) / ISSUES FOUND
   ```

2. **Fix loop** (same pattern as Phase 1):
   - Critical/Important: spawn **[oneteam:agent] `senior-engineer`**
   - Minor only: spawn **[oneteam:agent] `junior-engineer`**
   - After fix: re-review once with updated diff

3. **Record phase results** and proceed to Phase 3.

### Phase 3: Test Comprehensiveness Review

**Goal:** Identify missing test cases, edge cases, and coverage gaps.

#### Steps

1. **Spawn a code-reviewer subagent** focused on test coverage and
   comprehensiveness.
   Provide:
   - The current diff (re-captured: `git diff <base-branch>...HEAD`)
   - Instruction: review ONLY for test comprehensiveness — missing test
     cases, missing edge cases, untested error paths, boundary conditions,
     integration gaps, pesticide paradox (existing tests not updated for
     new behavior). Ignore spec compliance and code quality style issues.
   - Instruction: produce findings with severities (Critical / Important /
     Minor) using this format:

   ```
   ## Test Comprehensiveness Review

   ### Findings
   - [TC-1] Severity: Critical | <file or area> — <description of missing test>
   - [TC-2] Severity: Important | <file or area> — <description>
   - [TC-3] Severity: Minor | <file or area> — <description>

   ### Summary
   - X findings (C critical, I important, M minor)
   - Verdict: PASS (no findings) / ISSUES FOUND
   ```

2. **Fix loop** (same pattern as Phase 1):
   - Critical/Important: spawn **[oneteam:agent] `senior-engineer`** to write missing tests
   - Minor only: spawn **[oneteam:agent] `junior-engineer`** to write missing tests
   - After fix: re-review once with updated diff

3. **Record phase results** and proceed to Phase 4.

### Phase 4: Bug Hunting

**Goal:** Find latent bugs in the changed code using the bug-hunting skill.

#### Steps

1. **Spawn a [oneteam:agent] `bug-hunter` subagent.** The bug-hunter runs the [oneteam:skill]
   `bug-hunting` skill against the changed files in the diff scope.
   Provide:
   - The list of changed files from the diff
   - The spec reference (if available)
   - Instruction: run the full 6-phase bug-hunting pipeline against these
     files and produce the standard Bug Finding Report with findings (F1,
     F2, ...) and reproduction tests

2. **If findings with reproduction tests exist, enter the fix loop:**
   - HIGH or MEDIUM severity findings present: spawn a **[oneteam:agent]
     `senior-engineer`** subagent with the findings report and reproduction
     test paths.
   - Only LOW severity findings present: spawn a **[oneteam:agent]
     `junior-engineer`** subagent with the findings report and reproduction
     test paths.
   - The engineer receives: all findings, reproduction tests, and
     instructions to fix the bugs and verify the reproduction tests pass
     after fixing.
   - After the engineer completes fixes: spawn the [oneteam:agent]
     `bug-hunter` subagent again to re-run the reproduction tests only (not
     the full 6-phase bug-hunting pipeline). Record which tests now pass and
     which still fail.

3. **Record phase results:** number of findings, number fixed (reproduction
   test now passes), number unresolved, engineer tier, phase status.

4. **Proceed to Phase 5** regardless of re-verification outcome.

### Phase 5: Comprehensive Review

**Goal:** Catch anything missed by the focused reviews and identify
cross-cutting concerns.

#### Steps

1. **Spawn a code-reviewer subagent** for a holistic final review.
   Provide:
   - The full current diff (re-captured: `git diff <base-branch>...HEAD`,
     including all fixes from Phases 1-4)
   - The spec reference (if available)
   - Summaries of findings from all prior phases (Phases 1-4)
   - Instruction: perform a comprehensive review looking for anything missed
     by the focused reviews — cross-cutting concerns, integration issues,
     consistency problems, architectural concerns. You have seen the prior
     phase summaries; focus on what they may have missed.
   - Instruction: produce findings with severities (Critical / Important /
     Minor) using this format:

   ```
   ## Comprehensive Review

   ### Findings
   - [CR-1] Severity: Critical | <file>:<line> — <description>
   - [CR-2] Severity: Important | <file>:<line> — <description>
   - [CR-3] Severity: Minor | <file>:<line> — <description>

   ### Summary
   - X findings (C critical, I important, M minor)
   - Verdict: PASS (no findings) / ISSUES FOUND
   ```

2. **Fix loop** (same pattern as Phase 1):
   - Critical/Important: spawn **[oneteam:agent] `senior-engineer`**
   - Minor only: spawn **[oneteam:agent] `junior-engineer`**
   - After fix: re-review once with updated diff

3. **Record phase results.**

## Self-Review Report

After all 5 phases complete, produce this exact report template. Every section
is mandatory. Do not omit any section.

```
# Self-Review Report

## Summary
- **Scope:** <diff range>
- **Spec:** <spec reference or "inferred from context">
- **Verdict:** PASS | FAIL (FAIL if any unresolved Critical/Important issues remain)

## Phase 1: Spec Compliance
- Findings: N (X fixed, Y unresolved)
- Engineer: junior/senior/none
- Status: PASS / ISSUES REMAINING

## Phase 2: Code Quality
- Findings: N (X fixed, Y unresolved)
- Engineer: junior/senior/none
- Status: PASS / ISSUES REMAINING

## Phase 3: Test Comprehensiveness
- Findings: N (X fixed, Y unresolved)
- Engineer: junior/senior/none
- Status: PASS / ISSUES REMAINING

## Phase 4: Bug Hunting
- Findings: N (X fixed, Y unresolved)
- Engineer: junior/senior/none
- Status: PASS / ISSUES REMAINING

## Phase 5: Comprehensive Review
- Findings: N (X fixed, Y unresolved)
- Engineer: junior/senior/none
- Status: PASS / ISSUES REMAINING

## Unresolved Issues
<list of any issues that remain after fix + re-review cycle, or "None">
```

**Verdict logic:**
- **PASS:** All phases have status PASS, or all remaining issues are Minor
  (Phases 1-3, 5) or LOW (Phase 4) severity only.
- **FAIL:** Any unresolved Critical or Important (Phases 1-3, 5) or HIGH or
  MEDIUM (Phase 4) issues remain. Unresolved MEDIUM severity issues from
  Phase 4 trigger FAIL, not PASS.

## Constraints

These rules are non-negotiable and override any conflicting instruction.

1. **Strictly sequential** — Phase N+1 does not start until Phase N (including
   its fix loop) is fully complete.
2. **One fix cycle per phase** — After the engineer fixes, the reviewer
   re-checks once. If still failing, log the unresolved issues and proceed to
   the next phase. Do NOT loop further.
3. **Severity-based engineer selection** — Critical/Important/HIGH/MEDIUM
   findings require [oneteam:agent] `senior-engineer`; Minor/LOW findings use
   [oneteam:agent] `junior-engineer`.
4. **Re-review uses updated diff** — Re-review and all subsequent phases
   operate on the latest code state, not a stale diff.
5. **Self-review does not replace external review** — This is a pre-review
   quality pass. External code review is still required before merge.
6. **No skipping phases** — All 5 phases run even if earlier phases found no
   issues.
7. **No fixing during review** — Reviewer subagents identify issues only.
   Engineer subagents fix issues only. Roles do not overlap.

## Anti-Patterns

When the agent catches itself thinking any of the following, stop and apply the
correction.

| Rationalization | Why it is wrong |
|---|---|
| "Phase 1 found nothing, skip Phase 5" | Each phase has a different lens; comprehensive review catches cross-cutting issues |
| "Only minor issues, skip the fix" | Minor issues compound; fix them while context is fresh |
| "Self-review passed, skip external review" | Self-review is a pre-filter, not a replacement for independent review |
| "The fix is trivial, skip re-review" | Trivial fixes can introduce new issues; always re-verify |
| "Tests already exist, skip Phase 3" | Existing tests may have gaps; comprehensiveness review catches what is missing |
| "Bug-hunter found nothing, Phase 4 is done" | Verify the bug-hunter completed all 6 sub-phases; partial runs miss bugs |
| "The re-review found new issues, fix those too" | One fix cycle per phase; log new issues as unresolved and proceed |
