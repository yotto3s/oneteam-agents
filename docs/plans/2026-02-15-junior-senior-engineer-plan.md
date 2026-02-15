# Junior & Senior Engineer Agents Implementation Plan

**Goal:** Replace the generic `implementer` agent with `junior-engineer` and
`senior-engineer` agents, backed by a shared `implementation` skill.

**Architecture:** Create shared `implementation` skill, two thin agent files,
then update all consumers (lead-engineer, debug-team-leader, writing-plans,
team-leadership, CLAUDE.md, README.md) and delete the old implementer.

**Tech Stack:** YAML frontmatter + markdown (Claude Code agent/skill format)

**Strategy:** Subagent-driven

---

### Task 1: Create the implementation skill

**Files:**
- Create: `skills/implementation/SKILL.md`

**Reference:** Read `agents/implementer.md` for the source material to extract
shared phases from. Read `skills/team-collaboration/SKILL.md` to understand
what NOT to duplicate (communication practices).

**Step 1: Create the skill file**

Write `skills/implementation/SKILL.md` with the following structure:

```yaml
---
name: implementation
description: >-
  Shared workflow phases and best practices for implementation agents
  (junior-engineer, senior-engineer). Provides startup protocol, context
  discovery, common best practices, verification, and reporting. Agents
  layer tier-specific behavior on top.
---
```

Followed by markdown body with these sections:

**Startup Protocol:**
- Read `CLAUDE.md` at the worktree root (if it exists) to learn build commands,
  test commands, and project conventions
- Verify worktree access by listing root contents
- Check initialization context for `mode: team` or `mode: subagent`
  (default: subagent). If `mode: team`, apply the team-collaboration skill
  protocol for all communication throughout your workflow

Include a table of required initialization context fields:
- **Worktree path**: the Git worktree assigned to work in
- **Scope**: the files/modules/area responsible for
- **Skill directive**: (optional) which skill to follow
- **Plan**: (optional) a pre-written implementation plan to follow
- **Leader name**: the agent or user who spawned you
- **Teammates**: other agents to coordinate with

If **Scope** or **Task description** is missing, ask leader/user before
proceeding.

**Phase 1: Context Discovery** (extracted from implementer Phase 1):
1. Read `CLAUDE.md` and `README.md` (if they exist) for project conventions
2. Scan the scope area to understand the relevant code
3. Identify the test framework, build system, and test commands
4. If scope or task is unclear, ask for clarification. Do NOT guess.

**Common Best Practices:**
1. **Read before you write** — understand existing code, conventions, and the
   "why" behind current patterns before changing anything
2. **Stay in scope** — change only what the task requires; don't refactor,
   improve, or clean up surrounding code
3. **Atomic commits** — each commit is one logical change, leaves the codebase
   in a working state, uses semantic prefixes (`feat:`, `fix:`, `docs:`)
4. **Test after each change** — run the project's test suite after every
   meaningful change, not just at the end
5. **Self-review before reporting** — review your own diff before claiming
   completion; verify the change matches intent
6. **Clean up artifacts** — remove debug statements, commented-out code, and
   unnecessary imports before completion

Add a note: "Communication practices (never block silently, close the loop,
speak up early) are handled by the `team-collaboration` skill — not duplicated
here."

**Skill Override:**
If the agent receives a skill directive (e.g., "use the systematic-debugging
skill"), follow that skill's process for the core work. Phase 1 (Context
Discovery) and Phase 2 (Verification) still apply — run them before and after
the skill's process.

Example flow:
1. Phase 1: Context Discovery (always)
2. Skill's own process (replaces planning + implementation)
3. Phase 2: Verification (always)

**Phase 2: Verification** (extracted from implementer Phase 4):
1. Run the project's test suite using commands from Phase 1
2. Confirm all tests pass (or that failures are pre-existing, not caused by
   your changes)
3. Verify your changes match the approved plan — no missing items, no extras
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

**Reporting:**
After completing work (whether via skill or default workflow), produce a
summary for the leader or user. In team mode, also notify relevant teammates.

**Constraints:**
- ALWAYS run Phase 1 (Context Discovery), even when using a skill directive
- ALWAYS run Phase 2 (Verification) after completing work
- NEVER work outside your assigned scope without asking first
- In team mode, communicate via SendMessage per the team-collaboration skill
- ASK if context is missing. Do not guess scope, task, or approach.

**Step 2: Verify the file**

Read the created file back. Confirm:
- YAML frontmatter has `name` and `description`
- All sections from the design doc are present
- No duplication with team-collaboration skill content
- Phase numbering is consistent (Phase 1: Context Discovery, Phase 2:
  Verification)

**Step 3: Commit**

```bash
git add skills/implementation/SKILL.md
git commit -m "feat: add implementation skill — shared workflow for engineer agents"
```

---

### Task 2: Create the junior-engineer agent

**Files:**
- Create: `agents/junior-engineer.md`

**Reference:** Read `agents/implementer.md` for structural pattern. Read
`skills/implementation/SKILL.md` (just created) to understand what's shared
vs. agent-specific.

**Step 1: Create the agent file**

Write `agents/junior-engineer.md` with this frontmatter:

```yaml
---
name: junior-engineer
description: >-
  Handles trivial implementation tasks: boilerplate, CRUD, config changes,
  single-file edits. Receives detailed plans and follows them precisely.
  Works standalone or as a teammate in a team.
tools: Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch
model: sonnet
color: green
skills:
  - team-collaboration
  - implementation
---
```

Followed by markdown body:

**Title:** `# Junior Engineer`

**Introduction:** "You are a junior engineer agent. You receive detailed
implementation plans for trivial tasks — boilerplate, CRUD, config changes,
single-file edits — and execute them precisely. You may be given a specific
skill to use (e.g., 'use the systematic-debugging skill') or you may operate
with your default workflow."

**Startup:** "Follow the **implementation** skill startup protocol and Phase 1
(Context Discovery)."

**Default Workflow** (when no skill directive is given):

Phase 1: Context Discovery (from implementation skill — reference, don't
repeat)

Phase 2: Plan Execution (junior-specific — NO planning phase):
- "You receive a detailed plan from your leader or the user."
- Read the plan carefully
- Confirm understanding to the leader/user: "I've reviewed the plan. Here's
  my understanding: <summary>. Starting implementation."
- Execute the plan step by step
- Follow project conventions discovered in Phase 1
- Make minimal, focused changes — do not modify code outside the plan's scope
- Commit logically grouped changes with clear messages

Phase 3: Verification (from implementation skill — reference, don't repeat)

**Tier-Specific Best Practices:**
1. **Follow the plan literally** — execute steps in order as written; don't
   reinterpret, reorder, or "improve" the approach
2. **Don't over-engineer** — use the simplest solution that satisfies the
   requirement; avoid abstractions unless the plan calls for it
3. **Escalate after 3 failed attempts** — don't spin on a problem; report
   with what you tried

**Model Override:** "Default model is `sonnet`. Leaders can override to
`haiku` at dispatch time via the Task tool's `model` parameter for truly
trivial tasks (single-file boilerplate, config edits)."

**Constraints:**
- ALWAYS follow the implementation skill's Context Discovery and Verification
  phases
- NEVER deviate from the provided plan without asking first
- NEVER begin implementation without confirming plan understanding
- NEVER work outside your assigned scope without asking first
- In team mode, communicate via SendMessage per the team-collaboration skill
- ASK if context is missing. Do not guess scope, task, or approach.

**Step 2: Verify the file**

Read the created file back. Confirm:
- YAML frontmatter matches the design doc exactly
- Skills list includes both `team-collaboration` and `implementation`
- No planning phase exists (junior follows provided plans)
- Tier-specific best practices are present
- Constraints section exists

**Step 3: Commit**

```bash
git add agents/junior-engineer.md
git commit -m "feat: add junior-engineer agent — trivial task executor"
```

---

### Task 3: Create the senior-engineer agent

**Files:**
- Create: `agents/senior-engineer.md`

**Reference:** Read `agents/implementer.md` for structural pattern. Read
`skills/implementation/SKILL.md` for shared phases. Read
`agents/junior-engineer.md` (just created) for parallel structure.

**Step 1: Create the agent file**

Write `agents/senior-engineer.md` with this frontmatter:

```yaml
---
name: senior-engineer
description: >-
  Handles complex implementation tasks: multi-file changes, architectural work,
  novel logic, high-risk changes. Plans its own approach, gets approval, then
  implements. Works standalone or as a teammate in a team.
tools: Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch
model: opus
color: cyan
skills:
  - team-collaboration
  - implementation
---
```

Followed by markdown body:

**Title:** `# Senior Engineer`

**Introduction:** "You are a senior engineer agent. You receive complex
implementation tasks — multi-file changes, architectural work, novel logic,
high-risk changes — and execute them with careful planning and verification.
You may be given a specific skill to use (e.g., 'use the systematic-debugging
skill') or you may operate with your default workflow."

**Startup:** "Follow the **implementation** skill startup protocol and Phase 1
(Context Discovery)."

**Default Workflow** (when no skill directive is given):

Phase 1: Context Discovery (from implementation skill — reference, don't
repeat)

Phase 2: Planning (senior-specific — FULL planning phase):

**If a plan is already provided:**
1. Read the plan carefully
2. Identify anything unclear, ambiguous, or seemingly incorrect
3. Ask clarifying questions to your leader or the user
4. Once clarified, send the plan back for approval: "I've reviewed the plan.
   Here's my understanding: <summary>. Ready to proceed?"
5. **WAIT** for explicit approval before moving to Phase 3

**If no plan is provided:**
1. Analyze the task and create a plan:
   - List of changes needed
   - Files to create/modify
   - Approach and rationale
   - Edge cases and risks considered
2. Send the plan to the leader or user for approval
3. **WAIT** for explicit approval before moving to Phase 3

**HARD GATE:** Do NOT begin implementation without plan approval.

Phase 3: Implementation
1. Execute the approved plan step by step
2. Follow project conventions discovered in Phase 1
3. Make minimal, focused changes — do not modify code outside the plan's scope
4. Write or update tests for novel logic
5. Commit logically grouped changes with clear messages

Phase 4: Verification (from implementation skill — reference, don't repeat)

**Tier-Specific Best Practices:**
1. **Map the blast radius before changing** — trace callers, dependents, and
   side effects before modifying shared interfaces or core logic
2. **Consider edge cases explicitly** — null/empty inputs, error paths,
   concurrency, boundary values
3. **Write tests for novel logic** — any new algorithm, business rule, or
   non-trivial conditional needs test coverage
4. **Prefer incremental over big-bang** — break large changes into smaller,
   independently verifiable steps
5. **Minimize coupling** — prefer contained changes; when touching shared
   interfaces, ensure backward compatibility or coordinate the migration

**Constraints:**
- ALWAYS follow the implementation skill's Context Discovery and Verification
  phases
- NEVER begin implementation without plan approval (Phase 2 hard gate)
- NEVER work outside your assigned scope without asking first
- In team mode, communicate via SendMessage per the team-collaboration skill
- ASK if context is missing. Do not guess scope, task, or approach.

**Step 2: Verify the file**

Read the created file back. Confirm:
- YAML frontmatter matches the design doc exactly (model: opus, color: cyan)
- Skills list includes both `team-collaboration` and `implementation`
- Full planning phase exists with hard gate
- Tier-specific best practices are present (5 items)
- Constraints section exists

**Step 3: Commit**

```bash
git add agents/senior-engineer.md
git commit -m "feat: add senior-engineer agent — complex task executor"
```

---

### Task 4: Update writing-plans skill

**Files:**
- Modify: `skills/writing-plans/SKILL.md:48-56` (Phase 1 step 3)
- Modify: `skills/writing-plans/SKILL.md:127-168` (Task Structure)
- Modify: `skills/writing-plans/SKILL.md:196-223` (team-driven fragment section)

**Step 1: Extend Phase 1 step 3 with complexity heuristic**

In Phase 1, step 3 ("Extract planning signals"), after the existing bullet
"Complexity of each task (isolated vs. coupled, boilerplate vs. novel)", add
a new bullet:

```
   - Agent tier classification per task using this heuristic:

     | Signal | junior-engineer | senior-engineer |
     |--------|----------------|-----------------|
     | File count | 1-2 files | 3+ files |
     | Coupling | Low — isolated change | High — touches shared interfaces |
     | Pattern | Well-understood (boilerplate, CRUD, config) | Novel or complex logic |
     | Risk | Low — failure is obvious and contained | High — subtle bugs, data corruption, security |
     | Codebase knowledge | Minimal — can work from instructions alone | Deep — requires understanding architecture |

     When in doubt, classify as `senior-engineer`.
```

**Step 2: Update Task Structure with Agent role and Model fields**

In the Task Structure template (the ```` block around line 129), add two
fields after the `**Files:**` section:

```
**Agent role:** junior-engineer / senior-engineer
**Model:** (optional) haiku — only when a junior-engineer task is truly trivial
```

**Step 3: Update team-driven fragment template**

In the team-driven execution section, change `**Agent role:** implementer`
to `**Agent role:** junior-engineer / senior-engineer` in the fragment
template. The line currently reads:

```
- **Agent role:** implementer
```

Change to:

```
- **Agent role:** junior-engineer / senior-engineer
- **Model:** (optional) haiku — for truly trivial junior tasks
```

**Step 4: Verify changes**

Read the modified file back. Confirm:
- Heuristic table is present in Phase 1 step 3
- Task Structure template includes Agent role and Model fields
- Fragment template uses `junior-engineer / senior-engineer` not `implementer`
- No other references to `implementer` remain in the file

**Step 5: Commit**

```bash
git add skills/writing-plans/SKILL.md
git commit -m "feat: add agent tier classification to writing-plans skill"
```

---

### Task 5: Restructure lead-engineer agent

**Files:**
- Modify: `agents/lead-engineer.md`

This is the most significant change. The lead-engineer becomes a pure
orchestrator — no more self-implementation.

**Step 1: Update the description in frontmatter**

Change the `description` field from:
```
Receives specifications, reviews them for completeness, creates implementation
plans with complexity classification, delegates trivial tasks and implements
hard tasks itself. Embeds spec-review and task-classification expertise.
Uses team-leadership for orchestration when in team mode.
```

To:
```
Receives specifications, reviews them for completeness, and orchestrates
implementation by delegating to junior-engineer and senior-engineer agents.
Pure orchestrator — does not implement directly. Embeds spec-review expertise.
Uses team-leadership for orchestration when in team mode.
```

**Step 2: Update the introduction paragraph**

Change line 20 from:
```
work to implementer agents while handling the hard parts yourself.
```

To:
```
all work to junior-engineer and senior-engineer agents. You are a pure
orchestrator — you do not implement code directly.
```

**Step 3: Remove Phase 2 complexity heuristic**

In Phase 2 (Implementation Planning), step 3, remove the entire complexity
classification table and the `[DELEGATE]`/`[SELF]` classification system.
Replace with:

```
3. **Classify each task** using the agent tier heuristic from the writing-plans
   skill:

   | Signal | junior-engineer | senior-engineer |
   |--------|----------------|-----------------|
   | File count | 1-2 files | 3+ files |
   | Coupling | Low — isolated change | High — touches shared interfaces |
   | Pattern | Well-understood (boilerplate, CRUD, config) | Novel or complex logic |
   | Risk | Low — failure is obvious and contained | High — subtle bugs, data corruption, security |
   | Codebase knowledge | Minimal — can work from instructions alone | Deep — requires understanding architecture |

   When in doubt, classify as `senior-engineer`.
```

**Step 4: Update Implementation Plan format**

In Phase 2, step 4, change the plan format. Replace `[DELEGATE]` and `[SELF]`
with `[JUNIOR]` and `[SENIOR]`:

```
   ## Implementation Plan

   **Spec:** <spec name/reference>
   **Total tasks:** N (M junior, K senior)

   ### Task 1: <name> [JUNIOR]
   - **Files:** path/to/file1, path/to/file2
   - **Dependencies:** none
   - **Description:** <what to do>
   - **Acceptance criteria:** <how to verify>

   ### Task 2: <name> [SENIOR]
   - **Files:** path/to/file1, path/to/file2, path/to/file3
   - **Dependencies:** Task 1
   - **Description:** <what to do>
   - **Acceptance criteria:** <how to verify>
```

**Step 5: Rewrite Phase 3 (Execution) — remove self-implementation**

Replace the entire Phase 3 section. Remove all "Self-Implementation" and
"Self-Code Review" content. The new Phase 3:

```
### Phase 3: Execution

Delegate all tasks and monitor progress.

**Delegation:**
1. For each task in dependency order, delegate to the classified agent tier:
   - `[JUNIOR]` tasks → spawn `junior-engineer` (optionally override model
     to `haiku` for truly trivial tasks)
   - `[SENIOR]` tasks → spawn `senior-engineer`
2. Provide each agent with:
   - The task description and acceptance criteria from the plan
   - The exact file paths to work on
   - Any relevant context from the spec review

**Monitoring (team mode):**
1. Monitor agent progress via TaskList.
2. Handle escalations: if an agent exceeds the escalation threshold
   (default 3), review the problem and choose: **guide** (send advice),
   **reassign** (escalate junior task to senior-engineer), or **skip**
   (mark unresolvable).
3. When an agent reports completion, review their changes immediately.
```

**Step 6: Update Phase 4 (Completion Report)**

In the Completion Report template, replace `DELEGATE`/`SELF` with
`JUNIOR`/`SENIOR`, and replace `implementer-1`/`lead-engineer` with
`junior-engineer-1`/`senior-engineer-1`:

```
   ### Task Summary
   | Task | Classification | Completed By | Status |
   |------|---------------|--------------|--------|
   | Task 1 | JUNIOR | junior-engineer-1 | Done |
   | Task 2 | SENIOR | senior-engineer-1 | Done |
```

**Step 7: Update organization config**

In the Domain Configuration section, replace the organization roles. Change:

```yaml
roles:
  - name: "implementer"
    agent_type: "implementer"
    starts_first: true
    instructions: |
      Implement the delegated tasks per the provided plan. Each task has
      exact file paths, step-by-step instructions, and acceptance criteria.
      Follow your default workflow (context discovery, planning is already
      done -- skip to implementation, then verification). Report completion
      to the lead engineer.
```

To:

```yaml
roles:
  - name: "junior-engineer"
    agent_type: "junior-engineer"
    starts_first: true
    instructions: |
      Implement the delegated [JUNIOR] tasks per the provided plan. Each
      task has exact file paths, step-by-step instructions, and acceptance
      criteria. Follow your default workflow (context discovery, execute
      plan, then verification). Report completion to the lead engineer.
  - name: "senior-engineer"
    agent_type: "senior-engineer"
    starts_first: true
    instructions: |
      Implement the delegated [SENIOR] tasks per the provided plan. Each
      task has file paths and acceptance criteria. Plan your approach,
      get approval, implement, then verify. Report completion to the
      lead engineer.
```

Update the flow:
```
flow: "lead-engineer plans -> junior/senior-engineer builds -> reviewer reviews -> converge"
```

**Step 8: Update splitting_strategy**

Change:
```
1. Group [DELEGATE] tasks by module or functional area.
2. Ensure each fragment is independently workable.
3. Keep [SELF] tasks out of fragments.
```

To:
```
1. Group tasks by module or functional area.
2. Ensure each fragment is independently workable.
3. Group [JUNIOR] and [SENIOR] tasks separately where possible, so fragments
   can be assigned to a single agent tier.
```

**Step 9: Update report_fields**

Change:
```
- Tasks completed by self vs. delegated
```

To:
```
- Tasks completed by junior-engineer vs. senior-engineer
```

**Step 10: Update constraints**

Remove:
- `ALWAYS classify tasks using the complexity heuristic.`
- `NEVER delegate a task classified as [SELF]. Escalate to authority if stuck.`
- `When in doubt about task complexity, classify as [SELF].`

Add:
- `NEVER implement tasks directly. Delegate all implementation to junior-engineer or senior-engineer.`
- `When in doubt about task complexity, classify as [SENIOR].`

Change:
- `ALWAYS review implementer output before merging or accepting it.`
  → `ALWAYS review agent output before merging or accepting it.`

**Step 11: Verify changes**

Read the modified file back. Confirm:
- No references to `implementer` remain
- No references to `[DELEGATE]` or `[SELF]` remain
- No self-implementation code remains in Phase 3
- Organization config has two roles: junior-engineer and senior-engineer
- Constraints reflect pure orchestrator role

**Step 12: Commit**

```bash
git add agents/lead-engineer.md
git commit -m "feat: restructure lead-engineer as pure orchestrator"
```

---

### Task 6: Update debug-team-leader agent

**Files:**
- Modify: `agents/debug-team-leader.md:5,50-76`

**Step 1: Update description**

Change:
```
bug-hunter/implementer pairs to find and fix bugs, reviews all changes, merges fixes.
```

To:
```
bug-hunter/engineer pairs to find and fix bugs. Chooses junior-engineer or
senior-engineer based on bug severity. Reviews all changes, merges fixes.
```

**Step 2: Update organization config**

Replace the implementer role section with severity-based role selection.
Change:

```yaml
  - name: "implementer"
    agent_type: "implementer"
    starts_first: false
    instructions: |
      Use the systematic-debugging skill for all fixes. Wait for findings
      from the paired bug-hunter via SendMessage. For each finding (in severity
      order, HIGH first): read the reproduction test, run it to confirm
      failure, apply the systematic-debugging skill (all 4 phases: root cause
      investigation, pattern analysis, hypothesis testing, implementation),
      run the test to confirm it passes, run the full test suite for
      regressions. Send fixes report to both the bug-hunter and leader.
```

To:

```yaml
  - name: "engineer"
    agent_type: "junior-engineer OR senior-engineer (see Severity-Based Agent Selection below)"
    starts_first: false
    instructions: |
      Use the systematic-debugging skill for all fixes. Wait for findings
      from the paired bug-hunter via SendMessage. For each finding (in severity
      order, HIGH first): read the reproduction test, run it to confirm
      failure, apply the systematic-debugging skill (all 4 phases: root cause
      investigation, pattern analysis, hypothesis testing, implementation),
      run the test to confirm it passes, run the full test suite for
      regressions. Send fixes report to both the bug-hunter and leader.
```

**Step 3: Add severity-based agent selection section**

After the organization config block, before `### review_criteria`, add:

```markdown
### Severity-Based Agent Selection

When spawning engineer agents for each fragment, the leader selects the agent
tier based on the highest severity finding in that fragment's scope:

| Highest Severity in Fragment | Agent Type | Model |
|------------------------------|------------|-------|
| LOW | junior-engineer | sonnet (default) |
| MEDIUM | senior-engineer | opus |
| HIGH | senior-engineer | opus |

If a fragment contains a mix of severities, use the highest to determine the
agent tier. A senior-engineer can handle LOW severity fixes alongside HIGH
ones, but a junior-engineer should not be assigned HIGH severity bugs.
```

**Step 4: Update flow**

Change:
```
flow: "bug-hunter finds bugs -> implementer fixes -> bug-hunter verifies -> converge"
```

To:
```
flow: "bug-hunter finds bugs -> engineer fixes -> bug-hunter verifies -> converge"
```

**Step 5: Verify changes**

Read the modified file back. Confirm:
- No references to `implementer` remain
- Severity-based selection section exists
- Flow description updated
- Description updated

**Step 6: Commit**

```bash
git add agents/debug-team-leader.md
git commit -m "feat: update debug-team-leader to use junior/senior engineers"
```

---

### Task 7: Update team-leadership skill examples

**Files:**
- Modify: `skills/team-leadership/SKILL.md:398-424`

**Step 1: Update Example 2**

Replace Example 2 (Feature Development Team) with:

```markdown
### Example 2: Feature Development Team

A build-and-review team where junior and senior engineers write code and
reviewers validate it, with a lower escalation threshold for faster iteration.

```yaml
organization:
  group: "feature"
  roles:
    - name: "junior-engineer"
      agent_type: "junior-engineer"
      starts_first: true
      instructions: "Implement trivial tasks per plan, write tests, send for review"
    - name: "senior-engineer"
      agent_type: "senior-engineer"
      starts_first: true
      instructions: "Implement complex tasks per plan, write tests, send for review"
    - name: "reviewer"
      agent_type: "code-reviewer"
      starts_first: false
      instructions: "Review implementation against spec, send feedback or approval"
  flow: "engineers build -> reviewer reviews -> engineers fix -> converge"
  escalation_threshold: 2
```

Agent naming for 2 fragments: `feature-junior-engineer-1`,
`feature-senior-engineer-1`, `feature-reviewer-1`,
`feature-junior-engineer-2`, `feature-senior-engineer-2`,
`feature-reviewer-2`.

The reviewer role uses `starts_first: false` so each reviewer waits until
both engineers in their fragment have completed initial work before beginning
review.
```

**Step 2: Update any remaining implementer references in examples**

Check Example 3 (Multi-Group Project) for `feature-implementer-1` reference
on line 458. Change to `feature-junior-engineer-1, feature-senior-engineer-1`.

**Step 3: Verify changes**

Read the modified file back. Confirm:
- Example 2 uses junior-engineer and senior-engineer
- No references to `implementer` remain in examples
- Agent naming examples are consistent

**Step 4: Commit**

```bash
git add skills/team-leadership/SKILL.md
git commit -m "feat: update team-leadership examples with junior/senior engineers"
```

---

### Task 8: Update docs and delete implementer

**Files:**
- Modify: `CLAUDE.md:29-36,57-61`
- Modify: `README.md:8-51,86-93`
- Delete: `agents/implementer.md`

**Step 1: Update CLAUDE.md agent table**

Replace the agent table (lines 29-36). Remove the `implementer` row, add
`junior-engineer` and `senior-engineer`:

```markdown
| Agent | Model | Role |
|-------|-------|------|
| debug-team-leader | inherit | Orchestrates debugging sweeps, spawns bug-hunter/engineer pairs |
| bug-hunter | inherit | Finds bugs via bug-hunting skill, writes reproduction tests |
| junior-engineer | sonnet | Trivial task executor, follows detailed plans precisely |
| senior-engineer | opus | Complex task executor, plans own approach, handles architectural work |
| lead-engineer | opus | Pure orchestrator: reviews specs, delegates all implementation |
| code-reviewer | inherit | Read-only review for bugs, security, spec conformance |
| researcher | sonnet | Searches web and codebase, returns structured summaries to caller |
```

**Step 2: Update CLAUDE.md skill table**

Add the `implementation` skill to the skill table:

```markdown
| implementation | 2-phase: context discovery → verification + common best practices |
```

**Step 3: Update CLAUDE.md workflow descriptions**

Change:
```
**Debug workflow:** `debug-team-leader` → spawns `bug-hunter` + `implementer` pairs → reviews → merges
```
To:
```
**Debug workflow:** `debug-team-leader` → spawns `bug-hunter` + `junior-engineer`/`senior-engineer` pairs (by severity) → reviews → merges
```

Change:
```
**Lead-engineer workflow:** `lead-engineer` → reviews spec → classifies tasks as [DELEGATE] or [SELF] → delegates to implementers, implements hard parts → reviews → merges
```
To:
```
**Lead-engineer workflow:** `lead-engineer` → reviews spec → classifies tasks as [JUNIOR] or [SENIOR] → delegates to junior/senior engineers → reviews → merges
```

**Step 4: Update README.md agent table**

Replace the agent table. Remove `implementer`, add `junior-engineer` and
`senior-engineer`:

```markdown
| **debug-team-leader** | Orchestrates a debugging sweep. Spawns bug-hunter/engineer pairs (junior or senior based on severity), reviews changes, merges fixes. |
| **junior-engineer** | Handles trivial tasks: boilerplate, CRUD, config, single-file edits. Follows detailed plans precisely. Default model: sonnet (overridable to haiku). |
| **senior-engineer** | Handles complex tasks: multi-file changes, architectural work, novel logic. Plans own approach. Always uses opus model. |
| **bug-hunter** | Finds bugs and writes reproduction tests. Uses the bug-hunting skill, then verifies tests fail before handing findings to the paired engineer. |
| **lead-engineer** | Pure orchestrator. Receives specs, reviews them, creates implementation plans, delegates all work to junior and senior engineers. Uses opus model. |
| **code-reviewer** | Reviews code changes for bugs, security issues, and spec conformance. Read-only -- does not modify code. Communicates via team-collaboration protocol. |
| **researcher** | Searches web and codebase for information, returns structured summaries. Uses sonnet model. |
```

**Step 5: Update README.md skill table**

Add the `implementation` skill:

```markdown
| **implementation** | Shared workflow for engineer agents: startup protocol, context discovery, common best practices, verification, and reporting. |
```

**Step 6: Update README.md workflow diagrams**

Replace the debug workflow diagram:

```
debug-team-leader (orchestrator)
├── bug-hunter (finds bugs with bug-hunting skill)
│   └── Produces: findings with reproduction tests
└── junior-engineer / senior-engineer (fixes bugs with systematic-debugging skill)
    └── Produces: fixes verified against reproduction tests

Leader reviews all changes → merges → reports
```

Replace the lead-engineer workflow diagram:

```
lead-engineer (pure orchestrator)
├── Reviews spec and creates implementation plan
├── Classifies tasks: [JUNIOR] vs [SENIOR]
├── junior-engineer (handles trivial tasks)
│   └── code-reviewer reviews junior-engineer's code
├── senior-engineer (handles complex tasks)
│   └── code-reviewer reviews senior-engineer's code
└── Merges all reviewed changes → reports
```

**Step 7: Update README.md explanatory text**

Replace the paragraph about the implementer being generic (lines 48-51):

```markdown
The **junior-engineer** and **senior-engineer** share a common `implementation`
skill for context discovery, best practices, and verification. The junior
follows plans precisely; the senior plans its own approach. When the
debug-team-leader spawns them, it tells them to use `systematic-debugging`.
```

**Step 8: Update README.md usage examples**

Replace:
```
To use the implementer standalone for a task:

```
/agent implementer
```
```

With:
```
To use a junior engineer for a simple task:

```
/agent junior-engineer
```

To use a senior engineer for a complex task:

```
/agent senior-engineer
```
```

**Step 9: Delete agents/implementer.md**

```bash
git rm agents/implementer.md
```

**Step 10: Verify all changes**

Read `CLAUDE.md` and `README.md` back. Grep the entire repository for any
remaining references to `implementer`:

```bash
grep -r "implementer" agents/ skills/ CLAUDE.md README.md
```

The only acceptable matches are in `docs/plans/` (historical plan documents).
Any match in `agents/`, `skills/`, `CLAUDE.md`, or `README.md` must be fixed.

**Step 11: Commit**

```bash
git add CLAUDE.md README.md
git commit -m "feat: replace implementer with junior/senior engineers across docs"
```

---

## Execution: Subagent-Driven

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> to execute this plan task-by-task.

**Task Order:** Sequential, dependency-respecting order listed below.

1. Task 1: Create implementation skill — no dependencies
2. Task 2: Create junior-engineer agent — depends on Task 1
3. Task 3: Create senior-engineer agent — depends on Task 1
4. Task 4: Update writing-plans skill — no dependencies
5. Task 5: Restructure lead-engineer — no dependencies
6. Task 6: Update debug-team-leader — no dependencies
7. Task 7: Update team-leadership examples — no dependencies
8. Task 8: Update docs and delete implementer — depends on Tasks 1-7

Each task is self-contained with full context. Execute one at a time with
fresh subagent per task and two-stage review (spec compliance, then code
quality).
