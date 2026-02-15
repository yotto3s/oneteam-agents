# Design: Merge debug-team-leader into lead-engineer

**Date:** 2026-02-15
**Goal:** Reduce duplication by absorbing debug-team-leader into lead-engineer,
extract spec-review into a standalone skill.

## Motivation

Both debug-team-leader and lead-engineer are thin wrappers around the
team-management skill that fill in domain-specific slots. In real-world
engineering, a lead engineer handles both feature implementation and debugging.
The artificial separation creates duplication without meaningful benefit.

## Architecture

### Merged lead-engineer agent

**Name:** lead-engineer (unchanged)
**Model:** opus
**Tools:** Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch
**Skills:** team-management, team-collaboration, spec-review (new)
**Color:** purple

#### Context Inference

On startup, the agent reads its initialization context and infers the domain:

- **Feature mode** -- triggered when a spec/design document is provided, or when
  the task involves implementing new functionality. Invokes the spec-review
  skill, then plans and delegates to junior/senior engineers + code-reviewer.
- **Debug mode** -- triggered when the task involves finding and fixing bugs,
  running a debugging sweep, or when explicit debugging instructions are given.
  Splits by module boundaries + git churn, delegates to bug-hunter + engineer
  pairs with severity-based agent selection.

If ambiguous, the agent asks the user.

#### Domain Presets

The agent defines two sets of team-management slots inline:

**Feature preset:**
- Splitting: by implementation plan tasks
- Organization: `feature` group, junior-engineer + senior-engineer + code-reviewer
- Review criteria: spec conformance, no scope creep, test coverage
- Report: spec conformance table

**Debug preset:**
- Splitting: module boundaries + git churn
- Organization: `debug` group, bug-hunter + engineer (severity-based selection)
- Review criteria: root cause fixes, no regressions, minimal changes
- Report: systemic patterns + escalated findings

### Extracted spec-review skill

**Location:** skills/spec-review/SKILL.md

#### Phases

**Phase 1: Read & Understand**
- Obtain the spec from authority or initialization context
- Read it thoroughly end-to-end before analyzing

**Phase 2: Analyze target codebase**
- Read existing code in scope, map structure with Glob/Grep
- Understand current architecture, patterns, conventions

**Phase 3: Quality check against best-practice criteria**

Apply these checks to every requirement, drawn from IEEE 830, INVEST, and
Wiegers:

| Criterion | What to check | Red-flag words |
|-----------|--------------|----------------|
| Unambiguous | Each requirement has exactly one interpretation | "usually", "sometimes", "may", "mostly", "etc.", "appropriate", "as needed" |
| Complete | All functional, non-functional, and interface requirements present; no TBDs | "TBD", "to be determined", "later" |
| Consistent | No requirements contradict each other or existing code behavior | -- |
| Testable | Each requirement has definable acceptance criteria | "user-friendly", "fast", "intuitive", "robust" |
| Feasible | Achievable with available technology and codebase constraints | -- |
| Necessary | Every requirement traces to a business need; no gold-plating | -- |
| Independent | Requirements are self-contained; can be implemented and tested separately | -- |
| Scoped correctly | Specifies what, not how; doesn't mix requirements with design | -- |

**Phase 4: Issue identification**
- Ambiguities, missing edge cases (empty input, errors, concurrency, boundaries)
- Unstated assumptions (infrastructure, data formats, API contracts)
- Risks (blast radius, failure modes)
- Contradictions with existing code

**Phase 5: Produce Spec Review Report**

```
## Spec Review Report

### Quality Assessment
| Criterion | Pass/Fail | Notes |
|-----------|-----------|-------|

### Confirmed Requirements
- [R1] <requirement>

### Questions and Gaps
- [Q1] <issue> -- suggested resolution: <suggestion>

### Risks
- [K1] <risk> -- mitigation: <suggestion>

### Suggested Refinements
- [S1] <improvement>
```

**Phase 6: Hard gate -- wait for approval**

## File Changes

### Create
- skills/spec-review/SKILL.md

### Modify
- agents/lead-engineer.md -- rewrite with domain presets + context inference
- CLAUDE.md -- update agent table, add spec-review to skill table
- skills/team-management/SKILL.md -- update Example 3 reference
- README.md -- update references

### Delete
- agents/debug-team-leader.md

### Update references (docs)
- docs/plans/2026-02-15-junior-senior-engineer-plan.md
- docs/plans/2026-02-15-junior-senior-engineer-design.md
- docs/plans/2026-02-15-pipeline-redesign-plan.md
- docs/plans/2026-02-15-subagent-mode-plan.md
- docs/plans/2026-02-15-subagent-mode-design.md
