---
name: plan-authoring
description: >-
  Plan-writing methodology for the [oneteam:agent] architect agent. Defines bite-sized task
  granularity, plan document structure, strategy-adapted execution sections,
  and quality constraints for implementation plans.
---

# Plan Authoring

## Overview

This skill defines how to write implementation plans. It is used by the
[oneteam:agent] `architect` agent, which receives a design document, an analysis blob, and a
chosen execution strategy from the [oneteam:skill] `writing-plans` orchestrator.

Write comprehensive implementation plans assuming the engineer has zero context
for the codebase and questionable taste. Document everything they need to know:
which files to touch for each task, code, testing, docs they might need to
check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI.
TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about the toolset
or problem domain. Assume they don't know good test design very well.

## Inputs

The [oneteam:agent] `architect` agent provides these when invoking this skill:

- **Design document** — full text (read from provided path)
- **Analysis blob** — structured summary from the analyzer sub-agent, containing
  task sketch, independence level, and strategy recommendation
- **Chosen strategy** — `subagent` or `team` (decided by user in orchestrator)

If any input is missing, return immediately with an error describing what is
needed. Do not proceed without all three inputs.

## Phase 1: Codebase Reading

Read the codebase to understand existing patterns, conventions, and the specific
files that each task will touch. The analysis blob provides a rough task sketch
with scope areas — use those as starting points for targeted reading.

### Steps

1. **Read the design document.** Provided path — read it fully.

2. **Review the analysis blob.** Understand the task sketch, scope areas,
   dependencies, and complexity classifications.

3. **Read relevant source files.** For each task in the sketch, read the files
   in its scope area. Focus on:
   - Existing patterns and conventions to follow
   - Import structures and function signatures
   - Test patterns (if the project has tests)
   - Configuration and build files relevant to the changes

4. **Classify agent tiers.** Refine the analyzer's rough complexity
   classifications using this heuristic:

   | Signal | [oneteam:agent] junior-engineer | [oneteam:agent] senior-engineer |
   |--------|----------------|-----------------|
   | File count | 1-2 files | 3+ files |
   | Coupling | Low — isolated change | High — touches shared interfaces |
   | Pattern | Well-understood (boilerplate, CRUD, config) | Novel or complex logic |
   | Risk | Low — failure is obvious and contained | High — subtle bugs, data corruption, security |
   | Codebase knowledge | Minimal — can work from instructions alone | Deep — requires understanding architecture |

   When in doubt, classify as [oneteam:agent] `senior-engineer`.

## Phase 2: Plan Writing

Write the implementation plan following bite-sized task granularity.

### Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

### Plan Document Header

**Every plan MUST start with this header:**

~~~markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Strategy:** Subagent-driven / Team-driven

---
~~~

### Task Structure

````
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `exact/path/to/test.py`

**Agent role:** [oneteam:agent] junior-engineer / [oneteam:agent] senior-engineer
**Model:** (optional) haiku — only when a [oneteam:agent] junior-engineer task is truly trivial

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

After writing all tasks, add a strategy-specific section at the end of the
plan:

**If subagent-driven:**

~~~markdown
---

## Execution: Subagent-Driven

> **For Claude:** REQUIRED SUB-SKILL: Use [superpowers:skill] `subagent-driven-development`
> to execute this plan task-by-task.

**Task Order:** Sequential, dependency-respecting order listed below.

1. Task 1: [name] — no dependencies
2. Task 2: [name] — depends on Task 1
3. Task 3: [name] — no dependencies
...

Each task is self-contained with full context. Execute one at a time with
fresh subagent per task and two-stage review (spec compliance, then code
quality).
~~~

**If team-driven:**

~~~markdown
---

## Execution: Team-Driven

> **For Claude:** REQUIRED SUB-SKILL: Use [oneteam:skill] `team-management` skill to orchestrate
> execution starting from Phase 2 (Team Setup).

**Fragments:** N (max 4)

### Fragment 1: [name]
- **Tasks:** Task 1, Task 3
- **File scope:** `path/to/area/`
- **Agent role:** [oneteam:agent] junior-engineer / [oneteam:agent] senior-engineer
- **Model:** (optional) haiku — for truly trivial junior tasks
- **Inter-fragment dependencies:** none

### Fragment 2: [name]
- **Tasks:** Task 2, Task 4
- **File scope:** `path/to/other/`
- **Agent role:** [oneteam:agent] junior-engineer / [oneteam:agent] senior-engineer
- **Model:** (optional) haiku — for truly trivial junior tasks
- **Inter-fragment dependencies:** Fragment 1 must complete Task 1 before
  Task 2 can start
...

Fragment groupings are designed for parallel execution with worktree isolation.
~~~

### Remember

- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Output

Return the complete plan document as a markdown string. Do NOT write the file
yourself — the orchestrator saves it.

## Constraints

- ALWAYS read the codebase before writing the plan (Phase 1 before Phase 2).
- ALWAYS use bite-sized task granularity (each step is one action, 2-5 minutes).
- ALWAYS include the strategy-adapted execution section.
- NEVER create more than 4 fragments in team-driven plans.
- NEVER write files or commit. You are read-only. Return the plan as output.
- Exact file paths in every task, complete code, exact commands with expected
  output.
