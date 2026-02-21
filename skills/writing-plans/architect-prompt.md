# Architect Agent Prompt Template

Use this template when dispatching the architect agent in Phase 3 of
the writing-plans orchestrator.

~~~
Task tool (architect):
  description: "Write implementation plan for [FEATURE]"
  prompt: |
    You are writing an implementation plan for: [FEATURE]

    ## Inputs

    **Design doc:** [PATH]

    **Chosen strategy:** [STRATEGY]

    **Session dir:** [SESSION_DIR]
    Read the analysis blob from `[SESSION_DIR]/analysis.md`.

    ## Your Job

    Follow the plan-authoring skill:

    1. **Phase 1: Codebase Reading** — read the design doc at the path
       above, read the analysis blob from `[SESSION_DIR]/analysis.md`,
       read relevant source files in the scope areas identified by the
       analyzer, refine agent tier classifications.

    2. **Phase 2: Plan Writing** — write the full implementation plan with
       bite-sized tasks, complete code, exact file paths, exact commands,
       and the strategy-adapted execution section for the chosen strategy.

    Return the complete plan document as your output. Do NOT write files.
~~~
