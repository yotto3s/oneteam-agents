# Junior & Senior Engineer Agents Design

**Goal:** Replace the generic `implementer` agent with two tier-specific agents
(`junior-engineer` and `senior-engineer`) that match model selection and workflow
to task complexity, and extract shared implementation practices into a reusable
skill.

**Architecture:** Shared base skill (`implementation`) + thin agents. The
`implementation` skill contains startup protocol, context discovery, common best
practices, and verification. Each agent adds tier-specific best practices and
planning behavior.

---

## New Artifact: `skills/implementation/SKILL.md`

A shared skill containing the workflow phases and best practices common to both
junior and senior engineers.

### Contents

**Startup Protocol:**
- Read `CLAUDE.md` at the worktree root (if it exists)
- Verify worktree access by listing root contents
- Detect mode (`team` / `subagent`); if `mode: team`, apply team-collaboration
  skill protocol

**Phase 1: Context Discovery**
- Read `CLAUDE.md` and `README.md` for project conventions
- Scan the scope area to understand relevant code
- Identify test framework, build system, and test commands
- If scope or task is unclear, ask for clarification — do not guess

**Common Best Practices:**
1. **Read before you write** — understand existing code, conventions, and the
   "why" behind current patterns before changing anything
2. **Stay in scope** — change only what the task requires; don't refactor,
   improve, or clean up surrounding code
3. **Atomic commits** — each commit is one logical change, leaves the codebase
   in a working state, uses semantic prefixes (`feat:`, `fix:`, `docs:`)
4. **Test after each change** — run the project's test suite after every
   meaningful change, not just at the end
5. **Self-review before reporting** — review your own diff before claiming
   completion; verify the change matches intent
6. **Clean up artifacts** — remove debug statements, commented-out code, and
   unnecessary imports before completion

Communication practices (never block silently, close the loop, speak up early)
are handled by the `team-collaboration` skill — not duplicated here.

**Phase 2: Verification**
- Run the project's test suite
- Confirm all tests pass (or that failures are pre-existing)
- Verify changes match the approved plan — no missing items, no extras
- Produce a completion report:

```
## Implementation Report

**Task:** <what was done>
**Changes:**
- <file>: <what changed>

**Verification:**
- Build: PASS / FAIL
- Tests: PASS / FAIL (details if fail)
- Plan coverage: all items completed / <list missing items>
```

**Skill Override:**
If the agent receives a skill directive (e.g., `systematic-debugging`), the
skill's process replaces the planning+implementation phases. Context Discovery
(Phase 1) and Verification (Phase 2) still wrap it.

---

## New Artifact: `agents/junior-engineer.md`

### Frontmatter

```yaml
name: junior-engineer
description: >-
  Handles trivial implementation tasks: boilerplate, CRUD, config changes,
  single-file edits. Receives detailed plans and follows them precisely.
  Works standalone or as a teammate in a team.
tools: Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch
model: sonnet
color: green
skills:
  - team-collaboration
  - implementation
```

### Workflow

1. Run implementation skill startup + Phase 1 (context discovery)
2. **No planning phase** — receives a detailed plan from the leader, reads it,
   confirms understanding, begins immediately
3. Implementation — execute the plan step by step
4. Run implementation skill Phase 2 (verification)

### Tier-Specific Best Practices

1. **Follow the plan literally** — execute steps in order as written; don't
   reinterpret, reorder, or "improve" the approach
2. **Don't over-engineer** — use the simplest solution that satisfies the
   requirement; avoid abstractions unless the plan calls for it
3. **Escalate after 3 failed attempts** — don't spin on a problem; report with
   what you tried

### Model Override

Default model is `sonnet`. Leaders can override to `haiku` at dispatch time via
the Task tool's `model` parameter for truly trivial tasks (single-file
boilerplate, config edits).

---

## New Artifact: `agents/senior-engineer.md`

### Frontmatter

```yaml
name: senior-engineer
description: >-
  Handles complex implementation tasks: multi-file changes, architectural work,
  novel logic, high-risk changes. Plans its own approach, gets approval, then
  implements. Works standalone or as a teammate in a team.
tools: Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch
model: opus
color: cyan
skills:
  - team-collaboration
  - implementation
```

### Workflow

1. Run implementation skill startup + Phase 1 (context discovery)
2. **Full planning phase** — analyze the task, create a plan (files to change,
   approach, rationale), send to leader/user for approval. **Hard gate: wait
   for approval.**
3. Implementation — execute the approved plan
4. Run implementation skill Phase 2 (verification)

### Tier-Specific Best Practices

1. **Map the blast radius before changing** — trace callers, dependents, and
   side effects before modifying shared interfaces or core logic
2. **Consider edge cases explicitly** — null/empty inputs, error paths,
   concurrency, boundary values
3. **Write tests for novel logic** — any new algorithm, business rule, or
   non-trivial conditional needs test coverage
4. **Prefer incremental over big-bang** — break large changes into smaller,
   independently verifiable steps
5. **Minimize coupling** — prefer contained changes; when touching shared
   interfaces, ensure backward compatibility or coordinate the migration

---

## Deleted Artifact: `agents/implementer.md`

Removed. Fully replaced by `junior-engineer.md` and `senior-engineer.md`.

---

## Changes to Existing Artifacts

### `skills/writing-plans/SKILL.md`

- **Phase 1 step 3 (Extract planning signals):** Extend complexity analysis to
  classify each task as `junior-engineer` or `senior-engineer` using the
  heuristic:

  | Signal | Junior | Senior |
  |--------|--------|--------|
  | File count | 1-2 files | 3+ files |
  | Coupling | Low — isolated change | High — touches shared interfaces |
  | Pattern | Well-understood (boilerplate, CRUD, config) | Novel or complex logic |
  | Risk | Low — failure is obvious and contained | High — subtle bugs, data corruption, security |
  | Codebase knowledge | Minimal — can work from instructions alone | Deep — requires understanding architecture |

- **Task structure `Agent role` field:** Outputs `junior-engineer` or
  `senior-engineer` instead of `implementer`
- **Optional `Model` field:** Add `Model: haiku` when a junior task is truly
  trivial (single-file boilerplate)

### `agents/lead-engineer.md`

- **Remove** the complexity heuristic table (moved to writing-plans)
- **Remove** all `[SELF]` implementation — no more Phase 3 self-implementation
- **Remove** `[DELEGATE]` vs `[SELF]` classification entirely
- **Becomes:** receive spec → review → invoke writing-plans → execute the plan
  via team-leadership or subagent-driven-development
- **Update** organization roles: replace single `implementer` role with
  `junior-engineer` and `senior-engineer`

### `agents/debug-team-leader.md`

- **Replace** `implementer` role with a severity-based choice:
  - LOW severity bugs → spawn `junior-engineer`
  - MEDIUM/HIGH severity bugs → spawn `senior-engineer`
- **Update** organization config and flow description

### `skills/team-leadership/SKILL.md`

- **Update** Example 2 (Feature Development Team) to show `junior-engineer`
  and `senior-engineer` roles instead of generic `implementer`

### `CLAUDE.md`

- **Update** agent table: remove `implementer` row, add `junior-engineer` and
  `senior-engineer` rows
- **Update** workflow descriptions to reference the new agents

### `README.md`

- **Update** agent table, workflow diagrams, and usage examples to reference
  `junior-engineer` and `senior-engineer` instead of `implementer`
