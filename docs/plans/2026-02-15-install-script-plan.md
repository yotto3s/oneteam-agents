# Install Script Implementation Plan

**Goal:** Create `install.sh` that symlinks oneteam-agents and (optionally) superpowers agents/skills into a Claude Code config directory, with automatic override detection.

**Architecture:** Single bash script at repo root. Superpowers source is a git submodule at `external/superpowers/`. Override detection is filename-based — oneteam-agents items always win. Per-file symlinks for agents, per-directory symlinks for skills.

**Tech Stack:** Bash, git submodules

**Strategy:** Subagent-driven

---

### Task 1: Add superpowers git submodule

**Files:**
- Create: `.gitmodules`
- Create: `external/superpowers/` (submodule checkout)

**Agent role:** junior-engineer

**Step 1: Add the submodule**

```bash
cd /home/yotto/oneteam-agents
git submodule add https://github.com/anthropics/claude-plugins-official external/superpowers
```

**Step 2: Verify submodule was added**

```bash
cat .gitmodules
```

Expected: Shows `[submodule "external/superpowers"]` with path and url.

```bash
ls external/superpowers/agents/ external/superpowers/skills/
```

Expected: Lists agents and skills directories from the superpowers repo.

**Step 3: Commit**

```bash
git add .gitmodules external/superpowers
git commit -m "feat: add superpowers as git submodule"
```

---

### Task 2: Write install.sh

**Files:**
- Create: `install.sh`

**Agent role:** senior-engineer

**Step 1: Write the install script**

Create `install.sh` at repo root with executable permissions. The script must implement:

**Argument parsing:**
- `--target <path>` — sets target directory, skips prompt
- `--with-superpowers` — enables superpowers install, skips prompt
- `--no-superpowers` — disables superpowers install, skips prompt
- `--uninstall` — uninstall mode
- `-h` / `--help` — show usage

**Helper: `SCRIPT_DIR`**
Resolve the directory where install.sh lives (the repo root), using:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

**Interactive prompts (when args not provided):**
```
Install target [~/.claude]: <user input or enter for default>
Install superpowers? (not needed if already installed as plugin) [y/N]: <user input>
```

**Install logic:**

1. Create `$TARGET/agents/` and `$TARGET/skills/` via `mkdir -p`
2. Build override set: collect basenames from `$SCRIPT_DIR/agents/*.md` and directory names from `$SCRIPT_DIR/skills/*/`
3. Symlink oneteam-agents agents: for each `$SCRIPT_DIR/agents/*.md`, create symlink at `$TARGET/agents/<basename>`:
   - If target is already a symlink: remove and recreate (`ln -sf`)
   - If target is a regular file: warn and skip
   - Track count and print `+ <name> (oneteam-agents)`
   - If the same basename exists in superpowers, append `(overrides superpowers)` to the message
4. Symlink oneteam-agents skills: for each `$SCRIPT_DIR/skills/*/`, create symlink at `$TARGET/skills/<dirname>`:
   - Same conflict handling as agents
   - Track count and print `+ <name> (oneteam-agents)`
5. If superpowers enabled:
   - Initialize submodule if needed: `git -C "$SCRIPT_DIR" submodule update --init external/superpowers`
   - Verify `$SCRIPT_DIR/external/superpowers/agents/` and `skills/` exist
   - Symlink superpowers agents NOT in override set
   - Symlink superpowers skills NOT in override set
   - Track skipped count
6. Print summary: `Installed: N agents, M skills (skipped K superpowers overrides)`

**Uninstall logic:**

1. Scan `$TARGET/agents/` and `$TARGET/skills/` for symlinks
2. For each symlink, check if its target starts with `$SCRIPT_DIR/`
3. If yes, remove and print `- <name>`
4. Print summary: `Removed: N agents, M skills`

**Step 2: Make executable**

```bash
chmod +x install.sh
```

**Step 3: Test install mode with superpowers**

```bash
./install.sh --target /tmp/test-claude --with-superpowers
ls -la /tmp/test-claude/agents/ /tmp/test-claude/skills/
```

Expected:
- All 6 oneteam-agents agents symlinked
- All 7 oneteam-agents skills symlinked
- Superpowers agents except `code-reviewer.md` symlinked
- Superpowers skills except `writing-plans` symlinked
- Summary line matches counts

**Step 4: Test install mode without superpowers**

```bash
rm -rf /tmp/test-claude
./install.sh --target /tmp/test-claude --no-superpowers
ls -la /tmp/test-claude/agents/ /tmp/test-claude/skills/
```

Expected:
- Only oneteam-agents items symlinked
- No superpowers items

**Step 5: Test uninstall mode**

```bash
./install.sh --uninstall --target /tmp/test-claude
ls /tmp/test-claude/agents/ /tmp/test-claude/skills/
```

Expected:
- All symlinks removed
- Directories may remain but are empty

**Step 6: Test idempotency**

```bash
./install.sh --target /tmp/test-claude --with-superpowers
./install.sh --target /tmp/test-claude --with-superpowers
```

Expected: No errors, same result both times.

**Step 7: Cleanup test dir and commit**

```bash
rm -rf /tmp/test-claude
git add install.sh
git commit -m "feat: add install script with superpowers support"
```

---

### Task 3: Update CLAUDE.md install instructions

**Files:**
- Modify: `CLAUDE.md:9-13`

**Agent role:** junior-engineer

**Step 1: Update the install section**

Replace the current symlink instructions in CLAUDE.md (lines 9-13) with:

```markdown
Installed via the install script:
```
./install.sh
```

Or with flags for non-interactive use:
```
./install.sh --target ~/.claude --with-superpowers
```

Superpowers is included as a git submodule at `external/superpowers/`. The install script automatically skips superpowers agents/skills that oneteam-agents overrides.
```

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update install instructions for install.sh"
```

---

## Execution: Subagent-Driven

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> to execute this plan task-by-task.

**Task Order:** Sequential, dependency-respecting order listed below.

1. Task 1: Add superpowers git submodule — no dependencies
2. Task 2: Write install.sh — depends on Task 1 (needs submodule present for testing)
3. Task 3: Update CLAUDE.md — no dependencies (can run after Task 2)

Each task is self-contained with full context. Execute one at a time with
fresh subagent per task and two-stage review (spec compliance, then code
quality).
