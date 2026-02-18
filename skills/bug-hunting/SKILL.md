---
name: bug-hunting
description: >-
  Use when reviewing merged PRs for integration bugs, auditing code for latent
  issues, investigating vague suspicions about code correctness, or performing
  proactive bug discovery where no specific error or test failure exists yet.
---

# Bug Hunting

## Overview

**Iron Law:** The agent MUST complete ALL six phases for EVERY item in scope before declaring "no issues found" or producing any findings summary. Each phase produces explicit written output before the next phase begins -- finding one bug does not excuse skipping the remaining scope.

## When to Use

1. **Post-merge integration review** -- merged multiple PRs/branches, check for interaction bugs.
2. **Proactive audit** -- audit, review, or find bugs in a module/file/codebase with no known failure.
3. **Vague suspicion** -- "something feels off" or "can you check this area" without a specific error.

## When NOT to Use

- A specific error message or test failure exists --> use [superpowers:skill] `systematic-debugging`.
- The goal is to write or improve tests --> use TDD workflow.

## Phase Pipeline

Six phases in strict order. No phase may be skipped. Each produces written output before the next begins. If scope contains N items, every item passes through every phase.

### Phase 1: Scope Definition

Identify every changed file, function, and module in scope. Map the blast radius (callers, callees, dependents). Write the scope list explicitly. If the user does not provide scope, `AskUserQuestion` (header: "Scope"):

| Option label | Description |
|---|---|
| PR numbers | User provides one or more PR numbers to review |
| File paths | User provides specific file paths to analyze |
| Module or directory | User provides a module name or directory path |

After the user selects a scope type, collect the specific value(s) (e.g., PR numbers, file paths, or directory) and proceed with scope definition.

### Phase 2: Contract Inventory

For EACH function/module in scope, enumerate in writing:

| Contract Element | What to Document |
|---|---|
| Input preconditions | Types, ranges, nullability, required state |
| Output postconditions | Return values, side effects, state mutations |
| Invariants | What must be true before and after execution |
| Implicit assumptions | Data format, ordering, encoding, timing |

Skipping this phase is the primary cause of missed bugs -- without an explicit contract list, there is nothing to trace against.

### Phase 3: Impact Tracing and Spec Check

Compare implementation against its specification (PR description, issue requirements, doc comments, design docs). Trace impact: do all callers still satisfy preconditions? Do all callees still satisfy postconditions? Are cross-change interactions safe? FedEx tour: trace one key data entity through its full lifecycle.

### Phase 4: Adversarial Analysis

MANDATORY even if Phases 2-3 found nothing. Finding nothing earlier means this phase is MORE important. Apply techniques from Tier 1-4 disciplines (see `./disciplines.md`). Write at least one adversarial scenario per scope item. If nothing breaks, document what was tried and why.

### Phase 5: Gap Analysis

Identify: (1) changed code paths with no test coverage, (2) contracts from Phase 2 with no corresponding test assertions, (3) pesticide paradox -- tests that pass but do not exercise new behavior.

### Phase 6: Shallow Verification and Report

For each suspect from Phases 3-5: trace one concrete code path to confirm, assign severity and confidence, mark as "uncertain" if not reproducible through reasoning. Produce the formal report (see `./report-template.md` for the complete output format template). Do NOT fix bugs during this phase -- fixing mid-scan causes forgotten scope items.

## Quick Reference

| Phase | Input | Output | Key Question |
|---|---|---|---|
| 1. Scope | User request | Scope list with blast radius | What exactly are we analyzing? |
| 2. Contracts | Scope list | Contract table per function | What must be true for this code? |
| 3. Impact + Spec | Contracts | Traced issues, spec deviations | Does reality match the contract and spec? |
| 4. Adversarial | Traced issues | Adversarial findings | How can I make this break? |
| 5. Gaps | All prior phases | Coverage gaps list | What is NOT tested? |
| 6. Report | All findings | Formal ranked report | Is each finding real or theoretical? |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| "The code looks fine" | Did you complete all 6 phases? If not, you do not know that. |
| "I will just fix this quickly" | Stop. Add it to findings and keep scanning. |
| "The tests pass so it is probably fine" | Pesticide paradox -- passing tests only prove what they test. |
| "This change is trivial" | Trivial changes in high-traffic paths cause outages. Check contracts. |
| "I found a bug, so the review is complete" | Finding one bug does not excuse skipping remaining scope. |
| Declaring "no issues found" in under 2 minutes | Complete all 6 phases for every scope item first. |
| Skipping Phase 4 because earlier phases found nothing | Phase 4 is MANDATORY. Nothing earlier means this phase is MORE important. |
| Listing techniques without executing them | Actually check boundaries, not "I would check boundaries." |

## Constraints

1. **All six phases are mandatory.** No phase may be skipped regardless of prior findings.
2. **No fixing during scanning.** Bugs are recorded, not fixed. Fixing mid-scan causes forgotten scope items.
3. **Written output per phase.** Each phase produces explicit written output before the next begins.
4. **Scope must be explicit.** The agent never assumes scope from context alone -- ask if not provided.
5. **Structured report only.** Output uses the formal report template, never free-form narrative.
6. **Every scope item through every phase.** N items means N complete passes through all 6 phases.
