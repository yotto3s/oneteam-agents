---
name: implementation
description: >-
  Use when implementing tasks as a junior-engineer or senior-engineer agent. Provides shared startup protocol, context discovery, best practices, verification, and reporting that agents layer tier-specific behavior on top of.
---

# Implementation

## Overview

Shared workflow phases for implementation agents (junior-engineer, senior-engineer). Covers startup, context discovery, best practices, verification, and reporting. Tier-specific behavior lives in each agent file.

## When to Use

- Spawned as implementation agent (junior or senior engineer)
- Received a task to implement (feature, fix, config change)
- Need shared startup/verification workflow

## When NOT to Use

- For orchestration work -- use [oneteam:skill] `team-management`
- For bug finding without fixing -- use [oneteam:skill] `bug-hunting`
- For research/read-only work -- use [oneteam:skill] `research`

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

If any of the following are missing from your initialization context, ask your leader (or the user if standalone) before proceeding:
- **Scope** — what files/modules/area to work on
- **Task description** — what to do (fix a bug, add a feature, etc.)

Template: `"Blocked — missing <scope / task description / both>. What I have: <what was provided>. Can you clarify?"`

## Phase 1: Context Discovery

1. Scan the scope area to understand the relevant code.
2. Identify the test framework, build system, and test commands.
3. If scope or task is unclear, ask for clarification. Do NOT guess.
   Template: `"Unsure whether <ambiguity>. Should I <option A> or <option B>?"`

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

If the agent receives a skill directive, follow that skill's process for the core work while still running Phase 1 (Context Discovery) before and Phase 2 (Verification) after.

## Receiving Code Review

When you receive code review feedback, use the [superpowers:skill] `receiving-code-review` skill before implementing any suggestions.

## Phase 2: Verification

1. Run the project's test suite using commands from Phase 1.
2. Confirm all tests pass (or that failures are pre-existing, not caused by your changes).
3. Verify your changes match the approved plan — no missing items, no extras.
4. Produce a completion report and send it to the leader or user. In team mode, also notify relevant teammates (e.g., a paired [oneteam:agent] `bug-hunter` who needs to verify).

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

## Quick Reference

| Phase | Key Action | Output |
|-------|-----------|--------|
| Startup | Read CLAUDE.md, verify worktree, check for missing context | Ready to work or blocked message |
| Phase 1: Context Discovery | Scan scope, identify test framework | Understanding of relevant code |
| Phase 2: Verification | Run tests, verify plan coverage | Implementation Report |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Skipping Context Discovery when using a skill directive | ALWAYS run Phase 1 even with skill directives |
| Guessing scope when context is missing | ASK with the provided template |
| Working outside assigned scope | Ask before making out-of-scope changes |
| Writing status to files for team communication | Use SendMessage per team-collaboration skill |

## Constraints

- **ALWAYS** run Phase 1 (Context Discovery), even when using a skill directive.
- **ALWAYS** run Phase 2 (Verification) after completing work.
- **NEVER** work outside your assigned scope without asking first.
  Template: `"This requires <out-of-scope change> not in the plan. Proceed or stay in scope?"`
- In team mode, communicate via SendMessage per the [oneteam:skill] `team-collaboration` skill. Do not write status to files expecting others to read them.
- **ASK** if context is missing. Do not guess scope, task, or approach. (See Startup Protocol above for message templates.)
