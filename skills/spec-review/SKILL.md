---
name: spec-review
description: >-
  Use when reviewing a specification or design document before implementation to
  identify ambiguities, missing requirements, risks, and quality issues against
  industry best practices (IEEE 830, INVEST, Wiegers).
---

# Spec Review

## Overview

A 6-phase workflow for reviewing specifications before implementation. Applies industry-standard quality criteria, identifies issues, and produces a Spec Review Report with a hard gate for authority approval.

## When to Use

- A spec or design document has been provided for review
- Before implementation planning begins
- Leader agent needs quality validation of requirements

## When NOT to Use

- Code is already implemented and you need to review it -- use code review
- You need to create the spec -- use [oneteam:skill] `brainstorming`

## Phase 1: Read & Understand

1. **Obtain the spec.** Read from initialization context, authority message, or user prompt. If unavailable, ask before proceeding.
   Template: `"Need the spec to begin review. Please provide it or point me to the design doc."`
2. **Read end-to-end.** Complete the full read before analyzing -- understand overall intent and scope first.

## Phase 2: Analyze Target Codebase

1. **Map the scope.** Use Glob and Grep to identify files and modules in the spec's scope.
2. **Understand current architecture.** Read existing code to understand patterns, data flow, and dependencies. Note conflicts or dependencies with the spec.
3. **Identify test coverage.** Check for existing tests; note covered and uncovered areas.

## Phase 3: Quality Check

Apply to every requirement. Criteria drawn from IEEE 830, INVEST, and Wiegers.

| Criterion | What to check | Red-flag words |
|-----------|--------------|----------------|
| **Unambiguous** | Each requirement has exactly one interpretation. No vague qualifiers. | "usually", "sometimes", "may", "mostly", "etc.", "appropriate", "as needed" |
| **Complete** | All functional, non-functional, and interface requirements are present. No placeholders. | "TBD", "to be determined", "later", "TODO" |
| **Consistent** | No requirements contradict each other or conflict with existing code behavior. | -- |
| **Testable** | Each requirement has definable acceptance criteria. Can be verified via test, analysis, or demonstration. | "user-friendly", "fast", "intuitive", "robust", "efficient" (unmeasurable) |
| **Feasible** | Achievable with available technology, dependencies, and codebase constraints. | -- |
| **Necessary** | Every requirement traces to a business need. No gold-plating or scope creep. | -- |
| **Independent** | Requirements are self-contained with minimal overlap. Can be implemented and tested separately. | -- |
| **Scoped correctly** | Specifies *what*, not *how*. Does not mix requirements with design decisions or implementation details. | -- |

Mark Pass or Fail per criterion with specific issues noted.

## Phase 4: Issue Identification

Beyond the quality checklist, identify:

- **Ambiguities** -- statements interpretable multiple ways
- **Missing edge cases** -- empty input, errors, concurrency, boundaries, unexpected types
- **Unstated assumptions** -- assumed infrastructure, data formats, API contracts, environment
- **Risks** -- highest blast radius failures, unaddressed failure modes
- **Contradictions** -- conflicts within the spec or with existing code from Phase 2

## Phase 5: Produce Spec Review Report

Format the findings into this exact template:

```
## Spec Review Report

### Quality Assessment
| Criterion | Pass/Fail | Notes |
|-----------|-----------|-------|
| Unambiguous | | |
| Complete | | |
| Consistent | | |
| Testable | | |
| Feasible | | |
| Necessary | | |
| Independent | | |
| Scoped correctly | | |

### Confirmed Requirements
- [R1] <requirement clearly stated in spec>
- [R2] ...

### Questions and Gaps
- [Q1] <ambiguity or missing detail> -- suggested resolution: <suggestion>
- [Q2] ...

### Risks
- [K1] <risk description> -- mitigation: <suggestion>
- [K2] ...

### Suggested Refinements
- [S1] <improvement to spec>
- [S2] ...
```

If a section has no items, write "None" rather than omitting the section.

**Send to authority for approval.** Via SendMessage if in a team, or display
to user if standalone. Include the full report.
Template: `"Spec review complete. Blocked on answers to <Q1, Q2, ...>. Please confirm the spec to proceed."`

## Phase 6: Hard Gate — Wait for Approval

**STOP.** Do NOT proceed until the authority has reviewed the report, answered questions from the Questions and Gaps section, and explicitly confirmed the spec. If the authority provides an updated spec, return to Phase 1 and re-review; if they answer questions without changing the spec, incorporate answers into Confirmed Requirements and proceed.

## Quick Reference

| Phase | Key Action | Output |
|-------|-----------|--------|
| 1. Read | Read spec end-to-end | Understanding of intent and scope |
| 2. Analyze | Map scope in codebase | File list, architecture understanding |
| 3. Quality Check | Apply 8 criteria | Pass/Fail per criterion |
| 4. Issues | Identify ambiguities, gaps, risks | Issue list |
| 5. Report | Produce Spec Review Report | Spec Review Report for authority |
| 6. Hard Gate | STOP -- wait for approval | Authority confirmation |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Starting issue identification while still reading the spec | Complete the full read first (Phase 1 before Phase 3) |
| Skipping codebase analysis | Phase 2 is required -- feasibility/consistency needs code context |
| Proceeding without authority approval | Phase 6 is a hard gate -- STOP until explicit confirmation |

## Constraints

- ALWAYS complete all 6 phases in order. Do not skip any phase.
- ALWAYS read the full spec before identifying issues (Phase 1 before Phase 3).
- ALWAYS analyze the target codebase (Phase 2) before the quality check -- you need codebase context to assess feasibility and consistency.
- ALWAYS produce the full Spec Review Report template. Do not omit sections.
- NEVER proceed past the Phase 6 hard gate without explicit authority approval.
- NEVER begin implementation planning or coding during spec review.
