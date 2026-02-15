# Researcher Agent & Research Skill Design

**Goal:** Create a general-purpose researcher agent that searches the web and codebase for information, returning structured summaries to the calling agent — offloading context from the caller's window.

**Architecture:** Thin agent (`researcher.md`) + lightweight skill (`research/SKILL.md`), following the project's thick-skill + thin-agent convention.

## Agent: `researcher`

```yaml
name: researcher
description: Searches web and codebase for information, returns structured summaries to caller
tools: Read, Glob, Grep, Bash, WebSearch, WebFetch
model: sonnet
color: yellow
skills:
  - research
  - team-collaboration
```

- **No Write/Edit tools** — researcher never modifies files
- **Both modes:** Subagent (default) and team (via team-collaboration skill)
- **Subagent mode:** Receives question, runs research skill, returns summary as final output
- **Team mode:** Receives questions via SendMessage, sends summaries back, stays alive for follow-ups

## Skill: `research`

3-phase workflow:

### Phase 1: Clarify

- Parse the research question — what exactly is being asked?
- Identify what's already known (context provided by caller)
- Decide search strategy: web-only, codebase-only, or both
- Formulate 2-3 focused sub-queries (decompose before searching)

### Phase 2: Gather

- Execute searches iteratively, max 3 rounds
- **Web searches:** Start narrow, prefer primary sources (official docs > blogs > AI-generated), try different phrasings if first query underperforms
- **Codebase searches:** Glob-then-Read workflow — find files by pattern first, then read only the relevant ones
- Triangulate important claims against 2+ sources
- Re-anchor to original question after each round (prevent drift)
- Track sources as you go (URLs, file paths)

### Phase 3: Synthesize

Produce structured output:

```markdown
## Research Summary: [Topic]

**Question:** [Original question restated]

### Key Findings
- [Finding 1]
- [Finding 2]

### Sources
- [URL or file path 1]
- [URL or file path 2]

### Confidence
[HIGH / MEDIUM / LOW] — [brief justification]

### Open Questions
- [Anything unresolved or worth further investigation]
```

## Constraints

- Never modify files or create artifacts
- Always answer the question asked — no tangential drift
- Never return raw search results — always synthesize
- Max 3 search rounds, then report what you have
- Always include sources and confidence level
- If the question is ambiguous, state your interpretation before researching
- In team mode, send summary via SendMessage to the requester
