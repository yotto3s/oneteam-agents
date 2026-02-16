---
name: bug-hunting
description: >-
  Use when asked to review merged PRs for integration bugs, audit a module or
  codebase for latent issues, investigate vague suspicions about code correctness,
  or perform any proactive bug discovery where no specific error message or test
  failure exists yet. Not for known bugs with symptoms (use [superpowers:skill] systematic-debugging)
  or writing new tests (use TDD).
---

# Bug Hunting

## Iron Law

**The agent MUST complete ALL six phases for EVERY item in scope before declaring "no issues found" or producing any findings summary.** Each phase produces explicit written output before the next phase begins — finding one bug does not excuse skipping the remaining scope.

## When to Use

The agent activates this skill when any of these conditions hold:

1. **Post-merge integration review** -- the user merged multiple PRs or branches
   and wants to check for interaction bugs.
2. **Proactive audit** -- the user asks the agent to audit, review, or find bugs
   in a module, file, or codebase with no known failure.
3. **Vague suspicion** -- the user says "something feels off" or "can you check
   this area" without a specific error message.

The agent does NOT use this skill when:

- A specific error message or test failure exists (use [superpowers:skill] `systematic-debugging`).
- The goal is to write or improve tests (use TDD workflow).

## Phase Pipeline

The agent executes these six phases in strict order. No phase may be skipped.
Each phase produces written output before the next begins. If the scope contains
N items, every item passes through every phase.

1. **Phase 1: Scope Definition** --> scope list
2. **Phase 2: Contract Inventory** --> contract table
3. **Phase 3: Impact Tracing & Spec Check** --> traced issues
4. **Phase 4: Adversarial Analysis** --> adversarial findings
5. **Phase 5: Gap Analysis** --> coverage gaps
6. **Phase 6: Shallow Verification & Report** --> formal report

### Phase 1: Scope Definition

The agent defines the exact scope before reading any implementation code.

1. Identify every changed file, function, and module in scope.
2. Map the blast radius: what other code depends on or is called by the changes.
3. Write the scope list explicitly. Example: "Scope: PR #76, PR #81, files X, Y, Z,
   callers A, B, C."

If the user does not provide scope, the agent asks for it. The agent never
assumes scope from context alone.

### Phase 2: Contract Inventory

For EACH function or module in scope, the agent enumerates in writing:

| Contract Element | What to Document |
|---|---|
| Input preconditions | Types, ranges, nullability, required state |
| Output postconditions | Return values, side effects, state mutations |
| Invariants | What must be true before and after execution |
| Implicit assumptions | Data format, ordering, encoding, timing |

The agent writes this table before proceeding. Skipping this phase is the
primary cause of missed bugs -- without an explicit contract list, there is
nothing to trace against.

### Phase 3: Impact Tracing and Spec Check

For each item in scope, the agent performs both impact tracing and specification
checking.

**Specification conformance:** Compare the implementation against its
specification (PR description, issue requirements, doc comments, design docs).
Does the code do what it claims to do? The agent must read the specification
source, not guess at intent.

**Impact tracing:**
- Do all callers still satisfy preconditions after the change?
- Do all callees still satisfy postconditions?
- Are cross-change interactions safe? (Two independently-correct changes that
  break when combined.)
- FedEx tour: trace one key data entity through its full lifecycle across the
  changed code.

### Phase 4: Adversarial Analysis

The agent applies a "prove it breaks" mindset. This phase is MANDATORY even if
Phases 2-3 found nothing. Finding nothing earlier means this phase is MORE
important, not less.

Apply techniques from Tier 1-4 disciplines below. The agent writes at least one adversarial scenario per item in scope. If no scenario produces a finding, the agent documents what was tried and why it did not break.

### Phase 5: Gap Analysis

The agent identifies:

1. Changed code paths with no test coverage.
2. Contracts from Phase 2 that have no corresponding test assertions.
3. Pesticide paradox: tests that exist but have not evolved with the code (test
   passes but does not exercise the new behavior).

### Phase 6: Shallow Verification and Report

For each suspect found in Phases 3-5:

1. Trace one concrete code path to confirm it is a real issue.
2. If confirmed, add to findings with severity and confidence.
3. If not reproducible through reasoning, mark as "uncertain."
4. Produce the formal report (see Output Format below).

The agent does NOT fix bugs during this phase. Fixing mid-scan causes the agent
to forget remaining scope items. Findings are recorded; fixes come later.

## Bug-Finding Disciplines

### Tier 1: Contract and Invariant Analysis (Primary)

| Discipline | Description |
|---|---|
| Invariant checking | "This variable must always be positive here" |
| Type narrowing | "Type says X but runtime value could be Y" |
| Error path tracing | "If this call fails, does the caller handle it?" |
| Invalid state transitions | Can the system reach a state violating its contract? |
| Implicit coupling | "Two modules share assumptions about data format" |
| Specification conformance | Does the implementation match what it claims to do? |

### Tier 2: Change Impact Analysis

| Discipline | Description |
|---|---|
| Defect clustering (Pareto) | Focus on modules with frequent changes or prior bugs |
| Pesticide paradox | Tests unchanged but code changed -- tests may be blind |
| FedEx tour | Trace a data entity through its lifecycle across changed code |
| Boundary analysis | Zero, null, empty, max int, off-by-one at changed edges |

### Tier 3: Concurrency and Timing

| Discipline | Description |
|---|---|
| Race conditions | Two simultaneous callers -- what happens? |
| State machine analysis | Does new code respect transition ordering? |
| Time boundaries | Timezone, leap year, month-end logic in changed code |
| Session contradictions | Does code handle stale or concurrent sessions? |

### Tier 4: Input and Encoding

| Discipline | Description |
|---|---|
| Special characters | Does changed code sanitize emoji, control chars, injection? |
| Null and whitespace | Are empty or whitespace inputs handled in new code? |
| Pairwise interactions | When multiple parameters combine, do unexpected pairs break? |
| Resource limits | What if memory or storage is exhausted during this path? |

## Rationalization Defense

When the agent catches itself thinking any of the following, the agent stops and
applies the correction in the right column.

| Rationalization | Correction |
|---|---|
| "The code looks fine" | Did the agent complete all 6 phases? If not, the agent does not know that. |
| "I will just fix this quickly" | Stop. Add it to findings and keep scanning. Fixing mid-scan means forgetting the rest. |
| "The tests pass so it is probably fine" | Pesticide paradox -- passing tests only prove what they test. Check for gaps. |
| "This change is trivial" | Trivial changes in high-traffic code paths cause production outages. Check contracts. |
| "I already know what this code does" | Read it again. Assumptions are where bugs hide. |
| "I found a bug, so the review is complete" | Finding one bug does not excuse skipping remaining scope. Complete all phases for all items. |

## Red Flags

The agent is producing low-quality output if any of these are true:

- Declaring "no issues found" in under 2 minutes for any non-trivial scope.
- Skipping Phase 4 because Phases 2-3 found nothing.
- Reporting only one severity level (all "low" or all "high").
- Never looking at callers or callees of changed code.
- Summarizing a function without reading its implementation.
- Stopping analysis after the first finding.
- Producing free-form narrative instead of the structured report format.
- Listing techniques without executing them ("I would check boundaries" instead
  of actually checking boundaries).

## Output Format

The agent produces exactly this structure. Every section is mandatory. Empty
sections are written as "None identified" -- they are never omitted.

```
## Bug Finding Report

**Scope:** [what was analyzed -- PRs, modules, files]
**Branch/Commits:** [git refs]

### Phase Completion Checklist

- [ ] Phase 1: Scope defined (N items)
- [ ] Phase 2: Contracts inventoried (N functions)
- [ ] Phase 3: Impact traced and specs checked
- [ ] Phase 4: Adversarial analysis completed (N scenarios tested)
- [ ] Phase 5: Gap analysis completed
- [ ] Phase 6: Findings verified

### Findings

#### [F1] Severity: HIGH | file.cpp:123
**Category:** Contract violation / Integration issue / Spec mismatch / ...
**What:** One-sentence description of the bug.
**Reasoning:** Step-by-step trace of how the agent arrived at this conclusion.
**Confidence:** Confirmed / Likely / Uncertain

#### [F2] ...

### Coverage Gaps
- [G1] function_name() -- changed but no test covers the new path

### Spec Deviations
- [S1] PR #N says "X" but implementation does "Y"

### Summary
- X findings (H high, M medium, L low)
- Y coverage gaps
- Z spec deviations
```

**Severity levels:**
- HIGH: Confirmed bug, crash, or data corruption.
- MEDIUM: Likely issue, needs investigation to confirm.
- LOW: Code smell, edge case, or minor inconsistency.

**Confidence levels:**
- Confirmed: Traced a concrete code path demonstrating the issue.
- Likely: Strong reasoning supports the issue but no single path traced.
- Uncertain: Suspicious but could not verify through reasoning alone.

## Quick Reference

| Phase | Input | Output | Key Question |
|---|---|---|---|
| 1. Scope | User request | Scope list with blast radius | What exactly are we analyzing? |
| 2. Contracts | Scope list | Contract table per function | What must be true for this code? |
| 3. Impact + Spec | Contracts | Traced issues, spec deviations | Does reality match the contract and spec? |
| 4. Adversarial | Traced issues | Adversarial findings | How can I make this break? |
| 5. Gaps | All prior phases | Coverage gaps list | What is NOT tested? |
| 6. Report | All findings | Formal ranked report | Is each finding real or theoretical? |
