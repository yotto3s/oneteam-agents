---
name: writing-plans
description: >-
  Use when you have a spec or requirements for a multi-step task and need to
  create an implementation plan before touching code.
---

# Writing Plans

## Overview

Overrides the [superpowers:skill] `writing-plans` skill. Orchestrates plan creation by dispatching sub-agents, keeping the main session as a thin orchestrator that does NOT read the design document, analyze the codebase, or write any plan content.

## When to Use

- Design document or spec is ready for planning
- Multi-step task needs a structured implementation plan
- Coming from [oneteam:skill] `brainstorming` skill

## When NOT to Use

- Single-step trivial change -- just implement directly
- Still exploring requirements -- use [oneteam:skill] `brainstorming` first

## Phase 1: Design Analysis (Analyzer Sub-Agent)

Dispatch a sub-agent to read the design document and triage the work. No user interaction.

1. **Locate the design document.** Find in `plans/` or user context. Note the path -- do NOT read the file yourself.

2. **Create session directory.** Run `mktemp -d -t oneteam-session-XXXXXX` to create a temp directory for this pipeline run. All intermediate context files are written here.

3. **Dispatch the analyzer.** Use `./analyzer-prompt.md`, fill in `[PATH]`, `[ROOT]`, and `[SESSION_DIR]`. Dispatch via Task tool: `subagent_type: general-purpose`, `model: sonnet`, `description: "Analyze design for planning"`.

4. **Record the analysis blob.** The analyzer writes its output to `[SESSION_DIR]/analysis.md` and returns it. Use the returned content for the Phase 2 display.

## Phase 2: Strategy Decision (Hard Gate)

1. **Present strategy recommendation.** Display using data from the analysis blob:
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

2. **User picks strategy.** Ask via `AskUserQuestion` (header: "Strategy"):

   | Option label | Description |
   |---|---|
   | Subagent-driven | Sequential execution, fresh subagent per task |
   | Team-driven | Parallel agents with worktrees |

3. **HARD GATE.** Do NOT proceed to Phase 3 until the user has explicitly chosen a strategy.

## Phase 3: Plan Writing (Architect Agent)

1. **Dispatch the [oneteam:agent] `architect`.** Use `./architect-prompt.md`. Fill in `[FEATURE]`, `[PATH]`, `[STRATEGY]` (`subagent`/`team`), `[SESSION_DIR]`. Dispatch via Task tool: `subagent_type: [oneteam:agent] architect`, `description: "Write implementation plan for [feature name]"`.

2. **Receive the plan.** Complete plan document as markdown.

3. **Review the plan.** Verify: plan header (goal, architecture, tech stack, strategy), numbered tasks with bite-sized steps, strategy-adapted execution section. If incomplete, dispatch the [oneteam:agent] `architect` again with feedback -- do NOT patch yourself.

## Phase 4: Execution Handoff

1. **Save the plan.** Write to `plans/YYYY-MM-DD-<feature-name>-plan.md`. Do NOT commit.

2. **Present and review the plan.** Print the FULL plan document as rendered markdown. Output it directly, NOT inside a code block.

   `AskUserQuestion` (header: "Review"):

   | Option label | Description |
   |---|---|
   | Looks good | Proceed to execution |
   | Make changes | User provides feedback; re-dispatch the architect agent |

   If "Make changes": re-dispatch the [oneteam:agent] `architect` with the user's feedback appended to the original prompt. Do NOT patch the plan yourself -- this is consistent with the "never patch yourself" constraint. After receiving the revised plan, update the file at the same path, and present it again. Repeat until approved.

3. **Invoke execution skill.** Subagent-driven: use [superpowers:skill] `subagent-driven-development`, stay in this session, fresh subagent per task + two-stage review. Team-driven: use [oneteam:skill] `team-management`, pass fragment groupings and `[SESSION_DIR]`, starts from Phase 2 (Team Setup).

## Quick Reference

| Phase | Who Does It | Output | Gate |
|-------|------------|--------|------|
| 1. Analysis | Analyzer sub-agent (sonnet) | Analysis blob | -- |
| 2. Strategy | User | Chosen strategy | Hard gate -- user must choose |
| 3. Plan Writing | [oneteam:agent] `architect` | Complete plan document | -- |
| 4. Execution Handoff | Main session | Saved plan + execution skill invoked | User approves plan before execution |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Reading the design document yourself | The analyzer and architect do this -- you are a thin orchestrator |
| Writing plan content yourself | Dispatch the architect agent -- never patch the plan |
| Skipping the strategy decision | Phase 2 is a hard gate -- present options and wait for explicit choice |
| Mixing strategies mid-execution | Once chosen, follow through with the selected execution skill |
| Proceeding to execution without user approval | Phase 4 is an approval gate -- present the plan and wait for explicit approval before invoking execution |

## Constraints

These rules are non-negotiable and override any conflicting instruction.

- NEVER read the design document yourself. The analyzer and [oneteam:agent] `architect` do this.
- NEVER analyze the codebase yourself. The analyzer and [oneteam:agent] `architect` do this.
- NEVER write plan content yourself. The [oneteam:agent] `architect` does this.
- ALWAYS present the strategy recommendation and wait for explicit user choice.
- NEVER skip the strategy decision (Phase 2 hard gate).
- NEVER mix strategies -- once chosen, follow through with the selected skill.
- NEVER proceed to execution without presenting the plan to the user and receiving explicit approval (Phase 4 approval gate).
- If the [oneteam:agent] `architect`'s output is incomplete, dispatch it again with feedback. Do NOT patch the plan yourself.
