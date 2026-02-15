# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A library of reusable Claude Code **agents** and **skills** for team-based debugging and feature development workflows. This is a metaprogramming project — it defines agent behaviors and skill workflows as YAML+markdown files, not traditional application code.

Installed via symlinks:
```
ln -s ~/oneteam-agents/agents ~/.claude/agents
ln -s ~/oneteam-agents/skills ~/.claude/skills
```

Requires the `systematic-debugging` skill from the [superpowers](https://github.com/anthropics/claude-plugins-official) plugin for the debug workflow.

## Architecture

### Core Design: Thick Skill + Thin Agent

- **Skills** (`skills/{name}/SKILL.md`) contain all domain logic — phased workflows, constraints, output formats
- **Agents** (`agents/{name}.md`) are thin wrappers that combine tools + skills + model selection

### Agent Definitions

YAML frontmatter with `name`, `description`, `tools`, `model`, `color`, `skills` fields, followed by markdown startup instructions, workflow phases, and constraints.

| Agent | Model | Role |
|-------|-------|------|
| debug-team-leader | inherit | Orchestrates debugging sweeps, spawns bug-hunter/implementer pairs |
| bug-hunter | inherit | Finds bugs via bug-hunting skill, writes reproduction tests |
| implementer | sonnet | Generic task executor, accepts skill directives |
| lead-engineer | opus | Spec-driven development: reviews, plans, delegates, implements |
| code-reviewer | inherit | Read-only review for bugs, security, spec conformance |

### Skill Definitions

YAML frontmatter with `name` and `description`, followed by phased pipeline documentation.

| Skill | Phases |
|-------|--------|
| bug-hunting | 6-phase: scope → contract inventory → impact tracing → adversarial analysis → gap analysis → verification |
| team-collaboration | 4 principles: close the loop, never block silently, know ownership, speak up early |
| team-leadership | 5-phase orchestration: analysis → team setup (worktrees) → monitoring → review/merge → cleanup |
| lead-engineering | 5-phase: spec review → plan with complexity classification → mode decision → execution → integration |

### Two Main Workflows

**Debug workflow:** `debug-team-leader` → spawns `bug-hunter` + `implementer` pairs → reviews → merges

**Lead-engineer workflow:** `lead-engineer` → reviews spec → classifies tasks as [DELEGATE] or [SELF] → spawns `implementer` + `code-reviewer` → merges

## Conventions for Writing Agents and Skills

### Agent Files
- One file per agent: `agents/{agent-name}.md`
- YAML frontmatter defines capabilities; markdown body defines behavior
- Include explicit "Constraints" section with non-negotiable rules
- Use a distinct `color` for terminal identification

### Skill Files
- One file per skill: `skills/{skill-name}/SKILL.md`
- Structure as numbered phases with explicit steps
- Include hard gates (approval checkpoints) where workflows must pause
- Define structured output formats (exact markdown templates)
- Add "Iron Laws" or "Constraints" sections for non-negotiable rules
- Include anti-pattern / rationalization defense tables

### Workflow Patterns
- **Hard gates:** Explicit user/leader approval required before proceeding
- **Phase completion checklists:** Must be explicitly completed — no skipping
- **Sequential merge:** Test verification after each merge
- **Escalation threshold:** Default 3 attempts before escalating
- **Agent naming:** `{group}-{role}-{N}` (e.g., `debug-bug-hunter-1`)
- **Max 4 fragments** per orchestration run
- **Code review mandatory** before any merge — includes leader's own code

## Git Conventions

- Semantic commit prefixes: `feat:`, `docs:`, `fix:`
- Lowercase, concise messages focused on the change
