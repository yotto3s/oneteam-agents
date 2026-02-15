# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A library of reusable Claude Code **agents** and **skills** for team-based debugging and feature development workflows. This is a metaprogramming project — it defines agent behaviors and skill workflows as YAML+markdown files, not traditional application code.

Installed via the install script:
```
./install.sh
```

Or with flags for non-interactive use:
```
./install.sh --target ~/.claude --with-superpowers
```

[Superpowers](https://github.com/obra/superpowers.git) is included as a git submodule at `external/superpowers/`. The install script automatically skips superpowers agents/skills that oneteam-agents overrides. Superpowers can also be installed separately as a Claude Code plugin.

## Architecture

### Core Design: Thick Skill + Thin Agent

- **Skills** (`skills/{name}/SKILL.md`) contain all domain logic — phased workflows, constraints, output formats
- **Agents** (`agents/{name}.md`) are thin wrappers that combine tools + skills + model selection
- **Subagent is base**: Agent files describe core work without team infrastructure assumptions. Team behavior is layered on via the `team-collaboration` skill when `mode: team`.

### Agent Definitions

YAML frontmatter with `name`, `description`, `tools`, `model`, `color`, `skills` fields, followed by markdown startup instructions, workflow phases, and constraints.

| Agent | Model | Role |
|-------|-------|------|
| bug-hunter | inherit | Finds bugs via bug-hunting skill, writes reproduction tests |
| junior-engineer | sonnet | Trivial task executor, follows detailed plans precisely |
| senior-engineer | opus | Complex task executor, plans own approach, handles architectural work |
| lead-engineer | opus | Orchestrates feature implementation or debugging sweeps, delegates all work |
| code-reviewer | inherit | Read-only review for bugs, security, spec conformance |
| researcher | haiku | Searches web and codebase, returns structured summaries to caller |

### Skill Definitions

YAML frontmatter with `name` and `description`, followed by phased pipeline documentation.

| Skill | Phases |
|-------|--------|
| design-workflow | Modifies brainstorming: removes auto-commit, adds optional GitHub issue posting |
| writing-plans | 4-phase: design analysis → strategy decision → plan writing → execution handoff |
| bug-hunting | 6-phase: scope → contract inventory → impact tracing → adversarial analysis → gap analysis → verification |
| team-collaboration | 4 principles: close the loop, never block silently, know ownership, speak up early |
| team-management | 5-phase orchestration: analysis (conditional) → team setup → monitoring → review/merge → consolidation |
| research | 3-phase: clarify → gather → synthesize |
| spec-review | 6-phase: read spec → analyze codebase → quality check → issue identification → report → approval gate |
| implementation | 2-phase: context discovery → verification + common best practices |

### Pipeline

The standard development pipeline follows this flow:
1. **brainstorming** (superpowers) + **design-workflow** (override) → produces design document, optionally posts to GitHub issue
2. **writing-plans** (override) → analyzes design, asks user for strategy, writes plan
3. **Execution** → `superpowers:subagent-driven-development` (subagent) or `team-management` (team)

### Two Main Workflows

**Feature workflow:** `lead-engineer` (feature mode) → invokes spec-review skill → classifies tasks as [JUNIOR] or [SENIOR] → delegates to junior/senior engineers → reviews → merges

**Debug workflow:** `lead-engineer` (debug mode) → spawns `bug-hunter` + `junior-engineer`/`senior-engineer` pairs (by severity) → reviews → merges

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
