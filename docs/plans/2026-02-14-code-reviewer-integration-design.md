# Code-Reviewer Integration Design

## Problem

The lead-engineer currently reviews implementer code and its own code manually
in Phase 5. We want a dedicated code-reviewer agent to handle reviews, improving
quality and separation of concerns.

## Design Decisions

- **Agent**: Create `agents/code-reviewer.md` -- thin agent with `team-collaboration` skill
- **Built-in type**: Not used directly, since the built-in `superpowers:code-reviewer` lacks `team-collaboration`
- **Communication**: Code-reviewer joins the team as a teammate, uses SendMessage
- **Review timing**: After each implementer completes + after all lead-engineer [SELF] tasks complete
- **Spec conformance**: Stays with lead-engineer (domain expertise, not code-reviewer's job)

## Files

### New: `agents/code-reviewer.md`

- **Tools**: Read, Glob, Grep, Bash (read-only -- does not modify code)
- **Model**: inherit
- **Color**: cyan
- **Skills**: team-collaboration

### Modified: `agents/lead-engineer.md`

Add `code-reviewer` role to the organization config:

```yaml
roles:
  - name: "implementer"
    agent_type: "implementer"
    starts_first: true
    ...
  - name: "reviewer"
    agent_type: "code-reviewer"
    starts_first: false
    instructions: |
      Review code changes against the implementation plan and project
      conventions. Check for bugs, security issues, and spec conformance.
      Send findings to the lead engineer. If issues are found in
      implementer code, you may also message the implementer directly.
flow: "... -> reviewer reviews implementer -> ... -> reviewer reviews lead-engineer -> converge"
```

### Modified: `skills/lead-engineering/SKILL.md`

**Phase 4 -- add review of [SELF] tasks:**
- After all [SELF] tasks are implemented: spawn code-reviewer to review lead-engineer's own commits
- If issues found: fix, re-commit, re-request review
- HARD requirement: must pass review before Phase 5

**Phase 5 -- delegate implementer review to code-reviewer:**
- Replace manual diff reading with code-reviewer agent
- Code-reviewer reviews each implementer's work, sends findings to lead-engineer
- Lead-engineer relays fixable issues to implementer
- Lead-engineer still does spec conformance check (step 4)

**Constraints -- add:**
- NEVER merge code that hasn't passed code-reviewer review
- Code-reviewer reviews are mandatory even for trivial changes

### Modified: `README.md`

Update lead-engineer workflow diagram to show code-reviewer.
