# Subagent Mode: Dual-Strategy Execution for Agents and Skills

## Problem

All agents assume team infrastructure on startup (TeamCreate, SendMessage, worktrees, task tracking). This prevents using them in lighter subagent-driven workflows where agents are spawned via the Task tool, do work, and return results — no team coordination needed.

## Decision

Add a strategy decision point to team-leadership and lead-engineering skills. The leader analyzes work complexity, recommends team or subagent mode, and the user picks. All agents adopt subagent as their base behavior; team mode is layered on via team-collaboration skill.

## Design Principles

- **Subagent is base.** Agent files describe core work: receive task, execute phases, return result. No team infrastructure assumptions.
- **Team mode is the adapter.** team-collaboration skill adds SendMessage, ready messages, progress updates, teammate discovery when `mode: team`.
- **Always present recommendation, user decides.** Strategy and isolation choices are never automatic.
- **DRY.** Team mode described once (existing phase text), subagent overrides listed once as a thin section.

## Changes

### 1. Agent Files (all 5)

Remove team-specific startup logic (ready messages, SendMessage for completion/escalation, team config reading) from base behavior. Add mode detection block:

```markdown
## Mode Detection

Initialization context includes `mode: team` or `mode: subagent` (default: subagent).

If `mode: team`: apply team-collaboration skill protocol for all communication.
Otherwise: return completion report as final output.
```

Workflow phases, constraints, and output formats stay identical in both modes.

### 2. team-collaboration Skill

Add **Team Mode Activation Protocol** section at top, before existing principles:

| Behavior | Team mode implementation |
|----------|------------------------|
| Startup | Send ready message to leader via SendMessage |
| Progress | Send periodic updates to leader via SendMessage |
| Completion | Send report to leader via SendMessage (instead of returning as output) |
| Escalation | SendMessage to leader with context (instead of returning with ESCALATION NEEDED flag) |
| Blocking | SendMessage stating what's needed and from whom (instead of returning partial result) |
| Teammate discovery | Read team config to learn names and roles |

Frame existing 4 principles with: "The following principles govern your communication when operating in team mode."

### 3. team-leadership Skill

#### New Phase 2: Strategy Decision

Inserted after Phase 1 (Work Analysis). All subsequent phases renumber.

Steps:
1. Analyze fragment plan: fragment count (1 leans subagent, 2+ leans team) and task independence (shared files lean team)
2. Present recommendation to user with reasoning
3. User picks: `team` or `subagent`
4. If subagent: present isolation recommendation (current branch vs worktrees)
5. User picks: `branch` or `worktree`
6. HARD GATE — do not proceed without explicit user choice

#### Subagent Mode Overrides

Single section documenting what changes when subagent strategy is chosen. Everything not listed follows standard (team mode) phases:

- **Phase 3 (Team Setup):** Skip TeamCreate, TaskCreate, agent spawning. If `branch` isolation: skip worktrees too. Prepare ordered task queue from fragment plan.
- **Phase 4 (Monitoring):** Replace with sequential task execution. For each task: spawn implementer subagent via Task tool (no `team_name`, `mode: subagent`), spawn spec-compliance review subagent, fix loop if needed, spawn code-quality review subagent, fix loop if needed, run tests, next task.
- **Phase 5 (Review & Merge):** Skip code review gate (done per-task in Phase 4). If `branch` isolation: skip merge, run full test suite only.
- **Phase 6 (Consolidation):** Skip agent shutdown, TeamDelete. If `branch` isolation: skip worktree/branch cleanup. Adapt report: replace "agents" with "subagent tasks executed."

### 4. lead-engineering Skill

Expand Phase 3 (Mode Decision) to three-way choice:

| Signal | Single-branch | Subagent | Team |
|--------|--------------|----------|------|
| DELEGATE tasks | ≤2, same area | Any count, independent | 3+, or overlapping scopes |
| File overlap | None | None | Yes |
| Typical use | Tiny delegation | Medium work, sequential is fine | Large parallel effort |

Updated flow:
1. Analyze DELEGATE tasks using criteria above
2. Present recommendation to user with reasoning
3. User picks: `single-branch`, `subagent`, or `team`
4. If subagent: ask about isolation (branch vs worktree)
5. HARD GATE — wait for user choice

In subagent mode, DELEGATE tasks use Task tool dispatch with two-stage review. SELF tasks unchanged.

When lead-engineer chooses team mode, team-leadership's strategy decision takes over. In single-branch or subagent mode, lead-engineer handles strategy itself without invoking team-leadership.

## File Impact

| File | Change | Size |
|------|--------|------|
| `agents/debug-team-leader.md` | Add mode detection, remove team-specific startup | Small |
| `agents/bug-hunter.md` | Add mode detection, remove SendMessage from completion/escalation | Small |
| `agents/implementer.md` | Add mode detection, remove ready message and SendMessage calls | Small |
| `agents/code-reviewer.md` | Add mode detection, remove SendMessage from report delivery | Small |
| `agents/lead-engineer.md` | Add mode detection, remove team-specific startup | Small |
| `skills/team-collaboration/SKILL.md` | Add Team Mode Activation Protocol, frame existing principles | Medium |
| `skills/team-leadership/SKILL.md` | Insert Phase 2 (Strategy Decision), add Subagent Mode Overrides | Medium |
| `skills/lead-engineering/SKILL.md` | Expand Phase 3 to three-way decision | Medium |

## What Does NOT Change

- Agent workflow phases (bug-hunting's 6 phases, implementer's 4 phases, etc.)
- Agent constraints and output formats
- team-collaboration's 4 principles
- team-leadership's team mode behavior (still the default path)
- lead-engineering's other 4 phases
- No new files created
