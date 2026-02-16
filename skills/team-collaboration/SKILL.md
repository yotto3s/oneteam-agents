---
name: team-collaboration
description: Use when working in a multi-agent team (mode: team) and need to coordinate communication, hand off work, escalate blockers, or discover teammates.
---

# Team Collaboration

## Overview

Four principles for effective team collaboration in multi-agent contexts.

## When to Use

- Spawned with `mode: team` in initialization context
- Need to communicate with teammates or leader
- Blocked and need to escalate
- Need to discover who owns what scope

## When NOT to Use

- In subagent mode (default) -- agents skip team behaviors and return output directly

## Team Mode Activation Protocol

When an agent's initialization context includes `mode: team`, apply these behaviors on top of the agent's base workflow:

| Behavior | Team mode action |
|----------|-----------------|
| Startup | Send ready message to leader via SendMessage: `"<Role> ready. Worktree: <path>, scope: <scope>."` |
| Progress | Send periodic updates to leader via SendMessage |
| Completion | Send report to leader via SendMessage instead of returning as output |
| Escalation | SendMessage to leader with context instead of returning with `ESCALATION NEEDED` flag |
| Blocking | SendMessage stating what is needed and from whom instead of returning partial result |
| Teammate discovery | Read team config to learn names and roles |

In subagent mode (default), agents skip all of the above and return their completion report as final output. If stuck, they return partial results with an `ESCALATION NEEDED` flag instead of blocking.

## Principles

### 1. Close the Loop

Every message that requests action or delivers work gets confirmed. No message disappears into the void.

**How to keep it:**
- When you receive work (findings, feedback, instructions): acknowledge receipt and state what you will do next.
- When you hand off work: state what you delivered and what you expect the receiver to do.
- When you finish a task: report the outcome to whoever assigned it.
- When you send a message and get no response: follow up -- do not assume it was received.

### 2. Never Block Silently

If you cannot make progress, say so immediately. Silent waiting causes cascading delays.

**How to keep it:**
- When you are waiting for input from another teammate: send a message saying what you need and from whom.
- When you hit an unexpected obstacle: notify the leader with what is blocking you and what you have tried.
- When a task is taking longer than expected: send a status update before anyone has to ask.
- Never assume someone knows you are stuck -- tell them.

### 3. Know Who Owns What

Every team member knows who is responsible for what area. You do not need to know the details of their work -- you need to know who to ask.

**How to keep it:**
- On startup: read the team config to learn who your teammates are and what they are working on.
- When you need information outside your scope: message the owner directly rather than guessing or investigating yourself.
- When your scope changes: notify affected teammates.
- Do not broadcast full status to everyone -- share details only with those who need them.

### 4. Speak Up Early

Raise concerns and doubts immediately, no matter how small. A small question now prevents a big problem later.

**How to keep it:**
- When something feels wrong but you are not sure: ask the relevant teammate or leader now.
- When you notice a potential conflict with another teammate's work: mention it immediately.
- When instructions are ambiguous: ask for clarification before proceeding. Do not interpret silently.
- When you disagree with an approach: state your concern with reasoning -- then defer to the decision maker.

## Quick Reference

| Principle | Core Rule | Key Practice |
|-----------|----------|-------------|
| 1. Close the Loop | Every message gets confirmed | Acknowledge receipt, state next action |
| 2. Never Block Silently | Say so immediately if stuck | Message what you need and from whom |
| 3. Know Who Owns What | Know who to ask | Read team config, message owner |
| 4. Speak Up Early | Raise concerns immediately | Ask now, do not interpret silently |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Broadcasting status to all | Share details only with those who need them (Principle 3) |
| Waiting silently when blocked | Message immediately stating what you need (Principle 2) |
| Not acknowledging received work | Confirm receipt and state next action (Principle 1) |
| Investigating teammate's scope | Message the owner instead of guessing (Principle 3) |
| Interpreting ambiguous instructions | Ask for clarification before proceeding (Principle 4) |

## Constraints

- ALWAYS send a ready message on startup in team mode
- ALWAYS acknowledge receipt of work and state next action
- NEVER block silently -- report blockers immediately
- NEVER investigate outside your scope -- message the owner
- NEVER broadcast when a direct message suffices
