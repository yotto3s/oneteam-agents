# Lead-Engineer Agent Design

## Problem

The current agent team has a debugging orchestrator (`debug-team-leader`) but no agent for feature development. We need a `lead-engineer` agent that receives specifications, creates implementation plans, delegates trivial work to `implementer` agents, and implements the hard parts itself.

## Design Decisions

- **Approach**: Spec-driven solo+delegate with hybrid scaling
- **Pattern**: Thick skill (`lead-engineering`) + thin agent (`lead-engineer.md`), consistent with project convention
- **Model**: opus (handles complex implementation directly)
- **Complexity split**: Heuristic-based -- analyzes code complexity, dependency count, coupling, and risk level
- **Orchestration**: Hybrid -- uses `team-leadership` for multi-fragment work (3+ delegated tasks), simpler single-branch mode for small scope
- **Input**: User or leader agent provides spec; lead-engineer always reviews it
- **Team context**: Always operates as teammate (team-collaboration protocol). Spawns implementers as teammates. Authority = whoever provided the spec.

## Files

### 1. `agents/lead-engineer.md`

Thin agent definition:
- **Tools**: Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch
- **Model**: opus
- **Color**: purple
- **Skills**: lead-engineering, team-collaboration, team-leadership

### 2. `skills/lead-engineering/SKILL.md`

Full workflow skill with 5 phases.

## Skill: lead-engineering

### Phase 1: Spec Review

- Read the provided spec/design document
- Analyze the target codebase area (read existing code, understand architecture)
- Identify: ambiguities, missing edge cases, unstated assumptions, risks
- Produce a **Spec Review Report**:
  - Confirmed requirements (what's clear)
  - Questions/gaps (what needs clarification)
  - Risks (what could go wrong)
  - Suggested refinements
- Send to authority (user or leader) for approval
- **HARD GATE**: Do not proceed until spec review is resolved

### Phase 2: Implementation Planning

- Break approved spec into concrete implementation tasks
- For each task document: what changes, which files, dependencies on other tasks
- Classify each task using complexity heuristic:
  - **Trivial [DELEGATE]**: Isolated change, 1-2 files, low coupling, well-understood pattern (boilerplate, simple CRUD, config, straightforward tests)
  - **Hard [SELF]**: Multi-file changes, architectural decisions, complex logic, high risk of subtle bugs, requires deep understanding of existing code
- Produce an **Implementation Plan**: ordered task list, each tagged `[DELEGATE]` or `[SELF]`
- Send plan to authority for approval
- **HARD GATE**: Do not proceed without plan approval

### Phase 3: Mode Decision

- Count `[DELEGATE]` tasks and assess scope
- **Single-branch mode**: 2 or fewer `[DELEGATE]` tasks, all in same area. Spawn implementers directly, no worktrees.
- **Team mode**: 3+ `[DELEGATE]` tasks, or tasks span different modules. Invoke `team-leadership` for worktree setup, agent spawning, sequential merge.

### Phase 4: Execution

- **Delegated tasks**: Spawn `implementer` agents with:
  - Exact file list and scope
  - Step-by-step instructions from the plan
  - Expected behavior / acceptance criteria
- **Self tasks**: Lead-engineer implements directly, following the plan
  - Works on `[SELF]` tasks in parallel with implementers on `[DELEGATE]` tasks
  - Reviews implementer output as it arrives
- **Escalation handling**: If implementer gets stuck (hits escalation threshold), lead-engineer can take over the task

### Phase 5: Integration & Verification

- Review all implementer changes (code review)
- Merge changes (sequential merge in team mode, direct in single-branch)
- Run full test suite
- Verify spec conformance: check each requirement against implementation
- Produce **Completion Report**:
  - Spec requirements: covered / partially covered / not covered
  - Tasks: completed by self / completed by implementer / escalated
  - Test results
  - Remaining work (if any)
- Send report to authority

## Team Integration

The lead-engineer always operates within a team context:

- Uses `team-collaboration` protocol (close the loop, never block silently, speak up early)
- Authority = whoever provided the spec (user or leader agent)
- Creates team and spawns implementers when working standalone
- Uses existing team when spawned by another agent (never creates a second team)
- Reports completion and escalations to authority
