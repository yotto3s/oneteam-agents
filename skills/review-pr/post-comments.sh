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
#     "comments": [
#       {
#         "path": "src/foo.ts",
#         "line": 23,
#         "body": "**[CQ-1] Severity: Important**\n\n**What:** ..."
#       }
#     ],
#     "summary_file": "/tmp/review-summary.md"
#   }
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
SUMMARY_FILE="$(jq -r '.summary_file' "$INPUT_FILE")"
COMMENT_COUNT="$(jq '.comments | length' "$INPUT_FILE")"

echo "Posting review to $REPO#$PR ($COMMENT_COUNT comments)"

# ── Start pending review ─────────────────────────────────────────────────

REVIEW_ID="$(gh pr-review review --start -R "$REPO" "$PR" 2>&1 | grep -oE 'PRR_[A-Za-z0-9_-]+')" || {
  echo "Error: failed to start pending review." >&2
  exit 1
}

echo "Started review: $REVIEW_ID"

# ── Add inline comments ──────────────────────────────────────────────────

POSTED=0
FAILED=0

for i in $(seq 0 $(( COMMENT_COUNT - 1 ))); do
  FILE_PATH="$(jq -r ".comments[$i].path" "$INPUT_FILE")"
  LINE="$(jq -r ".comments[$i].line" "$INPUT_FILE")"

  # Write body to temp file — avoids all shell escaping issues
  BODY_FILE="$TMPDIR_WORK/comment-$i.md"
  jq -r ".comments[$i].body" "$INPUT_FILE" > "$BODY_FILE"

  if gh pr-review review --add-comment \
    --review-id "$REVIEW_ID" \
    --path "$FILE_PATH" \
    --line "$LINE" \
    --body "$(cat "$BODY_FILE")" \
    -R "$REPO" "$PR" 2>/dev/null; then
    echo "  + $FILE_PATH:$LINE"
    (( POSTED++ )) || true
  else
    echo "  ! FAILED $FILE_PATH:$LINE" >&2
    (( FAILED++ )) || true
  fi
done

# ── Submit review ────────────────────────────────────────────────────────

if [[ -f "$SUMMARY_FILE" ]]; then
  SUBMIT_BODY="$(cat "$SUMMARY_FILE")"
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
