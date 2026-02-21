# Analyzer Sub-Agent Prompt Template

Use this template when dispatching the analyzer sub-agent in Phase 1 of
the writing-plans orchestrator.

~~~
Task tool (general-purpose):
  description: "Analyze design for planning"
  model: sonnet
  prompt: |
    You are analyzing a design document to determine the best execution
    strategy for implementation.

    ## Inputs

    **Design doc:** [PATH]
    **Codebase root:** [ROOT]
    **Session dir:** [SESSION_DIR]

    ## Your Job

    1. **Read the design document** at the path above. Read it fully.

    2. **Rough codebase scan.** Use Glob and Grep to understand the scope
       areas the design touches. Skim key files — you do NOT need deep
       analysis, just enough to understand:
       - How many distinct tasks the design implies
       - Whether tasks touch overlapping file scopes
       - Whether parallel execution would save significant time

    3. **Classify each task roughly:**
       - Scope area (which part of the codebase)
       - Complexity: junior (1-2 files, isolated, boilerplate) or
         senior (3+ files, coupled, novel logic) — see [oneteam:agent] `lead-engineer`
         Phase 2 classification heuristic
       - Dependencies on other tasks

    4. **Produce a strategy recommendation** using these heuristics:

       | Signal | Subagent-driven | Team-driven |
       |--------|----------------|-------------|
       | Task count | 1-3 tasks | 4+ tasks |
       | Independence | Mostly independent | Overlapping file scopes |
       | Parallelism benefit | Low | High |

    ## Output Format

    Return EXACTLY this structured format:

    ```
    ## Analysis Summary

    **Design doc:** `[path]`
    **Tasks:** N
    **Independence:** all independent / overlap in [areas]
    **Parallelism benefit:** low / high

    ## Strategy Recommendation

    **Recommended:** Subagent-driven / Team-driven
    **Reasoning:** <1-2 sentences>

    ## Task Sketch

    ### Task 1: [name]
    - **Scope:** [which area of codebase]
    - **Complexity:** junior / senior
    - **Depends on:** none / Task N

    ### Task 2: [name]
    ...
    ```

    Keep the task sketch lightweight — names, scope areas, complexity,
    dependencies. The architect agent will flesh these out into full tasks.

    Write your analysis output to `[SESSION_DIR]/analysis.md`.
    Also return the same output in your response.

    Do NOT edit existing files or interact with the user.
~~~
