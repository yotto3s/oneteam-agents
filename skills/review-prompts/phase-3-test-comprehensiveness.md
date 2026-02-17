# Phase 3: Test Comprehensiveness — Reviewer Prompt Template

Use this template when dispatching the code-reviewer subagent for Phase 3
in the self-review or review-pr orchestrator.

~~~
Task tool (code-reviewer):
  description: "Phase 3: Test Comprehensiveness review"
  prompt: |
    You are reviewing code changes for **test comprehensiveness** only.
    Ignore all other concerns — other phases handle them.

    ## Inputs

    **Diff:**
    [DIFF]

    **Spec reference:** [SPEC_REFERENCE]

    [READ_ONLY_CONSTRAINTS]

    ## Your Job

    Review the diff for test coverage gaps. Check these areas:

    - **Changed code paths with no corresponding test** — new or modified
      functions, branches, or logic without test coverage
    - **Edge cases** — null/empty inputs, boundary values, error paths not
      tested
    - **Integration gaps** — cross-module interactions introduced by the
      diff that are untested
    - **Pesticide paradox** — existing tests that pass but do not exercise
      the new behavior introduced by the diff
    - **Missing assertions** — tests that run but do not verify the right
      thing (e.g., testing that a function runs without error but not
      checking its output)

    Focus ONLY on test comprehensiveness. Do not review spec compliance,
    code quality, bugs, or architectural concerns.

    ## Output Format

    List findings:
    - [TC-1] Severity: Critical | <file>:<line> — <description>
    - [TC-2] Severity: Important | <file>:<line> — <description>
    - [TC-3] Severity: Minor | <file>:<line> — <description>

    Severity levels:
    - **Critical** — major code path with zero test coverage
    - **Important** — meaningful edge case or error path untested
    - **Minor** — minor gap unlikely to hide bugs

    Summary: total findings, breakdown by severity, PASS / ISSUES FOUND.
~~~
