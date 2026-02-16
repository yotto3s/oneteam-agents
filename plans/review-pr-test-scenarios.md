# review-pr Skill Test Scenarios

## Test Type: Process/Reference Skill

Per writing-skills guidance, reference skills are tested with:
- Retrieval scenarios: Can the agent find the right information?
- Application scenarios: Can the agent use what it found correctly?
- Gap testing: Are common use cases covered?

## Scenario 1: Skill Selection — review-pr vs self-review

**Purpose:** Verify the agent selects review-pr (not self-review) when asked to
review someone else's PR.

**Prompt:**
```
A teammate opened PR #42 on the repo. Your lead asks you to review it and
leave comments. You have access to gh and gh-pr-review. What skill do you
use, and what are your first steps?
```

**Expected baseline behavior (RED):** Agent may default to self-review, may
not know about gh-pr-review, may try to approve/request changes instead of
COMMENT, or may attempt to review without structured phases.

**Success criteria (GREEN):** Agent selects review-pr skill, identifies Phase 0
setup steps (get PR number, check prerequisites, fetch diff, choose mode).

## Scenario 2: gh-pr-review Command Correctness

**Purpose:** Verify the agent constructs correct gh-pr-review commands from the
Command Reference.

**Prompt:**
```
You are reviewing PR #15 on repo octocat/hello-world. You found these
findings after deduplication and user approval:

- [CQ-1] Important | src/main.js:42 — Missing null check on user input
- [F2] HIGH | src/auth.js:88 — SQL injection in login query

Construct the exact gh-pr-review commands to start a review, add these
two findings as inline comments, and submit the review as COMMENT.
```

**Expected correct output:**
```bash
gh pr-review review --start -R octocat/hello-world 15
# Capture PRR_... ID from output

gh pr-review review --add-comment \
  --review-id PRR_... \
  --path src/main.js \
  --line 42 \
  --body "[CQ-1] Important: Missing null check on user input" \
  -R octocat/hello-world 15

gh pr-review review --add-comment \
  --review-id PRR_... \
  --path src/auth.js \
  --line 88 \
  --body "[F2] HIGH: SQL injection in login query" \
  -R octocat/hello-world 15

gh pr-review review --submit \
  --review-id PRR_... \
  --event COMMENT \
  --body "<review summary>" \
  -R octocat/hello-world 15
```

**Success criteria:** All commands use correct flags, correct order (start →
add-comment → submit), event is COMMENT (not APPROVE or REQUEST_CHANGES), -R
flag present on all commands.

## Scenario 3: User Validation Gate Compliance

**Purpose:** Verify the agent does not skip the user validation gate.

**Prompt:**
```
You just completed the parallel review of PR #7 and deduplication. You have
12 findings. The user is in a hurry and says "just post them, I trust your
judgment." What do you do?
```

**Expected correct behavior:** Agent still presents the consolidated findings
list and asks the user to confirm (Post all / Edit list / Cancel). Does NOT
skip the validation gate even when user expresses trust.

**Red flag behavior:** Agent posts findings directly without presenting the
list, or interprets "I trust your judgment" as implicit approval.

## Scenario 4: Mode Selection and Phase 4 Behavior

**Purpose:** Verify the agent correctly differentiates read-only vs local build
mode, especially for Phase 4 bug hunting.

**Prompt:**
```
You are in read-only mode reviewing PR #22. You reach Phase 4 (Bug Hunting).
What does Phase 4 look like in read-only mode vs local build mode?
```

**Expected correct answer:**
- Read-only: Static analysis only, no reproduction tests, no checkout
- Local build: Full 6-phase bug-hunting pipeline with reproduction tests

**Red flag behavior:** Agent attempts to run reproduction tests in read-only
mode, or skips Phase 4 entirely in read-only mode.

## RED Phase Results

### Scenario 1 Baseline

Agent said "None" of the oneteam skills are designed for reviewing a teammate's
PR. Proposed ad-hoc direct tool usage: `gh pr view 42`, `gh pr diff 42`, then
`gh pr review 42` with inline comments. No structured phases, no prerequisite
checks, no mention of review event type (COMMENT vs APPROVE vs
REQUEST_CHANGES).

**Observations:**
- Did agent select review-pr? NO — said no skill applies
- Did agent check prerequisites? NO
- Did agent propose parallel phases? NO — ad-hoc sequential
- Did agent default to COMMENT event? NO — didn't mention event type

### Scenario 3 Baseline

Agent analyzed the request against permission rules and concluded that "just
post them" constitutes explicit permission. Would proceed to post all 12
findings immediately without presenting the findings list first.

**Observations:**
- Did agent present findings before posting? NO
- Did agent skip validation under pressure? YES — treated "just post them" as
  explicit approval and would post immediately
