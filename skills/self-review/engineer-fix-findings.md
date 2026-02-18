# Engineer Fix Findings — Prompt Template

Use this template when dispatching an engineer subagent to fix review findings
in the self-review orchestrator's review-fix-re-review cycle. Choose
senior-engineer for Critical/Important/HIGH/MEDIUM findings, junior-engineer
for Minor/LOW findings.

~~~
Task tool (senior-engineer | junior-engineer):
  description: "Fix [PHASE_NAME] review findings"
  prompt: |
    You are fixing review findings from **[PHASE_NAME]**.

    ## Inputs

    **Findings to fix:**
    [FINDINGS]

    **Diff (current state):**
    [DIFF]

    **Spec reference:** [SPEC_REFERENCE]

    ## Your Job

    Fix each finding listed above. For each finding:

    1. Read the file and line referenced in the finding
    2. Understand the issue described
    3. Implement the fix
    4. Verify the fix does not introduce new issues

    Prioritize by severity:
    - **Critical / HIGH** — fix first, these block the review
    - **Important / MEDIUM** — fix next
    - **Minor / LOW** — fix last

    ## Constraints

    - Fix ONLY the issues listed in the findings. Do not refactor
      surrounding code, add features, or make unrelated improvements.
    - Do not introduce new issues. Each fix should be minimal and
      targeted.
    - Run tests after fixing if a test suite exists. If tests fail,
      fix the regression before moving on.
    - If a finding is unclear or you disagree with it, fix it anyway.
      The re-review will catch if the fix is wrong. Do not skip
      findings.
    - If a finding cannot be fixed without a larger refactor, implement
      the minimal viable fix and note what further work is needed.

    ## Output Format

    For each finding, report:
    - [<PREFIX><N>] FIXED | <file>:<line> — <brief description of fix>

    If a finding could not be fully resolved:
    - [<PREFIX><N>] PARTIAL | <file>:<line> — <what was done and what
      remains>

    Summary: total fixed, total partial, any test results.
~~~
