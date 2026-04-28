---
name: new-routine
description: Use this skill when the user wants to create a Claude routine — a recurring or one-shot remote agent that runs in Anthropic's cloud. Triggers on phrases like "create a routine", "new claude routine", "schedule a recurring agent", "build a cron job for claude code", "set up a daily/weekly task that runs in the cloud", or any mention of automating something via a scheduled remote Claude session. This skill ensures every required field is collected from the user (no silent defaults), surfaces known gotchas (DST in cron, MCP tool gaps, usage limits, auth scope, time-window semantics, first-run vs steady-state behaviour), catalogues the spec locally to ClaudeRoutines/<name>/ before creating it remotely, and gives the user a clear plan including a recommended manual first run. Use this in preference to the lower-level `schedule` skill when the user values rigor and wants no ambiguity in the result.
---

# new-routine

Build a Claude routine end-to-end with explicit field collection, gotcha disclosure, local cataloguing, and remote creation. The user should leave with two things: a routine running in the cloud, and a checked-in spec they can reproduce or audit later.

## Why this skill exists

Routine creation has many sharp edges that cost more later than asking about now:
- Cron expressions are UTC and DST-blind
- MCP connectors expose only the tools they expose — a "Microsoft 365 connector" may not include send-email
- Recurring writes to a shared branch need an explicit "open new PR or update existing PR" rule
- The remote agent has zero context — no local files, no env vars, no shell history — so the prompt must be self-contained
- Routines bill against the user's weekly/session caps, same as interactive sessions
- First-run behaviour is different from steady state (state files don't exist yet, branches don't exist yet)

The skill walks the user through these explicitly so nothing surprises them on day 7.

## Relationship to the `schedule` skill

`schedule` is the thin wrapper around the routines API: list, create, update, run-now. It already handles connector/environment discovery and converts cron expressions. **This skill builds on top of it.**

In the procedure below, when you need the current MCP connector list or environment list, those values are injected by the harness when `schedule` is loaded. If they're not visible in the current context, run the `schedule` skill once to surface them, then return to this procedure. Don't duplicate that data into this skill — it goes stale.

## Procedure

Run these phases in order. Don't skip ahead even if the user gives you most fields up front — the **gotcha pass** in phase 3 catches things they didn't think to mention.

### Phase 1 — Establish the goal

Ask the user, in plain language:
- What should the agent do, in one sentence?
- What does success look like — a file committed, a PR opened, a Slack message, a status check?

If the answer is vague ("summarize my emails"), ask the load-bearing question: **"Where does the output go and who acts on it?"** That answer determines repo, branch, PR strategy, and notification path. Without it, every later phase is guessing.

### Phase 2 — Collect every required field

Walk the user through these one bucket at a time. Don't assume defaults silently — for every field, either get an explicit answer or state your default and ask "OK?".

**Schedule** (one of):
- `cron_expression` — 5-field UTC cron. Minimum interval is 1 hour.
- `run_once_at` — RFC3339 UTC timestamp, must be in the future.

When the user gives a local time, convert it and **disclose DST** explicitly. Example: "Cron has no DST awareness. 9am ET = 13:00 UTC during EDT (Mar–Nov), but 14:00 UTC during EST (Nov–Mar). Pick the season you want it correct for, or accept the ±1 hour drift." Run `date -u +%Y-%m-%dT%H:%M:%SZ` via Bash before resolving any relative phrase ("tomorrow", "next Monday", "in 3 hours") — the harness's anchor time may be stale.

**Source repo** — the git checkout the agent runs from. Normalize any URL form to full HTTPS without `.git`. If the agent will write back, this is also the write target.

**Environment ID** — required. Get the list from `schedule`'s harness data. If only one env exists, default to it but state the choice.

**Model** — default `claude-sonnet-4-6`. State that and ask if they want different. On bundled plans (Pro/Max) Opus and Sonnet cost the same in dollars, but routines bill against weekly/session limits same as interactive sessions, so the practical guidance is "use what you'd use locally for this kind of task". For high-frequency routines that don't need deep reasoning, Sonnet is usually right.

**MCP connectors** — infer what services the agent needs from the goal. Cross-check against the connector list (from `schedule` harness data). Then **verify the connector exposes the tools the agent will need.** Many connectors are read-only — a Microsoft 365 connector may have `outlook_email_search` (read) but no `send_email` (write). Flag any gap explicitly. If a needed connector isn't connected, link the user to https://claude.ai/customize/connectors.

**Allowed tools** — default `["Bash", "Read", "Write", "Edit", "Glob", "Grep"]`. State the default and ask if anything's missing or excessive. A read-only status-check routine can drop Write/Edit. A pure-shell routine can drop Read/Write/Edit.

**Output destination & write semantics** (only if the agent writes back to the source repo):
- Target folder
- Filename pattern. **All dates resolved at runtime — never hardcode.**
- Branch name. If recurring, ask: "**One branch reused across runs, or a fresh branch per run?**" Reused = simpler git history but PRs accumulate commits until merged. Fresh-per-run = clean PRs but more branch clutter.
- PR strategy: open a new PR each time, push commits to an existing PR if one's open, or both (auto-detect)? Document which one in the prompt.
- Who reviews/merges?

**State persistence** (only if the agent needs continuity between runs, e.g., "emails since last run"):
- Where does the state file live? (Suggest: same folder as outputs, prefixed with `_` for low-clutter, or under `.state/` for hidden.)
- Format. (Usually a single ISO 8601 timestamp.)
- First-run behaviour when the file doesn't exist. (Usually: fall back to a sensible default like "now − 24h".)

**Constraints / safety** — any read-only or sensitive-data rules the agent must respect. Examples: "never reply or forward email", "paraphrase don't quote if the email contains MFA codes", "abort if more than N items would be modified".

### Phase 3 — Gotcha pass

Before drafting, run this checklist and surface any that apply. Don't skip — users often haven't thought about these:

1. **Cron min interval is 1 hour.** If they wanted "every 30 min", tell them now. The API will reject it.
2. **DST drift** — already covered in schedule, but reconfirm if they pushed back on the conversion.
3. **MCP tool reality check** — for every MCP connector attached, list the actual tools it exposes (the schedule harness data shows them, or check the `mcp__<connector>__*` tools available in the current session). If the agent's task implies a tool that's not there, surface it and offer alternatives: drop the step, switch connectors, or use git/PR notifications instead.
4. **Authentication scope** — if the agent pushes to GitHub, the cloud env's GitHub token must have write access on the target repo. The first run may fail on the push step if scope is wrong; the easiest debug is a manual run from the routines page so the error is captured.
5. **Remote-agent isolation** — the routine has no access to local files, env vars, or services on the user's machine. The prompt must be fully self-contained. Confirm.
6. **First run vs steady state** — if state files or branches don't exist on first run, the prompt must handle that case explicitly. Ask: "What does the agent do on its very first execution?"
7. **Usage limits** — routines bill against weekly/session caps, same as interactive Claude Code. State this if the user is choosing Opus for a high-frequency routine (e.g., hourly).
8. **Time-window tool semantics** — if the agent filters by time (e.g., "emails in the past 24 hours"), the exact filter syntax depends on the tool's API. The first run may need calibration; warn the user that the window may need tightening.
9. **Idempotency** — if the routine is interrupted mid-run and re-fires, can it re-run safely? Committing the same summary twice, sending the same Slack message twice, etc. If not, mention it and consider an idempotency check in the prompt.
10. **Secrets in prompts** — the prompt is stored in the routine config and visible to anyone with access to the routine via the web UI. Don't put credentials, API keys, or PII there.

### Phase 4 — Draft and review

Compose:
- The full **agent prompt** — self-contained, numbered steps, explicit constraints. Use imperative form. Explain the *why* for non-obvious steps so the agent has theory of mind, not just a checklist. Avoid all-caps MUSTs unless the constraint is genuinely load-bearing.
- The full **`RemoteTrigger create` body** — name, schedule, env, sources, model, allowed_tools, MCP connections.

Show both to the user **before** any cataloguing or API call. Let them adjust. Don't proceed without explicit approval.

### Phase 5 — Catalogue locally

When approved, save to `ClaudeRoutines/<kebab-case-routine-name>/`:

- **`prompt.md`** — the full prompt as readable markdown. This is the source of truth.
- **`config.json`** — the rest of the create body, with `events[0].data.message.content` replaced by `"content_source": "prompt.md"` so the prompt isn't duplicated. Include `routine_id` and `manage_url` (filled in after phase 6), plus a `notes` array with anything worth remembering: connector limitations, DST behaviour, first-run quirks, manual setup the user needs to do.

If the directory already exists, ask before overwriting.

Example `config.json` skeleton:
```json
{
  "routine_id": "<filled-in-after-create>",
  "manage_url": "<filled-in-after-create>",
  "name": "Human Readable Name",
  "schedule": {
    "cron_expression": "0 14 * * 1-5",
    "timezone_note": "14:00 UTC = 9am EST / 10am EDT, Mon–Fri"
  },
  "enabled": true,
  "job_config": {
    "ccr": {
      "environment_id": "env_...",
      "session_context": {
        "model": "claude-sonnet-4-6",
        "sources": [{"git_repository": {"url": "https://github.com/owner/repo"}}],
        "allowed_tools": ["Bash", "Read", "Write", "Edit", "Glob", "Grep"]
      },
      "events": [{
        "data": {
          "uuid": "<generate-fresh-v4-uuid-on-recreate>",
          "session_id": "",
          "type": "user",
          "parent_tool_use_id": null,
          "message": {"role": "user", "content_source": "prompt.md"}
        }
      }]
    }
  },
  "mcp_connections": [
    {"connector_uuid": "...", "name": "Connector-Name", "url": "https://..."}
  ],
  "notes": [
    "Connector X is read-only; no send-email step is in this routine.",
    "DST: cron fires at 9am EST / 10am EDT.",
    "First run will need a manual trigger to verify GitHub push scope."
  ]
}
```

### Phase 6 — Create remotely

Generate a fresh lowercase v4 UUID for `events[0].data.uuid`. On Windows where `uuidgen` isn't available, use `powershell -NoProfile -Command "[guid]::NewGuid().ToString().ToLower()"`. On Unix, `uuidgen | tr '[:upper:]' '[:lower:]'`.

Inline `prompt.md` into `events[0].data.message.content`. Call `RemoteTrigger` with `action: "create"` and the full body. Capture the response.

Write the returned `routine_id` and the manage URL (`https://claude.ai/code/routines/<id>`) back into `config.json`.

Tell the user:
- Routine ID
- Next-run timestamp (from `next_run_at` in the response)
- Manage URL
- Any caveats from the gotcha pass that might bite on first run

### Phase 7 — Suggest a manual first run

Recommend the user trigger a manual run from the routines page (or via `RemoteTrigger run`) rather than waiting for the cron. First runs commonly expose auth-scope, MCP-tool-availability, or time-window-syntax issues — catching them now is cheaper than catching them at 9am Monday when the user expected a clean PR.

## Updating an existing routine

If the user wants to change an already-created routine:
1. Read its current `ClaudeRoutines/<name>/config.json` and `prompt.md`.
2. Run the relevant phases (often just 2 → 3 → 4 → 5 → 6).
3. Use `RemoteTrigger` with `action: "update"` and a partial body — only the fields that changed.
4. Keep the local files in sync — update `prompt.md` and/or `config.json`.

## Deleting a routine

The API doesn't expose delete. Direct the user to https://claude.ai/code/routines and offer to remove the local `ClaudeRoutines/<name>/` directory if they confirm.

## Repo conventions

- The skill writes to `ClaudeRoutines/<routine-kebab-name>/` at the repo root.
- Each routine subdir has `prompt.md` (source of truth for the prompt) and `config.json` (everything else, with `content_source: "prompt.md"`).
- If you ever inline the prompt directly in `config.json`, drop the `content_source` field to avoid two-sources-of-truth ambiguity.

## What this skill does NOT do

- Does not delete routines (API limitation).
- Does not list or run existing routines — use the lower-level `schedule` skill.
- Does not manage MCP connections at the user level — that's done at https://claude.ai/customize/connectors.
- Does not babysit the routine after creation — for ongoing maintenance use `schedule` or the web UI.

## Common variants

### "Daily summary" pattern
- Cron: `0 <hour> * * 1-5` (weekdays only is usually right; weekends accumulate into Monday)
- State file: `_last-run.txt` next to outputs, holds last successful run timestamp
- Output: timestamped markdown file, committed to a reused branch with a PR for review
- First-run fallback: now − 24h
- Gotcha to surface: branch reuse semantics, MCP tool availability for the data source

### "One-shot reminder" pattern
- `run_once_at` instead of `cron_expression`
- No state file — single-run agents don't need continuity
- Output usually a Slack message, an issue, or a PR comment
- Gotcha to surface: timestamp must be in the future (re-check `date -u`)

### "Status check" pattern (read-only)
- Cron of any cadence ≥ 1h
- No write access to repos — set `allowed_tools` to a read-only set, exclude `gh` operations from the prompt
- Output: comment on a tracked issue, or just stdout for the run logs (visible in the routines page)
- Gotcha to surface: read-only is enforced by the prompt, not by the harness — be explicit
