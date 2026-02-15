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
   - Agent tier classification per task using this heuristic:

     | Signal | junior-engineer | senior-engineer |
     |--------|----------------|-----------------|
     | File count | 1-2 files | 3+ files |
     | Coupling | Low — isolated change | High — touches shared interfaces |
     | Pattern | Well-understood (boilerplate, CRUD, config) | Novel or complex logic |
     | Risk | Low — failure is obvious and contained | High — subtle bugs, data corruption, security |
     | Codebase knowledge | Minimal — can work from instructions alone | Deep — requires understanding architecture |

     When in doubt, classify as `senior-engineer`.

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
- Test: `exact/path/to/test.py`

**Agent role:** junior-engineer / senior-engineer
**Model:** (optional) haiku — only when a junior-engineer task is truly trivial

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
> execution starting from Phase 2 (Team Setup).

**Fragments:** N (max 4)

### Fragment 1: [name]
- **Tasks:** Task 1, Task 3
- **File scope:** `path/to/area/`
- **Agent role:** junior-engineer / senior-engineer
- **Model:** (optional) haiku — for truly trivial junior tasks
- **Inter-fragment dependencies:** none

### Fragment 2: [name]
- **Tasks:** Task 2, Task 4
- **File scope:** `path/to/other/`
- **Agent role:** junior-engineer / senior-engineer
- **Model:** (optional) haiku — for truly trivial junior tasks
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
   - team-leadership detects the plan and starts from Phase 2 (Team Setup)

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
