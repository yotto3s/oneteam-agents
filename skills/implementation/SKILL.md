---
name: implementation
description: >-
  Shared workflow phases and best practices for implementation agents
  ([oneteam:agent] junior-engineer, [oneteam:agent] senior-engineer). Provides startup protocol, context
  discovery, common best practices, verification, and reporting. Agents
  layer tier-specific behavior on top.
---

# Implementation

This skill provides shared workflow phases for implementation agents. Agents use it via their `skills` list. It covers startup, context discovery, common best practices, verification, and reporting. Tier-specific behavior (planning, best practices) lives in each agent file.

## Startup Protocol

When spawned, the agent receives initialization context that may include:
- **Worktree path**: the Git worktree assigned to work in
- **Scope**: the files/modules/area responsible for
- **Skill directive**: (optional) which skill to follow (e.g., [superpowers:skill] `systematic-debugging`)
- **Plan**: (optional) a pre-written implementation plan to follow
- **Leader name**: the agent or user who spawned you
- **Teammates**: other agents to coordinate with

Execute these steps immediately on startup:
1. Read `CLAUDE.md` at the worktree root (if it exists) to learn build commands, test commands, and project conventions.
2. Verify you can access the worktree by listing its root contents.
3. Check your initialization context for `mode: team` or `mode: subagent` (default: subagent). If `mode: team`, apply the [oneteam:skill] `team-collaboration` skill protocol for all communication throughout your workflow.

If any of the following are missing from your initialization context, ask your leader (or the user if standalone) before proceeding:
- **Scope** — what files/modules/area to work on
- **Task description** — what to do (fix a bug, add a feature, etc.)

## Phase 1: Context Discovery

1. Read `CLAUDE.md` and `README.md` (if they exist) for project conventions.
2. Scan the scope area to understand the relevant code.
3. Identify the test framework, build system, and test commands.
4. If scope or task is unclear, ask for clarification. Do NOT guess.

## Common Best Practices

These practices apply to all implementation work, regardless of task complexity.

1. **Read before you write** — understand existing code, conventions, and the "why" behind current patterns before changing anything.
2. **Stay in scope** — change only what the task requires; don't refactor, improve, or clean up surrounding code.
3. **Atomic commits** — each commit is one logical change, leaves the codebase in a working state, uses semantic prefixes (`feat:`, `fix:`, `docs:`).
4. **Test after each change** — run the project's test suite after every meaningful change, not just at the end.
5. **Self-review before reporting** — review your own diff before claiming completion; verify the change matches intent.
6. **Clean up artifacts** — remove debug statements, commented-out code, and unnecessary imports before completion.

Communication practices (never block silently, close the loop, speak up early) are handled by the [oneteam:skill] `team-collaboration` skill — not duplicated here.

## Skill Override

If the agent receives a skill directive (e.g., "use the [superpowers:skill] `systematic-debugging` skill"), follow that skill's process for the core work. Phase 1 (Context Discovery) and Phase 2 (Verification) still apply — run them before and after the skill's process.

Example flow with a skill directive:
1. Phase 1: Context Discovery (always)
2. Skill's own process (replaces planning + implementation)
3. Phase 2: Verification (always)

## Phase 2: Verification

1. Run the project's test suite using commands from Phase 1.
2. Confirm all tests pass (or that failures are pre-existing, not caused by your changes).
3. Verify your changes match the approved plan — no missing items, no extras.
4. Produce a completion report:

```
## Implementation Report

**Task:** <what was done>
**Changes:**
- <file>: <what changed>

**Verification:**
- Build: PASS / FAIL
- Tests: PASS / FAIL (details if fail)
- Plan coverage: all items completed / <list missing items>
```

## Reporting

After completing work (whether via skill or default workflow), produce a summary for the leader or user. In team mode, also notify relevant teammates (e.g., a paired [oneteam:agent] `bug-hunter` who needs to verify).

## Constraints

- **ALWAYS** run Phase 1 (Context Discovery), even when using a skill directive.
- **ALWAYS** run Phase 2 (Verification) after completing work.
- **NEVER** work outside your assigned scope without asking first.
- In team mode, communicate via SendMessage per the [oneteam:skill] `team-collaboration` skill. Do not write status to files expecting others to read them.
- **ASK** if context is missing. Do not guess scope, task, or approach.
