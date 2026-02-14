# Code-Reviewer Integration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a code-reviewer agent that reviews both implementer code and lead-engineer's own code, integrated into the lead-engineering workflow.

**Architecture:** Create a thin code-reviewer agent with team-collaboration skill and read-only tools. Modify lead-engineer's organization config to include a reviewer role. Update the lead-engineering skill to spawn code-reviewers at two points: after implementer completion (Phase 5) and after all [SELF] tasks (Phase 4).

**Tech Stack:** Claude Code agents and skills (markdown files with YAML frontmatter)

---

### Task 1: Create code-reviewer agent definition

**Files:**
- Create: `agents/code-reviewer.md`

**Reference:** `agents/tester.md` for read-only agent pattern. `agents/implementer.md` for startup structure.

**Step 1: Write the agent file**

Create `agents/code-reviewer.md` with this exact content:

```markdown
---
name: code-reviewer
description: >-
  Reviews code changes for bugs, security issues, spec conformance, and project
  convention adherence. Read-only -- does not modify code. Sends findings to the
  requesting agent via SendMessage. Works as a teammate in any team context.
tools: Read, Glob, Grep, Bash
model: inherit
color: cyan
skills:
  - team-collaboration
---

# Code Reviewer

You are a code reviewer agent. You review code changes and report findings to
the agent who requested the review. You do NOT modify code -- you only read
and analyze it.

Follow the **team-collaboration** skill for all communication.

## Startup

When spawned, you receive initialization context that may include:

- **Worktree path**: the Git worktree containing the code to review
- **Leader name**: the agent who requested the review
- **Diff scope**: which commits, branches, or files to review
- **Review criteria**: what to check for (provided by the requesting agent)
- **Implementation plan**: the plan the code was built against

Execute these steps immediately on startup:

1. Read `CLAUDE.md` at the worktree root (if it exists) to learn project
   conventions, build commands, and coding standards.
2. Verify you can access the worktree by listing its root contents.
3. Send a ready message to the leader via SendMessage:
   `"Code reviewer ready. Worktree: <path>."`

If the diff scope is missing from your initialization context, ask your leader
for it before proceeding. Do NOT review the entire codebase without a scope.

## Review Process

1. **Gather the diff.** Use `git diff` or `git log` to obtain the changes
   in scope. Read the full diff.

2. **Read the implementation plan** (if provided) to understand what was
   intended.

3. **Review the changes** against these criteria:
   - **Correctness**: Does the code do what it's supposed to? Are there logic
     errors, off-by-one mistakes, or missed edge cases?
   - **Security**: Are there injection vulnerabilities, exposed secrets,
     unsafe input handling, or missing authorization checks?
   - **Spec conformance**: Does the implementation match the plan and
     acceptance criteria?
   - **Conventions**: Does the code follow project conventions from CLAUDE.md?
     Naming, formatting, patterns, directory structure?
   - **Test coverage**: Are new code paths tested? Do tests verify behavior
     (not just mock interactions)?
   - **Regressions**: Could any change break existing functionality?
   - **Custom criteria**: Apply any additional review criteria provided by
     the requesting agent.

4. **Produce the Review Report.** Format:

   ```
   ## Code Review Report

   **Scope:** <what was reviewed -- commits, files, branch>
   **Reviewed for:** <who requested the review>

   ### Findings

   #### [CR1] Severity: HIGH | file.py:123
   **Category:** Bug / Security / Spec mismatch / Convention / Missing test
   **What:** One-sentence description.
   **Suggestion:** How to fix it.

   #### [CR2] Severity: MEDIUM | file.py:45
   ...

   ### Strengths
   - <what was done well>

   ### Summary
   - X findings (H high, M medium, L low)
   - Assessment: APPROVED / CHANGES NEEDED
   ```

5. **Send the report** to the leader via SendMessage.

6. **Handle follow-up.** If the leader requests a re-review after fixes:
   - Gather the updated diff.
   - Verify each previous finding is addressed.
   - Report which findings are resolved and which remain.

## Severity Levels

- **HIGH**: Bug, security vulnerability, data corruption, or crash.
- **MEDIUM**: Spec mismatch, missing test, convention violation with impact.
- **LOW**: Style nit, minor convention deviation, suggestion for improvement.

## Assessment Criteria

- **APPROVED**: No HIGH findings. Any MEDIUM findings are acknowledged.
- **CHANGES NEEDED**: One or more HIGH findings, or multiple unresolved MEDIUM
  findings.

## Constraints

- NEVER modify code. You are read-only.
- NEVER approve code with unresolved HIGH findings.
- ALWAYS read the actual code -- do not trust summaries or claims about what
  was implemented.
- ALWAYS send findings to the requesting agent via SendMessage.
- ALWAYS check for security issues, even if not explicitly asked.
- If you cannot determine whether something is a bug, mark it as MEDIUM with
  an explanation and let the requesting agent decide.
```

**Step 2: Verify the file**

Run: `head -5 agents/code-reviewer.md`
Expected: YAML frontmatter starting with `---` and `name: code-reviewer`

**Step 3: Commit**

```bash
git add agents/code-reviewer.md
git commit -m "feat: add code-reviewer agent definition"
```

---

### Task 2: Update lead-engineer organization config

**Files:**
- Modify: `agents/lead-engineer.md:70-86`

**Step 1: Replace the organization YAML block**

In `agents/lead-engineer.md`, replace the `organization` section (lines 72-86) -- the YAML code block -- with this updated version that adds the reviewer role:

Replace:

````markdown
```yaml
group: "feature"
roles:
  - name: "implementer"
    agent_type: "implementer"
    starts_first: true
    instructions: |
      Implement the delegated tasks per the provided plan. Each task has
      exact file paths, step-by-step instructions, and acceptance criteria.
      Follow your default workflow (context discovery, planning is already
      done -- skip to implementation, then verification). Report completion
      to the lead engineer.
flow: "lead-engineer plans -> implementer builds delegated tasks -> lead-engineer reviews -> converge"
escalation_threshold: 3
```
````

With:

````markdown
```yaml
group: "feature"
roles:
  - name: "implementer"
    agent_type: "implementer"
    starts_first: true
    instructions: |
      Implement the delegated tasks per the provided plan. Each task has
      exact file paths, step-by-step instructions, and acceptance criteria.
      Follow your default workflow (context discovery, planning is already
      done -- skip to implementation, then verification). Report completion
      to the lead engineer.
  - name: "reviewer"
    agent_type: "code-reviewer"
    starts_first: false
    instructions: |
      Review code changes against the implementation plan and project
      conventions. Check for bugs, security issues, spec conformance, and
      test coverage. Send findings to the lead engineer. If issues are
      found in implementer code, you may also message the implementer
      directly with specific fix suggestions.
flow: "lead-engineer plans -> implementer builds -> reviewer reviews implementer -> lead-engineer implements hard parts -> reviewer reviews lead-engineer -> converge"
escalation_threshold: 3
```
````

**Step 2: Verify**

Run: `grep -A2 "reviewer" agents/lead-engineer.md`
Expected: Shows the new reviewer role definition

**Step 3: Commit**

```bash
git add agents/lead-engineer.md
git commit -m "feat: add code-reviewer role to lead-engineer organization config"
```

---

### Task 3: Update lead-engineering skill Phase 4 -- add self-review step

**Files:**
- Modify: `skills/lead-engineering/SKILL.md:208-244`

**Step 1: Add "Self-Code Review" subsection after Delegation Monitoring**

In `skills/lead-engineering/SKILL.md`, after the "### Ordering" subsection (after line 244), insert a new subsection before Phase 5. Find this text:

```
- When a `[SELF]` task depends on a `[DELEGATE]` task, wait for the
  implementer to complete and for the review to pass before starting
  the dependent `[SELF]` task.
```

After it, insert:

```markdown

### Self-Code Review

After all `[SELF]` tasks are implemented and committed, the lead engineer's own
code must be reviewed before proceeding to Phase 5.

1. **Spawn a code-reviewer agent** with:
   - The worktree path
   - Diff scope: all commits by the lead engineer for `[SELF]` tasks
   - The implementation plan (for spec conformance checking)
   - The review criteria from the agent's domain configuration
   - Leader name: this agent
2. **Wait for the review report.**
3. **If CHANGES NEEDED:**
   - Fix each finding.
   - Re-commit.
   - Request re-review from the code-reviewer.
   - Repeat until APPROVED.
4. **If APPROVED:** Proceed to Phase 5.

This review is mandatory. Do NOT proceed to Phase 5 with unreviewed self-code.
```

**Step 2: Verify**

Run: `grep "Self-Code Review" skills/lead-engineering/SKILL.md`
Expected: Shows the new heading

**Step 3: Commit**

```bash
git add skills/lead-engineering/SKILL.md
git commit -m "feat: add self-code review step to lead-engineering Phase 4"
```

---

### Task 4: Update lead-engineering skill Phase 5 -- delegate reviews to code-reviewer

**Files:**
- Modify: `skills/lead-engineering/SKILL.md:253-259` (Phase 5, step 1)

**Step 1: Replace step 1 of Phase 5**

In `skills/lead-engineering/SKILL.md`, find this text in Phase 5:

```markdown
1. **Review implementer changes.** For each implementer's work:
   - Read the diff against the base branch.
   - Check against the plan's acceptance criteria.
   - Check against the review criteria (spec match, no scope creep,
     conventions followed, tests present, no regressions).
   - If issues found: send feedback via SendMessage, wait for fixes,
     re-review. Repeat until approved.
```

Replace with:

```markdown
1. **Review implementer changes via code-reviewer.** For each implementer's
   completed work:
   a. Spawn a code-reviewer agent (or reuse one already in the team) with:
      - The worktree path containing the implementer's changes
      - Diff scope: the implementer's commits against the base branch
      - The implementation plan (tasks assigned to this implementer)
      - The review criteria from the agent's domain configuration
      - Leader name: this agent
   b. Wait for the code-reviewer's report.
   c. If CHANGES NEEDED: relay the findings to the implementer via
      SendMessage with specific file paths and fix suggestions. Wait for
      fixes, then request re-review from the code-reviewer. Repeat until
      APPROVED.
   d. If APPROVED: proceed to the next implementer's review or to step 2.
```

**Step 2: Verify**

Run: `grep "via code-reviewer" skills/lead-engineering/SKILL.md`
Expected: Shows the updated step text

**Step 3: Commit**

```bash
git add skills/lead-engineering/SKILL.md
git commit -m "feat: delegate implementer review to code-reviewer in Phase 5"
```

---

### Task 5: Update lead-engineering skill Constraints and Quick Reference

**Files:**
- Modify: `skills/lead-engineering/SKILL.md` (Constraints section and Quick Reference)

**Step 1: Add two constraints**

In `skills/lead-engineering/SKILL.md`, find the Constraints section. After the line:

```
- When an implementer is stuck, prefer taking over the task yourself rather
  than letting it stall indefinitely.
```

Add:

```markdown
- NEVER merge code that has not passed code-reviewer review -- both
  implementer code and lead-engineer's own code.
- Code-reviewer reviews are mandatory even for changes that appear trivial.
```

**Step 2: Update Quick Reference table**

Replace the Phase 4 and Phase 5 rows:

Find:
```
| 4. Execution | Setup + plan | Implemented tasks (self + delegated) | No |
| 5. Integration & Verification | All completed tasks | Completion Report | No |
```

Replace with:
```
| 4. Execution | Setup + plan | Implemented tasks (self + delegated), self-code review passed | No |
| 5. Integration & Verification | All completed tasks | Completion Report, all code-reviewer reviews passed | No |
```

**Step 3: Verify**

Run: `grep "code-reviewer review" skills/lead-engineering/SKILL.md`
Expected: Shows the two new constraints

**Step 4: Commit**

```bash
git add skills/lead-engineering/SKILL.md
git commit -m "feat: add code-reviewer constraints and update quick reference"
```

---

### Task 6: Update README.md

**Files:**
- Modify: `README.md`

**Step 1: Add code-reviewer to agents table**

In `README.md`, after the lead-engineer row in the Agents table (line 13), add:

```markdown
| **code-reviewer** | Reviews code changes for bugs, security issues, and spec conformance. Read-only -- does not modify code. Communicates via team-collaboration protocol. |
```

**Step 2: Update lead-engineer workflow diagram**

In `README.md`, replace the lead-engineer diagram (lines 36-44):

Find:
```
lead-engineer (spec-driven development)
├── Reviews spec and creates implementation plan
├── Classifies tasks: [DELEGATE] vs [SELF]
├── implementer (handles trivial delegated tasks)
│   └── Produces: implemented features per plan
└── lead-engineer implements hard tasks directly
    └── Reviews all changes → merges → reports
```

Replace with:
```
lead-engineer (spec-driven development)
├── Reviews spec and creates implementation plan
├── Classifies tasks: [DELEGATE] vs [SELF]
├── implementer (handles trivial delegated tasks)
│   └── code-reviewer reviews implementer's code
├── lead-engineer implements hard tasks directly
│   └── code-reviewer reviews lead-engineer's own code
└── Merges all reviewed changes → reports
```

**Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add code-reviewer to README and update workflow diagram"
```

---

### Task 7: Final verification

**Step 1: Check all files exist**

Run: `ls -la agents/code-reviewer.md agents/lead-engineer.md skills/lead-engineering/SKILL.md README.md`
Expected: all files exist

**Step 2: Verify code-reviewer agent**

Run: `grep "color: cyan" agents/code-reviewer.md && grep "team-collaboration" agents/code-reviewer.md`
Expected: both matches found

**Step 3: Verify reviewer role in lead-engineer**

Run: `grep "code-reviewer" agents/lead-engineer.md`
Expected: shows agent_type reference to code-reviewer

**Step 4: Verify skill has code review steps**

Run: `grep -c "code-reviewer" skills/lead-engineering/SKILL.md`
Expected: multiple matches (Phase 4 self-review, Phase 5 implementer review, constraints)

**Step 5: Verify git log**

Run: `git log --oneline -8`
Expected: 5 new commits for code-reviewer integration
