# Subagent Mode Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refactor all agents and skills so subagent mode is the base behavior and team mode is layered on via team-collaboration skill.

**Architecture:** Agent files describe core work (receive task, execute phases, return result). team-collaboration skill becomes the team-mode adapter. team-leadership and lead-engineering skills gain strategy decision points that let the user choose between team and subagent execution.

**Tech Stack:** YAML frontmatter + Markdown agent/skill definitions (no application code)

**Design doc:** `docs/plans/2026-02-15-subagent-mode-design.md`

---

### Task 1: Add Team Mode Activation Protocol to team-collaboration skill

**Files:**
- Modify: `skills/team-collaboration/SKILL.md`

**Step 1: Add Team Mode Activation Protocol section**

Insert after the Overview section (after line 18), before the Principles section. This new section defines what agents do differently when `mode: team`:

```markdown
## Team Mode Activation Protocol

When an agent's initialization context includes `mode: team`, apply these
behaviors on top of the agent's base workflow:

| Behavior | Team mode action |
|----------|-----------------|
| Startup | Send ready message to leader via SendMessage: `"<Role> ready. Worktree: <path>, scope: <scope>."` |
| Progress | Send periodic updates to leader via SendMessage |
| Completion | Send report to leader via SendMessage instead of returning as output |
| Escalation | SendMessage to leader with context instead of returning with `ESCALATION NEEDED` flag |
| Blocking | SendMessage stating what is needed and from whom instead of returning partial result |
| Teammate discovery | Read team config to learn names and roles |

In subagent mode (default), agents skip all of the above and return their
completion report as final output. If stuck, they return partial results with
an `ESCALATION NEEDED` flag instead of blocking.
```

**Step 2: Add framing line before Principles**

Change the Principles heading area to frame the principles as team-mode guidance:

Replace:
```
## Principles
```

With:
```
## Principles

The following principles govern agent communication when operating in team mode.
```

**Step 3: Verify**

Read the file back. Confirm the structure is: frontmatter → Overview → Team Mode Activation Protocol → Principles (with framing line) → 4 principles unchanged.

**Step 4: Commit**

```bash
git add skills/team-collaboration/SKILL.md
git commit -m "feat: add team mode activation protocol to team-collaboration skill"
```

---

### Task 2: Refactor all 5 agents to subagent-as-base

**Files:**
- Modify: `agents/implementer.md`
- Modify: `agents/code-reviewer.md`
- Modify: `agents/lead-engineer.md`
- Modify: `agents/bug-hunter.md`
- Modify: `agents/debug-team-leader.md`

Each agent gets the same treatment: remove hardcoded team-specific behavior from base workflow, add a mode detection block. The agent's workflow phases, constraints, and output formats stay unchanged.

**Step 1: Refactor implementer.md**

This agent has the most team-specific references to remove.

In the Startup section, replace the current step 3 and the conditional ready message:

Replace:
```
3. If you are in a team, send a ready message to the leader via SendMessage:
   `"Implementer ready. Worktree: <path>, scope: <scope>."`
```

With:
```
3. Check your initialization context for `mode: team` or `mode: subagent`
   (default: subagent). If `mode: team`, apply the team-collaboration skill
   protocol for all communication throughout your workflow.
```

In Phase 1 (Context Discovery), replace step 4:

Replace:
```
4. If scope or task is unclear, ask via SendMessage (team) or ask the user
   (standalone). Do NOT guess.
```

With:
```
4. If scope or task is unclear, ask for clarification. Do NOT guess.
```

In Phase 2 (Planning), replace SendMessage references. Change:

Replace:
```
3. Ask clarifying questions via SendMessage to your leader (or the user).
```

With:
```
3. Ask clarifying questions to your leader or the user.
```

Replace:
```
2. Send the plan to the leader/user for approval via SendMessage.
```

With:
```
2. Send the plan to the leader or user for approval.
```

In Phase 4 (Verification), replace step 4:

Replace:
```
4. Send a completion report to the leader/user via SendMessage:
```

With:
```
4. Produce a completion report:
```

In Reporting section, replace:

Replace:
```
After completing work (whether via skill or default workflow), send a summary
to the leader/user. If in a team, also notify relevant teammates (e.g., a
paired bug-hunter who needs to verify).
```

With:
```
After completing work (whether via skill or default workflow), produce a
summary for the leader or user. In team mode, also notify relevant teammates
(e.g., a paired bug-hunter who needs to verify).
```

In Constraints, replace the SendMessage constraint:

Replace:
```
- **ONLY** communicate via SendMessage when in a team. Do not write status to
  files expecting others to read them.
```

With:
```
- In team mode, communicate via SendMessage per the team-collaboration skill.
  Do not write status to files expecting others to read them.
```

**Step 2: Refactor code-reviewer.md**

In the description (frontmatter), update:

Replace:
```
description: >-
  Reviews code changes for bugs, security issues, spec conformance, and project
  convention adherence. Read-only -- does not modify code. Sends findings to the
  requesting agent via SendMessage. Works as a teammate in any team context.
```

With:
```
description: >-
  Reviews code changes for bugs, security issues, spec conformance, and project
  convention adherence. Read-only -- does not modify code. Sends findings to
  the requesting agent via SendMessage. Works as a teammate in any team context.
```

In the intro paragraph, replace:

Replace:
```
You are a code reviewer agent. You review code changes and report findings to
the agent who requested the review. You do NOT modify code -- you only read
and analyze it.

Follow the **team-collaboration** skill for all communication.
```

With:
```
You are a code reviewer agent. You review code changes and report findings.
You do NOT modify code -- you only read and analyze it.
```

In the Startup section, replace the steps:

Replace:
```
Execute these steps immediately on startup:

1. Read `CLAUDE.md` at the worktree root (if it exists) to learn project
   conventions, build commands, and coding standards.
2. Verify you can access the worktree by listing its root contents.
3. Send a ready message to the leader via SendMessage:
   `"Code reviewer ready. Worktree: <path>."`
```

With:
```
Execute these steps immediately on startup:

1. Read `CLAUDE.md` at the worktree root (if it exists) to learn project
   conventions, build commands, and coding standards.
2. Verify you can access the worktree by listing its root contents.
3. Check your initialization context for `mode: team` or `mode: subagent`
   (default: subagent). If `mode: team`, apply the team-collaboration skill
   protocol for all communication throughout your workflow.
```

In the Review Process, replace step 5:

Replace:
```
5. **Send the report** to the leader via SendMessage.
```

With:
```
5. **Deliver the report.** In team mode, send via SendMessage to the leader.
   In subagent mode, return the report as final output.
```

In Constraints, replace the SendMessage constraint:

Replace:
```
- ALWAYS send findings to the requesting agent via SendMessage.
```

With:
```
- ALWAYS deliver findings to the requesting agent (via SendMessage in team
  mode, or as return output in subagent mode).
```

**Step 3: Refactor lead-engineer.md**

In the intro, replace:

Replace:
```
Follow the **lead-engineering** skill for your core workflow. Follow the
**team-leadership** skill for orchestration mechanics when in team mode. Follow the
**team-collaboration** skill for all communication.
```

With:
```
Follow the **lead-engineering** skill for your core workflow. Follow the
**team-leadership** skill for orchestration mechanics when in team mode.
```

In Startup, replace step 4:

Replace:
```
4. Send a ready message to the authority via SendMessage:
   `"Lead engineer ready. Worktree: <path>, scope: <scope>."`
5. Begin the lead-engineering skill workflow.
```

With:
```
4. Check your initialization context for `mode: team` or `mode: subagent`
   (default: subagent). If `mode: team`, apply the team-collaboration skill
   protocol for all communication throughout your workflow.
5. Begin the lead-engineering skill workflow.
```

**Step 4: Refactor bug-hunter.md**

This agent has minimal team-specific references in its body (the workflow phases don't mention SendMessage). Add the mode detection block after the intro paragraph.

After:
```
You are a bug hunter agent. Your job is to find bugs in recently implemented code
and write reproduction tests that prove each bug exists. You do NOT fix bugs.
```

Insert:
```

## Mode Detection

Check your initialization context for `mode: team` or `mode: subagent`
(default: subagent). If `mode: team`, apply the team-collaboration skill
protocol for all communication throughout your workflow.
```

**Step 5: Refactor debug-team-leader.md**

This is a leader agent. It orchestrates workers but may itself be spawned as a subagent by a higher-level process. Add mode detection for how it communicates with its parent.

After:
```
You orchestrate a debugging sweep of a codebase. Follow the **team-leadership**
skill for all orchestration mechanics (team setup, worktrees, monitoring, review,
merge, cleanup). This agent provides the domain-specific configuration below.
```

Insert:
```

## Mode Detection

Check your initialization context for `mode: team` or `mode: subagent`
(default: subagent). If `mode: team`, apply the team-collaboration skill
protocol for communication with your parent authority. Regardless of your own
mode, you orchestrate your workers per the team-leadership skill's strategy
decision.
```

**Step 6: Verify**

Read all 5 agent files back. Confirm:
- No hardcoded SendMessage in base behavior (except in role instructions within organization configs, which describe worker behavior)
- Each agent has mode detection
- Workflow phases, constraints, and output formats unchanged

**Step 7: Commit**

```bash
git add agents/implementer.md agents/code-reviewer.md agents/lead-engineer.md agents/bug-hunter.md agents/debug-team-leader.md
git commit -m "feat: refactor all agents to subagent-as-base with mode detection"
```

---

### Task 3: Add Strategy Decision and Subagent Mode Overrides to team-leadership skill

**Files:**
- Modify: `skills/team-leadership/SKILL.md`

**Step 1: Update Overview**

Replace:
```
This skill provides the complete orchestration mechanics for leading a team of
agents through a parallelized workflow. The core architecture is one flat team
with logical groups via naming (`{group}-{role}-{N}`). The design follows a
thick skill + thin agent pattern: this skill contains all orchestration logic
while leader agents provide domain-specific configuration through "slots." Any
agent can message any other agent directly -- there are no hierarchy walls.
Leader agents define what to do; this skill defines how to coordinate it.
```

With:
```
This skill provides the complete orchestration mechanics for leading a team of
agents through a workflow. It supports two execution strategies:

- **Team mode**: parallel agents with worktrees, task tracking, SendMessage
  coordination. Best for 2+ fragments or overlapping scopes.
- **Subagent mode**: sequential task execution via Task tool, two-stage review,
  lighter infrastructure. Best for 1 fragment or fully independent tasks.

The core architecture for team mode is one flat team with logical groups via
naming (`{group}-{role}-{N}`). The design follows a thick skill + thin agent
pattern: this skill contains all orchestration logic while leader agents provide
domain-specific configuration through "slots." Any agent can message any other
agent directly -- there are no hierarchy walls. Leader agents define what to do;
this skill defines how to coordinate it.

The leader always presents a strategy recommendation to the user, who makes the
final decision.
```

**Step 2: Insert Phase 2: Strategy Decision**

After Phase 1 (after the "Wait for confirmation" step, before the current Phase 2: Team Setup heading), insert:

```markdown
## Phase 2: Strategy Decision

After the user approves the fragment plan, the leader analyzes the work and
recommends an execution strategy. The user makes the final decision.

### Steps

1. **Analyze decision signals.**
   - Fragment count: 1 fragment leans subagent, 2+ fragments lean team.
   - Task independence: check if any fragments share files. Overlapping scopes
     lean team (worktree isolation needed for safe parallel work).

2. **Present strategy recommendation.** Display to the user:
   ```
   ## Strategy Recommendation

   **Fragments:** N
   **Task independence:** all independent / overlap in [list files]

   **Recommended:** Team mode / Subagent mode
   **Reasoning:** <1-2 sentences>

   1. **Team mode** — Parallel agents with worktrees, task tracking, SendMessage
   2. **Subagent mode** — Sequential task execution via Task tool, two-stage review
   ```

3. **User picks strategy:** `team` or `subagent`.

4. **If subagent chosen, present isolation recommendation:**
   ```
   ## Isolation Strategy

   **Recommended:** Current branch / Worktrees
   **Reasoning:** <1-2 sentences>

   1. **Current branch** — Subagents work directly here (simpler, faster)
   2. **Worktrees** — Isolated branches per fragment (safer)
   ```

5. **User picks isolation:** `branch` or `worktree`.

6. **HARD GATE.** Do NOT proceed until the user has explicitly chosen both
   strategy and (if applicable) isolation. Store the decisions for use in all
   subsequent phases.
```

**Step 3: Renumber Phase 2 → Phase 3**

Rename the current "## Phase 2: Team Setup" to "## Phase 3: Team Setup".

**Step 4: Renumber Phase 3 → Phase 4**

Rename "## Phase 3: Monitoring" to "## Phase 4: Monitoring".

**Step 5: Renumber Phase 4 → Phase 5**

Rename "## Phase 4: Review & Merge" to "## Phase 5: Review & Merge".

**Step 6: Renumber Phase 5 → Phase 6**

Rename "## Phase 5: Consolidation" to "## Phase 6: Consolidation".

**Step 7: Add Subagent Mode Overrides section**

Insert after the Constraints section, before the Organization Structure Examples:

```markdown
## Subagent Mode Overrides

When the user chooses subagent strategy in Phase 2, the following overrides
apply. Everything not listed here follows the standard (team mode) phases.

### Phase 3 (Team Setup) overrides

- Skip TeamCreate, TaskCreate, TaskUpdate, and agent spawning.
- If user chose `branch` isolation: skip worktree creation too.
- If user chose `worktree` isolation: create worktrees as normal but no team
  infrastructure.
- Prepare an ordered task queue from the fragment plan (dependency order).

### Phase 4 (Monitoring) overrides

Replace the polling/check-in loop with sequential task execution:

For each task in the queue:
1. Spawn an implementer subagent via the `Task` tool (no `team_name`,
   include `mode: subagent` in the prompt). Provide: worktree or branch path,
   file list, step-by-step instructions, acceptance criteria.
2. Wait for the subagent to return its result.
3. Spawn a spec-compliance review subagent to verify the result matches
   the plan and requirements.
4. If issues found: spawn a fix subagent with the review findings. Repeat
   steps 3-4 until the spec-compliance review passes.
5. Spawn a code-quality review subagent to check conventions, security,
   and code quality.
6. If issues found: spawn a fix subagent with the review findings. Repeat
   steps 5-6 until the code-quality review passes.
7. Run the project's test suite to verify no regressions.
8. Proceed to the next task.

### Phase 5 (Review & Merge) overrides

- Skip the code review gate (already done per-task in Phase 4).
- If user chose `branch` isolation: skip merge entirely. Run the full test
  suite as final verification.
- If user chose `worktree` isolation: merge sequentially as normal.

### Phase 6 (Consolidation) overrides

- Skip agent shutdown (subagents already terminated after each task).
- Skip TeamDelete (no team was created).
- If user chose `branch` isolation: skip worktree and branch cleanup.
- Adapt the report template: replace "Agents" field with "Subagent tasks
  executed" and list tasks instead of agent names.
```

**Step 8: Update Constraints**

Add to the Constraints section:

```markdown
- ALWAYS present the strategy recommendation in Phase 2 and wait for user
  choice before proceeding.
- In subagent mode, ALWAYS run two-stage review (spec-compliance then
  code-quality) for each task before proceeding to the next.
```

**Step 9: Update Quick Reference table**

Replace the current Quick Reference table with:

```markdown
## Quick Reference

| Phase | Input | Output | Key Question |
|-------|-------|--------|--------------|
| 1. Work Analysis | User request + codebase | Fragment plan (approved) | How should we split this work? |
| 2. Strategy Decision | Approved plan | Strategy + isolation choice | Team or subagent? Branch or worktree? |
| 3. Team Setup | Strategy choice | Infrastructure (worktrees, tasks, agents OR task queue) | Is infrastructure ready? |
| 4. Monitoring / Execution | Running agents OR task queue | Progress updates, completed tasks | Are tasks making progress? |
| 5. Review & Merge | Completed work | Reviewed and merged code | Do changes meet quality standards? |
| 6. Consolidation | Merged code | Final report, cleaned infrastructure | Is everything documented and cleaned up? |
```

**Step 10: Verify**

Read the file back. Confirm:
- 6 phases numbered correctly
- Strategy Decision is Phase 2
- Subagent Mode Overrides section exists after Constraints
- Quick Reference reflects 6 phases
- Existing team mode behavior unchanged

**Step 11: Commit**

```bash
git add skills/team-leadership/SKILL.md
git commit -m "feat: add strategy decision phase and subagent mode overrides to team-leadership"
```

---

### Task 4: Expand lead-engineering Phase 3 to three-way mode decision

**Files:**
- Modify: `skills/lead-engineering/SKILL.md`

**Step 1: Update Overview**

Replace:
```
This skill turns specifications into working implementations. The lead engineer
reviews a spec, breaks it into tasks, classifies each by complexity, delegates
trivial work to implementer agents, and handles the hard parts directly. It
operates in two modes based on scope: single-branch for small work, team mode
(via team-leadership) for larger efforts.
```

With:
```
This skill turns specifications into working implementations. The lead engineer
reviews a spec, breaks it into tasks, classifies each by complexity, delegates
trivial work to implementer agents, and handles the hard parts directly. It
operates in three modes based on scope: single-branch for tiny delegation,
subagent mode for medium independent work, and team mode (via team-leadership)
for larger parallel efforts. The lead engineer always presents a recommendation
and the user makes the final choice.
```

**Step 2: Replace Phase 3: Mode Decision**

Replace the entire Phase 3 section (from "## Phase 3: Mode Decision" through the end of "### Team Mode Setup") with:

```markdown
## Phase 3: Mode Decision

The lead engineer analyzes the delegated work, recommends an execution mode,
and the user makes the final choice.

### Decision Criteria

| Signal | Single-branch | Subagent | Team |
|--------|--------------|----------|------|
| DELEGATE tasks | ≤2, same area | Any count, all independent | 3+, or overlapping scopes |
| File overlap | None | None | Yes |
| Typical use | Tiny delegation | Medium work, sequential OK | Large parallel effort |

### Steps

1. **Analyze DELEGATE tasks** using the criteria above.

2. **Present recommendation to user:**
   ```
   ## Mode Recommendation

   **DELEGATE tasks:** N
   **File independence:** all independent / overlap in [list files]
   **SELF tasks:** M

   **Recommended:** Single-branch / Subagent / Team
   **Reasoning:** <1-2 sentences>

   1. **Single-branch** — Spawn implementers on current branch, no worktrees
   2. **Subagent** — Sequential Task tool dispatch, two-stage review per task
   3. **Team** — Full team-leadership orchestration with worktrees
   ```

3. **User picks mode:** `single-branch`, `subagent`, or `team`.

4. **If subagent chosen:** present isolation recommendation (current branch vs
   worktrees). User picks: `branch` or `worktree`.

5. **HARD GATE.** Do NOT proceed until the user has explicitly chosen.

### Single-Branch Mode Setup

1. Create a team (or use existing team if already a teammate).
2. For each `[DELEGATE]` task, spawn an implementer agent with:
   - The current worktree path
   - Exact file list and scope
   - Step-by-step instructions from the plan
   - Acceptance criteria
   - Leader name (this agent)
3. Create tasks via TaskCreate for each `[DELEGATE]` task.
4. Assign tasks to implementers via TaskUpdate.
5. Proceed to Phase 4.

Note: In single-branch mode, delegate tasks MUST NOT have overlapping file
scopes. If two delegate tasks touch the same file, either use team mode
(with separate worktrees) or serialize the delegate tasks.

### Subagent Mode Setup

1. If user chose `worktree` isolation: create worktrees per the
   team-leadership skill worktree creation steps. If `branch`: use
   current working directory.
2. Prepare an ordered task queue from the `[DELEGATE]` tasks (dependency order).
3. `[SELF]` tasks stay with the lead engineer (unchanged).
4. Proceed to Phase 4.

### Team Mode Setup

1. Fill in the team-leadership domain configuration slots (`splitting_strategy`,
   `fragment_size`, `organization`, `review_criteria`, `report_fields`,
   `domain_summary_sections`) as defined in the agent file.
2. Follow the team-leadership skill (starting from Phase 2: Strategy Decision),
   using the `[DELEGATE]` tasks as the fragment plan. Each fragment groups
   related `[DELEGATE]` tasks.
3. `[SELF]` tasks are NOT included in fragments -- they stay with the lead
   engineer.
4. Proceed to Phase 4.
```

**Step 3: Update Phase 4 Delegation Monitoring for subagent mode**

After the existing "### Delegation Monitoring" subsection content, add:

```markdown

### Subagent Delegation

When operating in subagent mode, replace the Delegation Monitoring workflow
above with sequential task execution:

For each `[DELEGATE]` task in the queue:
1. Spawn an implementer subagent via the `Task` tool (no `team_name`,
   include `mode: subagent`). Provide: worktree or branch path, file list,
   instructions, acceptance criteria.
2. Wait for the subagent to return its result.
3. Spawn a spec-compliance review subagent to verify the result.
4. If issues: spawn a fix subagent. Repeat until spec passes.
5. Spawn a code-quality review subagent.
6. If issues: spawn a fix subagent. Repeat until quality passes.
7. Run test suite.
8. Next task.

`[SELF]` tasks are still executed by the lead engineer directly, unchanged.
```

**Step 4: Update Phase 5 for subagent mode**

In Phase 5 step 1 ("Review implementer changes via code-reviewer"), after the existing content for team/single-branch review, add a note:

After:
```
   d. If APPROVED: proceed to the next implementer's review or to step 2.
```

Add:
```

   **Subagent mode:** Skip this step. Code review was already done per-task
   during Phase 4 (two-stage review).
```

In Phase 5 step 2 ("Merge changes"), add subagent mode:

Replace:
```
2. **Merge changes.**
   - **Team mode:** Follow team-leadership Phase 4 (sequential merge with
     test verification after each merge).
   - **Single-branch mode:** Implementers committed directly to the branch.
     No merge needed -- verify the combined state instead.
```

With:
```
2. **Merge changes.**
   - **Team mode:** Follow team-leadership Phase 5 (sequential merge with
     test verification after each merge).
   - **Single-branch mode:** Implementers committed directly to the branch.
     No merge needed -- verify the combined state instead.
   - **Subagent mode with worktrees:** Merge sequentially as in team mode.
   - **Subagent mode with branch:** No merge needed -- all work committed
     to current branch. Verify combined state.
```

**Step 5: Update Phase 5 Cleanup**

Replace:
```
7. **Cleanup.** If this agent created the team:
   - Follow team-leadership Phase 5 (Consolidation) for cleanup.
   - If single-branch mode: shut down implementers, delete team.
```

With:
```
7. **Cleanup.** If this agent created the team:
   - Follow team-leadership Phase 6 (Consolidation) for cleanup.
   - If single-branch mode: shut down implementers, delete team.
   - If subagent mode: clean up worktrees (if used). No team to delete,
     no agents to shut down.
```

**Step 6: Update Quick Reference**

Replace the Mode Decision row:
```
| 3. Mode Decision | Approved plan | Single-branch or team mode setup | No |
```

With:
```
| 3. Mode Decision | Approved plan | Single-branch, subagent, or team setup | Yes -- user choice |
```

**Step 7: Verify**

Read the file back. Confirm:
- Phase 3 has three-way decision with user prompt
- Phase 4 has Subagent Delegation subsection
- Phase 5 references subagent mode for review, merge, and cleanup
- Quick Reference updated
- All other phases unchanged

**Step 8: Commit**

```bash
git add skills/lead-engineering/SKILL.md
git commit -m "feat: expand lead-engineering mode decision to three-way choice with subagent mode"
```

---

### Task 5: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Update Architecture section**

In the "### Core Design: Thick Skill + Thin Agent" section, add after the existing bullet points:

```markdown
- **Subagent is base**: Agent files describe core work without team infrastructure assumptions. Team behavior is layered on via the `team-collaboration` skill when `mode: team`.
```

**Step 2: Update Two Main Workflows section**

Replace:
```
### Two Main Workflows

**Debug workflow:** `debug-team-leader` → spawns `bug-hunter` + `implementer` pairs → reviews → merges

**Lead-engineer workflow:** `lead-engineer` → reviews spec → classifies tasks as [DELEGATE] or [SELF] → spawns `implementer` + `code-reviewer` → merges
```

With:
```
### Two Main Workflows

Both workflows support two execution strategies chosen by the user:
- **Team mode**: parallel agents, worktrees, task tracking, SendMessage coordination
- **Subagent mode**: sequential Task tool dispatch, two-stage review, lighter infrastructure

**Debug workflow:** `debug-team-leader` → spawns `bug-hunter` + `implementer` pairs → reviews → merges

**Lead-engineer workflow:** `lead-engineer` → reviews spec → classifies tasks as [DELEGATE] or [SELF] → spawns `implementer` + `code-reviewer` → merges
```

**Step 3: Update Skill Definitions table**

Replace the team-leadership row:
```
| team-leadership | 5-phase orchestration: analysis → team setup (worktrees) → monitoring → review/merge → cleanup |
```

With:
```
| team-leadership | 6-phase orchestration: analysis → strategy decision → team setup → monitoring → review/merge → cleanup |
```

**Step 4: Verify**

Read the file back. Confirm CLAUDE.md reflects the new architecture.

**Step 5: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md with subagent mode architecture"
```
