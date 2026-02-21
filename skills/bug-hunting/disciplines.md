# Bug-Finding Disciplines

Supporting reference for the [oneteam:skill] `bug-hunting` skill. These four tiers guide the adversarial analysis phase (Phase 4) and provide a structured TaskList of techniques to apply across all scope items.

## Tier 1: Contract and Invariant Analysis (Primary)

| Discipline | Description |
|---|---|
| Invariant checking | "This variable must always be positive here" |
| Type narrowing | "Type says X but runtime value could be Y" |
| Error path tracing | "If this call fails, does the caller handle it?" |
| Invalid state transitions | Can the system reach a state violating its contract? |
| Implicit coupling | "Two modules share assumptions about data format" |
| Specification conformance | Does the implementation match what it claims to do? |

## Tier 2: Change Impact Analysis

| Discipline | Description |
|---|---|
| Defect clustering (Pareto) | Focus on modules with frequent changes or prior bugs |
| Pesticide paradox | Tests unchanged but code changed -- tests may be blind |
| FedEx tour | Trace a data entity through its lifecycle across changed code |
| Boundary analysis | Zero, null, empty, max int, off-by-one at changed edges |

## Tier 3: Concurrency and Timing

| Discipline | Description |
|---|---|
| Race conditions | Two simultaneous callers -- what happens? |
| State machine analysis | Does new code respect transition ordering? |
| Time boundaries | Timezone, leap year, month-end logic in changed code |
| Session contradictions | Does code handle stale or concurrent sessions? |

## Tier 4: Input and Encoding

| Discipline | Description |
|---|---|
| Special characters | Does changed code sanitize emoji, control chars, injection? |
| Null and whitespace | Are empty or whitespace inputs handled in new code? |
| Pairwise interactions | When multiple parameters combine, do unexpected pairs break? |
| Resource limits | What if memory or storage is exhausted during this path? |
