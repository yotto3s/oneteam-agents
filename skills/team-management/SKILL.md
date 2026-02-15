---
name: team-management
description: >-
  Use when orchestrating a team of agents to work on a project. Provides the
  complete lifecycle for team mode: work analysis, team setup with git worktrees,
  agent spawning with logical group naming, progress monitoring, escalation
  handling, code review gates, sequential merge protocol, and cleanup. Leader
  agents load this skill and fill in domain-specific configuration slots.
---

# Team Management

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
[oneteam:skill] `writing-plans` skill), the skill starts directly from Phase 2 (Team Setup),
using the plan's fragments. Otherwise, Phase 1 (Work Analysis) analyzes the
codebase and produces a fragment plan.

## Slot Reference Table

Leader agents MUST define all required slots before orchestration begins. Optional
slots have defaults that apply when unset.

| Slot | Required | Default | Description | Example |
|------|----------|---------|-------------|---------|
| `splitting_strategy` | Yes | -- | How to analyze and split work into fragments. Defines the criteria for decomposing the codebase into independent units of work. | `"Module boundaries + git changes"` |
| `fragment_size` | Yes | -- | Target number of files per fragment. Guides the granularity of work decomposition. | `"5-15 files"` |
| `organization.group` | Yes | -- | Naming prefix for all agents in this organization. Used to construct agent names as `{group}-{role}-{N}`. | `"debug"` |
| `organization.roles` | Yes | -- | Array of role definitions. Each role has: `name` (string), `agent_type` (string), `starts_first` (bool), `instructions` (string). | `[{name: "bug-hunter", agent_type: "bug-hunter", starts_first: true, instructions: "Run tests and report findings"}]` |
| `organization.flow` | Yes | -- | Describes the communication and dependency flow between roles. Human-readable description of how work moves through the team. | `"bug-hunter finds -> debugger fixes -> bug-hunter verifies"` |
| `team_name` | No | `{group}-team` | Override the team name used for TeamCreate and task coordination. | `"my-debug-team"` |
| `escalation_threshold` | No | `3` | Number of attempts an agent makes before escalating to the leader. | `5` |
| `review_criteria` | No | General code quality | Domain-specific checklist applied during code review. Appended to the standard review process. | `"All error paths must have tests; no raw SQL queries"` |
| `report_fields` | No | None | Extra fields inserted into the top-level section of the final report. | `"Total bugs found, Coverage delta"` |
| `domain_summary_sections` | No | None | Extra sections appended to the end of the final report. | `"## Regression Risk Assessment\n..."` |

## Phase 1: Work Analysis

The leader analyzes the codebase and produces a fragment plan before any agents
are spawned or worktrees created.

**Conditional:** If a plan document with fragment groupings is provided (from
the [oneteam:skill] `writing-plans` skill), skip this phase entirely and proceed to Phase 2
(Team Setup), using the plan's fragment groupings as the approved fragment plan.
Only execute this phase when no pre-built plan is available.

### Steps

1. **Read project context.** Read `CLAUDE.md` and `README.md` from the
   repository root to understand project conventions, build commands, test
   commands, and architectural constraints.

2. **Detect base branch.** Store the current branch for use throughout all
   phases:
   ```bash
   BASE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
   ```
   This branch is the merge target for all worktrees. Record it explicitly and
   reference it in every git operation that needs it.

3. **Apply splitting strategy.** Use the leader's `splitting_strategy` to
   analyze the codebase and identify natural fragment boundaries. Target the
   number of files specified by `fragment_size`. Produce a maximum of 4
   fragments. Each fragment MUST be independently workable -- no fragment should
   depend on changes from another fragment to compile or pass tests.

4. **Respect explicit scope.** If the user provided an explicit scope (specific
   files, directories, or modules), subdivide that scope into fragments instead
   of analyzing the full codebase.

5. **Present the fragment plan.** Display the plan to the user in this format:
   ```
   ## Work Plan
   **Repository:** <name>
   **Base branch:** <branch>
   **Total files in scope:** <count>
   **Fragments:** N

   ### Fragment 1: <name>
   - **Focus:** <description of what this fragment covers>
   - **Files:** <count>
     - path/to/file1
     - path/to/file2

   ### Fragment 2: <name>
   - **Focus:** <description>
   - **Files:** <count>
     - path/to/file3
     - path/to/file4

   Proceed with this plan?
   ```

6. **Wait for confirmation.** STOP and wait for the user to confirm the plan.
   If the user requests changes (different grouping, different scope, fewer
   fragments), adjust the plan and re-present it. Do NOT proceed to Phase 2
   (Team Setup) until the user explicitly approves.

## Phase 2: Team Setup

With an approved fragment plan, the leader sets up infrastructure and spawns
agents. Every sub-step must complete before the next begins.

### Steps

1. **Create team.**
   - If the leader is a top-level agent (not already a teammate in an existing
     team): call `TeamCreate` with the name from the `team_name` slot, or
     `{group}-team` if unset.
   - If the leader is already a teammate in an existing team: skip TeamCreate
     entirely and work within the current team. Use the existing team name for
     all subsequent operations.

2. **Create git worktrees.** For each fragment N (1-indexed):
   ```bash
   # Clean up stale worktree if it exists
   git worktree remove ../{{group}}-fragment-N 2>/dev/null
   git branch -D {{group}}-fragment-N 2>/dev/null

   # Create fresh worktree
   git worktree add ../{{group}}-fragment-N -b {{group}}-fragment-N

   # Resolve absolute path for agent instructions
   WORKTREE_PATH=$(realpath ../{{group}}-fragment-N)
   ```
   After creation, verify each worktree by listing its contents to confirm it
   is a valid checkout. If worktree creation fails, diagnose and retry once
   before aborting with an error to the user.

3. **Create tasks.** For each fragment, create one task per role defined in
   `organization.roles`:
   - Task subject: `"{group}-{role} fragment N: <fragment description>"`
   - For roles where `starts_first: false`, set `addBlockedBy` pointing to the
     task ID of the `starts_first: true` role's task for the same fragment.
     This ensures dependent roles wait until their prerequisite completes.
   - Use `TaskCreate` for each task.
   - For reviewer roles specifically, create one task per lead group (not per
     fragment), since a reviewer covers all fragments in their lead group. The
     reviewer task subject should be:
     `"{group}-reviewer lead-group-N: review tasks for fragments X-Y"`.
     Set `addBlockedBy` pointing to all engineer tasks in the reviewer's lead
     group, so the reviewer is notified as each engineer task completes.

4. **Spawn agents.** For each fragment N, for each role in `organization.roles`
   (for reviewer roles, spawn one agent per lead group rather than per fragment):
   - Agent name: `{group}-{role}-{N}`
   - `subagent_type`: from the role's `agent_type` field
   - `team_name`: the team name established in step 1
   - The initialization message sent to each agent MUST include:
     - The absolute worktree path for this fragment
     - The complete list of files in the fragment (as absolute paths within
       the worktree)
     - The names of all other agents working on the same fragment (so they
       can message each other directly)
     - The leader's name for escalation messages
     - If the plan includes a Team Composition table with reviewer assignments:
       the name of the paired reviewer for this fragment (so the lead-engineer
       knows which reviewer to trigger for per-task reviews)
     - The role-specific `instructions` from the role definition
   - For multi-group organizations (where `organization.groups` is an array
     instead of a single group): spawn group leaders the same way, passing
     them their sub-group configuration so they can further subdivide if needed.

5. **Assign tasks.** Use `TaskUpdate` to set the `owner` field of each task to
   the corresponding agent name. Roles with `starts_first: true` get their
   tasks assigned immediately. Roles with `starts_first: false` have their
   tasks assigned but blocked -- agents will be notified when unblocked.

## Phase 3: Monitoring

The leader monitors progress, handles escalations, and facilitates cross-group
communication throughout the execution phase.

### Steps

1. **Poll task progress.** Periodically call `TaskList` to check the status of
   all tasks. Track which fragments have all tasks completed, which are still
   in progress, and which are blocked.

2. **Handle escalations.** When an agent reports that it has exceeded the
   `escalation_threshold` (default 3 attempts) without success:
   - Read the escalation details from the agent's message.
   - Review the relevant code using Read, Grep, and Glob tools to understand
     the problem.
   - Choose one of three actions:
     - **Guide:** Send specific, actionable advice to the stuck agent via
       `SendMessage`. Include file paths, line numbers, and concrete
       suggestions.
     - **Skip:** Mark the item as unresolvable for now. Update the task
       description to record what was attempted and why it could not be
       resolved. Move on.
     - **Reassign:** If a different agent is better suited, reassign the
       work by updating task ownership via `TaskUpdate` and sending context
       to the new agent via `SendMessage`.

3. **Check on stuck agents.** If an agent's task remains `in_progress` with no
   messages or updates for an extended period, send a check-in message via
   `SendMessage` asking for a status report. Do not assume failure -- the
   agent may be working on a complex problem.

4. **Periodic friendly check-ins.** Proactively reach out to each active
   teammate for a status update at regular intervals -- don't wait for them
   to report or for problems to surface. Keep the tone friendly and
   supportive, not interrogative. Examples:
   - "Hey, how's it going on your end? Anything I can help with?"
   - "Just checking in -- making progress? Let me know if you hit any snags."
   - "How are things looking? No rush, just want to stay in the loop."

   Aim to check in with each active agent at least once between major
   milestones (e.g., between fragment completions). Stagger check-ins so
   you're not messaging everyone at the same time. If an agent recently
   sent a substantive update, skip the check-in -- they've already
   communicated their status.

5. **Cross-group relay.** For multi-group organizations where groups work on
   related aspects:
   - If one group produces output that is relevant to another group, relay a
     summary of the findings to the other group's agents.
   - Agents CAN message across groups directly (flat team architecture), but
     the leader should facilitate when agents do not know about each other's
     work or when coordination is needed.

6. **Per-task review loop.** When the plan includes per-task review checkpoints
   (indicated by a Team Composition table with reviewer roles):
   1. Engineer reports task complete to lead-engineer.
   2. Lead-engineer triggers the fragment's paired reviewer to review the diff
      for that task. Send via `SendMessage` to the reviewer with: the task
      name, the files changed, and the review checkpoint criteria from the plan.
   3. Reviewer produces a single-pass review (spec compliance + code quality
      combined) and sends the result to the lead-engineer.
   4. If APPROVED: lead-engineer unblocks the next task for the engineer.
   5. If CHANGES NEEDED: lead-engineer sends the reviewer's feedback to the
      engineer via `SendMessage`. Engineer fixes the issues and reports
      completion again. Lead-engineer re-triggers the reviewer. Repeat until
      approved.
   6. Engineer does NOT start the next task until the current task passes
      review. The lead-engineer enforces this by only unblocking the next task
      after reviewer approval.

7. **Fragment completion review.** After all tasks in a fragment pass their
   per-task reviews:
   1. Lead-engineer triggers a two-stage fragment completion review by sending
      a `SendMessage` to the fragment's paired reviewer with the full fragment
      diff (`git diff $BASE_BRANCH...HEAD` in the fragment's worktree).
   2. Stage 1 — Spec compliance: reviewer checks that all acceptance criteria
      across all fragment tasks are met.
   3. Stage 2 — Code quality: reviewer checks conventions, security, test
      coverage, and regressions across the entire fragment diff.
   4. Both stages must PASS before the fragment is marked merge-ready.
   5. If either stage produces CHANGES NEEDED: lead-engineer delegates the
      fixes to the responsible engineer and re-triggers the two-stage review
      after fixes are applied.
   6. Only after both stages pass does the lead-engineer report the fragment
      as merge-ready to the top-level orchestrator.

## Phase 4: Review & Merge

The Phase 3 fragment completion review is performed by the lead-engineer's
paired reviewer within the fragment. Phase 4 is the top-level orchestrator's
merge-gate review. Both are required — the fragment review validates correctness
within the worktree, while the merge-gate review validates integration safety.

When agents report their work complete, the leader reviews changes and merges
them into the base branch sequentially.

### Steps

1. **Code review.** When a fragment group reports all work complete:
   a. Gather the diff for the worktree:
      ```bash
      git -C <worktree_path> diff $BASE_BRANCH...HEAD
      ```
   b. Present the diff output in the conversation context for analysis.
   c. If the [superpowers:skill] `requesting-code-review` skill is available, invoke
      the Skill tool with `skill: "superpowers:requesting-code-review"` to
      apply the structured review process. Otherwise, review the diff manually
      against the criteria below.
   d. Follow the structured review guidance to evaluate the changes.
   e. If the leader has defined `review_criteria`, evaluate the diff against
      each criterion in the checklist. Document pass/fail for each item.

2. **Feedback loop.** After review:
   - If issues are found: send detailed feedback to the responsible agent via
     `SendMessage`. Include the specific file path, line number, and a clear
     description of what needs to change. Wait for the agent to apply fixes,
     then re-review the updated diff. Repeat until the changes pass review.
   - If the changes are approved: proceed to merge.

3. **Merge protocol.** Merge one worktree at a time, sequentially:
   ```bash
   git checkout $BASE_BRANCH
   git merge {{group}}-fragment-N --no-ff -m "Merge {{group}}-fragment-N: <fragment description>"
   ```
   After each merge, run the project's test suite to verify nothing is broken.
   Only proceed to the next merge after tests pass. If the project has no test
   suite, note this in the final report.

4. **Conflict resolution.** If a merge produces conflicts:
   - List conflicted files:
     ```bash
     git diff --name-only --diff-filter=U
     ```
   - If 3 or fewer files are conflicted: resolve the conflicts manually by
     reading both versions, choosing the correct resolution, and editing the
     files. Run the test suite after resolution.
   - If more than 3 files are conflicted: abort the merge and delegate:
     ```bash
     git merge --abort
     ```
     Send the conflict details to the agent responsible for the worktree and
     instruct them to rebase their branch onto the updated base branch. Retry
     the merge after the agent completes the rebase.

## Phase 5: Consolidation

After all fragments are merged, the leader produces a final report and cleans
up all infrastructure.

### Steps

1. **Produce the final report.** Use this template, inserting the leader's
   `report_fields` and `domain_summary_sections` where indicated:

   ```
   ## Team Report

   **Scope:** <what was analyzed or worked on>
   **Base branch:** <branch name>
   **Fragments completed:** N / N

   [Insert leader's report_fields here, if any]

   ### Per Fragment

   #### Fragment 1: <name>
   - **Agents:** {group}-{roleA}-1, {group}-{roleB}-1, ...
   - **Branch:** {group}-fragment-1
   - **Tasks completed:** M / M
   - **Summary:** <brief description of what was accomplished>

   #### Fragment 2: <name>
   - **Agents:** {group}-{role}-2, ...
   - **Branch:** {group}-fragment-2
   - **Tasks completed:** M / M
   - **Summary:** <brief description>

   ...

   ### Unresolved Items
   | Item | Fragment | Description | Reason |
   |------|----------|-------------|--------|
   | <item> | <N> | <what was attempted> | <why it was not resolved> |

   [Insert leader's domain_summary_sections here, if any]
   ```

   If there are no unresolved items, write "None" in the table body. Every
   section is mandatory -- none may be omitted.

2. **Cleanup.** Execute all cleanup steps in order:
   - Remove worktrees:
     ```bash
     git worktree remove ../{{group}}-fragment-N
     ```
     Repeat for each fragment.
   - Delete merged branches:
     ```bash
     git branch -d {{group}}-fragment-N
     ```
     Use lowercase `-d` (safe delete) to ensure only fully-merged branches are
     removed.
   - Shut down all agents: send `shutdown_request` via `SendMessage` to each
     spawned agent. Wait for each agent to confirm shutdown before proceeding.
   - Delete the team: if this leader created the team (top-level leader), call
     `TeamDelete` to remove the team and its task list. If working within a
     parent team, skip this step.

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
- ALWAYS merge sequentially, one worktree branch at a time. Run tests after
  each merge before proceeding to the next.
- ALWAYS clean up when work is complete: remove worktrees, delete branches,
  shut down agents, and delete the team.
- NEVER spawn agents before their worktrees are created and verified.
- If already operating as a teammate in an existing team, do NOT create a new
  team. Work within the existing team structure.

## Organization Structure Examples

These examples demonstrate the versatility of the slot system across different
use cases.

### Example 1: Debugging Team

A two-role team where bug-hunters find bugs and debuggers fix them, operating in
a tight feedback loop per fragment.

```yaml
organization:
  group: "debug"
  roles:
    - name: "[oneteam:agent] bug-hunter"
      agent_type: "[oneteam:agent] bug-hunter"
      starts_first: true
      instructions: "Run [oneteam:skill] bug-hunting, write reproduction tests, send findings to debugger"
    - name: "debugger"
      agent_type: "debugger"
      starts_first: false
      instructions: "Receive findings, apply [superpowers:skill] systematic-debugging, send fixes to [oneteam:agent] bug-hunter"
  flow: "[oneteam:agent] bug-hunter finds bugs -> debugger fixes -> [oneteam:agent] bug-hunter verifies -> converge"
  escalation_threshold: 3
```

Agent naming for 2 fragments: `debug-bug-hunter-1`, `debug-debugger-1`,
`debug-bug-hunter-2`, `debug-debugger-2`.

Task dependencies: each `debug-debugger-N` task is blocked by the corresponding
`debug-bug-hunter-N` task. Debuggers begin work only after [oneteam:agent] `bug-hunter`s produce
initial findings.

### Example 2: Feature Development Team

A four-role team where a lead-engineer coordinates engineers and a reviewer,
with per-task review checkpoints and a two-stage fragment completion review.

```yaml
organization:
  group: "feature"
  roles:
    - name: "[oneteam:agent] lead-engineer"
      agent_type: "[oneteam:agent] lead-engineer"
      starts_first: true
      instructions: "Oversee fragments, coordinate per-task reviews, trigger fragment completion review"
    - name: "[oneteam:agent] junior-engineer"
      agent_type: "[oneteam:agent] junior-engineer"
      starts_first: true
      instructions: "Implement [JUNIOR] tasks, wait for reviewer approval between tasks"
    - name: "[oneteam:agent] senior-engineer"
      agent_type: "[oneteam:agent] senior-engineer"
      starts_first: true
      instructions: "Implement [SENIOR] tasks, wait for reviewer approval between tasks"
    - name: "reviewer"
      agent_type: "[oneteam:agent] code-reviewer"
      starts_first: false
      instructions: "Per-task single-pass review, per-fragment two-stage review (spec + quality)"
  flow: "lead delegates -> engineers build task -> reviewer reviews task ->
         repeat until all tasks done -> reviewer does two-stage fragment review ->
         lead reports completion"
  escalation_threshold: 2
```

Agent naming for 2 fragments with 1 lead group: `feature-lead-engineer-1`,
`feature-junior-engineer-1`, `feature-senior-engineer-1`,
`feature-reviewer-1`, `feature-junior-engineer-2`,
`feature-senior-engineer-2`.

The lead-engineer oversees 2-3 fragments per lead group. The reviewer covers
all fragments in the lead group and uses `starts_first: false` so it waits
until engineers produce initial work before beginning per-task reviews.

### Example 3: Multi-Group Project

A pipeline of three groups where each group has its own leader. The planning
group produces a plan, the feature group implements it, and the debug group
verifies the result. Each group leader can further subdivide work internally.

```yaml
organization:
  groups:
    - group: "planning"
      roles:
        - name: "lead"
          agent_type: "planning-team-leader"
          starts_first: true
          instructions: "Analyze requirements, produce implementation plan"
    - group: "feature"
      roles:
        - name: "lead"
          agent_type: "feature-team-leader"
          starts_first: false
          instructions: "Implement features per plan from planning lead"
    - group: "debug"
      roles:
        - name: "lead"
          agent_type: "[oneteam:agent] lead-engineer"
          starts_first: false
          instructions: "Run debugging sweep on completed features"
  flow: "planning-lead plans -> feature-lead builds -> debug-lead verifies"
```

Agent naming: `planning-lead-1`, `feature-lead-1`, `debug-lead-1`. Each group
leader can spawn their own sub-agents within the same flat team, using their
group prefix (e.g., `feature-junior-engineer-1`, `feature-senior-engineer-1`).

Task dependencies chain across groups: `feature-lead-1` is blocked by
`planning-lead-1`, and `debug-lead-1` is blocked by `feature-lead-1`. This
ensures the pipeline executes in the correct order while still allowing
parallelism within each group.

## Quick Reference

| Phase | Input | Output | Key Question |
|-------|-------|--------|--------------|
| 1. Work Analysis | User request + codebase (or skip if plan provided) | Fragment plan (approved) | How should we split this work? |
| 2. Team Setup | Approved fragment plan | Infrastructure (worktrees, tasks, agents) | Is infrastructure ready? |
| 3. Monitoring | Running agents | Progress updates, completed tasks | Are tasks making progress? |
| 4. Review & Merge | Completed work | Reviewed and merged code | Do changes meet quality standards? |
| 5. Consolidation | Merged code | Final report, cleaned infrastructure | Is everything documented and cleaned up? |
