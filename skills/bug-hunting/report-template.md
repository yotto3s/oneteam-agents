# Bug Finding Report Template

Supporting reference for the [oneteam:skill] `bug-hunting` skill. The agent produces exactly this structure. Every section is mandatory. Empty sections are written as "None identified" -- they are never omitted.

## Template

```
## Bug Finding Report

**Scope:** [what was analyzed -- PRs, modules, files]
**Branch/Commits:** [git refs]

### Phase Completion Checklist

- [ ] Phase 1: Scope defined (N items)
- [ ] Phase 2: Contracts inventoried (N functions)
- [ ] Phase 3: Impact traced and specs checked
- [ ] Phase 4: Adversarial analysis completed (N scenarios tested)
- [ ] Phase 5: Gap analysis completed
- [ ] Phase 6: Findings verified

### Findings

#### [F1] Severity: HIGH | file.cpp:123
**Category:** Contract violation / Integration issue / Spec mismatch / ...
**What:** One-sentence description of the bug.
**Reasoning:** Step-by-step trace of how the agent arrived at this conclusion.
**Confidence:** Confirmed / Likely / Uncertain

#### [F2] ...

### Coverage Gaps
- [G1] function_name() -- changed but no test covers the new path

### Spec Deviations
- [S1] PR #N says "X" but implementation does "Y"

### Summary
- X findings (H high, M medium, L low)
- Y coverage gaps
- Z spec deviations
```

## Severity Levels

- **HIGH:** Confirmed bug, crash, or data corruption.
- **MEDIUM:** Likely issue, needs investigation to confirm.
- **LOW:** Code smell, edge case, or minor inconsistency.

## Confidence Levels

- **Confirmed:** Traced a concrete code path demonstrating the issue.
- **Likely:** Strong reasoning supports the issue but no single path traced.
- **Uncertain:** Suspicious but could not verify through reasoning alone.
