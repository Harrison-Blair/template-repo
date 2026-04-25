#!/usr/bin/env bash
# PostToolUse hook: after `git commit`, update the "N commits since summary"
# counter in the open PR's body. Silent — no prompts, no tokens consumed,
# always exits 0 so it never blocks a commit.
#
# The trailer (written by the /summarize-pr skill) is three italic lines at the
# bottom of the PR body. Only line 1's commit count is rewritten here:
#   _🤖 AI summary · 3 commits since summary · HEAD `abc1234` · claude-haiku-4-5_
#   _↳ at summary · context 9 · response 3.1k · cache-write 45.7k · ... · $0.11_
#   _↻ run `/summarize-pr` in Claude Code to refresh this summary_
# Lines 2 and 3 are frozen at summary time and never touched by this hook.

set -u

input=$(cat)

command=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Match `git commit` as an actual command, not a mention in a quoted
# string. Exclude `git commit-tree` by requiring the word to end.
if ! printf '%s' "$command" | grep -qE '(^|[;|&])[[:space:]]*git[[:space:]]+commit([[:space:]]|$)'; then
  exit 0
fi

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0
[ -z "$branch" ] && exit 0
[ "$branch" = "HEAD" ] && exit 0

pr_number=$(gh pr list --head "$branch" --json number --jq '.[0].number' 2>/dev/null) || exit 0
[ -z "$pr_number" ] && exit 0
[ "$pr_number" = "null" ] && exit 0

body=$(gh pr view "$pr_number" --json body --jq .body 2>/dev/null) || exit 0
[ -z "$body" ] && exit 0

# Recorded summary-point SHA (7-char short sha inside backticks in the trailer).
recorded_sha=$(printf '%s' "$body" | grep -oE 'AI summary · [0-9]+ commits since summary · HEAD `[0-9a-f]+`' | grep -oE '`[0-9a-f]+`' | head -n1 | tr -d '`')
[ -z "$recorded_sha" ] && exit 0

# Count commits on HEAD since the recorded summary point. If the SHA is
# unreachable (history rewrite, fresh clone, etc.), bail silently.
count=$(git rev-list "${recorded_sha}..HEAD" --count 2>/dev/null) || exit 0

# Skip the API call entirely if the count hasn't changed.
old_count=$(printf '%s' "$body" | grep -oE 'AI summary · [0-9]+ commits since summary' | grep -oE '[0-9]+' | head -n1)
[ "$old_count" = "$count" ] && exit 0

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
printf '%s' "$body" | sed -E "s/(AI summary · )[0-9]+( commits since summary)/\\1${count}\\2/" > "$tmp"

gh pr edit "$pr_number" --body-file "$tmp" >/dev/null 2>&1 || true
exit 0
