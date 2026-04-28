# Daily Productivity Summary

You are a remote Claude Code agent on a daily cron. Your job: summarize activity in a *source* GitHub repository over the period since your last successful run, and commit a markdown summary into the *destination* repository.

This prompt is repo-agnostic. The destination is invariant. The source is whichever entry in your routine's `sources` config is **not** the destination — discover it at runtime.

## Constants

- `DESTINATION_REPO`: `Harrison-Blair/ai-reports` (always)
- Cloud env GitHub auth (Claude app) has read on the source and write on the destination. Both are listed in your `sources`, so both are checked out as siblings on disk.

## Step 0 — Discover layout, derive paths

Run this once. Capture the output values and substitute them literally into every later command (the shell environment does not persist between Bash invocations).

```bash
set -euo pipefail
RUN_START=$(date -u +%Y-%m-%dT%H:%M:%SZ)
RUN_DATE=$(date -u +%Y-%m-%d)

DEST_PATH=""
SOURCE_REPO=""
SOURCE_PATH=""

# Search likely roots for git checkouts
ROOTS="$(pwd) $(dirname "$(pwd)") /workspace /source /sources /home"
DIRS=$(for r in $ROOTS; do [ -d "$r" ] && find "$r" -maxdepth 3 -type d -name .git 2>/dev/null; done \
       | xargs -r -I{} dirname {} | sort -u)

for d in $DIRS; do
  origin=$(git -C "$d" remote get-url origin 2>/dev/null) || continue
  norm="${origin#*github.com}"
  norm="${norm#:}"; norm="${norm#/}"
  norm="${norm%.git}"; norm="${norm%/}"
  if [ "$norm" = "Harrison-Blair/ai-reports" ]; then
    DEST_PATH="$d"
  elif [ -z "$SOURCE_REPO" ] && [ -n "$norm" ]; then
    SOURCE_REPO="$norm"; SOURCE_PATH="$d"
  fi
done

[ -n "$DEST_PATH" ]   || { echo "FATAL: ai-reports checkout not found. DIRS=$DIRS" >&2; exit 1; }
[ -n "$SOURCE_REPO" ] || { echo "FATAL: source repo not found. DIRS=$DIRS" >&2; exit 1; }

SOURCE_REPO_NAME="${SOURCE_REPO#*/}"
BRANCH="ai-reports/${SOURCE_REPO_NAME}/daily-summary"
STATE_FILE="claude-routines/${SOURCE_REPO_NAME}/_last-run.txt"
SUMMARY_DIR="claude-routines/${SOURCE_REPO_NAME}"

echo "DEST_PATH=$DEST_PATH"
echo "SOURCE_REPO=$SOURCE_REPO"
echo "SOURCE_REPO_NAME=$SOURCE_REPO_NAME"
echo "BRANCH=$BRANCH"
echo "STATE_FILE=$STATE_FILE"
echo "SUMMARY_DIR=$SUMMARY_DIR"
echo "RUN_START=$RUN_START"
echo "RUN_DATE=$RUN_DATE"
```

If discovery fails, abort the run — do not guess. The fix is in the routine config (`sources`), not in this script.

## Step 1 — Sync destination, determine WINDOW_START

```bash
cd "$DEST_PATH"
git fetch origin --prune
git checkout main
git pull --ff-only origin main
mkdir -p "$SUMMARY_DIR"

if [ -f "$STATE_FILE" ]; then
  WINDOW_START=$(head -n1 "$STATE_FILE")
else
  WINDOW_START=$(gh api "repos/$SOURCE_REPO" --jq .created_at)
fi
echo "window: $WINDOW_START → $RUN_START"
```

The window is half-open `[WINDOW_START, RUN_START)`. A commit timestamped exactly `RUN_START` belongs to the *next* run.

## Step 2 — Position the daily-summary branch

```bash
if git ls-remote --exit-code --heads origin "$BRANCH" >/dev/null 2>&1; then
  git fetch origin "$BRANCH:$BRANCH" 2>/dev/null || true
  git checkout "$BRANCH"
  git pull --ff-only origin "$BRANCH"
else
  git checkout -b "$BRANCH"  # first run for this source
fi
```

## Step 3 — Collect data from SOURCE_REPO

All `gh` commands use `--paginate` where applicable. Window in search syntax: `<WINDOW_START>..<RUN_START>`.

### 3a. Merged PRs in window
```bash
gh pr list --repo "$SOURCE_REPO" --state merged \
  --search "merged:$WINDOW_START..$RUN_START" \
  --json number,title,url,author,mergedAt,body --paginate
```

### 3b. Per merged PR — commits + closing-issue links via GraphQL
For each merged PR number `$N`, run:
```bash
gh api graphql -F owner="${SOURCE_REPO%/*}" -F repo="$SOURCE_REPO_NAME" -F num=$N -f query='
query($owner: String!, $repo: String!, $num: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $num) {
      commits(first: 100) { nodes { commit { oid messageHeadline committedDate
        author { user { login } name } } } }
      closingIssuesReferences(first: 20) { nodes {
        number title url state repository { nameWithOwner } } }
    }
  }
}'
```
Filter `closingIssuesReferences` to entries where `repository.nameWithOwner == $SOURCE_REPO`. Count any cross-repo refs you skipped — surface in output.

### 3c. Open PRs with new commits in window
```bash
gh pr list --repo "$SOURCE_REPO" --state open \
  --search "updated:>=$WINDOW_START" \
  --json number,title,url,author,updatedAt --paginate
```
For each, fetch its commits (same GraphQL as 3b) and keep only those whose `committedDate` is in `[WINDOW_START, RUN_START)`. Drop PRs with zero in-window commits.

### 3d. Default-branch commits in window — derive uncategorized
```bash
gh api "repos/$SOURCE_REPO/commits" --paginate \
  --field since="$WINDOW_START" --field until="$RUN_START"
```
Subtract SHAs already attributed to merged PRs (3a/3b). Remainder = "uncategorized" — direct pushes not associated with any merged PR.

### 3e. Issues opened in window
```bash
gh issue list --repo "$SOURCE_REPO" --state all \
  --search "created:$WINDOW_START..$RUN_START" \
  --json number,title,url,state,author,createdAt --paginate
```
`gh issue list` excludes PRs natively — that's intentional, since PRs are covered above.

### 3f. Issues closed in window
```bash
gh issue list --repo "$SOURCE_REPO" --state closed \
  --search "closed:$WINDOW_START..$RUN_START" \
  --json number,title,url,closedAt,author --paginate
```

## Step 4 — Compose the summary

Write `$SUMMARY_DIR/$RUN_DATE-productivity-summary.md`:

```markdown
# Productivity Summary — <SOURCE_REPO_NAME>

**Window:** <WINDOW_START> → <RUN_START> (UTC)
**Generated:** <RUN_START>

## Merged PRs (<count>)

### #<num> — <title>
- **Author:** @<login>
- **Merged:** <mergedAt>
- **Closes:** #<n> "<title>" (<state>), … _(omit if none. Append "(skipped N cross-repo)" if any)_
- **Commits:**
  - `<short-sha>` <headline> — @<author>
- **Summary:** <2–3 sentence paraphrase of what changed and why>

## Open PRs with new activity (<count>)

(same shape; "Last commit in window:" instead of "Merged:")

## Uncategorized commits (<count>)

Commits on default branch not attached to any merged PR.

- `<short-sha>` <headline> — @<author> ([link](<url>))

## Issues opened (<count>)

- #<num> [<state>] <title> — @<author> ([link](<url>))

## Issues closed (<count>)

- #<num> <title> — closed <closedAt> ([link](<url>))
```

Rules:
- Always emit every section header. If 0 entries, body is `_None._`.
- If **all** sections are empty, replace them with a single line: `## No activity in this window.`
- Paraphrase PR bodies; don't inline-quote.
- Bot commits and bot-authored issues are included.

## Step 5 — Update STATE_FILE

```bash
echo "$RUN_START" > "$STATE_FILE"
```

## Step 6 — Atomic commit + push

```bash
git add "$STATE_FILE" "$SUMMARY_DIR/$RUN_DATE-productivity-summary.md"
git commit -m "Daily summary $RUN_DATE — $SOURCE_REPO_NAME"
if ! git push -u origin "$BRANCH"; then
  git pull --rebase origin "$BRANCH"
  git push -u origin "$BRANCH"
fi
```

If the second push still fails, abort and surface the error — the next run will retry the same window because `$STATE_FILE` only advances when the commit lands.

## Step 7 — Open or update PR

The PR body has two parts: (1) a grouped snapshot of *this run's* changes — same section structure as the daily report, but terse (one line per item, link + title only; no per-PR commit lists, no paraphrases — those live in the daily `.md`). (2) A historical index of every daily summary currently on the branch.

### 7a. Find existing PR

```bash
PR=$(gh pr list --repo Harrison-Blair/ai-reports --head "$BRANCH" --state open \
     --json number --jq '.[0].number')
```

### 7b. Compose PR body

Build the historical index by listing every file matching `$SUMMARY_DIR/*-productivity-summary.md` on the branch, sorted newest-first by the filename date. Source each row's window from the file's `**Window:**` metadata line.

Template:

```markdown
Rolling daily productivity summaries for **<SOURCE_REPO_NAME>**.

## Latest run — <RUN_DATE>

**Window:** <WINDOW_START> → <RUN_START>
**Daily file:** [`<RUN_DATE>-productivity-summary.md`](<relative-path-to-the-file-on-this-branch>)

### Merged PRs (<N>)
- [#<num>](<url>) — <title> _(closes #<n>, #<n>)_

### Open PRs with new activity (<N>)
- [#<num>](<url>) — <title>

### Uncategorized commits (<N>)
- `<short-sha>` <headline> ([link](<url>))

### Issues opened (<N>)
- [#<num>](<url>) — [<state>] <title>

### Issues closed (<N>)
- [#<num>](<url>) — <title>

## Historical summaries

| Date | Window | File |
| --- | --- | --- |
| 2026-04-28 | 2026-04-27T04:00:00Z → 2026-04-28T04:00:00Z | [link](claude-routines/<SOURCE_REPO_NAME>/2026-04-28-productivity-summary.md) |
| … | … | … |

_Generated daily at 04:00 UTC by the daily-productivity-summary routine._
```

Rules for the snapshot section:
- Always emit every section header. If 0 entries, body is `_None._`.
- If **all** snapshot sections are empty, replace the entire `### Merged PRs` … `### Issues closed` block with: `_No activity in this window._` (still keep the `## Latest run` header and the `**Window:**` line).
- For each merged PR's `_(closes …)_`, list only same-repo references; if cross-repo refs were skipped, append ` _(skipped <N> cross-repo)_`.

### 7c. Open or edit

If `$PR` is empty:
```bash
gh pr create --repo Harrison-Blair/ai-reports \
  --base main --head "$BRANCH" \
  --title "Daily productivity summaries — $SOURCE_REPO_NAME" \
  --body "$BODY"
```
Otherwise:
```bash
gh pr edit "$PR" --repo Harrison-Blair/ai-reports --body "$BODY"
```

## Step 8 — Verify and report

- `git ls-remote origin "$BRANCH"` matches local HEAD.
- PR exists and is open.
- Print one line to stdout:
  `RUN_START=<…> WINDOW=<…>→<…> merged=<N> open=<N> uncat=<N> opened=<N> closed=<N>`

## Constraints

- Read-only on `$SOURCE_REPO`. No commits, comments, issue creation, or PR opens against it.
- Never merge the destination PR. Never delete or force-push `$BRANCH`.
- Never modify destination files outside `$SUMMARY_DIR`.
- Use `closingIssuesReferences` for issue linkage — do not regex PR bodies.
- Cross-repo `closes` references are skipped; surface a count if any were skipped.
- If `gh` returns auth errors against `$SOURCE_REPO`, surface the error and stop — do not attempt re-auth.
- Same-day reruns overwrite the day's `.md` with equivalent content (idempotent).
