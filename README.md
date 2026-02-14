# oneteam-agents

Reusable [Claude Code](https://docs.anthropic.com/en/docs/claude-code) agents
and skills for team-based debugging workflows.

## Agents

| Agent | Description |
|-------|-------------|
| **debug-team-leader** | Orchestrates a debugging sweep. Spawns tester/implementer pairs, reviews changes, merges fixes. |
| **implementer** | Generic implementation agent. Receives tasks with an optional skill directive. Falls back to a default workflow: context discovery, planning with approval gate, implementation, verification. |
| **tester** | Finds bugs and writes reproduction tests. Uses the finding-bugs skill, then verifies tests fail before handing findings to the implementer. |

## Skills

| Skill | Description |
|-------|-------------|
| **finding-bugs** | 6-phase bug discovery pipeline: scope definition, contract inventory, impact tracing, adversarial analysis, gap analysis, shallow verification. |
| **team-collaboration** | Communication protocol for multi-agent teams. Close the loop, never block silently, know who owns what, speak up early. |
| **team-leadership** | Full orchestration lifecycle: work analysis, team setup with git worktrees, agent spawning, progress monitoring, code review, sequential merge, cleanup. |

## How It Works

```
debug-team-leader (orchestrator)
├── tester (finds bugs with finding-bugs skill)
│   └── Produces: findings with reproduction tests
└── implementer (fixes bugs with systematic-debugging skill)
    └── Produces: fixes verified against reproduction tests

Leader reviews all changes → merges → reports
```

The **implementer** is generic — it can be directed to use any skill. When the
debug-team-leader spawns it, it tells the implementer to use
`systematic-debugging`. In other contexts, you could tell it to use a different
skill (e.g., `implement-feature`).

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

To use the implementer standalone for a task:

```
/agent implementer
```

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- The `systematic-debugging` skill (from the
  [superpowers](https://github.com/anthropics/claude-code-plugins) plugin) is
  required for the debug workflow
