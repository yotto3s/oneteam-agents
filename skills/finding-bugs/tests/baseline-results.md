# Baseline Test Results (RED Phase)

## Scenario 1: Post-Merge Integration

**Behavior:** Agent went directly to reading real codebase files (InsertOverflowChecks.cpp, mlir_codegen.cpp). Found a real gap (no test exercises both overflow + div-by-zero together). Recommended blocking release.

**What went right:**
- Found a real integration gap
- Traced pass ordering correctly
- Identified shared `__polang_runtime_error` as interaction point

**What failed (no skill):**
- NO phased approach — jumped straight to reading code ad-hoc
- NO contract inventory — didn't enumerate contracts for each PR
- NO specification check — didn't compare implementation against PR descriptions
- NO adversarial analysis — didn't probe boundary conditions, race conditions, etc.
- NO formal report format — free-form narrative instead of severity/confidence ratings
- Stopped analysis after finding one major gap — didn't check remaining interaction points

**Rationalizations observed:**
- Implicitly treated "I found something" as "I'm done"
- Relied on tool-assisted code reading rather than systematic reasoning

## Scenario 2: Large Scope Overwhelm

**Choice:** C (correct — start over with structured approach)

**What went right:**
- Identified sunk cost fallacy
- Recognized unstructured reading doesn't work
- Proposed honest communication with manager

**What failed:**
- THEORETICAL not PRACTICAL — said "here's what I would do" but didn't DO it
- Listed tools (clang-tidy, sanitizers) rather than reasoning disciplines
- No concrete methodology — just "review error paths, check boundary conditions"
- No phased pipeline — loose list of techniques with no ordering or completeness guarantee

**Rationalizations observed:**
- Treated listing techniques as equivalent to executing them

## Scenario 3: Subtle Contract Violation

**Bug found:** YES — correctly identified registerFunction overwriting PolymorphicSignature

**What went right:**
- Found the critical overwrite bug
- Proposed correct fix (add else clause)
- Explained why tests still pass
- Referenced MEMORY.md (because it's in context)

**What failed:**
- STOPPED AFTER ONE FINDING — no check for other issues in the same code
- No contract inventory — didn't enumerate what processDefinitions' own contract should be
- No adversarial analysis — what if defs is empty? What about thread safety? What about callers?
- No gap analysis — are there tests for processDefinitions at all?
- No formal report — just "I found a bug, here's the fix"

**Rationalizations observed:**
- "I found the bug, so the review is complete"
- No completeness check — declared done without systematic coverage

## Patterns Across All Scenarios

1. **No phased pipeline** — all 3 agents used ad-hoc exploration
2. **Stops at first finding** — none completed a full scope analysis
3. **Theory vs practice** — knows the right answer but doesn't execute methodology
4. **No report format** — free-form narrative, no severity/confidence
5. **Skips adversarial analysis** — none probed boundary conditions or race conditions
6. **No contract inventory** — none systematically enumerated contracts before tracing
7. **No specification check** — none compared implementation against spec/requirements
