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
- **Subagent is base**: Agent files describe core work without team infrastructure assumptions. Team behavior is layered on via the [oneteam:skill] `team-collaboration` skill when `mode: team`.

### Agent Definitions

YAML frontmatter with `name`, `description`, `tools`, `model`, `color`, `skills` fields, followed by markdown startup instructions, workflow phases, and constraints.

| Agent | Model | Role |
|-------|-------|------|
| [oneteam:agent] architect | inherit | Reads design docs and codebase, writes implementation plans |
| [oneteam:agent] bug-hunter | inherit | Finds bugs via [oneteam:skill] `bug-hunting` skill, writes reproduction tests |
| [oneteam:agent] junior-engineer | sonnet | Trivial task executor, follows detailed plans precisely |
| [oneteam:agent] senior-engineer | opus | Complex task executor, plans own approach, handles architectural work |
| [oneteam:agent] lead-engineer | opus | Orchestrates feature implementation or debugging sweeps, delegates all work |
| [oneteam:agent] researcher | haiku | Searches web and codebase, returns structured summaries to caller |

### Skill Definitions

YAML frontmatter with `name` and `description`, followed by phased pipeline documentation.

| Skill | Phases |
|-------|--------|
| [oneteam:skill] brainstorming | Collaborative design: explores intent, proposes approaches, writes design doc, optional GitHub issue posting, invokes [oneteam:skill] `writing-plans` |
| [oneteam:skill] writing-plans | 4-phase orchestrator: dispatch analyzer → strategy decision → dispatch [oneteam:agent] `architect` → execution handoff |
| [oneteam:skill] bug-hunting | 6-phase: scope → contract inventory → impact tracing → adversarial analysis → gap analysis → verification |
| [oneteam:skill] plan-authoring | Plan-writing methodology: task granularity, document structure, strategy-adapted sections |
| [oneteam:skill] team-collaboration | 4 principles: close the loop, never block silently, know ownership, speak up early |
| [oneteam:skill] team-management | 5-phase orchestration: analysis (conditional) → team setup → monitoring → review/merge → consolidation |
| [oneteam:skill] research | 3-phase: clarify → gather → synthesize |
| [oneteam:skill] self-review | 5-phase two-wave parallel pipeline: Phases 1-4 (spec compliance, code quality, test comprehensiveness, bug hunting) run in parallel with deduplication and consolidated fix, then Phase 5 (comprehensive review) with prior findings context |
| [oneteam:skill] spec-review | 6-phase: read spec → analyze codebase → quality check → issue identification → report → approval gate |
| [oneteam:skill] review-pr | 5-phase parallel pipeline: spec compliance, code quality, test comprehensiveness, bug hunting, comprehensive review with deduplication, user validation gate, and gh-pr-review posting |
| [oneteam:skill] post-review-comment | Posting reference: prerequisites, JSON format, line numbers, gh-pr-review commands |
| [oneteam:skill] review-navi | 5-phase interactive PR walkthrough: setup, pre-analysis dispatch, summary & TaskList, interactive walkthrough with structured AskUserQuestion pauses, completion with optional posting |
| [oneteam:skill] implementation | 2-phase: context discovery → verification + common best practices |
| [oneteam:skill] writing-tests | 5-phase: read spec → read implementation → merge and organize → write tests → verify |

### Pipeline

The standard development pipeline follows this flow:
1. [oneteam:skill] **`brainstorming`** → produces design document, optionally posts to GitHub issue
2. [oneteam:skill] **`writing-plans`** (override) → dispatches analyzer (sonnet) for triage, user picks strategy, dispatches [oneteam:agent] `architect` to write plan
3. **Execution** → [superpowers:skill] `subagent-driven-development` (subagent) or [oneteam:skill] `team-management` (team)
4. [oneteam:skill] **`self-review`** → pre-merge quality gate (spec compliance, code quality, tests, bugs, comprehensive review)

### Two Main Workflows

**Feature workflow:** [oneteam:agent] `lead-engineer` (feature mode) → invokes [oneteam:skill] `spec-review` skill → classifies tasks as [JUNIOR] or [SENIOR] → delegates to [oneteam:agent] `junior-engineer`/[oneteam:agent] `senior-engineer` → invokes [oneteam:skill] `self-review` → reviews → merges

**Debug workflow:** [oneteam:agent] `lead-engineer` (debug mode) → spawns [oneteam:agent] `bug-hunter` + [oneteam:agent] `junior-engineer`/[oneteam:agent] `senior-engineer` pairs (by severity) → reviews → merges

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
- **Phase completion TaskLists:** Must be explicitly completed — no skipping
- **Sequential merge:** Test verification after each merge
- **Escalation threshold:** Default 3 attempts before escalating
- **Agent naming:** `{group}-{role}-{N}` (e.g., `debug-bug-hunter-1`)
- **Max 4 fragments** per orchestration run
- **Code review mandatory** before any merge (via code-reviewer) — includes leader's own code

## Git Conventions

- Semantic commit prefixes: `feat:`, `docs:`, `fix:`
- Lowercase, concise messages focused on the change
