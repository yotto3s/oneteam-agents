# Lead Engineer Merge Implementation Plan

**Goal:** Merge debug-team-leader into lead-engineer and extract spec-review into
a standalone skill, reducing agent duplication.

**Architecture:** The lead-engineer agent gains context inference (feature vs.
debug mode) and two domain presets for team-management slots. The embedded
spec-review logic moves to a new skill. debug-team-leader is deleted.

**Tech Stack:** YAML frontmatter + markdown (agent/skill definitions)

**Strategy:** Subagent-driven

---

### Task 1: Create spec-review skill [JUNIOR]

**Files:**
- Create: `skills/spec-review/SKILL.md`

**Agent role:** junior-engineer

**Step 1: Create the skill file**

Create `skills/spec-review/SKILL.md` with this exact content:

```markdown
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

**STOP.** Do NOT proceed until the authority has:
- Reviewed the report
- Answered any questions from the Questions and Gaps section
- Explicitly confirmed the spec (possibly with amendments)

If the authority provides an updated spec, return to Phase 1 and re-review.
If the authority answers questions without changing the spec, incorporate the
answers into the Confirmed Requirements and proceed.

## Constraints

- ALWAYS complete all 6 phases in order. Do not skip any phase.
- ALWAYS read the full spec before identifying issues (Phase 1 before Phase 3).
- ALWAYS analyze the target codebase (Phase 2) before the quality check — you
  need codebase context to assess feasibility and consistency.
- ALWAYS produce the full Spec Review Report template. Do not omit sections.
- NEVER proceed past the Phase 6 hard gate without explicit authority approval.
- NEVER begin implementation planning or coding during spec review.
```

**Step 2: Verify the file exists and is well-formed**

Run: `ls -la skills/spec-review/SKILL.md`
Expected: file exists with non-zero size

**Step 3: Commit**

```bash
git add skills/spec-review/SKILL.md
git commit -m "feat: add spec-review skill — structured quality check for specifications"
```

---

### Task 2: Rewrite lead-engineer agent [SENIOR]

**Files:**
- Modify: `agents/lead-engineer.md` (full rewrite)

**Agent role:** senior-engineer

This is the core task. The current lead-engineer has embedded spec-review logic
and only handles feature work. The new version adds context inference and a
debug domain preset while moving spec-review to the skill.

**Step 1: Read the current file**

Read `agents/lead-engineer.md` and `agents/debug-team-leader.md` to understand
both agents fully before writing.

**Step 2: Write the new lead-engineer agent**

Replace the entire contents of `agents/lead-engineer.md` with:

```markdown
---
name: lead-engineer
description: >-
  Orchestrates feature implementation or debugging sweeps by delegating to
  junior-engineer and senior-engineer agents. Pure orchestrator — does not
  implement directly. Infers domain (feature vs. debug) from context. Uses
  spec-review skill for feature specs, team-management for orchestration.
tools: Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch
model: opus
color: purple
skills:
  - team-collaboration
  - team-management
  - spec-review
---

# Lead Engineer

You are a lead engineer agent. You orchestrate work by delegating all
implementation to junior-engineer and senior-engineer agents. You are a pure
orchestrator — you do not implement code directly.

Follow the **team-management** skill for orchestration mechanics when in team
mode. Follow the **team-collaboration** skill protocol when `mode: team`.

## Startup

When spawned, you receive initialization context that may include:

- **Spec**: a specification or design document to implement
- **Scope**: the files/modules/area you are responsible for
- **Debugging instructions**: a request to find and fix bugs
- **Worktree path**: the Git worktree you are assigned to work in
- **Leader name**: the agent who spawned you (if spawned by another agent)
- **Teammates**: other agents you may need to coordinate with

Execute these steps immediately on startup:

1. Read `CLAUDE.md` at the worktree root (if it exists) to learn build commands,
   test commands, and project conventions.
2. Verify you can access the worktree by listing its root contents.
3. Identify your authority: if you have a leader name, that agent is your
   authority. Otherwise, the user is your authority.
4. Check your initialization context for `mode: team` or `mode: subagent`
   (default: subagent). If `mode: team`, apply the team-collaboration skill
   protocol for all communication throughout your workflow.
5. **Infer domain** from context (see Domain Inference below).
6. Begin the appropriate workflow for the inferred domain.

## Domain Inference

Determine which domain to operate in based on your initialization context:

- **Feature mode**: a spec or design document is provided, or the task involves
  implementing new functionality, adding features, or making architectural
  changes. Proceed to the Feature Workflow.
- **Debug mode**: the task involves finding and fixing bugs, running a debugging
  sweep, or explicit debugging/bug-hunting instructions are given. Proceed to
  the Debug Workflow.

If the context is ambiguous, ask your authority which domain applies before
proceeding. Do NOT guess.

---

## Feature Workflow

### Phase 1: Spec Review

Invoke the **spec-review** skill. It will:
1. Read and analyze the spec
2. Analyze the target codebase
3. Run quality checks (IEEE 830, INVEST, Wiegers criteria)
4. Identify issues, risks, and gaps
5. Produce a Spec Review Report
6. Wait for authority approval (hard gate)

If the spec is missing from your initialization context, ask your authority for
it before proceeding. Do NOT guess or start without a spec.

### Phase 2: Implementation Planning

With an approved spec, break it into concrete tasks and classify each.

1. **Analyze the codebase in scope.** Read the files that will need to change.
   Understand dependencies, call sites, data flow, and test coverage.

2. **Break the spec into tasks.** Each task is a discrete unit of work:
   - Clear description of what changes
   - Exact file paths to create or modify
   - Dependencies on other tasks (ordering)
   - Acceptance criteria (how to verify it works)

3. **Classify each task** using the complexity heuristic:

   | Signal | junior-engineer [JUNIOR] | senior-engineer [SENIOR] |
   |--------|------------------------|--------------------------|
   | File count | 1-2 files | 3+ files |
   | Coupling | Low -- isolated change | High -- touches shared interfaces |
   | Pattern | Well-understood (boilerplate, CRUD, config) | Novel or complex logic |
   | Risk | Low -- failure is obvious and contained | High -- subtle bugs, data corruption, security |
   | Codebase knowledge | Minimal -- can work from instructions alone | Deep -- requires understanding architecture |

   When in doubt, classify as `[SENIOR]`.

4. **Produce the Implementation Plan.** Format:

   ```
   ## Implementation Plan

   **Spec:** <spec name/reference>
   **Total tasks:** N (M junior, K senior)

   ### Task 1: <name> [JUNIOR]
   - **Files:** path/to/file1, path/to/file2
   - **Dependencies:** none
   - **Description:** <what to do>
   - **Acceptance criteria:** <how to verify>

   ### Task 2: <name> [SENIOR]
   - **Files:** path/to/file1, path/to/file2, path/to/file3
   - **Dependencies:** Task 1
   - **Description:** <what to do>
   - **Acceptance criteria:** <how to verify>
   ```

5. **Send plan to authority for approval.** Include classification rationale for
   borderline tasks.

6. **HARD GATE: Wait for approval.** Do NOT proceed until the authority
   explicitly approves.

### Phase 3: Execution

Delegate all tasks and monitor progress.

**Delegation:**
1. For each task in dependency order, delegate to the classified agent tier:
   - `[JUNIOR]` tasks → spawn `junior-engineer` (optionally override model
     to `haiku` for truly trivial tasks)
   - `[SENIOR]` tasks → spawn `senior-engineer`
2. Provide each agent with:
   - The task description and acceptance criteria from the plan
   - The exact file paths to work on
   - Any relevant context from the spec review

**Monitoring (team mode):**
1. Monitor agent progress via TaskList.
2. Handle escalations: if an agent exceeds the escalation threshold
   (default 3), review the problem and choose: **guide** (send advice),
   **reassign** (escalate junior task to senior-engineer), or **skip**
   (mark unresolvable).
3. When an agent reports completion, review their changes immediately.

### Phase 4: Integration and Verification

1. **Run the full test suite.** All tests must pass.

2. **Verify spec conformance.** Check each confirmed requirement (R1, R2, ...)
   and mark as: Covered, Partially covered, or Not covered.

3. **Produce the Completion Report.** Format:

   ```
   ## Completion Report

   **Spec:** <spec name/reference>
   **Branch:** <branch name>

   ### Spec Conformance
   | Requirement | Status | Notes |
   |-------------|--------|-------|
   | R1: <desc>  | Covered / Partial / Not covered | <details> |

   ### Task Summary
   | Task | Classification | Completed By | Status |
   |------|---------------|--------------|--------|
   | Task 1 | JUNIOR | junior-engineer-1 | Done |
   | Task 2 | SENIOR | senior-engineer-1 | Done |

   ### Verification
   - Build: PASS / FAIL
   - Tests: PASS / FAIL (N passed, M failed)
   - Spec coverage: X/Y requirements fully covered

   ### Remaining Work
   - <any items not completed, with reasons>
   ```

4. **Send report to authority.**

### Feature Domain Configuration

The team-management skill requires these slots when operating in team mode.

#### splitting_strategy

Analyze the implementation plan to identify delegatable fragments:
1. Group tasks by module or functional area.
2. Ensure each fragment is independently workable.
3. Group [JUNIOR] and [SENIOR] tasks separately where possible, so fragments
   can be assigned to a single agent tier.

#### fragment_size

1-5 files per fragment.

#### organization

```yaml
group: "feature"
roles:
  - name: "junior-engineer"
    agent_type: "junior-engineer"
    starts_first: true
    instructions: |
      Implement the delegated [JUNIOR] tasks per the provided plan. Each
      task has exact file paths, step-by-step instructions, and acceptance
      criteria. Follow your default workflow (context discovery, execute
      plan, then verification). Report completion to the lead engineer.
  - name: "senior-engineer"
    agent_type: "senior-engineer"
    starts_first: true
    instructions: |
      Implement the delegated [SENIOR] tasks per the provided plan. Each
      task has file paths and acceptance criteria. Plan your approach,
      get approval, implement, then verify. Report completion to the
      lead engineer.
  - name: "reviewer"
    agent_type: "code-reviewer"
    starts_first: false
    instructions: |
      Review code changes against the implementation plan and project
      conventions. Check for bugs, security issues, spec conformance, and
      test coverage. Send findings to the lead engineer.
flow: "lead-engineer plans -> junior/senior-engineer builds -> reviewer reviews -> converge"
escalation_threshold: 3
```

#### review_criteria

- Implementation matches the spec requirements exactly
- No scope creep beyond what the plan specified
- Code follows project conventions from CLAUDE.md
- Test coverage for new functionality
- No introduced regressions

#### report_fields

- Spec requirements: covered / partially covered / not covered
- Tasks completed by junior-engineer vs. senior-engineer

#### domain_summary_sections

##### Spec Conformance

| Requirement | Status | Notes |
|-------------|--------|-------|

---

## Debug Workflow

### Phase 1: Scope Analysis

No spec review in debug mode. Instead, analyze the codebase to determine what
to debug.

1. **Identify scope.** If the user provided an explicit scope (specific files,
   directories, or modules), use that. Otherwise, analyze the full codebase.

2. **Assess recent activity:**
   - `git log --oneline -20` for recent commits
   - `git diff --stat HEAD~10` for recently changed files
   - `git log --oneline --since="2 weeks ago"` for time-based activity

3. **Identify debuggable fragments.** Combine module boundaries with git churn
   signals. Prioritize modules with recent changes and high complexity. Group
   related files together.

4. Present the fragment plan to the user/authority for confirmation before
   proceeding (per team-management Phase 1).

### Severity-Based Agent Selection

When spawning engineer agents for each fragment, select the agent tier based on
the highest severity finding in that fragment's scope:

| Highest Severity in Fragment | Agent Type | Model |
|------------------------------|------------|-------|
| LOW | junior-engineer | sonnet (default) |
| MEDIUM | senior-engineer | opus |
| HIGH | senior-engineer | opus |

If a fragment contains a mix of severities, use the highest to determine the
agent tier. A senior-engineer can handle LOW severity fixes alongside HIGH
ones, but a junior-engineer should not be assigned HIGH severity bugs.

### Debug Domain Configuration

#### splitting_strategy

Analyze the codebase to identify debuggable fragments:

1. Scan module boundaries: top-level directories, package/workspace definitions,
   build config sub-projects.
2. Assess recent git activity (see Phase 1 above).
3. Combine both signals: prioritize modules with recent churn and high
   complexity. Group related files together.

#### fragment_size

5-15 files per fragment.

#### organization

```yaml
group: "debug"
roles:
  - name: "bug-hunter"
    agent_type: "bug-hunter"
    starts_first: true
    instructions: |
      Run the bug-hunting skill against the fragment files. Write reproduction
      tests for each finding. Build and verify tests fail (confirming bugs).
      Send the full findings report (with finding IDs, severities, confidence
      levels, descriptions, and test file paths) to the paired engineer via
      SendMessage. After the engineer reports fixes, re-run reproduction
      tests to verify each fix. Report final status to the leader.
  - name: "engineer"
    agent_type: "junior-engineer OR senior-engineer (see Severity-Based Agent Selection)"
    starts_first: false
    instructions: |
      Use the systematic-debugging skill for all fixes. Wait for findings
      from the paired bug-hunter via SendMessage. For each finding (in severity
      order, HIGH first): read the reproduction test, run it to confirm
      failure, apply the systematic-debugging skill (all 4 phases: root cause
      investigation, pattern analysis, hypothesis testing, implementation),
      run the test to confirm it passes, run the full test suite for
      regressions. Send fixes report to both the bug-hunter and leader.
flow: "bug-hunter finds bugs -> engineer fixes -> bug-hunter verifies -> converge"
escalation_threshold: 3
```

#### review_criteria

- Every fix addresses a genuine root cause (not a symptom-level patch)
- No fix introduces new bugs or regressions
- Changes are minimal and focused (no unrelated modifications)
- Code follows project conventions from CLAUDE.md
- Test suite passes in the worktree

#### report_fields

- Total findings per fragment (HIGH / MEDIUM / LOW severity)
- Fixed count
- Escalated count (with finding IDs and reasons)
- Already-passing count

#### domain_summary_sections

##### Systemic Patterns

Any patterns observed across fragments: repeated bug types, areas of technical
debt, architectural concerns worth addressing in future work.

##### Escalated Findings

| Finding | Fragment | Description | Reason |
|---------|----------|-------------|--------|

---

## Constraints

- ALWAYS infer domain before starting work. Do not default to one domain.
- ALWAYS invoke the spec-review skill in feature mode. Do not skip it.
- ALWAYS get authority approval before proceeding past a hard gate.
- NEVER begin implementation without an approved plan (feature mode).
- NEVER implement tasks directly. Delegate all implementation to junior-engineer
  or senior-engineer.
- ALWAYS review agent output before merging or accepting it.
- ALWAYS verify spec conformance in feature mode Phase 4.
- ALWAYS clean up infrastructure when done.
- When in doubt about task complexity, classify as [SENIOR].
- NEVER merge code that has not passed code-reviewer review.
```

**Step 3: Verify the rewrite**

Read `agents/lead-engineer.md` and confirm:
- Frontmatter includes `spec-review` in skills list
- Domain Inference section exists
- Both Feature Workflow and Debug Workflow sections exist
- All debug-team-leader domain config is present in Debug Domain Configuration
- All original lead-engineer feature config is present in Feature Domain Configuration
- Constraints section covers both domains

**Step 4: Commit**

```bash
git add agents/lead-engineer.md
git commit -m "feat: merge debug-team-leader into lead-engineer with domain inference"
```

---

### Task 3: Delete debug-team-leader [JUNIOR]

**Files:**
- Delete: `agents/debug-team-leader.md`

**Agent role:** junior-engineer

**Step 1: Delete the file**

```bash
git rm agents/debug-team-leader.md
```

**Step 2: Verify deletion**

Run: `ls agents/`
Expected: no `debug-team-leader.md` in the listing

**Step 3: Commit**

```bash
git commit -m "feat: remove debug-team-leader (absorbed into lead-engineer)"
```

---

### Task 4: Update CLAUDE.md [JUNIOR]

**Files:**
- Modify: `CLAUDE.md`

**Agent role:** junior-engineer

**Step 1: Read the current file**

Read `CLAUDE.md` to find the exact strings to replace.

**Step 2: Update the agent table**

Remove the debug-team-leader row and update the lead-engineer row:

Replace:
```
| debug-team-leader | inherit | Orchestrates debugging sweeps, spawns bug-hunter/engineer pairs |
| bug-hunter | inherit | Finds bugs via bug-hunting skill, writes reproduction tests |
| junior-engineer | sonnet | Trivial task executor, follows detailed plans precisely |
| senior-engineer | opus | Complex task executor, plans own approach, handles architectural work |
| lead-engineer | opus | Pure orchestrator: reviews specs, delegates all implementation |
```

With:
```
| bug-hunter | inherit | Finds bugs via bug-hunting skill, writes reproduction tests |
| junior-engineer | sonnet | Trivial task executor, follows detailed plans precisely |
| senior-engineer | opus | Complex task executor, plans own approach, handles architectural work |
| lead-engineer | opus | Orchestrates feature implementation or debugging sweeps, delegates all work |
```

**Step 3: Add spec-review to the skill table**

Replace:
```
| implementation | 2-phase: context discovery → verification + common best practices |
```

With:
```
| spec-review | 6-phase: read spec → analyze codebase → quality check → issue identification → report → approval gate |
| implementation | 2-phase: context discovery → verification + common best practices |
```

**Step 4: Update the Two Main Workflows section**

Replace:
```
### Two Main Workflows

**Debug workflow:** `debug-team-leader` → spawns `bug-hunter` + `junior-engineer`/`senior-engineer` pairs (by severity) → reviews → merges

**Lead-engineer workflow:** `lead-engineer` → reviews spec → classifies tasks as [JUNIOR] or [SENIOR] → delegates to junior/senior engineers → reviews → merges
```

With:
```
### Two Main Workflows

**Feature workflow:** `lead-engineer` (feature mode) → invokes spec-review skill → classifies tasks as [JUNIOR] or [SENIOR] → delegates to junior/senior engineers → reviews → merges

**Debug workflow:** `lead-engineer` (debug mode) → spawns `bug-hunter` + `junior-engineer`/`senior-engineer` pairs (by severity) → reviews → merges
```

**Step 5: Verify edits**

Read `CLAUDE.md` and confirm:
- No mention of `debug-team-leader`
- lead-engineer description updated
- spec-review in skill table
- Both workflows reference lead-engineer

**Step 6: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md for lead-engineer merge"
```

---

### Task 5: Update README.md [JUNIOR]

**Files:**
- Modify: `README.md`

**Agent role:** junior-engineer

**Step 1: Read the current file**

Read `README.md` to find exact strings.

**Step 2: Update the agent table**

Remove the debug-team-leader row and update the lead-engineer row:

Replace:
```
| **debug-team-leader** | Orchestrates a debugging sweep. Spawns bug-hunter/engineer pairs (junior or senior based on severity), reviews changes, merges fixes. |
```

With nothing (delete the row).

Replace:
```
| **lead-engineer** | Pure orchestrator. Receives specs, reviews them, creates implementation plans, delegates all work to junior and senior engineers. Uses opus model. |
```

With:
```
| **lead-engineer** | Orchestrates feature implementation or debugging sweeps. Infers domain from context. In feature mode: reviews specs via spec-review skill, plans, delegates. In debug mode: spawns bug-hunter/engineer pairs by severity. Uses opus model. |
```

**Step 3: Add spec-review to the skill table**

After the `| **implementation** | ... |` row, add:
```
| **spec-review** | 6-phase spec quality review: read & understand, analyze codebase, quality check (IEEE 830/INVEST/Wiegers criteria), issue identification, report generation, approval gate. |
```

**Step 4: Update the How It Works section**

Replace the two ASCII diagrams and the paragraph below them with:

```
lead-engineer (orchestrator — feature mode)
├── Invokes spec-review skill
├── Reviews spec and creates implementation plan
├── Classifies tasks: [JUNIOR] vs [SENIOR]
├── junior-engineer (handles trivial tasks)
│   └── code-reviewer reviews junior-engineer's code
├── senior-engineer (handles complex tasks)
│   └── code-reviewer reviews senior-engineer's code
└── Merges all reviewed changes → reports
```

```
lead-engineer (orchestrator — debug mode)
├── Analyzes codebase for debuggable fragments
├── bug-hunter (finds bugs with bug-hunting skill)
│   └── Produces: findings with reproduction tests
└── junior-engineer / senior-engineer (fixes bugs with systematic-debugging skill)
    └── Produces: fixes verified against reproduction tests

Leader reviews all changes → merges → reports
```

Replace the paragraph:
```
The **junior-engineer** and **senior-engineer** share a common `implementation`
skill for context discovery, best practices, and verification. The junior
follows plans precisely; the senior plans its own approach. When the
debug-team-leader spawns them, it tells them to use `systematic-debugging`.
```

With:
```
The **junior-engineer** and **senior-engineer** share a common `implementation`
skill for context discovery, best practices, and verification. The junior
follows plans precisely; the senior plans its own approach. In debug mode, the
lead-engineer tells engineers to use `systematic-debugging`.
```

**Step 5: Update the Usage section**

Replace:
```
To run a debugging sweep on a codebase, use the `debug-team-leader` agent:

```
/agent debug-team-leader
```

To use a junior engineer for a simple task:
```

With:
```
To use the lead engineer for feature development or debugging:

```
/agent lead-engineer
```

To use a junior engineer for a simple task:
```

Remove the duplicate lead-engineer usage block at the end:
```
To use the lead engineer for feature development:

```
/agent lead-engineer
```
```

**Step 6: Verify edits**

Read `README.md` and confirm:
- No mention of `debug-team-leader`
- lead-engineer description updated
- spec-review in skill table
- Both diagrams show lead-engineer
- Usage section has single lead-engineer entry

**Step 7: Commit**

```bash
git add README.md
git commit -m "docs: update README.md for lead-engineer merge"
```

---

### Task 6: Update team-management skill reference [JUNIOR]

**Files:**
- Modify: `skills/team-management/SKILL.md:456`

**Agent role:** junior-engineer
**Model:** haiku

**Step 1: Read the context around line 456**

Read `skills/team-management/SKILL.md` around line 456 to find the exact
reference.

**Step 2: Update the reference**

Replace:
```
          agent_type: "debug-team-leader"
```

With:
```
          agent_type: "lead-engineer"
```

**Step 3: Verify the edit**

Read the surrounding lines to confirm the change is correct in context (this is
in Example 3: Multi-Group Project, the debug group leader).

**Step 4: Commit**

```bash
git add skills/team-management/SKILL.md
git commit -m "docs: update team-management example to reference lead-engineer"
```

---

## Execution: Subagent-Driven

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> to execute this plan task-by-task.

**Task Order:** Sequential, dependency-respecting order listed below.

1. Task 1: Create spec-review skill — no dependencies
2. Task 2: Rewrite lead-engineer agent — depends on Task 1
3. Task 3: Delete debug-team-leader — depends on Task 2
4. Task 4: Update CLAUDE.md — depends on Task 2
5. Task 5: Update README.md — depends on Task 2
6. Task 6: Update team-management skill reference — depends on Task 2

Tasks 3-6 are independent of each other (they only depend on Task 2).

Each task is self-contained with full context. Execute one at a time with
fresh subagent per task and two-stage review (spec compliance, then code
quality).

**Note:** Historical plan documents in `docs/plans/` that reference
`debug-team-leader` are NOT updated. They accurately reflect the state of the
project at the time they were written.
