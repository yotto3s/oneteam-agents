# oneteam-agents

Reusable [Claude Code](https://docs.anthropic.com/en/docs/claude-code) agents
and skills for team-based debugging workflows.

## Agents

| Agent | Description |
|-------|-------------|
| **debug-team-leader** | Orchestrates a debugging sweep. Spawns bug-hunter/engineer pairs (junior or senior based on severity), reviews changes, merges fixes. |
| **junior-engineer** | Handles trivial tasks: boilerplate, CRUD, config, single-file edits. Follows detailed plans precisely. Default model: sonnet (overridable to haiku). |
| **senior-engineer** | Handles complex tasks: multi-file changes, architectural work, novel logic. Plans own approach. Always uses opus model. |
| **bug-hunter** | Finds bugs and writes reproduction tests. Uses the bug-hunting skill, then verifies tests fail before handing findings to the paired engineer. |
| **lead-engineer** | Pure orchestrator. Receives specs, reviews them, creates implementation plans, delegates all work to junior and senior engineers. Uses opus model. |
| **code-reviewer** | Reviews code changes for bugs, security issues, and spec conformance. Read-only -- does not modify code. Communicates via team-collaboration protocol. |
| **researcher** | Searches web and codebase for information, returns structured summaries. Uses sonnet model. |

## Skills

| Skill | Description |
|-------|-------------|
| **bug-hunting** | 6-phase bug discovery pipeline: scope definition, contract inventory, impact tracing, adversarial analysis, gap analysis, shallow verification. |
| **team-collaboration** | Communication protocol for multi-agent teams. Close the loop, never block silently, know who owns what, speak up early. |
| **team-leadership** | Full orchestration lifecycle: work analysis, team setup with git worktrees, agent spawning, progress monitoring, code review, sequential merge, cleanup. |
| **writing-plans** | 4-phase pipeline override: design analysis, strategy decision (subagent vs team), plan writing with bite-sized TDD tasks, execution handoff. |
| **implementation** | Shared workflow for engineer agents: startup protocol, context discovery, common best practices, verification, and reporting. |

## How It Works

```
debug-team-leader (orchestrator)
├── bug-hunter (finds bugs with bug-hunting skill)
│   └── Produces: findings with reproduction tests
└── junior-engineer / senior-engineer (fixes bugs with systematic-debugging skill)
    └── Produces: fixes verified against reproduction tests

Leader reviews all changes → merges → reports
```

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

The **junior-engineer** and **senior-engineer** share a common `implementation`
skill for context discovery, best practices, and verification. The junior
follows plans precisely; the senior plans its own approach. When the
debug-team-leader spawns them, it tells them to use `systematic-debugging`.

## Installation

Clone the repository:

```bash
git clone <repo-url> ~/oneteam-agents
```

Symlink agents and skills into your Claude Code config:

```bash
# Back up existing directories if needed
mv ~/.claude/agents ~/.claude/agents.bak
mv ~/.claude/skills ~/.claude/skills.bak

# Create symlinks
ln -s ~/oneteam-agents/agents ~/.claude/agents
ln -s ~/oneteam-agents/skills ~/.claude/skills
```

Verify the symlinks:

```bash
ls -la ~/.claude/agents
ls -la ~/.claude/skills
```

## Usage

To run a debugging sweep on a codebase, use the `debug-team-leader` agent:

```
/agent debug-team-leader
```

To use a junior engineer for a simple task:

```
/agent junior-engineer
```

To use a senior engineer for a complex task:

```
/agent senior-engineer
```

To use the lead engineer for feature development:

```
/agent lead-engineer
```

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- The `systematic-debugging` skill (from the
  [superpowers](https://github.com/anthropics/claude-plugins-official) plugin) is
  required for the debug workflow
