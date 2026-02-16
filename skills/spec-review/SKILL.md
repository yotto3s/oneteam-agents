---
name: spec-review
description: >-
  Use when reviewing a specification or design document before implementation.
  Provides a structured quality check against industry best practices (IEEE 830,
  INVEST, Wiegers), identifies issues, and produces a Spec Review Report with
  hard gate for authority approval.
---

# Spec Review

## Overview

This skill provides a structured process for reviewing specifications before
implementation begins. It applies industry-standard quality criteria to every
requirement, identifies issues, and produces a report for authority approval.

Invoked by leader agents (e.g., lead-engineer) when a spec or design document
is provided. The output is a Spec Review Report that must be approved before
any implementation planning begins.

## Phase 1: Read & Understand

1. **Obtain the spec.** Read the specification from the initialization context,
   authority message, or user prompt. If no spec is available, ask the authority
   for it before proceeding. Do NOT guess or start without a spec.

2. **Read it end-to-end.** Read the entire spec thoroughly before analyzing.
   Do not start identifying issues mid-read — complete the full read first to
   understand the overall intent and scope.

## Phase 2: Analyze Target Codebase

1. **Map the scope.** Use Glob and Grep to identify the files and modules that
   fall within the spec's scope. List the key files that will need to change.

2. **Understand current architecture.** Read existing code in the scope area to
   understand patterns, conventions, data flow, and dependencies. Note anything
   that the spec may conflict with or depend on.

3. **Identify test coverage.** Check for existing tests in the scope area. Note
   which areas have coverage and which do not.

## Phase 3: Quality Check

Apply these checks to every requirement in the spec. These criteria are drawn
from IEEE 830, the INVEST framework, and Karl Wiegers' requirements engineering
best practices.

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

For each criterion, mark Pass or Fail and note specific issues.

## Phase 4: Issue Identification

Beyond the quality checklist, identify:

1. **Ambiguities** — statements that could be interpreted multiple ways.
2. **Missing edge cases** — what happens with empty input, errors, concurrent
   access, boundary values, unexpected types?
3. **Unstated assumptions** — does the spec assume certain infrastructure, data
   formats, API contracts, or environmental conditions that are not documented?
4. **Risks** — what could go wrong? What has the highest blast radius? What
   failure modes are not addressed?
5. **Contradictions** — does any part of the spec conflict with another part
   or with existing code behavior discovered in Phase 2?

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

## Phase 6: Hard Gate — Wait for Approval

**STOP.** Do NOT proceed until the authority has reviewed the report, answered questions from the Questions and Gaps section, and explicitly confirmed the spec. If the authority provides an updated spec, return to Phase 1 and re-review; if they answer questions without changing the spec, incorporate answers into Confirmed Requirements and proceed.

## Constraints

- ALWAYS complete all 6 phases in order. Do not skip any phase.
- ALWAYS read the full spec before identifying issues (Phase 1 before Phase 3).
- ALWAYS analyze the target codebase (Phase 2) before the quality check — you
  need codebase context to assess feasibility and consistency.
- ALWAYS produce the full Spec Review Report template. Do not omit sections.
- NEVER proceed past the Phase 6 hard gate without explicit authority approval.
- NEVER begin implementation planning or coding during spec review.
