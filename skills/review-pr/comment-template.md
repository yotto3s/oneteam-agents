# Review PR Comment Template

Supporting reference for the [oneteam:skill] `review-pr` skill. This template
is used as the comment body when adding inline comments via
`gh-pr-review review --add-comment`. Each section is mandatory. Keep every
section to 1-2 lines -- inline comments must be scannable, not walls of text.

## Template

When the finding has a **concrete code change**, include a GitHub suggestion
block so reviewers can apply it with one click:

````
**[<PREFIX><N>] Severity: <level>**

**What:** <1-2 sentence description of the issue>

**Why:** <1-2 sentence impact or reasoning -- why this matters>

```suggestion
<replacement code for the line(s) covered by this comment>
```
````

When the finding is a **non-code recommendation** (architectural advice,
missing test coverage, process concern), use a plain-text suggestion instead:

```
**[<PREFIX><N>] Severity: <level>**

**What:** <1-2 sentence description of the issue>

**Why:** <1-2 sentence impact or reasoning -- why this matters>

**Suggestion:** <1-2 sentence recommended action>
```

## Field Reference

| Field | Source | Example |
|-------|--------|---------|
| PREFIX | Phase prefix from internal Finding Format (SC-, CQ-, TC-, F, CR-) | CQ- |
| N | Finding number within phase | 3 |
| level | Severity from internal Finding Format | Important |
| What | Description of the issue | Missing null check on `user.email` before string comparison |
| Why | Impact or reasoning | Will throw TypeError at runtime if user has no email set |
| suggestion block | Replacement code for the commented line(s) | `user.email?.toLowerCase()` |
| Suggestion (text) | Non-code recommendation when no code block applies | Add integration tests for the new auth flow |

## GitHub Suggestion Block Rules

- The `suggestion` block replaces the **exact line(s)** the comment is attached
  to. The replacement code must be complete and ready to apply.
- Use multi-line comments (`--start-line` + `--line` in `gh-pr-review`) when
  the suggestion spans multiple lines.
- Do **not** use a `suggestion` block for deletions (empty block), additions of
  new lines outside the comment range, or non-code advice. Use plain-text
  `**Suggestion:**` for those cases.

## Usage

This template is filled in and passed as the `--body` argument to
`gh-pr-review review --add-comment`. One comment is posted per approved finding.
The finding's `--path` and `--line` are set from the `<file>:<line>` in the
internal finding format.

To avoid shell escaping issues with special characters in the comment body,
use the `post-comments.sh` script (see `./post-comments.sh`) or write the
body to a temp file and pass it via `--body "$(cat /tmp/comment-body.txt)"`.
