# Task and Execution Section Templates

Reference templates for the [oneteam:skill] `plan-authoring` skill. Copy and
adapt these when writing implementation plans.

## Task Structure

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

**Step 6: Review checkpoint** *(team-driven only -- omit for subagent-driven plans)*

**Review Checkpoint:**

| Check | Criteria | Pass/Fail |
|-------|----------|-----------|
| Acceptance criteria met | [from task definition] | |
| Tests pass | Run: `<test command>` | |
| No regressions | Full suite green | |

Reviewer: `<reviewer from Team Composition>` (e.g., `{group}-reviewer-1`) reviews diff for this task.
Action on CHANGES NEEDED: fix the issues, then re-review before starting the next task.
````

## Execution Section: Subagent-Driven

Add this section after all tasks when strategy is `subagent`:

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

## Execution Section: Team-Driven

Add this section after all tasks when strategy is `team`:

~~~markdown
---

## Execution: Team-Driven

> **For Claude:** REQUIRED SUB-SKILL: Use [oneteam:skill] `team-management` skill to orchestrate
> execution starting from Phase 2 (Team Setup).

**Fragments:** N (max 4)

### Team Composition

| Name | Type | Scope |
|------|------|-------|
| {group}-reviewer-1 | code-reviewer | All fragments |
| {group}-junior-engineer-1 | junior-engineer | Fragment 1, Tasks ... |
| {group}-senior-engineer-1 | senior-engineer | Fragment 1, Tasks ... |
| ... | ... | ... |

Names use the `{group}-{role}-{N}` convention from the `team-management` skill.
These names are used as agent names when spawning and as `SendMessage` recipients.

**Reviewer count:** 1 per lead group.
**Engineers:** 1 per fragment, junior or senior per task classification.

### Fragment 1: [name]
- **Tasks:** Task 1, Task 3
- **File scope:** `path/to/area/`
- **Agent role:** [oneteam:agent] junior-engineer / [oneteam:agent] senior-engineer
- **Model:** (optional) haiku — for truly trivial junior tasks
- **Inter-fragment dependencies:** none

#### Fragment 1: Post-Completion Review

| Stage | Reviewer | Criteria | Status |
|-------|----------|----------|--------|
| 1. Spec compliance | {group}-reviewer-{G} | All acceptance criteria across fragment tasks met | |
| 2. Code quality | {group}-reviewer-{G} | Conventions, security, test coverage, no regressions | |

Both stages must PASS before fragment is merge-ready.

### Fragment 2: [name]
- **Tasks:** Task 2, Task 4
- **File scope:** `path/to/other/`
- **Agent role:** [oneteam:agent] junior-engineer / [oneteam:agent] senior-engineer
- **Model:** (optional) haiku — for truly trivial junior tasks
- **Inter-fragment dependencies:** Fragment 1 must complete Task 1 before
  Task 2 can start

#### Fragment 2: Post-Completion Review

| Stage | Reviewer | Criteria | Status |
|-------|----------|----------|--------|
| 1. Spec compliance | {group}-reviewer-{G} | All acceptance criteria across fragment tasks met | |
| 2. Code quality | {group}-reviewer-{G} | Conventions, security, test coverage, no regressions | |

Both stages must PASS before fragment is merge-ready.

...

Fragment groupings are designed for parallel execution with worktree isolation.
~~~
