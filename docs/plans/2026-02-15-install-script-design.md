# Install Script Design

## Goal

Create `install.sh` that symlinks oneteam-agents' agents and skills into a Claude Code config directory, with optional superpowers support via git submodule. Superpowers items that are overridden by oneteam-agents are skipped.

## Architecture

### Sources

1. **oneteam-agents** — `agents/*.md` and `skills/*/` in this repo (always installed)
2. **superpowers** — git submodule at `external/superpowers/` (optional, user chooses)

### Override Detection

Filename-based: if oneteam-agents has `agents/X.md` or `skills/X/`, the matching superpowers item is skipped.

Current overrides:
- Agent: `code-reviewer.md`
- Skill: `writing-plans`

### CLI Interface

```
Usage: install.sh [OPTIONS]

Options:
  --target <path>       Target directory (default: interactive prompt, fallback ~/.claude)
  --with-superpowers    Install superpowers (skip prompt)
  --no-superpowers      Don't install superpowers (skip prompt)
  --uninstall           Remove symlinks pointing into this repo
  -h, --help            Show help
```

Interactive mode (no args): prompts for target dir and superpowers choice.

### Install Flow

1. Parse arguments
2. Prompt for target directory if not specified (default: `~/.claude`)
3. Prompt for superpowers if neither `--with-superpowers` nor `--no-superpowers`
4. If superpowers requested: ensure `external/superpowers` submodule is initialized
5. Create `$TARGET/agents/` and `$TARGET/skills/` directories
6. Collect override set from oneteam-agents filenames
7. Symlink all oneteam-agents agents (`agents/*.md` → `$TARGET/agents/`)
8. Symlink all oneteam-agents skills (`skills/*/` → `$TARGET/skills/`)
9. If superpowers: symlink non-overridden agents and skills
10. Print summary

### Symlink Strategy

- Per-file symlinks for agents (each `*.md` file)
- Per-directory symlinks for skills (each skill directory)
- Existing symlinks are overwritten (idempotent)
- Non-symlink files at target paths: warn and skip

### Uninstall Flow

1. Scan `$TARGET/agents/` and `$TARGET/skills/` for symlinks
2. Remove only those pointing into this repo's directory tree
3. Print what was removed

### Example Output

```
Install target [~/.claude]:
Install superpowers? (not needed if already installed as plugin) [y/N]: y
Initializing superpowers submodule...
Installing agents...
  + bug-hunter.md (oneteam-agents)
  + code-reviewer.md (oneteam-agents, overrides superpowers)
  + junior-engineer.md (oneteam-agents)
  + lead-engineer.md (oneteam-agents)
  + researcher.md (oneteam-agents)
  + senior-engineer.md (oneteam-agents)
Installing skills...
  + bug-hunting (oneteam-agents)
  + brainstorming (superpowers)
  + dispatching-parallel-agents (superpowers)
  + writing-plans (oneteam-agents, overrides superpowers)
  ...
Installed: 6 agents, 21 skills (skipped 2 superpowers overrides)
```
