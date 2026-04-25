---
name: summarize-pr
description: Summarize the open PR's description to reflect the current state of the branch. Use when the user says "summarize the PR", "sync the PR", "update the PR description/body", "refresh the PR", or when commits landed from outside Claude Code.
---

# summarize-pr

Canonical procedure: **CLAUDE.md §`keeping-pr-summaries-fresh`**. Re-read that section each time before acting — it is the source of truth for which PR sections refresh vs. preserve. Do not duplicate those lists here.

The Summary-of-Changes draft is delegated to a headless `claude -p` call against `claude-haiku-4-5` so (1) the expensive LLM step runs on the cheap-model budget, and (2) real token counts come back in the JSON result and can be written into the AI-summary trailer. The main-session model orchestrates shell, body assembly, and `gh pr edit`.

## Steps

1. **Resolve the PR for the current branch.** Stop if there isn't one.
   ```bash
   pr=$(gh pr list --head "$(git branch --show-current)" --json number,baseRefName --jq '.[0]')
   num=$(printf '%s' "$pr" | jq -r .number)
   base=$(printf '%s' "$pr" | jq -r .baseRefName)
   [ -z "$num" ] || [ "$num" = "null" ] && { echo "No open PR — skipping."; exit 0; }
   ```

2. **Three-dot diff against the PR's real base** (never hard-code `main` or `dev`):
   ```bash
   git fetch origin "$base" --quiet
   git diff "origin/$base...HEAD" --stat
   git log "origin/$base..HEAD" --format='%h %s'
   ```

3. **Save the current PR body** so preserved sections survive:
   ```bash
   gh pr view "$num" --json body --jq .body > /tmp/pr-$num-body.orig.md
   ```

4. **Delegate the Summary-of-Changes draft to Haiku.** Assemble a prompt file that contains:
   - A brief instruction ("Draft the Summary of Changes section for this PR. Return only markdown bullets grouped by theme — no `##` heading, no trailer line, no other sections.")
   - `git diff --stat` output + `git log --format='%h %s'` output
   - The full three-dot diff (`git diff origin/$base...HEAD`). If the diff exceeds ~150k chars, include the stat plus per-file diffs for only the files with substantive changes.
   - The current Summary of Changes section from `/tmp/pr-$num-body.orig.md` as a tone/format reference.

   Invoke (alias `haiku` resolves to the latest Haiku):
   ```bash
   claude -p --model haiku --output-format json < /tmp/pr-$num-prompt.md > /tmp/pr-$num-draft.json
   ```

   Parse all four token buckets separately — `usage.input_tokens` is only the fresh (non-cached) input, so summing just in+out under-reports the actual work by 10-50× when the prompt or the Claude Code system prompt hit the cache. Use `.total_cost_usd` for the dollar figure:
   ```bash
   summary_md=$(jq -r '.result' /tmp/pr-$num-draft.json)
   in_tok=$(jq -r '.usage.input_tokens // 0' /tmp/pr-$num-draft.json)
   out_tok=$(jq -r '.usage.output_tokens // 0' /tmp/pr-$num-draft.json)
   cw_tok=$(jq -r '.usage.cache_creation_input_tokens // 0' /tmp/pr-$num-draft.json)
   cr_tok=$(jq -r '.usage.cache_read_input_tokens // 0' /tmp/pr-$num-draft.json)
   total_tok=$((in_tok + out_tok + cw_tok + cr_tok))
   cost_usd=$(jq -r '.total_cost_usd // 0' /tmp/pr-$num-draft.json)
   model_used=$(jq -r '.modelUsage | keys[0] // "claude-haiku-4-5"' /tmp/pr-$num-draft.json | sed -E 's/-[0-9]{8}$//')
   short_sha=$(git rev-parse --short=7 HEAD)

   # Format helper: values < 1000 as-is, otherwise X.Xk with one decimal.
   # Pass the value via `-v` so awk-escape rules never see shell-interpolated content.
   fmt() { if [ "$1" -lt 1000 ]; then printf '%s' "$1"; else awk -v v="$1" 'BEGIN { printf "%.1fk", v/1000 }'; fi; }
   in_s=$(fmt "$in_tok"); out_s=$(fmt "$out_tok"); cw_s=$(fmt "$cw_tok"); cr_s=$(fmt "$cr_tok"); tot_s=$(fmt "$total_tok")
   # Shell printf handles floats portably (POSIX); avoids the awk `\$` escape which
   # renders inconsistently across gawk/mawk/BSD-awk.
   cost_s=$(printf '$%.2f' "$cost_usd")
   ```

   If `claude -p` fails (auth, rate-limit, network), fall back to drafting the Summary yourself in the main session and write the trailer with `(cost unknown)` in place of the breakdown line.

5. **Rebuild the body** per CLAUDE.md's refresh/preserve lists. Replace the Summary-of-Changes section with the Haiku draft. Copy every other section verbatim from `/tmp/pr-$num-body.orig.md`. Then append this **three-line trailer at the very end of the body** (after Related Documentation and any other preserved sections), separated from the last section by a blank line:
   ```
   _🤖 AI summary · 0 commits since summary · HEAD `<short_sha>` · <model_used>_
   _↳ at summary · context <in_s> · response <out_s> · cache-write <cw_s> · cache-read <cr_s> · total <tot_s> · <cost_s>_
   _↻ run `/summarize-pr` in Claude Code to refresh this summary_
   ```
   The leading `at summary ·` on line 2 is a disclaimer: every number on that line is a snapshot from the last `/summarize-pr` run, **not** a live total. Line 3 is a static how-to-refresh hint for readers viewing the PR on GitHub — same wording every time, never rewritten by the hook. The commit-counter hook only rewrites `<N>` on line 1; lines 2 and 3 stay frozen between summaries.
   Bottom placement keeps the auto-updated trailer (and the silent hook's commit-counter edits) out of the human-authored sections — the summary can touch docs references mid-body, and the trailer stays a pure footer. If the body is empty (new PR), use `.github/PULL_REQUEST_TEMPLATE.md` as the baseline. When an existing summary produced a trailer higher up (e.g. at the end of the Summary section), strip it from the preserved body before rebuilding so it doesn't end up duplicated.

6. **Apply** via a tempfile (avoid shell-escaping surprises):
   ```bash
   gh pr edit "$num" --body-file /tmp/pr-$num-body.md
   ```

7. **Verify**:
   ```bash
   gh pr view "$num" --json url,body --jq '{url, bodyLen: (.body | length)}'
   ```

## The AI-summary trailer

Three italic lines at the **very bottom of the PR body** — after Testing, Sensitive Data Check, Related Documentation, and any other preserved sections. Bottom placement means the auto-updating element (commit counter from the hook, full rewrite from `/summarize-pr`) never sits inside human-authored content, even when the draft touches docs references mid-body.

Line 1 is load-bearing — the `.claude/hooks/pr-summary-counter.sh` hook regex matches `AI summary · <N> commits since summary · HEAD \`<sha>\``, so the exact delimiter pattern on that line must not change. Line 2 is free-form for the cost breakdown. Line 3 is a static how-to-refresh hint for the GitHub reader — same text every run, hook ignores it.

```
_🤖 AI summary · <N> commits since summary · HEAD `<short-sha>` · <model>_
_↳ at summary · context <in> · response <out> · cache-write <cw> · cache-read <cr> · total <total> · <cost>_
_↻ run `/summarize-pr` in Claude Code to refresh this summary_
```

Line 1 — staleness + model:
- **`<N>`** — commits on HEAD since the recorded SHA. `/summarize-pr` always resets this to `0`. The silent PostToolUse hook rewrites this number after each `git commit`. Never edit `<N>` by hand during a summary run.
- **`<short-sha>`** — 7-char SHA of HEAD at summary time. Fixed until the next `/summarize-pr`.
- **`<model>`** — the model `claude -p` reports having used, with the `-YYYYMMDD` version suffix stripped (e.g. `claude-haiku-4-5`).

Line 2 — cost breakdown (all four token buckets + total + dollar cost):
- **`<in>` (context)** — `usage.input_tokens` — fresh, uncached input. Typically small because the prompt gets cached.
- **`<out>` (response)** — `usage.output_tokens` — the generated summary.
- **`<cw>` (cache-write)** — `usage.cache_creation_input_tokens` — tokens written to cache (usually our big diff prompt on first run).
- **`<cr>` (cache-read)** — `usage.cache_read_input_tokens` — tokens read from cache (Claude Code's system prompt etc).
- **`<total>`** — sum of the four above.
- **`<cost>`** — `total_cost_usd` formatted as `$X.XX`.

Line 3 — static refresh hint, identical every run:

```
_↻ run `/summarize-pr` in Claude Code to refresh this summary_
```

No tokens, no variables, no hook interaction. Its only purpose is to tell a GitHub reader how to regenerate the summary without needing to know the skill name. Keep the exact text so the format stays scannable across PRs.

## Guardrails

- Do **not** tick or untick checkboxes in the preserved sections. Those are user attestations.
- Do **not** touch sections the user added that aren't in `.github/PULL_REQUEST_TEMPLATE.md` — they are off-limits.
- Do **not** alter the trailer format — the shell hook's regex depends on the exact delimiter pattern (`·` separator, `HEAD \`<sha>\``, etc.).
- If HEAD is ahead of `origin/<head-branch>`, note it to the user — the PR reflects the pushed tip, not HEAD. Offer to push first, or generate the body from `origin/<base>...origin/<head-branch>` instead.
