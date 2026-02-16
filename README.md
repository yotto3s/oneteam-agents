# oneteam-agents

Reusable [Claude Code](https://docs.anthropic.com/en/docs/claude-code) agents
and skills for team-based debugging and feature development workflows.

## Agents

| Agent | Model | Description |
|-------|-------|-------------|
| **architect** | inherit | Reads design docs and codebase, writes implementation plans. Read-only codebase access. |
| **junior-engineer** | sonnet | Handles trivial tasks: boilerplate, CRUD, config, single-file edits. Follows detailed plans precisely. |
| **senior-engineer** | opus | Handles complex tasks: multi-file changes, architectural work, novel logic. Plans own approach. |
| **bug-hunter** | inherit | Finds bugs and writes reproduction tests. Uses the bug-hunting skill, then verifies tests fail before handing findings to the paired engineer. |
| **lead-engineer** | opus | Orchestrates feature implementation or debugging sweeps. In feature mode: reviews specs via spec-review skill, plans, delegates. In debug mode: spawns bug-hunter/engineer pairs by severity. |
| **researcher** | haiku | Searches web and codebase for information, returns structured summaries. |

## Skills

| Skill | Description |
|-------|-------------|
| **brainstorming** | Collaborative design exploration: understand project context, ask clarifying questions one at a time, propose 2-3 approaches with trade-offs, present design for approval, write design doc, optionally post to GitHub issue, then hand off to writing-plans. |
| **bug-hunting** | 6-phase bug discovery pipeline: scope definition, contract inventory, impact tracing, adversarial analysis, gap analysis, shallow verification. |
| **implementation** | Shared workflow for engineer agents: startup protocol, context discovery, common best practices, verification, and reporting. |
| **plan-authoring** | Plan-writing methodology for the architect agent. Defines bite-sized task granularity, plan document structure, strategy-adapted execution sections, and quality constraints. |
| **research** | 3-phase pipeline: clarify question, gather from web and codebase, synthesize structured summary. |
| **review-pr** | 5-phase parallel PR review pipeline: spec compliance, code quality, test comprehensiveness, bug hunting, comprehensive review with deduplication, user validation gate, and gh-pr-review posting. |
| **self-review** | 5-phase pre-merge quality gate: spec compliance, code quality, test comprehensiveness, bug hunting, comprehensive review. Each phase spawns reviewer/bug-hunter subagents and engineers for fixes. Produces a PASS/FAIL Self-Review Report. |
| **spec-review** | 6-phase spec quality review: read & understand, analyze codebase, quality check (IEEE 830/INVEST/Wiegers criteria), issue identification, report generation, approval gate. |
| **team-collaboration** | Communication protocol for multi-agent teams. Close the loop, never block silently, know who owns what, speak up early. |
| **team-management** | Full orchestration lifecycle: work analysis, team setup with git worktrees, agent spawning, progress monitoring, code review, sequential merge, cleanup. |
| **writing-plans** | 4-phase pipeline override: design analysis, strategy decision (subagent vs team), plan writing with bite-sized TDD tasks, execution handoff. |

## How It Works

```
lead-engineer (orchestrator — feature mode)
├── Invokes spec-review skill
├── Reviews spec and creates implementation plan
├── Classifies tasks: [JUNIOR] vs [SENIOR]
├── junior-engineer (handles trivial tasks)
├── senior-engineer (handles complex tasks)
├── Invokes self-review skill (5-phase quality gate)
└── Reviews all changes (via code-reviewer) → merges → reports
```

```
lead-engineer (orchestrator — debug mode)
├── Analyzes codebase for debuggable fragments
├── bug-hunter (finds bugs with bug-hunting skill)
│   └── Produces: findings with reproduction tests
└── junior-engineer / senior-engineer (fixes bugs with systematic-debugging skill)
    └── Produces: fixes verified against reproduction tests

Leader reviews all changes → merges → reports
```

The **junior-engineer** and **senior-engineer** share a common `implementation`
skill for context discovery, best practices, and verification. The junior
follows plans precisely; the senior plans its own approach. In debug mode, the
lead-engineer tells engineers to use `systematic-debugging`.

## Installation

Clone the repository:

```bash
git clone <repo-url> ~/oneteam-agents
cd ~/oneteam-agents
git submodule update --init
```

Run the install script:

```bash
./install.sh
```

Or with flags for non-interactive use:

```bash
./install.sh --target ~/.claude --with-superpowers
```

To uninstall:

```bash
./install.sh --uninstall
```

## Usage

To use the lead engineer for feature development or debugging:

```
/agent lead-engineer
```

To use a junior engineer for a simple task:

```
/agent junior-engineer
```

To use a senior engineer for a complex task:

```
/agent senior-engineer
```

## When to Use Which Skill

Use this guide to pick the right skill for your situation. Skills are invoked
automatically by agents, but knowing which one fits your goal helps you start
the right workflow.

### Decision Tree

```
What do you want to do?
|
+-- Build something new
|   +-- Have a clear idea?
|      +-- No  --> brainstorming
|      +-- Yes --> Have a written spec?
|         +-- No  --> writing-plans
|         +-- Yes --> Is the spec solid?
|            +-- Unsure --> spec-review
|            +-- Yes   --> How complex?
|               +-- Small (few tasks)  --> subagent-driven-development*
|               +-- Large (many tasks) --> team-management
|
+-- Review changes before merge
|   +-- self-review
|
+-- Fix or investigate bugs
|   +-- Have a specific error/failure?
|      +-- Yes --> systematic-debugging*
|      +-- No  --> Proactive bug hunting?
|         +-- Yes --> bug-hunting
|         +-- No  --> Full debug sweep?
|            +-- Small scope --> subagent-driven-development*
|            +-- Large scope --> team-management
|
+-- Research something
    +-- research
```

### Example Scenarios

**Building Features**

| Scenario | Skill | What happens |
|----------|-------|--------------|
| "I have a vague idea for a new auth system" | brainstorming | Asks clarifying questions, proposes approaches, writes design doc, hands off to writing-plans |
| "I have requirements, need a plan" | writing-plans | Analyzes complexity, picks strategy (subagent vs team), dispatches architect to write plan |
| "I have a spec but I'm not sure it's complete" | spec-review | Reviews against IEEE 830/INVEST criteria, identifies gaps, produces quality report |
| "Plan is ready, 3 independent tasks" | subagent-driven-development\* | Spawns fresh subagent per task, two-stage review after each |
| "Plan is ready, 10+ tasks, needs coordination" | team-management | Sets up team with worktrees, spawns engineers, monitors progress, reviews, merges |
| "Implementation is done, review before merge" | self-review | Runs 5-phase pipeline: spec compliance, code quality, test comprehensiveness, bug hunting, comprehensive review. Spawns fixers for issues found. Produces PASS/FAIL report. |

**Tip:** Even when you have a concrete plan, consider starting with
`brainstorming` -- it often surfaces missing requirements and edge cases before
you commit to implementation.

**Debugging**

| Scenario | Skill | What happens |
|----------|-------|--------------|
| "Tests are failing with this error message" | systematic-debugging\* | Structured debugging: reproduce, hypothesize, isolate, fix, verify |
| "I suspect there are bugs in the auth module but nothing is failing yet" | bug-hunting | 6-phase audit: scope, contracts, impact tracing, adversarial analysis, gap analysis, shallow verification & report |
| "Full codebase debug sweep after a big refactor" | team-management | Spawns bug-hunter + engineer pairs, coordinates fixes |

**Research & Planning**

| Scenario | Skill | What happens |
|----------|-------|--------------|
| "How does the caching layer work in this codebase?" | research | Searches codebase and web, returns structured summary |
| "Find best practices for WebSocket auth" | research | Web search + synthesis, returns actionable summary |

Skills marked with \* (`subagent-driven-development`, `systematic-debugging`)
come from [superpowers](https://github.com/obra/superpowers.git), included as a
git submodule at `external/superpowers/`. The install script automatically skips
superpowers agents/skills that oneteam-agents overrides.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- [Superpowers](https://github.com/obra/superpowers.git) (included as a git
  submodule) — provides `systematic-debugging`, `subagent-driven-development`,
  and other foundational skills
