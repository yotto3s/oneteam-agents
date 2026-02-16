---
name: writing-plans
description: >-
  Use when you have a spec or requirements for a multi-step task, before touching
  code. Dispatches an analyzer sub-agent for design triage, presents strategy
  recommendation to user, then dispatches the [oneteam:agent] architect agent to write the plan.
  Saves the plan and hands off to the chosen execution skill.
---

# Writing Plans

## Overview

This skill overrides the [superpowers:skill] `writing-plans` skill. It orchestrates
plan creation by dispatching sub-agents for the heavy work, keeping the main
session lean.

The main session acts as a thin orchestrator:
1. Dispatches an analyzer sub-agent for design triage (Phase 1)
2. Presents strategy recommendation and waits for user choice (Phase 2)
3. Dispatches the [oneteam:agent] `architect` agent to write the full plan (Phase 3)
4. Saves the plan and invokes the execution skill (Phase 4)

The main session does NOT read the design document, analyze the codebase, or
write any part of the plan itself.

**Announce at start:** "I'm using the [oneteam:skill] `writing-plans` skill to create the
implementation plan."

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>-plan.md`

## Phase 1: Design Analysis (Analyzer Sub-Agent)

Dispatch a lightweight sub-agent to read the design document and triage the
work. No user interaction in this phase.

### Steps

1. **Locate the design document.** Find the design doc in `docs/plans/` or
   from the user's context. Note the path — do NOT read the file yourself.

2. **Dispatch the analyzer sub-agent.** Use the prompt template in
   `./analyzer-prompt.md`. Fill in the placeholders:
   - `[PATH]` — path to the design document
   - `[ROOT]` — codebase root directory

   Dispatch via Task tool:
   - `subagent_type: general-purpose`
   - `model: sonnet`
   - `description: "Analyze design for planning"`

3. **Receive the analysis blob.** The analyzer returns a structured markdown
   blob with: task count, independence level, parallelism benefit, strategy
   recommendation, and a lightweight task sketch.

4. **Record the analysis blob.** Keep it for use in Phases 2 and 3.

## Phase 2: Strategy Decision

Present the analysis and strategy recommendation to the user. The user
makes the final choice.

### Steps

1. **Present strategy recommendation.** Display to the user using the data
   from the analysis blob:
   ```
   ## Strategy Recommendation

   **Tasks:** N
   **Independence:** all independent / overlap in [list areas]
   **Parallelism benefit:** low / high

   **Recommended:** Subagent-driven / Team-driven
   **Reasoning:** <from analysis blob>

   1. **Subagent-driven** — Sequential execution in this session, fresh subagent
      per task, two-stage review (spec + quality)
   2. **Team-driven** — Parallel agents with worktrees, task tracking, SendMessage
      coordination
   ```

2. **User picks strategy.** Wait for the user to choose `subagent` or `team`.

3. **HARD GATE.** Do NOT proceed to Phase 3 until the user has explicitly
   chosen a strategy.

## Phase 3: Plan Writing (Architect Agent)

Dispatch the [oneteam:agent] `architect` agent to write the full implementation plan.

### Steps

1. **Dispatch the [oneteam:agent] `architect` agent.** Use the prompt template in
   `./architect-prompt.md`. Fill in the placeholders:
   - `[FEATURE]` — feature name
   - `[PATH]` — path to the design document
   - `[STRATEGY]` — chosen strategy (`subagent` or `team`)
   - `[ANALYSIS_BLOB]` — the full analysis blob from Phase 1

   Dispatch via Task tool:
   - `subagent_type: [oneteam:agent] architect`
   - `description: "Write implementation plan for [feature name]"`

2. **Receive the plan.** The [oneteam:agent] `architect` returns the complete plan document as
   a markdown string.

3. **Review the plan.** Skim the returned plan to verify it has:
   - Plan header (goal, architecture, tech stack, strategy)
   - Numbered tasks with bite-sized steps
   - Strategy-adapted execution section at the end
   If anything is missing, note it but do NOT rewrite the plan — dispatch the
   [oneteam:agent] `architect` again with specific feedback if needed.

## Phase 4: Execution Handoff

Save the plan and invoke the appropriate execution skill.

### Steps

1. **Save the plan.** Write the [oneteam:agent] `architect`'s output to
   `docs/plans/YYYY-MM-DD-<feature-name>-plan.md`.
   Do NOT commit the plan file to git.

2. **Invoke execution skill.**

   **If subagent-driven:**
   - **REQUIRED SUB-SKILL:** Use [superpowers:skill] `subagent-driven-development`
   - Stay in this session
   - Fresh subagent per task + two-stage review

   **If team-driven:**
   - **REQUIRED SUB-SKILL:** Use [oneteam:skill] `team-management`
   - The plan's fragment groupings are passed as input
   - [oneteam:skill] `team-management` detects the plan and starts from Phase 2 (Team Setup)

## Constraints

These rules are non-negotiable and override any conflicting instruction.

- NEVER read the design document yourself. The analyzer and [oneteam:agent] `architect` do this.
- NEVER analyze the codebase yourself. The analyzer and [oneteam:agent] `architect` do this.
- NEVER write plan content yourself. The [oneteam:agent] `architect` does this.
- ALWAYS present the strategy recommendation and wait for explicit user choice.
- NEVER skip the strategy decision (Phase 2 hard gate).
- NEVER mix strategies — once chosen, follow through with the selected skill.
- If the [oneteam:agent] `architect`'s output is incomplete, dispatch it again with feedback.
  Do NOT patch the plan yourself.
