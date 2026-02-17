# Phase 4: Bug Hunting — Reviewer Prompt Template

Use this template when dispatching the bug-hunter subagent for Phase 4
in the self-review or review-pr orchestrator. This phase uses the
bug-hunter agent (not code-reviewer) with the bug-hunting skill's 6-phase
pipeline.

~~~
Task tool (bug-hunter):
  description: "Phase 4: Bug Hunting review"
  prompt: |
    You are hunting for **latent bugs** in code changes.
    Ignore spec compliance, code quality, test coverage, and architectural
    concerns — other phases handle them.

    ## Inputs

    **Diff:**
    [DIFF]

    **Spec reference:** [SPEC_REFERENCE]

    [READ_ONLY_CONSTRAINTS]

    ## Your Job

    Use the bug-hunting skill's 6-phase pipeline on the changed files from
    the diff:

    1. **Scope Definition** — identify changed files, functions, and
       modules; map the blast radius
    2. **Contract Inventory** — enumerate preconditions, postconditions,
       invariants, and implicit assumptions for each changed function
    3. **Impact Tracing and Spec Check** — trace callers/callees; verify cross-change
       interactions are safe
    4. **Adversarial Analysis** — apply adversarial techniques; write at
       least one adversarial scenario per scope item
    5. **Gap Analysis** — identify changed code paths with no test
       coverage, untested contracts
    6. **Shallow Verification and Report** — trace concrete code paths to confirm
       each suspect; assign severity and confidence

    All six phases are mandatory. Do not skip any phase even if earlier
    phases found nothing.

    ## Output Format

    List findings:
    - [F1] Severity: HIGH | <file>:<line> — <description>
      Suggestion: <optional — concrete fix or action to resolve>
    - [F2] Severity: MEDIUM | <file>:<line> — <description>
      Suggestion: <optional — concrete fix or action to resolve>
    - [F3] Severity: LOW | <file>:<line> — <description>
      Suggestion: <optional — concrete fix or action to resolve>

    Severity levels:
    - **HIGH** — likely bug that causes incorrect behavior, data loss, or
      security issue
    - **MEDIUM** — potential bug under specific conditions or edge cases
    - **LOW** — theoretical concern with low probability of manifesting

    Summary: total findings, breakdown by severity, PASS / ISSUES FOUND.
~~~
