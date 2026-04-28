# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A templates/config grab-bag — reusable GitHub Actions workflows, Claude Code skills, and Windows launcher scripts intended to be cherry-picked into other repos. There is **no build, no install, no test suite** at the root. Treat each subtree as an independent artifact whose consumers live elsewhere.

The README is split into a user-owned section (`<!-- USER:START -->` … `<!-- USER:END -->`) and an AI-managed section (`<!-- AI:START -->` … `<!-- AI:END -->`). Never edit the USER section unless explicitly asked. Regenerate the AI section via `/update-readme`.

## Common tasks

- **Drag a workflow into another repo:** `cp .github/workflows/<file>.yml /path/to/target/.github/workflows/`
- **Drag a Claude skill into another repo:** `cp -r .claude/skills/<skill> /path/to/target/.claude/skills/`
- **Run the web-dev launcher:** `powershell.exe -ExecutionPolicy Bypass -File .\WindowsPowerShell\web-dev.ps1` (or double-click `WindowsCommandPrompt\web-dev.cmd`). Requires 3 monitors; aborts otherwise.
- **Refresh the README:** invoke the `/update-readme` skill — don't hand-edit the AI block.
- **Refresh an open PR's body:** invoke the `/summarize-pr` skill — it delegates the draft to a `claude -p` Haiku call and rewrites only the auto-managed sections.

The Husky `pre-commit` hook auto-formats staged `python/*.py` (via `python/.venv/bin/ruff`) and `*.{js,jsx,mjs,cjs,ts,tsx}` (via `npx --no-install eslint`). It refuses to run if a staged file also has unstaged changes — stage everything or stash the unstaged hunks. Both branches are inert in *this* repo (no `python/` tree, no `package.json`); they fire only in consumer repos that adopt the hook alongside those toolchains.

## Architecture: load-bearing couplings

Several files in this repo share contracts that are not enforced by code. Renaming a label, header, or trailer line in one place silently breaks the other. The big ones:

### ISSUE_TEMPLATE labels ↔ workflow logic

The four template type labels (`Feature`, `Chore`, `Bug`, `Research`) defined by `.github/ISSUE_TEMPLATE/*.yml` are referenced by name in:

- `.github/workflows/pr-title-and-tag.yml` → `TEMPLATE_TYPES` array. Drives PR title prefixes (`[FEATURE]`, `[BUG]`, …) and label propagation from linked issues.
- `.github/workflows/issue-triage.yml` → `SCOPED_LABELS` array. Decides whether an issue is in scope for the `needs-triage` label.

Renaming any of those four labels requires editing both arrays.

### Issue-form section headers ↔ triage parser

`issue-triage.yml`'s `getSection(body, 'Story points' | 'Priority')` parses `### <heading>` blocks from issue bodies. The heading text in `.github/ISSUE_TEMPLATE/*.yml` must match exactly. `_No response_` and `?` are treated as missing.

### PR template checklist header ↔ checklist gate

`.github/workflows/pr-checklist.yml` fails the check if `## Pre-merge checklist` is missing from the PR body or any item is unticked. The `sectionRe` is anchored on that exact header — renaming the section in `.github/pull_request_template.md` will make every PR fail until the regex is updated.

The checklist items themselves reference `npm run lint`, `npm run build`, `ruff check .`, `mypy .` — these are aspirational expectations for consumer repos, not invocations against this one.

### `/summarize-pr` trailer ↔ commit-counter hook

The three italic lines that `/summarize-pr` writes at the bottom of a PR body are a silent contract with `.claude/hooks/pr-summary-counter.sh`:

```
_🤖 AI summary · <N> commits since summary · HEAD `<short-sha>` · <model>_
_↳ at summary · context … · response … · cache-write … · cache-read … · total … · $X.XX_
_↻ run `/summarize-pr` in Claude Code to refresh this summary_
```

After every `git commit`, the PostToolUse hook re-runs `gh pr edit` to bump `<N>` on line 1 only. It matches with `grep -E 'AI summary · [0-9]+ commits since summary · HEAD \`[0-9a-f]+\`'`. Any change to the line-1 delimiters (`·`), the literal phrase `commits since summary`, or the backticked SHA breaks the hook silently — it exits 0 even on regex miss so a commit never fails because of it. Lines 2 and 3 are frozen at summary time.

The skill's full procedure (which sections to refresh vs preserve, the four-bucket token math, fallback when `claude -p` fails) is in `.claude/skills/summarize-pr/SKILL.md`. Re-read it before editing the trailer format.

### README markers ↔ update-readme splice

`.claude/skills/update-readme/scripts/splice.sh` rewrites the body between `<!-- AI:START -->` and `<!-- AI:END -->`. Removing or moving those markers, or partially deleting one, puts the README into `status=partial` — the skill stops and asks rather than auto-repairing. The user-owned `<!-- USER:START -->` … `<!-- USER:END -->` block is never touched by the skill.

## Claude Code configuration

`.claude/settings.json` registers two PostToolUse hooks:

- `doc-reminder.sh` (matcher: `Edit|Write`) — informational nudge that prints to stderr when files like `package.json`, `pyproject.toml`, `.gitignore`, `eslint.config.*`, CI workflows, etc. are edited. References `docs/SETUP.md`, `docs/SECURITY.md`, `docs/CODE_QUALITY.md`, `docs/CI_CD.md` — those paths are conventions for consumer repos, not files in this one. Exit code 2 surfaces the message to the model; safe to ignore if the doc is already current or doesn't exist.
- `pr-summary-counter.sh` (matcher: `Bash`) — see "trailer ↔ counter" above.

Both hooks always exit 0 on the failure paths (no PR found, no trailer present, branch is HEAD, `gh` unavailable) so they never block tool use.

## Workflow path filters

The two language CI workflows trigger only on path changes:

- `python-format-lint-typecheck.yml` runs in `python/` working dir and expects `pip install -e '.[dev]'` to provide `ruff` and `mypy`. Filters: `python/**/*.py`, `python/**/pyproject.toml`.
- `typescript-lint-typecheck.yml` runs at the repo root and expects `npm run lint` plus `npx tsc --noEmit`. Filters: `src/**`, top-level `*.ts*`/`*.mts`, `tsconfig.json`, `eslint.config.mjs`, `package*.json`.

Neither workflow has any consumer in *this* repo — they are templates ready to drop into a project that follows the matching layout.
