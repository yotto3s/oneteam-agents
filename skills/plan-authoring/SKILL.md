---
name: plan-authoring
description: >-
  Use when writing implementation plans as the architect agent. Defines
  bite-sized task granularity, plan document structure, strategy-adapted
  execution sections, and quality constraints.
---

# Plan Authoring

## Overview

Plan-writing methodology for the [oneteam:agent] `architect` agent. Defines task
granularity, document structure, and strategy-adapted execution sections.

## When to Use

- Dispatched as [oneteam:agent] `architect` agent to write an implementation plan.
- Received design doc, analysis blob, and chosen strategy.

## When NOT to Use

- For the orchestration of plan creation -- use [oneteam:skill] `writing-plans`.
- For executing a plan -- use [superpowers:skill] `subagent-driven-development`
  or [oneteam:skill] `team-management`.

## Quick Reference

| Phase | Key Action | Output |
|-------|-----------|--------|
| 1. Codebase Reading | Read design doc, review analysis, read source files | Refined tier classifications |
| 2. Plan Writing | Write header, tasks (bite-sized), execution section | Complete plan document |

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
files that each task will touch. Use the analysis blob's task sketch and scope
areas as starting points.

1. **Read the design document** fully.
2. **Review the analysis blob** -- task sketch, scope areas, dependencies,
   complexity classifications.
3. **Read relevant source files** for each task scope area: existing patterns,
   imports, function signatures, test patterns, config/build files.
4. **Classify agent tiers** using the JUNIOR/SENIOR heuristic in
   [oneteam:agent] `lead-engineer` (Phase 2, step 3). When in doubt, classify
   as [oneteam:agent] `senior-engineer`.

## Phase 2: Plan Writing

Write the implementation plan. Assume the engineer has zero codebase context.
Document everything: files to touch, code, tests, commands. DRY. YAGNI. TDD.
Frequent commits. Follow [oneteam:skill] `declarative-programming`: code examples
in plans MUST model decomposed functions — show named functions for each
meaningful procedure, not monolithic blocks.

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

### Task and Execution Section Templates

Use the full templates in `./task-template.md` for:
- **Task Structure** -- the `### Task N: [Component Name]` block with all steps
  including the review checkpoint (team-driven only).
- **Subagent-Driven execution section** -- task order and subagent instructions.
- **Team-Driven execution section** -- fragment groupings, team composition,
  and post-completion review tables.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Writing the plan without reading the codebase first | Phase 1 before Phase 2 -- always |
| Steps that combine multiple actions | Each step is one action (2-5 minutes) |
| Missing file paths or commands | Exact file paths, complete code, exact commands in every task |
| Writing files to disk | Return plan as output -- orchestrator saves it |

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
- ALWAYS follow [oneteam:skill] `declarative-programming` in plan code examples: decompose into named functions, not inline blocks with comment headers.
