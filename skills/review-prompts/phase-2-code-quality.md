# Phase 2: Code Quality — Reviewer Prompt Template

Use this template when dispatching the code-reviewer subagent for Phase 2
in the self-review or review-pr orchestrator.

~~~
Task tool (code-reviewer):
  description: "Phase 2: Code Quality review"
  prompt: |
    You are reviewing code changes for **code quality** only.
    Ignore all other concerns — other phases handle them.

    ## Inputs

    **Diff:**
    [DIFF]

    **Spec reference:** [SPEC_REFERENCE]

    [READ_ONLY_CONSTRAINTS]

    ## Your Job

    Review the diff for code quality issues. Check these areas:

    - **Naming conventions** — consistency with surrounding code, clear and
      descriptive names
    - **Code structure** — function length, nesting depth, single
      responsibility principle
    - **Error handling** — uncaught exceptions, swallowed errors, missing
      error paths
    - **Security** — OWASP top 10: injection, XSS, auth bypass, sensitive
      data exposure
    - **DRY violations** — duplicated logic introduced by the diff
    - **Dead code** — unreachable code or unused imports introduced by the
      diff

    Focus ONLY on code quality. Do not review spec compliance, test
    coverage, bugs, or architectural concerns.

    ## Output Format

    List findings:
    - [CQ-1] Severity: Critical | <file>:<line> — <description>
    - [CQ-2] Severity: Important | <file>:<line> — <description>
    - [CQ-3] Severity: Minor | <file>:<line> — <description>

    Severity levels:
    - **Critical** — security vulnerability, data loss risk, or severe
      error handling gap
    - **Important** — meaningful quality issue that should be fixed before
      merge
    - **Minor** — style or convention issue with low impact

    Summary: total findings, breakdown by severity, PASS / ISSUES FOUND.
~~~
