# Review PR Comment Template

Supporting reference for the [oneteam:skill] `review-pr` skill. This template
defines the comment body format used by `post-comments.sh`. Each section is
mandatory. Keep every section to 1-2 lines -- inline comments must be
scannable, not walls of text.

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
- Use `start_line` in the JSON when the suggestion spans multiple lines.
- Do **not** use a `suggestion` block for deletions (empty block), additions of
  new lines outside the comment range, or non-code advice. Use plain-text
  `**Suggestion:**` for those cases.

## JSON Format

The agent builds a single JSON file and passes it to `post-comments.sh`. The
JSON schema matches what the script expects:

```json
{
  "repo": "owner/repo",
  "pr": 42,
  "summary": "## Review Summary\n\n3 findings across 2 files ...",
  "comments": [
    {
      "path": "src/auth.ts",
      "line": 15,
      "body": "**[CQ-1] Severity: Important**\n\n**What:** Missing null check on `user.email`\n\n**Why:** Will throw TypeError at runtime\n\n```suggestion\nif (user?.email) {\n```"
    },
    {
      "path": "src/auth.ts",
      "line": 25,
      "start_line": 20,
      "body": "**[CQ-2] Severity: Important**\n\n**What:** Redundant validation block\n\n**Why:** Same check is already performed upstream\n\n```suggestion\nconst result = validate(input);\n```"
    },
    {
      "path": "src/auth.ts",
      "line": 40,
      "body": "**[TC-1] Severity: Minor**\n\n**What:** No test for error path\n\n**Why:** Rejected promise case is untested\n\n**Suggestion:** Add a test for the rejected promise case"
    }
  ]
}
```

### Comment Fields

| Field | Required | Description |
|-------|----------|-------------|
| `path` | yes | File path relative to repo root |
| `line` | yes | End line number for the comment |
| `start_line` | no | Start line for multi-line comments / suggestions |
| `body` | yes | Comment body using the template above |

### Top-Level Fields

| Field | Required | Description |
|-------|----------|-------------|
| `repo` | yes | GitHub repository in `owner/repo` format |
| `pr` | yes | Pull request number |
| `summary` | yes | Markdown review summary submitted with the review |
| `comments` | yes | Array of inline comment objects |
