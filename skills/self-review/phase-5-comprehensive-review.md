# Phase 5: Comprehensive Review — Reviewer Prompt Template

Use this template when dispatching the code-reviewer subagent for Phase 5
in the self-review or review-pr orchestrator. Phase 5 receives summaries
from all prior phases via the `[PRIOR_FINDINGS_SUMMARY]` placeholder.

~~~
Task tool (code-reviewer):
  description: "Phase 5: Comprehensive Review"
  prompt: |
    You are reviewing code changes for **cross-cutting and integration
    concerns** only. You have access to findings from all prior review
    phases. Your job is to catch issues that span multiple areas and would
    be missed by any single-focus phase.

    ## Inputs

    **Diff:**
    [DIFF]

    **Spec reference:** [SPEC_REFERENCE]

    [READ_ONLY_CONSTRAINTS]

    **Prior phase findings:**
    [PRIOR_FINDINGS_SUMMARY]

    ## Your Job

    Review the diff for issues that span multiple concerns:

    - **Integration issues** — problems in how changed components interact
      with each other or with unchanged code
    - **Consistency** — naming, patterns, or error handling approaches that
      are inconsistent across the diff
    - **Architectural concerns** — coupling, abstraction leaks, layering
      violations introduced by the diff
    - **Systemic issues** — patterns that appear across multiple files in
      the diff and suggest a deeper problem

    Do NOT duplicate findings already reported by prior phases. Reference
    prior findings where relevant but focus on issues that cross phase
    boundaries.

    ## Output Format

    List findings:
    - [CR-1] Severity: Critical | <file>:<line> — <description>
      Suggestion: <optional — concrete fix or action to resolve>
    - [CR-2] Severity: Important | <file>:<line> — <description>
      Suggestion: <optional — concrete fix or action to resolve>
    - [CR-3] Severity: Minor | <file>:<line> — <description>
      Suggestion: <optional — concrete fix or action to resolve>

    Severity levels:
    - **Critical** — systemic issue affecting multiple components or
      architectural violation with broad impact
    - **Important** — cross-cutting concern that should be addressed
      before merge
    - **Minor** — consistency or style issue spanning multiple files

    Summary: total findings, breakdown by severity, PASS / ISSUES FOUND.
~~~
