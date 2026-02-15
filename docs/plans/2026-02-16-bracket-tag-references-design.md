# Bracket-Tag References for Skill and Agent Names

## Goal

Add `[source:type]` bracket tags to all skill and agent references in oneteam-agents files, making it unambiguous whether a name refers to a skill or agent and which package provides it.

## Format

**Tag syntax:** `[source:type]` placed immediately before the backtick-formatted name.

**Sources:**
- `oneteam` — defined in this repo (`skills/`, `agents/`)
- `superpowers` — defined in `external/superpowers/` only

**Types:**
- `skill` — references a skill
- `agent` — references an agent

**Examples:**
```markdown
Use [superpowers:skill] `subagent-driven-development`
invoke [oneteam:skill] `writing-plans`
Follow [oneteam:skill] `team-management`
spawn [oneteam:agent] `junior-engineer`
```

## Classification

| Name | Source | Type |
|------|--------|------|
| brainstorming | oneteam | skill |
| writing-plans | oneteam | skill |
| team-management | oneteam | skill |
| team-collaboration | oneteam | skill |
| implementation | oneteam | skill |
| bug-hunting | oneteam | skill |
| spec-review | oneteam | skill |
| plan-authoring | oneteam | skill |
| research | oneteam | skill |
| systematic-debugging | superpowers | skill |
| subagent-driven-development | superpowers | skill |
| executing-plans | superpowers | skill |
| receiving-code-review | superpowers | skill |
| requesting-code-review | superpowers | skill |
| test-driven-development | superpowers | skill |
| finishing-a-development-branch | superpowers | skill |
| using-git-worktrees | superpowers | skill |
| verification-before-completion | superpowers | skill |
| lead-engineer | oneteam | agent |
| junior-engineer | oneteam | agent |
| senior-engineer | oneteam | agent |
| architect | oneteam | agent |
| bug-hunter | oneteam | agent |
| code-reviewer | oneteam | agent |
| researcher | oneteam | agent |

## Scope

**Files to modify:**
- `CLAUDE.md`
- All 7 agent files: `agents/*.md`
- 6 skill files with cross-references: `skills/{brainstorming,writing-plans,bug-hunting,plan-authoring,team-management,implementation}/SKILL.md`

**What gets tagged:**
- Skill names in YAML `skills:` arrays
- Skill/agent names in markdown prose
- References in tables

**What does NOT get tagged:**
- YAML `name:` self-declarations (these define the name, not reference it)
- Generic English usage that happens to match a name (use judgment)

## Edge Cases

### Existing `superpowers:` prefix references
The `superpowers:` prefix moves into the bracket tag; the backtick name becomes clean:
```markdown
# Before
Use `superpowers:subagent-driven-development`

# After
Use [superpowers:skill] `subagent-driven-development`
```

### Skill tool invocation strings
When the text contains actual Skill tool call syntax, the `superpowers:` prefix stays in the invocation string (Claude Code needs it for resolution), and the bracket tag is added for readability:
```markdown
invoke the Skill tool with [superpowers:skill] `skill: "superpowers:requesting-code-review"`
```

### Table cells
Tags go in the Name column:
```markdown
| [oneteam:agent] lead-engineer | opus | Orchestrates... |
```

### Plain prose references without backticks
Add both the tag and backticks:
```markdown
# Before
invoke writing-plans skill

# After
invoke [oneteam:skill] `writing-plans`
```

## Non-goals

- No changes to superpowers files (external submodule)
- No changes to install script or resolution logic
- No runtime behavior changes — this is purely documentation/readability
