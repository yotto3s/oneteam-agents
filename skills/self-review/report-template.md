# Self-Review Report Template

After all 5 phases complete, produce this exact report template. Every section
is mandatory. Do not omit any section.

```
# Self-Review Report

## Summary
- **Scope:** <diff range>
- **Spec:** <spec reference or "inferred from context">
- **Verdict:** PASS | FAIL (FAIL if any unresolved Critical/Important/HIGH/MEDIUM issues remain)

## Phase 1: Spec Compliance
- Findings: N (X fixed, Y unresolved)
- Engineer: junior/senior/none
- Status: PASS / ISSUES REMAINING

## Phase 2: Code Quality
- Findings: N (X fixed, Y unresolved)
- Engineer: junior/senior/none
- Status: PASS / ISSUES REMAINING

## Phase 3: Test Comprehensiveness
- Findings: N (X fixed, Y unresolved)
- Engineer: junior/senior/none
- Status: PASS / ISSUES REMAINING

## Phase 4: Bug Hunting
- Findings: N (X fixed, Y unresolved)
- Engineer: junior/senior/none
- Status: PASS / ISSUES REMAINING

## Phase 5: Comprehensive Review
- Findings: N (X fixed, Y unresolved)
- Engineer: junior/senior/none
- Status: PASS / ISSUES REMAINING

## Unresolved Issues
<list of any issues that remain after fix + re-review cycle, or "None">
```

## Verdict Logic

- **PASS:** All phases have status PASS, or all remaining issues are Minor
  (Phases 1-3, 5) or LOW (Phase 4) severity only.
- **FAIL:** Any unresolved Critical or Important (Phases 1-3, 5) or HIGH or
  MEDIUM (Phase 4) issues remain. Unresolved MEDIUM severity issues from
  Phase 4 trigger FAIL, not PASS.
