---
name: design-workflow
description: >-
  Modifies brainstorming behavior: removes auto-commit and adds optional
  GitHub issue posting. Load alongside the superpowers brainstorming skill.
---

# Design Workflow

These modifications apply on top of the superpowers `brainstorming` skill.
Follow the standard brainstorming process with these changes:

## Change 1: Do NOT commit design files

After writing the design doc to `docs/plans/YYYY-MM-DD-<topic>-design.md`,
do NOT run `git add` or `git commit`. The file stays as an uncommitted local
file.

## Change 2: Offer GitHub issue posting

After writing the design file (and before invoking writing-plans), ask the user
if they want to post the design to a GitHub issue. If they decline, proceed
directly to writing-plans.

If they accept:

1. **Ask which repository.** Always ask for the target repository in
   `owner/repo` format. NEVER assume the current working directory's repository
   is the target — the user may want to post to an entirely different repo.

2. **Ask new issue or existing.**
   - **New issue:** `gh issue create -R owner/repo --title "..." --body "..."`
   - **Existing issue:** Ask for issue number, then
     `gh issue comment NUMBER -R owner/repo --body "..."`

3. **Always use the `-R` flag.** Never run `gh issue create` or
   `gh issue comment` without `-R owner/repo`. This prevents accidentally
   targeting the wrong repository.
