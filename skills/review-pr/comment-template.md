# Review PR Comment Template

Supporting reference for the [oneteam:skill] `review-pr` skill. This template
is used as the comment body when adding inline comments via
`gh-pr-review review --add-comment`. Each section is mandatory. Keep every
section to 1-2 lines -- inline comments must be scannable, not walls of text.

## Template

```
**[<PREFIX><N>] Severity: <level>**

**What:** <1-2 sentence description of the issue>

**Why:** <1-2 sentence impact or reasoning -- why this matters>

**Suggestion:** <1-2 sentence suggested fix or improvement>
```

## Field Reference

| Field | Source | Example |
|-------|--------|---------|
| PREFIX | Phase prefix from Finding Format (SC-, CQ-, TC-, F, CR-) | CQ- |
| N | Finding number within phase | 3 |
| level | Severity from Finding Format | Important |
| What | Description of the issue | Missing null check on `user.email` before string comparison |
| Why | Impact or reasoning | Will throw TypeError at runtime if user has no email set |
| Suggestion | Suggested fix or improvement | Add early return or optional chaining: `user.email?.toLowerCase()` |

## Usage

This template is filled in and passed as the `--body` argument to
`gh-pr-review review --add-comment`. One comment is posted per approved finding.
The finding's `--path` and `--line` are set from the `<file>:<line>` in the
internal finding format.

To avoid shell escaping issues with special characters in the comment body,
use the `post-comments.sh` script (see `./post-comments.sh`) or write the
body to a temp file and pass it via `--body "$(cat /tmp/comment-body.txt)"`.
