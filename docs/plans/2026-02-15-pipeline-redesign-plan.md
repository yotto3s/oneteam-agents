# Pipeline Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restructure the oneteam-agents workflow pipeline so that writing-plans handles strategy decisions and delegates execution to either subagent-driven-development or team-leadership.

**Architecture:** Override the superpowers `writing-plans` skill with a new version that adds design analysis and strategy decision phases before plan writing. Simplify `team-leadership` to be team-only (remove strategy decision and subagent mode). Remove `lead-engineering` skill and embed its spec-review/classification expertise into the `lead-engineer` agent definition.

**Tech Stack:** YAML frontmatter + markdown (agent/skill definition files)

---

### Task 1: Create the writing-plans override skill

**Files:**
- Create: `skills/writing-plans/SKILL.md`

**Context:** This skill overrides the superpowers `writing-plans` skill via symlink precedence (`~/.claude/skills` symlinks to this repo). It inserts design analysis and strategy decision phases before plan writing. Phase 3 (plan writing) follows the exact same format as the original superpowers writing-plans skill. Phase 4 hands off to either `superpowers:subagent-driven-development` or `team-leadership`.

**Step 1: Create the skill file**

Create `skills/writing-plans/SKILL.md` with this exact content:

````markdown
---
name: writing-plans
description: >-
  Use when you have a spec or requirements for a multi-step task, before touching
  code. Analyzes the design, recommends an execution strategy (subagent-driven or
  team-driven), writes a strategy-adapted implementation plan, and hands off to
  the chosen execution skill.
---

# Writing Plans

## Overview

This skill overrides the superpowers `writing-plans` skill to add strategy
decision before plan writing. It receives a design document (typically from the
brainstorming skill), analyzes the work, asks the user which execution strategy
to use (subagent-driven or team-driven), then writes a strategy-adapted
implementation plan.

Write comprehensive implementation plans assuming the engineer has zero context
for our codebase and questionable taste. Document everything they need to know:
which files to touch for each task, code, testing, docs they might need to
check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI.
TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset
or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the
implementation plan."

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>-plan.md`

## Phase 1: Design Analysis

Read and analyze the design document produced by brainstorming (or provided by
the user). No user interaction in this phase -- purely analytical.

### Steps

1. **Read the design document.** Locate the design doc in `docs/plans/` or from
   the user's context. Read it thoroughly.

2. **Analyze the target codebase.** Read existing code in the scope area to
   understand current architecture, patterns, and conventions. Use Glob and Grep
   to map the relevant code structure.

3. **Extract planning signals.** Identify:
   - Total number of tasks the design implies
   - File touch areas per task
   - Dependencies between tasks (which must come before which)
   - Complexity of each task (isolated vs. coupled, boilerplate vs. novel)

4. **Record analysis.** Keep the extracted signals for use in Phase 2. Do not
   present them to the user yet -- they will be incorporated into the strategy
   recommendation.

## Phase 2: Strategy Decision

Present a light analysis and strategy recommendation to the user. The user
makes the final choice.

### Steps

1. **Analyze decision signals.** Use these heuristics:

   | Signal | Subagent-driven | Team-driven |
   |--------|----------------|-------------|
   | Task count | 1-3 tasks | 4+ tasks |
   | Independence | Mostly independent | Overlapping file scopes |
   | Parallelism benefit | Low (sequential is fine) | High (significant time savings) |

2. **Present strategy recommendation.** Display to the user:
   ```
   ## Strategy Recommendation

   **Tasks:** N
   **Independence:** all independent / overlap in [list areas]
   **Parallelism benefit:** low / high

   **Recommended:** Subagent-driven / Team-driven
   **Reasoning:** <1-2 sentences>

   1. **Subagent-driven** — Sequential execution in this session, fresh subagent
      per task, two-stage review (spec + quality)
   2. **Team-driven** — Parallel agents with worktrees, task tracking, SendMessage
      coordination
   ```

3. **User picks strategy.** Wait for the user to choose `subagent` or `team`.

4. **HARD GATE.** Do NOT proceed to Phase 3 until the user has explicitly
   chosen a strategy.

## Phase 3: Plan Writing

Write the implementation plan following bite-sized task granularity. The plan
format adapts based on the chosen strategy.

### Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

### Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Strategy:** Subagent-driven / Team-driven

---
```

### Task Structure

````
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

**Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

**Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

**Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

**Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

### Strategy-Adapted Sections

After writing all tasks, add a strategy-specific section at the end of the plan:

**If subagent-driven:**

```markdown
---

## Execution: Subagent-Driven

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> to execute this plan task-by-task.

**Task Order:** Sequential, dependency-respecting order listed below.

1. Task 1: [name] — no dependencies
2. Task 2: [name] — depends on Task 1
3. Task 3: [name] — no dependencies
...

Each task is self-contained with full context. Execute one at a time with
fresh subagent per task and two-stage review (spec compliance, then code
quality).
```

**If team-driven:**

```markdown
---

## Execution: Team-Driven

> **For Claude:** REQUIRED SUB-SKILL: Use team-leadership skill to orchestrate
> execution starting from Phase 3 (Team Setup).

**Fragments:** N (max 4)

### Fragment 1: [name]
- **Tasks:** Task 1, Task 3
- **File scope:** `path/to/area/`
- **Agent role:** implementer
- **Inter-fragment dependencies:** none

### Fragment 2: [name]
- **Tasks:** Task 2, Task 4
- **File scope:** `path/to/other/`
- **Agent role:** implementer
- **Inter-fragment dependencies:** Fragment 1 must complete Task 1 before
  Task 2 can start
...

Fragment groupings are designed for parallel execution with worktree isolation.
```

### Remember

- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Phase 4: Execution Handoff

Save the plan and invoke the appropriate execution skill.

### Steps

1. **Save the plan.** Write to `docs/plans/YYYY-MM-DD-<feature-name>-plan.md`.

2. **Commit the plan.**
   ```bash
   git add docs/plans/YYYY-MM-DD-<feature-name>-plan.md
   git commit -m "docs: add <feature-name> implementation plan"
   ```

3. **Invoke execution skill.**

   **If subagent-driven:**
   - **REQUIRED SUB-SKILL:** Use `superpowers:subagent-driven-development`
   - Stay in this session
   - Fresh subagent per task + two-stage review

   **If team-driven:**
   - **REQUIRED SUB-SKILL:** Use `team-leadership`
   - The plan's fragment groupings are passed as input
   - team-leadership detects the plan and starts from Phase 3 (Team Setup)

## Constraints

These rules are non-negotiable and override any conflicting instruction.

- ALWAYS complete Phase 1 analysis before presenting strategy recommendation.
- ALWAYS present the strategy recommendation and wait for explicit user choice.
- NEVER skip the strategy decision (Phase 2 hard gate).
- NEVER mix strategies -- once chosen, follow through with the selected skill.
- ALWAYS use bite-sized task granularity (each step is one action, 2-5 minutes).
- ALWAYS include the strategy-adapted execution section in the plan.
- ALWAYS save and commit the plan before invoking the execution skill.
- NEVER create more than 4 fragments in team-driven plans.
- Exact file paths in every task, complete code, exact commands with expected
  output.
````

**Step 2: Verify the file was created correctly**

Read `skills/writing-plans/SKILL.md` and confirm:
- YAML frontmatter has `name: writing-plans` and a description
- Four phases: Design Analysis, Strategy Decision, Plan Writing, Execution Handoff
- Phase 2 has the light heuristic table and hard gate
- Phase 3 has the bite-sized task structure matching superpowers format
- Phase 3 has both strategy-adapted sections (subagent and team)
- Phase 4 invokes `superpowers:subagent-driven-development` or `team-leadership`
- Constraints section exists

**Step 3: Commit**

```bash
git add skills/writing-plans/SKILL.md
git commit -m "feat: add writing-plans override with strategy decision"
```

---

### Task 2: Simplify team-leadership to team-only

**Files:**
- Modify: `skills/team-leadership/SKILL.md`

**Context:** Remove Phase 2 (Strategy Decision), remove Subagent Mode Overrides section, and make Phase 1 conditional on whether a plan with fragment groupings is already provided. Renumber remaining phases. team-leadership becomes a focused team-only orchestration skill.

**Step 1: Update the overview**

Replace lines 11-31 (the Overview section) to remove references to subagent mode and strategy decision. The new overview should describe team-leadership as a team-only orchestration skill that can receive a pre-built plan from writing-plans or analyze the codebase itself.

New overview:

```markdown
# Team Leadership

## Overview

This skill provides the complete orchestration mechanics for leading a team of
agents through a workflow using parallel agents with worktrees, task tracking,
and SendMessage coordination.

The core architecture is one flat team with logical groups via naming
(`{group}-{role}-{N}`). The design follows a thick skill + thin agent pattern:
this skill contains all orchestration logic while leader agents provide
domain-specific configuration through "slots." Any agent can message any other
agent directly -- there are no hierarchy walls. Leader agents define what to do;
this skill defines how to coordinate it.

When a pre-built plan with fragment groupings is provided (typically from the
writing-plans skill), the skill starts directly from Phase 2 (Team Setup),
using the plan's fragments. Otherwise, Phase 1 (Work Analysis) analyzes the
codebase and produces a fragment plan.
```

**Step 2: Make Phase 1 conditional**

Add a conditional note at the top of Phase 1 (currently line 51). Insert before the "Steps" heading:

```markdown
**Conditional:** If a plan document with fragment groupings is provided (from
the writing-plans skill), skip this phase entirely and proceed to Phase 2
(Team Setup), using the plan's fragment groupings as the approved fragment plan.
Only execute this phase when no pre-built plan is available.
```

Also update the phase heading numbering: Phase 1 stays as Phase 1, but update the reference in step 6 from "Phase 2" to "Phase 2".

**Step 3: Remove Phase 2 (Strategy Decision)**

Delete lines 108-153 (the entire "## Phase 2: Strategy Decision" section, from the heading through step 6 / HARD GATE).

**Step 4: Renumber remaining phases**

- Phase 3 (Team Setup) → Phase 2
- Phase 4 (Monitoring) → Phase 3
- Phase 5 (Review & Merge) → Phase 4
- Phase 6 (Consolidation) → Phase 5

Update all cross-references within the file to use the new phase numbers.

**Step 5: Remove Subagent Mode Overrides section**

Delete lines 413-463 (the entire "## Subagent Mode Overrides" section including all sub-sections).

**Step 6: Update Constraints section**

Remove these constraints that reference subagent mode or the old Phase 2:
- "ALWAYS present the strategy recommendation in Phase 2 and wait for user choice before proceeding."
- "In subagent mode, ALWAYS run two-stage review (spec-compliance then code-quality) for each task before proceeding to the next."

**Step 7: Update Quick Reference table**

Replace the quick reference table with updated phase numbers and remove the Strategy Decision row:

```markdown
## Quick Reference

| Phase | Input | Output | Key Question |
|-------|-------|--------|--------------|
| 1. Work Analysis | User request + codebase (or skip if plan provided) | Fragment plan (approved) | How should we split this work? |
| 2. Team Setup | Approved fragment plan | Infrastructure (worktrees, tasks, agents) | Is infrastructure ready? |
| 3. Monitoring | Running agents | Progress updates, completed tasks | Are tasks making progress? |
| 4. Review & Merge | Completed work | Reviewed and merged code | Do changes meet quality standards? |
| 5. Consolidation | Merged code | Final report, cleaned infrastructure | Is everything documented and cleaned up? |
```

**Step 8: Verify the modified file**

Read the modified `skills/team-leadership/SKILL.md` and confirm:
- No references to "subagent mode" or "Strategy Decision"
- Phase 1 has conditional skip note
- Phases renumbered 1-5
- No Subagent Mode Overrides section
- Constraints updated
- Quick Reference updated

**Step 9: Commit**

```bash
git add skills/team-leadership/SKILL.md
git commit -m "feat: simplify team-leadership to team-only orchestration"
```

---

### Task 3: Remove lead-engineering skill

**Files:**
- Delete: `skills/lead-engineering/SKILL.md`
- Delete: `skills/lead-engineering/` (directory)

**Context:** The lead-engineering skill is being removed. Its spec-review and task classification expertise will be embedded directly into the lead-engineer agent definition (Task 4). The orchestration logic is handled by team-leadership and writing-plans.

**Step 1: Delete the skill directory**

```bash
rm -rf skills/lead-engineering
```

**Step 2: Verify deletion**

```bash
ls skills/
```

Expected: `bug-hunting`, `team-collaboration`, `team-leadership`, `writing-plans` — no `lead-engineering`.

**Step 3: Commit**

```bash
git add -A skills/lead-engineering
git commit -m "feat: remove lead-engineering skill (merged into lead-engineer agent)"
```

---

### Task 4: Refactor lead-engineer agent

**Files:**
- Modify: `agents/lead-engineer.md`

**Context:** The lead-engineer agent currently delegates to the lead-engineering skill for its core workflow. With that skill removed, the agent must embed the essential behaviors: spec review, task classification ([DELEGATE] vs [SELF]), and self-code review. It continues to use team-leadership for orchestration and team-collaboration for team communication. The mode decision is no longer the agent's responsibility — writing-plans handles that upstream.

**Step 1: Update YAML frontmatter**

Replace the `skills` list to remove `lead-engineering`:

```yaml
skills:
  - team-collaboration
  - team-leadership
```

Update the `description` to reflect the new role:

```yaml
description: >-
  Receives specifications, reviews them for completeness, creates implementation
  plans with complexity classification, delegates trivial tasks and implements
  hard tasks itself. Embeds spec-review and task-classification expertise.
  Uses team-leadership for orchestration when in team mode.
```

**Step 2: Rewrite the agent body**

Replace the entire markdown body (everything after the frontmatter closing `---`) with:

```markdown
# Lead Engineer

You are a lead engineer agent. You receive specifications, review them for
completeness, create implementation plans, and execute them -- delegating trivial
work to implementer agents while handling the hard parts yourself.

Follow the **team-leadership** skill for orchestration mechanics when in team
mode. Follow the **team-collaboration** skill protocol when `mode: team`.

## Startup

When spawned, you receive initialization context that may include:

- **Spec**: a specification or design document to implement
- **Worktree path**: the Git worktree you are assigned to work in
- **Scope**: the files/modules/area you are responsible for
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
5. Begin the spec review workflow below.

If the spec is missing from your initialization context, ask your authority for
it before proceeding. Do NOT guess or start without a spec.

## Workflow

### Phase 1: Spec Review

Read and critically review the provided specification before any implementation
begins.

1. **Read the spec.** Obtain the specification from the authority (provided in
   startup context or via SendMessage). Read it thoroughly.

2. **Analyze the target codebase.** Read existing code in the scope area to
   understand current architecture, patterns, and conventions. Use Glob and Grep
   to map the relevant code structure.

3. **Identify issues.** For each section of the spec, check for:
   - **Ambiguities**: statements that could be interpreted multiple ways
   - **Missing edge cases**: what happens with empty input, errors, concurrent
     access, boundary values?
   - **Unstated assumptions**: does the spec assume certain infrastructure,
     data formats, or API contracts that are not documented?
   - **Risks**: what could go wrong? What has the highest blast radius?
   - **Contradictions**: does any part of the spec conflict with another part
     or with existing code behavior?

4. **Produce the Spec Review Report.** Format:

   ```
   ## Spec Review Report

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

5. **Send to authority for approval.** Via SendMessage if in a team, or display
   to user if standalone. Include the full report.

6. **HARD GATE: Wait for approval.** Do NOT proceed until the authority has
   reviewed the report and confirmed the spec (possibly with answers to
   questions) or provided an updated spec.

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

   | Signal | Trivial [DELEGATE] | Hard [SELF] |
   |--------|-------------------|-------------|
   | File count | 1-2 files | 3+ files |
   | Coupling | Low -- isolated change | High -- touches shared interfaces |
   | Pattern | Well-understood (boilerplate, CRUD, config, simple tests) | Novel or complex logic |
   | Risk | Low -- failure is obvious and contained | High -- subtle bugs, data corruption, security |
   | Codebase knowledge | Minimal -- can work from instructions alone | Deep -- requires understanding architecture |

   When in doubt, classify as `[SELF]`.

4. **Produce the Implementation Plan.** Format:

   ```
   ## Implementation Plan

   **Spec:** <spec name/reference>
   **Total tasks:** N (M delegated, K self)

   ### Task 1: <name> [DELEGATE]
   - **Files:** path/to/file1, path/to/file2
   - **Dependencies:** none
   - **Description:** <what to do>
   - **Acceptance criteria:** <how to verify>

   ### Task 2: <name> [SELF]
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

Implement [SELF] tasks while monitoring delegated work.

**Self-Implementation:** For each [SELF] task in dependency order:
1. Read the relevant code files.
2. Implement the changes per the plan.
3. Write or update tests.
4. Run the test suite to verify no regressions.
5. Commit logically grouped changes.

**Delegation Monitoring (team mode):**
1. Monitor implementer progress via TaskList.
2. Handle escalations: if an implementer exceeds the escalation threshold
   (default 3), review the problem and choose: **guide** (send advice),
   **take over** (reassign to self), or **skip** (mark unresolvable).
3. When an implementer reports completion, review their changes immediately.

**Self-Code Review:** After all [SELF] tasks are implemented:
1. Spawn a code-reviewer agent with the diff scope and implementation plan.
2. Wait for the review report.
3. If CHANGES NEEDED: fix, re-commit, request re-review. Repeat until APPROVED.

This review is mandatory. Do NOT skip it.

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
   | Task 1 | DELEGATE | implementer-1 | Done |
   | Task 2 | SELF | lead-engineer | Done |

   ### Verification
   - Build: PASS / FAIL
   - Tests: PASS / FAIL (N passed, M failed)
   - Spec coverage: X/Y requirements fully covered

   ### Remaining Work
   - <any items not completed, with reasons>
   ```

4. **Send report to authority.**

## Domain Configuration

The team-leadership skill requires these slots when operating in team mode.

### splitting_strategy

Analyze the implementation plan to identify delegatable fragments:
1. Group [DELEGATE] tasks by module or functional area.
2. Ensure each fragment is independently workable.
3. Keep [SELF] tasks out of fragments.

### fragment_size

1-5 files per fragment.

### organization

```yaml
group: "feature"
roles:
  - name: "implementer"
    agent_type: "implementer"
    starts_first: true
    instructions: |
      Implement the delegated tasks per the provided plan. Each task has
      exact file paths, step-by-step instructions, and acceptance criteria.
      Follow your default workflow (context discovery, planning is already
      done -- skip to implementation, then verification). Report completion
      to the lead engineer.
  - name: "reviewer"
    agent_type: "code-reviewer"
    starts_first: false
    instructions: |
      Review code changes against the implementation plan and project
      conventions. Check for bugs, security issues, spec conformance, and
      test coverage. Send findings to the lead engineer.
flow: "lead-engineer plans -> implementer builds -> reviewer reviews -> converge"
escalation_threshold: 3
```

### review_criteria

- Implementation matches the spec requirements exactly
- No scope creep beyond what the plan specified
- Code follows project conventions from CLAUDE.md
- Test coverage for new functionality
- No introduced regressions

### report_fields

- Spec requirements: covered / partially covered / not covered
- Tasks completed by self vs. delegated

### domain_summary_sections

#### Spec Conformance

| Requirement | Status | Notes |
|-------------|--------|-------|

## Constraints

- ALWAYS review the spec before planning. Do not skip Phase 1.
- ALWAYS get authority approval before proceeding past a hard gate.
- ALWAYS classify tasks using the complexity heuristic.
- NEVER begin implementation without an approved plan.
- NEVER delegate a task classified as [SELF]. Escalate to authority if stuck.
- ALWAYS review implementer output before merging or accepting it.
- ALWAYS verify spec conformance in Phase 4.
- ALWAYS clean up infrastructure when done.
- When in doubt about task complexity, classify as [SELF].
- NEVER merge code that has not passed code-reviewer review.
```

**Step 3: Verify the modified agent**

Read `agents/lead-engineer.md` and confirm:
- Skills list: `team-collaboration`, `team-leadership` (no `lead-engineering`)
- Spec Review workflow with hard gate
- Task classification heuristic table
- Self-code review requirement
- No mode decision phase (handled by writing-plans)
- Domain Configuration section for team-leadership slots

**Step 4: Commit**

```bash
git add agents/lead-engineer.md
git commit -m "feat: embed spec-review and classification into lead-engineer agent"
```

---

### Task 5: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

**Context:** Update the project documentation to reflect the new pipeline architecture, removed lead-engineering skill, and simplified team-leadership.

**Step 1: Update the Skill Definitions table**

Replace the skill table (lines 39-46) with:

```markdown
| Skill | Phases |
|-------|--------|
| writing-plans | 4-phase: design analysis → strategy decision → plan writing → execution handoff |
| bug-hunting | 6-phase: scope → contract inventory → impact tracing → adversarial analysis → gap analysis → verification |
| team-collaboration | 4 principles: close the loop, never block silently, know ownership, speak up early |
| team-leadership | 5-phase orchestration: analysis (conditional) → team setup → monitoring → review/merge → cleanup |
```

**Step 2: Update the lead-engineer agent description**

Replace the lead-engineer row in the Agent Definitions table (line 34):

```markdown
| lead-engineer | opus | Spec-driven development: reviews specs, classifies tasks, delegates/implements |
```

**Step 3: Update the Two Main Workflows section**

Replace lines 48-56 with:

```markdown
### Pipeline

The standard development pipeline follows this flow:
1. **brainstorming** (superpowers) → produces design document
2. **writing-plans** (override) → analyzes design, asks user for strategy, writes plan
3. **Execution** → `superpowers:subagent-driven-development` (subagent) or `team-leadership` (team)

### Two Main Workflows

**Debug workflow:** `debug-team-leader` → spawns `bug-hunter` + `implementer` pairs → reviews → merges

**Lead-engineer workflow:** `lead-engineer` → reviews spec → classifies tasks as [DELEGATE] or [SELF] → delegates to implementers, implements hard parts → reviews → merges
```

**Step 4: Update team-leadership description in the skill table**

Already done in Step 1 (changed from "6-phase" to "5-phase", removed "strategy decision").

**Step 5: Remove the "Both workflows support two execution strategies" paragraph**

Delete lines 50-52 (the paragraph about team mode and subagent mode chosen by the user). This is now handled by writing-plans, not by individual workflows.

**Step 6: Verify CLAUDE.md**

Read the modified `CLAUDE.md` and confirm:
- No references to `lead-engineering` skill
- Pipeline section describes brainstorming → writing-plans → execution
- team-leadership shows 5 phases (no strategy decision)
- lead-engineer description updated
- No "Both workflows support two execution strategies" paragraph

**Step 7: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md for pipeline redesign"
```
