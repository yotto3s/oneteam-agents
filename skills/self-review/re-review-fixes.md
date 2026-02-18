# Re-Review Fixes — Reviewer Prompt Template

Use this template when dispatching the code-reviewer subagent to re-review
engineer fixes in the self-review orchestrator's review-fix-re-review cycle.
The re-reviewer verifies each fix resolves its original finding and checks for
regressions introduced by the fixes.

**Wave 1 (Phases 1–4 consolidated fix):** The findings file contains
deduplicated findings from multiple phases with mixed prefixes (e.g.,
SC-1/CQ-3). The fix report file contains the engineer's per-finding results.

**Wave 2 (Phase 5 only):** The findings file contains Phase 5 findings with
CR- prefixes. The fix report file contains the engineer's per-finding results.

~~~
Task tool (code-reviewer):
  description: "Re-review [WAVE_CONTEXT] fixes"
  prompt: |
    You are re-reviewing engineer fixes for **[WAVE_CONTEXT]**. Your job is
    to verify that each fix actually resolves its original finding and to
    check for regressions introduced by the fixes.

    ## Inputs

    **Findings file:** [FINDINGS_FILE]
    Read this file for the original findings the engineer was asked to fix.

    **Fix report file:** [FIX_REPORT_FILE]
    Read this file for the engineer's per-finding fix results (FIXED or
    PARTIAL).

    **Diff (post-fix state):**
    [DIFF]

    **Spec reference:** [SPEC_REFERENCE]

    [READ_ONLY_CONSTRAINTS]

    ## Your Job

    ### 1. Fix Verification

    For each finding in the findings file:

    1. Read the original finding (file, line, description, severity)
    2. Read the engineer's fix result from the fix report file
    3. Check the updated diff to verify the fix resolves the issue
    4. Verdict: RESOLVED / UNRESOLVED / PARTIALLY RESOLVED

    A fix is RESOLVED only if the described issue no longer exists in the
    updated code. If the engineer marked it FIXED but the issue persists,
    mark it UNRESOLVED and explain why.

    ### 2. Regression Check

    Scan the fix changes for new issues introduced by the fixes themselves.
    Scope your check to the same concern areas as the original findings —
    do NOT do a full re-review of the entire diff.

    Flag regressions only if they were directly caused by the fix changes.

    ## Output Format

    ## Fix Verification
    - [<PREFIX><N>] RESOLVED | <file>:<line> — <brief confirmation>
    - [<PREFIX><N>] UNRESOLVED | <file>:<line> — <why it's not resolved>
    - [<PREFIX><N>] PARTIALLY RESOLVED | <file>:<line> — <what's resolved
      and what remains>

    ## Regressions Introduced
    - [REG-1] Severity: <level> | <file>:<line> — <description>

    If no regressions: "None found."

    ## Summary
    - Verified: N findings (X resolved, Y unresolved, Z partial)
    - Regressions: N new issues
    - Status: ALL FIXES VERIFIED / ISSUES REMAIN

    Severity levels for regressions:
    - **Critical** — fix introduced a new bug or security issue
    - **Important** — fix introduced a meaningful quality or behavior issue
    - **Minor** — fix introduced a style or convention issue
~~~
