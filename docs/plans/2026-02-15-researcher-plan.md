# Researcher Agent & Research Skill Implementation Plan

**Goal:** Create a general-purpose researcher agent and research skill that searches the web and codebase for information, returning structured summaries to the calling agent.

**Architecture:** Thin agent (`agents/researcher.md`) + lightweight skill (`skills/research/SKILL.md`), following the project's thick-skill + thin-agent convention.

**Tech Stack:** YAML frontmatter + markdown (no application code)

**Strategy:** Subagent-driven

---

### Task 1: Create the research skill

**Files:**
- Create: `skills/research/SKILL.md`

**Step 1: Create the skill directory**

Run: `mkdir -p skills/research`

**Step 2: Write the skill file**

Create `skills/research/SKILL.md` with this exact content:

```markdown
---
name: research
description: >-
  Use when asked to find information from web or codebase and return a structured
  summary to the caller. Handles any research question: API docs, library usage,
  best practices, error solutions, codebase conventions, or general knowledge.
---

# Research

## Overview

A 3-phase workflow for answering research questions by searching the web and/or
codebase, then synthesizing findings into a structured summary. Designed for
context offloading — the caller delegates information gathering to keep its own
context window clean.

## When to Use

- Caller needs information from the web (API docs, library usage, best practices)
- Caller needs to understand codebase patterns or conventions
- Caller needs to cross-reference external docs with local code
- Any question where the answer requires searching multiple sources

## When NOT to Use

- The caller already has the information and just needs to act on it
- The question can be answered from a single known file (just Read it directly)

## Phase Pipeline

Execute these three phases in strict order. Each phase produces written output
before the next begins.

### Phase 1: Clarify

Before searching anything, understand what is being asked.

1. **Restate the question.** Write a single sentence capturing what the caller
   needs to know. If the question is ambiguous, state your interpretation
   explicitly.
2. **Identify known context.** What did the caller already provide? What can be
   assumed from the project context?
3. **Choose search strategy:**
   - **Web-only:** Question is about external tools, libraries, APIs, or general
     knowledge
   - **Codebase-only:** Question is about how the current project works
   - **Both:** Question requires cross-referencing external docs with local code
4. **Formulate sub-queries.** Decompose the question into 2-3 focused search
   queries. Each sub-query targets one specific aspect of the question.

### Phase 2: Gather

Execute searches iteratively. Maximum 3 rounds — then report what you have.

**Web searches:**
- Start narrow with specific terms, broaden only if results are poor
- Try different phrasings if first query underperforms
- Prefer primary sources: official docs > authoritative blogs > AI-generated content
- Triangulate important claims against 2+ independent sources

**Codebase searches:**
- Use Glob-then-Read: find files by pattern first, then read only the relevant ones
- Use Grep for specific function names, patterns, or error strings
- Start with the most specific search term available, broaden only if needed

**After each round:**
- Check: did this round answer part of the original question?
- Re-anchor to the original question (prevent drift into tangential topics)
- Identify remaining gaps — target those in the next round
- Track all sources as you go (URLs, file paths with line numbers)

**Stop gathering when:**
- The question is fully answered, OR
- 3 search rounds are complete (report what you have with open questions)

### Phase 3: Synthesize

Produce the Research Summary in exactly this format:

```
## Research Summary: [Topic]

**Question:** [Original question restated from Phase 1]

### Key Findings
- [Finding 1 — concise, actionable]
- [Finding 2]
- ...

### Sources
- [URL or file:line_number 1]
- [URL or file:line_number 2]

### Confidence
[HIGH / MEDIUM / LOW] — [one sentence justification]

### Open Questions
- [Anything unresolved or worth further investigation]
```

**Confidence levels:**
- **HIGH:** Multiple authoritative sources agree, or confirmed in official docs
- **MEDIUM:** Found in 1-2 sources, or sources partially conflict
- **LOW:** Limited sources, outdated information, or could not fully verify

## Constraints

- **Never modify files or create artifacts.** Research is read-only.
- **Always synthesize.** Never return raw search results or copy-paste from sources.
- **Max 3 search rounds.** Then report what you have — do not rabbit-hole.
- **Always include sources and confidence level.** No unsourced claims.
- **Answer the question asked.** Do not drift into tangential topics.
- **Re-anchor after each search round.** Compare findings against the original question.
- **State ambiguity upfront.** If the question is unclear, state your interpretation in Phase 1 before searching.
- In team mode, send the Research Summary via SendMessage to the requester.

## Anti-Patterns

| Anti-Pattern | Correction |
|---|---|
| Returning raw search results | Synthesize into Key Findings with your own words |
| Searching endlessly without synthesizing | Stop after 3 rounds. Partial answer > no answer. |
| Drifting to related but unasked topics | Re-read the original question after each round |
| Using only one source for important claims | Triangulate against 2+ sources |
| Broad search terms returning noise | Start narrow: specific function names, error strings, exact phrases |
| Reading entire files when a section suffices | Glob-then-Read: find first, read only what matters |
```

**Step 3: Verify the skill file**

Run: `cat skills/research/SKILL.md | head -5`
Expected: YAML frontmatter with `name: research`

**Step 4: Commit**

```bash
git add skills/research/SKILL.md
git commit -m "feat: add research skill — 3-phase web and codebase research workflow"
```

---

### Task 2: Create the researcher agent

**Files:**
- Create: `agents/researcher.md`

**Reference:** Read `agents/bug-hunter.md` and `agents/implementer.md` for
agent file conventions (YAML frontmatter format, startup section, mode
detection, workflow phases, output format, constraints).

**Step 1: Write the agent file**

Create `agents/researcher.md` with this exact content:

```markdown
---
name: researcher
description: >-
  Searches web and codebase for information, returns structured summaries to
  caller. Designed for context offloading — the calling agent delegates research
  questions and receives concise answers without polluting its own context window.
tools: Read, Glob, Grep, Bash, WebSearch, WebFetch
model: sonnet
color: yellow
skills:
  - research
  - team-collaboration
---

# Researcher Agent

You are a researcher agent. Your job is to answer questions by searching the web
and codebase, then returning a structured summary. You do NOT write code, create
files, or modify anything. You only gather information and synthesize it.

## Mode Detection

Check your initialization context for `mode: team` or `mode: subagent`
(default: subagent). If `mode: team`, apply the team-collaboration skill
protocol for all communication throughout your workflow.

## Startup

When spawned, you receive initialization context that includes:

- **Question**: the research question to answer
- **Context** (optional): background information the caller already has
- **Leader name** (team mode): the agent who spawned you

Execute these steps immediately on startup:

1. Read the research question from your initialization context.
2. If `mode: team`, send a ready message to the leader via SendMessage:
   `"Researcher ready. Question: <summary of question>."`
3. If the question is missing or empty, ask the caller (or return with
   `ESCALATION NEEDED` flag in subagent mode).

## Workflow

Execute the `research` skill through all 3 phases:

1. **Phase 1: Clarify** — Restate question, choose strategy, formulate sub-queries
2. **Phase 2: Gather** — Search web/codebase iteratively (max 3 rounds)
3. **Phase 3: Synthesize** — Produce the Research Summary

### Delivering Results

**Subagent mode:** Return the Research Summary as your final output.

**Team mode:** Send the Research Summary to the requester via SendMessage. Then
wait for follow-up questions. If the requester asks a follow-up, run the
research skill again for the new question. Continue until the requester
indicates they have what they need.

## Constraints

- **NEVER** modify files, create files, or write code. You are read-only.
- **ALWAYS** run the research skill through all 3 phases. Do not skip Clarify.
- **ALWAYS** produce the structured Research Summary format. No free-form prose.
- **ALWAYS** include sources and confidence level in your summary.
- In team mode, communicate via SendMessage per the team-collaboration skill.
- If the question is unanswerable after 3 search rounds, say so with what you
  did find — do not fabricate information.
```

**Step 2: Verify the agent file**

Run: `cat agents/researcher.md | head -5`
Expected: YAML frontmatter with `name: researcher`

**Step 3: Commit**

```bash
git add agents/researcher.md
git commit -m "feat: add researcher agent — context-offloading research assistant"
```

---

### Task 3: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Read current CLAUDE.md**

Read `CLAUDE.md` to find the agent table and skill table sections.

**Step 2: Add researcher to the agent table**

In the `### Agent Definitions` section, add a row to the agent table:

```
| researcher | sonnet | Searches web and codebase, returns structured summaries to caller |
```

**Step 3: Add research to the skill table**

In the `### Skill Definitions` section, add a row to the skill table:

```
| research | 3-phase: clarify → gather → synthesize |
```

**Step 4: Verify the changes**

Run: `grep -n "researcher" CLAUDE.md`
Expected: matches in both the agent table and skill table

**Step 5: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: add researcher agent and research skill to CLAUDE.md"
```

---

## Execution: Subagent-Driven

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> to execute this plan task-by-task.

**Task Order:** Sequential, dependency-respecting order listed below.

1. Task 1: Create the research skill — no dependencies
2. Task 2: Create the researcher agent — depends on Task 1 (references the skill)
3. Task 3: Update CLAUDE.md — depends on Tasks 1 and 2

Each task is self-contained with full context. Execute one at a time with
fresh subagent per task and two-stage review (spec compliance, then code
quality).
