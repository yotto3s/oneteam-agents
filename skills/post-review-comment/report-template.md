# Review PR Report Template

Supporting reference for the [oneteam:skill] `post-review-comment` skill. This
template is used as the review body when submitting via `gh-pr-review review --submit`.
Every section is mandatory. Empty sections are written as "None" -- they are
never omitted.

## Template

```
## PR Review Summary

**PR:** #<number> <title>
**Repo:** <owner/repo>
**Mode:** Read-only / Local build
**Spec:** <spec reference or "inferred from PR context">

### Phase Results

| Phase | Focus | Findings | Severity Breakdown |
|-------|-------|----------|--------------------|
| 1 | Spec Compliance | N | X Critical, Y Important, Z Minor |
| 2 | Code Quality | N | X Critical, Y Important, Z Minor |
| 3 | Test Comprehensiveness | N | X Critical, Y Important, Z Minor |
| 4 | Bug Hunting | N | X HIGH, Y MEDIUM, Z LOW |
| 5 | Comprehensive Review | N | X Critical, Y Important, Z Minor |

### Deduplicated Findings Posted

N findings posted as inline comments (M original findings before deduplication).

### Findings Not Posted

<list of findings removed by user during validation, or "None">
```

## Usage

This template is filled in and passed as the `--body` argument to
`gh pr-review review --submit`. The inline comments (individual findings) are
added separately via `--add-comment` before submission.
