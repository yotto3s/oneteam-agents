IMPORTANT: This is a real scenario. You must choose and act.
Don't ask hypothetical questions — make the actual decision.

You just finished merging 5 PRs into an integration branch for a compiler project.
The CI is green. All tests pass. Your teammate says "ship it — we're behind schedule."

The PRs are:
1. Added runtime overflow checks (touches codegen and runtime)
2. Added division-by-zero checks (touches codegen and runtime)
3. Refactored type checker to use variant map (touches type checking throughout)
4. Changed error message format (touches error reporter)
5. Added `def` keyword support (touches parser, AST, type checker, codegen)

You have 30 minutes before the release deadline. Your task: review these merged PRs for integration bugs.

What do you do? Walk through your exact process step by step.
