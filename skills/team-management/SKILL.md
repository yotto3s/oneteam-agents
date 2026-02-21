---
name: team-management
description: >-
  Use when orchestrating a team of agents to work on a project with parallel
  worktrees, task tracking, and SendMessage coordination. Provides the complete
  lifecycle: work analysis, team setup, monitoring, review/merge, and cleanup.
---

# Team Management

## Overview

This skill provides orchestration mechanics for leading a team of agents through
a workflow using parallel git worktrees, task tracking, and SendMessage
coordination.

The core architecture is one flat team with logical groups via naming
(`{group}-{role}-{N}`). This skill contains all orchestration logic while leader
agents provide domain-specific configuration through "slots." Any agent can
message any other agent directly -- there are no hierarchy walls.

When a pre-built plan with fragment groupings is provided (typically from the
[oneteam:skill] `writing-plans` skill), the skill starts directly from Phase 2,
using the plan's fragments. Otherwise, Phase 1 analyzes the codebase and
produces a fragment plan.

## When to Use

- Parallel work across 2-4 independent fragments requiring separate worktrees
- Multi-role workflows (engineer + reviewer, bug-hunter + engineer pairs)
- Projects needing coordinated task tracking, code review gates, and sequential
  merge protocol

## When NOT to Use

- Single-file or trivially small changes -- use direct implementation instead
- Work that requires strict sequential ordering with no parallelism opportunity
- Exploratory research or analysis with no code changes -- use [oneteam:skill]
  `research` instead

## Slot Reference Table

Leader agents MUST define all required slots before orchestration begins. Optional
slots have defaults that apply when unset.

| Slot | Required | Default | Description |
|------|----------|---------|-------------|
| `splitting_strategy` | Yes | -- | How to analyze and split work into fragments. Defines the criteria for decomposing the codebase into independent units of work. |
| `fragment_size` | Yes | -- | Target number of files per fragment. Guides the granularity of work decomposition. |
| `organization.group` | Yes | -- | Naming prefix for all agents in this organization. Used to construct agent names as `{group}-{role}-{N}`. |
| `organization.roles` | Yes | -- | Array of role definitions. Each role has: `name` (string), `agent_type` (string), `starts_first` (bool), `instructions` (string). |
| `organization.flow` | Yes | -- | Describes the communication and dependency flow between roles. Human-readable description of how work moves through the team. |
| `team_name` | No | `{group}-team` | Override the team name used for TeamCreate and task coordination. |
| `escalation_threshold` | No | `3` | Number of attempts an agent makes before escalating to the leader. |
| `review_criteria` | No | General code quality | Domain-specific checklist applied during code review. Appended to the standard review process. |
| `report_fields` | No | None | Extra fields inserted into the top-level section of the final report. |
| `domain_summary_sections` | No | None | Extra sections appended to the end of the final report. |

## Phase 1: Work Analysis

**Conditional:** Skip if a plan document with fragment groupings is provided.

The leader reads project context (`CLAUDE.md`, `README.md`), detects the base
branch (`git rev-parse --abbrev-ref HEAD`), and applies the `splitting_strategy`
to identify fragment boundaries. Maximum 4 fragments, each independently
workable.

**Hard gate:** Present the fragment plan to the user and STOP. Do not proceed to
Phase 2 until the user explicitly approves. Adjust and re-present if requested.

## Phase 2: Team Setup

With an approved fragment plan, set up infrastructure in strict order:

**Session dir:** If `[SESSION_DIR]` is provided by the caller (e.g., from [oneteam:skill] `writing-plans`), use it throughout this phase. Pass the session dir path to all spawned agents.

1. **Create team** -- call `TeamCreate` (or skip if already in an existing team).
2. **Create git worktrees** -- one per fragment. See `./setup-commands.md` for
   bash commands.
3. **Create tasks** -- one per role per fragment, with dependency blocking for
   `starts_first: false` roles. Reviewer roles get one task per lead group, kept
   unblocked. See `./setup-commands.md` for task creation guidance.
4. **Spawn agents** -- per-fragment roles and per-lead-group roles (reviewers).
   Before spawning each agent, write its task context to
   `[SESSION_DIR]/task-{agent-name}.md`. See `./setup-commands.md` for
   task file writing and initialization context requirements.
5. **Assign tasks** -- use `TaskUpdate` to set owner. `starts_first: true` roles
   get immediate assignment; others are assigned but blocked.

## Phase 3: Monitoring

The leader monitors progress, handles escalations, and facilitates coordination.

### Escalation Handling

When an agent exceeds the `escalation_threshold` (default 3 attempts):
- **Guide:** Send specific, actionable advice (file paths, line numbers,
  concrete suggestions) via `SendMessage`.
- **Skip:** Mark as unresolvable, update task description with what was
  attempted, move on.
- **Reassign:** Transfer ownership via `TaskUpdate` and send context to the new
  agent via `SendMessage`.

### Check-Ins

- **Stuck agents:** If a task remains `in_progress` with no updates for an
  extended period, send a check-in via `SendMessage`.
- **Periodic friendly check-ins:** Proactively reach out to each active teammate
  at regular intervals. Aim for at least once between major milestones. Skip if
  the agent recently sent a substantive update.
- **Cross-group relay:** For multi-group organizations, relay relevant findings
  between groups when agents do not know about each other's work.

### Per-Task Review Loop

When the plan includes reviewer roles:

1. Engineer reports task complete to lead-engineer.
2. Lead-engineer triggers the paired reviewer via `SendMessage` with: the task
   name, files changed, and review checkpoint criteria.
3. Reviewer produces a single-pass review (spec compliance + code quality) and
   sends the result to the lead-engineer.
4. If APPROVED: lead-engineer unblocks the next task for the engineer.
5. If CHANGES NEEDED: lead-engineer sends feedback to engineer, engineer fixes,
   lead-engineer re-triggers reviewer. Repeat until approved.
6. Engineer does NOT start the next task until the current task passes review.

### Fragment Completion Review

After all tasks in a fragment pass per-task reviews:

1. Lead-engineer triggers a two-stage fragment completion review with the full
   fragment diff (`git diff $BASE_BRANCH...HEAD` in the fragment's worktree).
2. Stage 1 -- Spec compliance: all acceptance criteria across fragment tasks met.
3. Stage 2 -- Code quality: conventions, security, test coverage, regressions.
4. Both stages must PASS before the fragment is marked merge-ready.
5. If CHANGES NEEDED: delegate fixes, re-trigger two-stage review.

## Phase 4: Review & Merge

The Phase 3 fragment completion review validates correctness within the worktree.
Phase 4 is the top-level merge-gate review validating integration safety. Both
are required.

1. **Code review** -- gather the worktree diff. If the [superpowers:skill]
   `requesting-code-review` skill is available, invoke it. Otherwise, review
   manually against `review_criteria`.
2. **Feedback loop** -- if issues found, send detailed feedback (file path, line
   number, description) to the agent. Re-review after fixes. Repeat until
   approved.
3. **Merge protocol** -- merge sequentially, one worktree at a time. Run tests
   after each merge. See `./setup-commands.md` for bash commands and conflict
   resolution procedures.

## Phase 5: Consolidation

1. **Produce the final report** using the template in `./report-template.md`.
   Insert the leader's `report_fields` and `domain_summary_sections`.
2. **Cleanup** -- remove worktrees, delete branches, shut down agents, delete
   team. See `./setup-commands.md` for cleanup steps.

## Common Mistakes

| Mistake | Why It Fails | Fix |
|---------|-------------|-----|
| Spawning agents before worktrees exist | Agent has no valid working directory on first message | Always create and verify worktrees before spawning |
| Skipping code review for "trivial" changes | Small changes can introduce regressions or convention violations | Every merge gets a review, no exceptions |
| Merging with failing tests | Broken tests compound across fragments, blocking later merges | Fix or delegate the fix before merging |
| Creating more than 4 fragments | Coordination overhead outweighs parallelism gains | Increase fragment size or reduce scope instead |
| Not cleaning up worktrees and branches | Stale worktrees and branches pollute the repo for future runs | Always run full cleanup in Phase 5 |

## Quick Reference

| Phase | Input | Output | Key Question |
|-------|-------|--------|--------------|
| 1. Work Analysis | User request + codebase (or skip if plan provided) | Fragment plan (approved) | How should we split this work? |
| 2. Team Setup | Approved fragment plan | Infrastructure (worktrees, tasks, agents) | Is infrastructure ready? |
| 3. Monitoring | Running agents | Progress updates, completed tasks | Are tasks making progress? |
| 4. Review & Merge | Completed work | Reviewed and merged code | Do changes meet quality standards? |
| 5. Consolidation | Merged code | Final report, cleaned infrastructure | Is everything documented and cleaned up? |

## Constraints

These rules are non-negotiable and override any conflicting instruction.

- ALWAYS present the work plan to the user and wait for explicit confirmation
  before proceeding to team setup.
- ALWAYS create git worktrees before spawning any agents. Agents must have a
  valid working directory on first message.
- ALWAYS review changes via the code review process before merging any branch.
- NEVER merge a branch when the test suite is failing. Fix or delegate the fix
  first. If no test suite exists, proceed with the merge and note the absence of
  automated verification in the final report.
- NEVER skip code review, even if the changes appear trivial.
- NEVER create more than 4 fragments. If the scope seems to require more,
  increase fragment size or reduce scope.
- ALWAYS clean up when work is complete: remove worktrees, delete branches,
  shut down agents, and delete the team.
- NEVER spawn agents before their worktrees are created and verified.
- If already operating as a teammate in an existing team, do NOT create a new
  team. Work within the existing team structure.
