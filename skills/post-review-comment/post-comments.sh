#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# post-comments.sh — Safely post review comments via gh-pr-review
#
# Reads a JSON input file describing review comments to post, writes each
# comment body to a temp file, and passes it via --body "$(cat file)" to
# avoid shell escaping issues with special characters (backticks, $, quotes).
#
# Usage:
#   ./post-comments.sh <input.json>
#
# Input JSON format:
#   {
#     "repo": "owner/repo",
#     "pr": 42,
#     "summary": "## Review Summary\n\n3 findings ...",
#     "comments": [
#       {
#         "path": "src/foo.ts",
#         "line": 23,
#         "start_line": 20,
#         "body": "**[CQ-1] Severity: Important**\n\n**What:** ..."
#       }
#     ]
#   }
#
# Top-level fields:
#   repo    - (required) GitHub repository in owner/repo format
#   pr      - (required) pull request number
#   summary - (required) markdown review summary submitted with the review
#   comments - (required) array of inline comment objects
#
# Comment fields:
#   path       - (required) file path relative to repo root
#   line       - (required) end line number for the comment
#   start_line - (optional) start line for multi-line comments / suggestions
#   body       - (required) comment body (use comment-template.md format)
#
# Prerequisites:
#   - gh CLI (https://cli.github.com/)
#   - gh-pr-review extension (gh extension install agynio/gh-pr-review)
#   - jq (https://jqlang.github.io/jq/)
# ---------------------------------------------------------------------------

# ── Temp file cleanup ─────────────────────────────────────────────────────

TMPDIR_WORK="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_WORK"' EXIT

# ── Argument validation ──────────────────────────────────────────────────

if [[ $# -lt 1 ]]; then
  echo "Usage: $(basename "$0") <input.json>" >&2
  exit 1
fi

INPUT_FILE="$1"

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Error: input file not found: $INPUT_FILE" >&2
  exit 1
fi

# ── Prerequisite checks ──────────────────────────────────────────────────

for cmd in gh jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: $cmd is not installed." >&2
    exit 1
  fi
done

if ! gh pr-review --help &>/dev/null; then
  echo "Error: gh-pr-review extension is not installed." >&2
  echo "Install with: gh extension install agynio/gh-pr-review" >&2
  exit 1
fi

# ── Parse input ──────────────────────────────────────────────────────────

REPO="$(jq -r '.repo' "$INPUT_FILE")"
PR="$(jq -r '.pr' "$INPUT_FILE")"
SUMMARY="$(jq -r '.summary // empty' "$INPUT_FILE")"
COMMENT_COUNT="$(jq '.comments | length' "$INPUT_FILE")"

# Validate required fields
if [[ -z "$REPO" || "$REPO" == "null" ]]; then
  echo "Error: missing or null 'repo' in $INPUT_FILE" >&2
  exit 1
fi
if [[ -z "$PR" || "$PR" == "null" ]]; then
  echo "Error: missing or null 'pr' in $INPUT_FILE" >&2
  exit 1
fi
if [[ -z "$COMMENT_COUNT" || "$COMMENT_COUNT" == "null" || "$COMMENT_COUNT" -le 0 ]] 2>/dev/null; then
  echo "Error: 'comments' array is missing or empty in $INPUT_FILE" >&2
  exit 1
fi

echo "Posting review to $REPO#$PR ($COMMENT_COUNT comments)"

# ── Start pending review ─────────────────────────────────────────────────

REVIEW_CMD_OUTPUT="$(gh pr-review review --start -R "$REPO" "$PR" 2>&1)" || {
  echo "Error: failed to start pending review." >&2
  echo "$REVIEW_CMD_OUTPUT" >&2
  exit 1
}

mapfile -t REVIEW_IDS < <(grep -oE 'PRR_[A-Za-z0-9_-]+' <<<"$REVIEW_CMD_OUTPUT" | uniq || true)

if (( ${#REVIEW_IDS[@]} == 0 )); then
  echo "Error: failed to parse review ID from gh-pr-review output." >&2
  echo "$REVIEW_CMD_OUTPUT" >&2
  exit 1
fi

if (( ${#REVIEW_IDS[@]} > 1 )); then
  echo "Warning: multiple review IDs found; using the first one." >&2
  printf '  Detected IDs: %s\n' "${REVIEW_IDS[@]}" >&2
fi

REVIEW_ID="${REVIEW_IDS[0]}"

echo "Started review: $REVIEW_ID"

# ── Add inline comments ──────────────────────────────────────────────────

POSTED=0
FAILED=0

for i in $(seq 0 $(( COMMENT_COUNT - 1 ))); do
  FILE_PATH="$(jq -r ".comments[$i].path" "$INPUT_FILE")"
  LINE="$(jq -r ".comments[$i].line" "$INPUT_FILE")"
  START_LINE="$(jq -r ".comments[$i].start_line // empty" "$INPUT_FILE")"

  # Write body to temp file — avoids all shell escaping issues
  BODY_FILE="$TMPDIR_WORK/comment-$i.md"
  jq -r ".comments[$i].body" "$INPUT_FILE" > "$BODY_FILE"

  # Build command args — include --start-line only for multi-line comments
  CMD_ARGS=(
    --review-id "$REVIEW_ID"
    --path "$FILE_PATH"
    --line "$LINE"
    --body "$(cat "$BODY_FILE")"
    -R "$REPO" "$PR"
  )
  if [[ -n "$START_LINE" ]]; then
    CMD_ARGS+=(--start-line "$START_LINE")
  fi

  if gh pr-review review --add-comment "${CMD_ARGS[@]}" 2>/dev/null; then
    if [[ -n "$START_LINE" ]]; then
      echo "  + $FILE_PATH:$START_LINE-$LINE"
    else
      echo "  + $FILE_PATH:$LINE"
    fi
    (( POSTED++ )) || true
  else
    echo "  ! FAILED $FILE_PATH:$LINE" >&2
    (( FAILED++ )) || true
  fi
done

# ── Submit review ────────────────────────────────────────────────────────

if [[ -n "$SUMMARY" ]]; then
  SUBMIT_BODY="$SUMMARY"
else
  SUBMIT_BODY="Review posted by post-comments.sh ($POSTED comments)"
fi

if gh pr-review review --submit \
  --review-id "$REVIEW_ID" \
  --event COMMENT \
  --body "$SUBMIT_BODY" \
  -R "$REPO" "$PR" 2>/dev/null; then
  echo "Review submitted: $POSTED posted, $FAILED failed"
else
  echo "Error: failed to submit review." >&2
  exit 1
fi
