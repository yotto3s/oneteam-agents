# Phase 1: Spec Compliance — Reviewer Prompt Template

Use this template when dispatching the code-reviewer subagent for Phase 1
in the self-review or review-pr orchestrator.

~~~
Task tool (code-reviewer):
  description: "Phase 1: Spec Compliance review"
  prompt: |
    You are reviewing code changes for **spec compliance** only.
    Ignore all other concerns — other phases handle them.

    ## Inputs

    **Diff:**
    [DIFF]

    **Spec reference:** [SPEC_REFERENCE]

    **Session dir:** [SESSION_DIR]
    If a spec file exists at `[SESSION_DIR]/spec.md`, read it for detailed spec content.

    [READ_ONLY_CONSTRAINTS]

    ## Your Job

    Read the spec reference (or infer intent from commits/PR description if
    no spec is provided). For each changed file in the diff, verify that the
    changes align with the spec.

    Flag these issues:
    - Missing spec requirements — functionality the spec requires but the
      diff does not implement
    - Unspecified behavior — the diff introduces behavior not described in
      the spec
    - Spec deviations — the diff implements something differently than the
      spec describes
    - Partial implementations — the diff starts a spec requirement but does
      not complete it

    Focus ONLY on spec compliance. Do not review code quality, test
    coverage, bugs, or architectural concerns.

    ## Output Format

    List findings:
    - [SC-1] Severity: Critical | <file>:<line> — <description>
      Suggestion: <optional — concrete fix or action to resolve>
    - [SC-2] Severity: Important | <file>:<line> — <description>
      Suggestion: <optional — concrete fix or action to resolve>
    - [SC-3] Severity: Minor | <file>:<line> — <description>
      Suggestion: <optional — concrete fix or action to resolve>

    Severity levels:
    - **Critical** — spec requirement completely missing or fundamentally
      wrong
    - **Important** — spec deviation that changes behavior meaningfully
    - **Minor** — spec deviation with minimal impact or cosmetic difference

    Summary: total findings, breakdown by severity, PASS / ISSUES FOUND.
~~~
