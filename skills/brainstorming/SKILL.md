---
name: brainstorming
description: >-
  Use when starting creative work -- creating features, building components, adding functionality, or modifying behavior -- and you need to explore intent and design before implementation.
---

# Brainstorming Ideas Into Designs

## Overview

Turn ideas into designs through collaborative dialogue. Explore context, ask questions one at a time, propose approaches, get design approval, then hand off to planning.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity — "simple" projects are where unexamined assumptions cause the most wasted work. The design can be short (a few sentences for truly simple projects), but you MUST present it and get approval. **The terminal state is invoking [oneteam:skill] `writing-plans`.** Do NOT invoke any other implementation skill.
</HARD-GATE>

## When to Use

- Starting a new feature or component
- Modifying existing behavior
- Any creative work requiring design decisions

## When NOT to Use

- Bug fix with clear symptoms -- use [superpowers:skill] `systematic-debugging`
- Task already has a detailed plan -- skip to implementation
- Pure refactoring with no behavior change

## Checklist

1. **Explore project context** -- files, docs, recent commits.
2. **Ask clarifying questions** -- one at a time; purpose, constraints, success criteria.
3. **Propose 2-3 approaches** -- trade-offs and your recommendation.
4. **Present design** -- sections scaled to complexity; approve after each.
   After each section: `"Look right, or any changes?"`
   After final section: `"Full design above. Approve to continue?"`
5. **Choose working branch** -- via AskUserQuestion (see below).
6. **Present full design doc** -- pretty-print as rendered markdown (NOT in a code block); approve via AskUserQuestion.
7. **Write design doc** -- `plans/YYYY-MM-DD-<topic>-design.md` (do NOT commit).
8. **Offer GitHub issue posting** -- optionally post design to a GitHub issue.
9. **Invoke [oneteam:skill] `writing-plans`** -- no other skill.

## Process Flow

```dot
digraph brainstorming {
    "Explore project context" [shape=box];
    "Ask clarifying questions" [shape=box];
    "Propose 2-3 approaches" [shape=box];
    "Present design sections" [shape=box];
    "User approves design?" [shape=diamond];
    "Choose working branch" [shape=box];
    "Present full design doc" [shape=box];
    "User approves final doc?" [shape=diamond];
    "Write design doc" [shape=box];
    "Offer GitHub issue posting" [shape=box];
    "Invoke [oneteam:skill] writing-plans skill" [shape=doublecircle];

    "Explore project context" -> "Ask clarifying questions";
    "Ask clarifying questions" -> "Propose 2-3 approaches";
    "Propose 2-3 approaches" -> "Present design sections";
    "Present design sections" -> "User approves design?";
    "User approves design?" -> "Present design sections" [label="no, revise"];
    "User approves design?" -> "Choose working branch" [label="yes"];
    "Choose working branch" -> "Present full design doc";
    "Present full design doc" -> "User approves final doc?";
    "User approves final doc?" -> "Present full design doc" [label="no, revise"];
    "User approves final doc?" -> "Write design doc" [label="yes"];
    "Write design doc" -> "Offer GitHub issue posting";
    "Offer GitHub issue posting" -> "Invoke [oneteam:skill] writing-plans skill";
}
```

## After the Design

### Step 5: Choose Working Branch

Run `git branch --show-current`, then `AskUserQuestion` (header: "Branch"):

| Option label | Description |
|---|---|
| Stay on `<branch>` | Continue on current branch |
| Switch to existing | User types target branch name |
| Create new branch | Suggest `feat/<topic-slug>`; user can accept or edit |

**Switch to existing**: `git checkout <branch>`. **Create new branch**: `git checkout -b <name>`.

### Step 6: Present Full Design Doc

Pretty-print the full compiled design document as rendered markdown. Output it directly -- NOT inside a code block -- so the user sees formatted headings, bold text, bullets, etc.

`AskUserQuestion` (header: "Write to file"):

| Option label | Description |
|---|---|
| Yes, write it | Proceed to write the design doc to file |
| Revise | User provides feedback; revise and re-present |

If "Revise": incorporate the user's feedback, revise the document, and present it again. Repeat until approved.

### Step 7: Write Design Doc

Save to `plans/YYYY-MM-DD-<topic>-design.md`. Use elements-of-style:writing-clearly-and-concisely if available. Do NOT `git add` or `git commit`.

### Step 8: GitHub Issue Posting

`AskUserQuestion` (header: "GitHub issue"):

| Option label | Description |
|---|---|
| Post to GitHub issue | Post design as new or existing issue |
| Skip | Go straight to planning |

If accepted:

1. **Repository** -- always ask, NEVER assume current repo. `AskUserQuestion` (header: "Repository"):

   | Option label | Description |
   |---|---|
   | This repo (`<owner/repo>`) | Current working directory's repo |
   | Different repo | User types `owner/repo` or URL |

2. **New or existing issue.** `AskUserQuestion` (header: "Issue"):

   | Option label | Description |
   |---|---|
   | New issue | Create with design topic as title |
   | Existing issue | Comment on existing (user provides number) |

   New: `gh issue create -R owner/repo --title "<topic>" --body "..."`. Existing: `gh issue comment NUMBER -R owner/repo --body "..."`. Always use `-R`.

## Quick Reference

| Step | Action | Gate |
|------|--------|------|
| 1 | Explore project context | -- |
| 2 | Ask clarifying questions (one at a time) | -- |
| 3 | Propose 2-3 approaches with trade-offs | -- |
| 4 | Present design sections | User approves each section |
| 5 | Choose working branch | User selects via AskUserQuestion |
| 6 | Present full design doc | User approves via AskUserQuestion |
| 7 | Write design doc to `plans/` | -- |
| 8 | Offer GitHub issue posting | User opts in/out |
| 9 | Invoke [oneteam:skill] `writing-plans` | Terminal state |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Asking multiple questions at once | One question at a time |
| Jumping to implementation before design approval | Hard gate -- present design and get explicit approval |
| Invoking a skill other than `writing-plans` at the end | `writing-plans` is the only valid terminal state |

## Constraints

- ALWAYS ask one question at a time; prefer multiple choice when possible
- ALWAYS propose 2-3 approaches before settling on a design
- ALWAYS present design and get explicit approval before moving on
- NEVER begin implementation until design is approved (hard gate)
- NEVER invoke any skill other than [oneteam:skill] `writing-plans` as terminal state
- YAGNI ruthlessly -- cut unnecessary features from all designs
