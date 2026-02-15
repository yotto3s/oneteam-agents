# Pipeline Redesign: writing-plans Override with Strategy Decision

## Problem

The current library has strategy decision logic scattered across multiple skills (team-leadership Phase 2, lead-engineering Phase 3). The superpowers writing-plans skill offers "subagent-driven vs parallel session" but doesn't know about team-driven execution. lead-engineering duplicates orchestration logic that team-leadership already handles.

## Solution

Override the superpowers `writing-plans` skill in oneteam-agents to insert a strategy decision point between design and execution. Remove lead-engineering as a separate skill, embedding its spec-review and classification expertise into the lead-engineer agent.

## New Pipeline

```
brainstorming (superpowers, unchanged)
    |  produces design doc
writing-plans (oneteam-agents override)
    |  Phase 1: Design Analysis
    |  Phase 2: Strategy Decision (light heuristics + user choice)
    |  Phase 3: Plan Writing (superpowers format + strategy-adapted sections)
    |  Phase 4: Execution Handoff
    |
    +-- subagent-driven --> superpowers:subagent-driven-development
    +-- team-driven -----> team-leadership (starts from Phase 3 when plan provided)
```

## writing-plans Skill (New Override)

### Phase 1: Design Analysis

Read the design doc from brainstorming. Extract task count, file touch areas, dependencies between tasks, and complexity signals. No user interaction.

### Phase 2: Strategy Decision

Light heuristic analysis:

| Signal | Subagent-driven | Team-driven |
|--------|----------------|-------------|
| Task count | 1-3 tasks | 4+ tasks |
| Independence | Mostly independent | Overlapping file scopes |
| Parallelism benefit | Low | High |

Present recommendation with brief rationale. User confirms or overrides.

### Phase 3: Plan Writing

Same format as superpowers writing-plans:
- Plan header (Goal, Architecture, Tech Stack)
- Bite-sized tasks with TDD steps (write failing test, run, implement, run, commit)
- Exact file paths, complete code, exact commands with expected output

Strategy-adapted additions:
- **Subagent-driven:** Tasks numbered sequentially with dependency notes. Each task self-contained with full context.
- **Team-driven:** Tasks grouped into fragments (max 4). Each fragment notes agent role, file scope boundaries, and inter-fragment dependencies.

### Phase 4: Execution Handoff

Save plan to `docs/plans/YYYY-MM-DD-<feature-name>-plan.md`, commit, then:
- Subagent-driven: invoke `superpowers:subagent-driven-development`
- Team-driven: invoke `team-leadership` (detects plan, starts from Phase 3)

## team-leadership Modifications

- Remove Phase 2 (Strategy Decision) entirely
- Remove Subagent Mode Overrides section
- Phase 1 (Work Analysis) becomes conditional: if a plan with fragment groupings is provided, skip analysis and use the plan directly. If no plan, run analysis as before.
- Renumber: Work Analysis (conditional) -> Team Setup -> Monitoring -> Review & Merge -> Consolidation
- Skill becomes team-only (no subagent mode awareness)

## lead-engineering Removal & lead-engineer Agent Changes

Delete `skills/lead-engineering/SKILL.md`.

lead-engineer agent embeds key behaviors from lead-engineering:
- **Spec review:** Critically review specs for ambiguities, missing edge cases, risks. Produce Spec Review Report. Hard gate for approval.
- **Task classification:** Classify as [DELEGATE] (trivial: 1-2 files, isolated, boilerplate) vs [SELF] (hard: 3+ files, coupled, novel, security-sensitive).
- **Self-code review:** Own code must be reviewed by code-reviewer before merge.

Removed from agent (handled by pipeline): mode decision, execution orchestration.

## File Changes

| Action | File |
|--------|------|
| Create | `skills/writing-plans/SKILL.md` |
| Modify | `skills/team-leadership/SKILL.md` |
| Delete | `skills/lead-engineering/SKILL.md` |
| Modify | `agents/lead-engineer.md` |
| Modify | `CLAUDE.md` |

## Design Decisions

- **Override via naming:** oneteam-agents `writing-plans` overrides superpowers `writing-plans` through symlink precedence
- **Two strategies only:** No executing-plans option. Subagent-driven and team-driven cover all cases.
- **Strategy-adapted format:** Plans differ structurally based on strategy (not a unified format with appendix)
- **team-leadership is team-only:** Subagent execution fully delegated to superpowers:subagent-driven-development
- **lead-engineer keeps expertise, loses orchestration:** Spec review and classification embedded in agent, orchestration delegated to skills
