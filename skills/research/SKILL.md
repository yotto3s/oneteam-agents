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
