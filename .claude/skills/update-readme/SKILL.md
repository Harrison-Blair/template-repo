---
name: update-readme
description: Refresh the AI-managed sections of README.md (documentation table of contents, setup guide) while preserving the user-owned title and project description. Use when the user says "update readme", "refresh readme", "regenerate readme docs", or before tagging a release.
---

# update-readme

Keeps `README.md` in sync with the repo without overwriting the project's title and description. Two protected zones:

- **USER section** (`<!-- USER:START -->` … `<!-- USER:END -->`) — title + project description. Never edited unless the user explicitly says so.
- **AI section** (`<!-- AI:START -->` … `<!-- AI:END -->`) — documentation TOC + setup guide. Rewritten every run.

The skill leans on bundled bash scripts so the main-session model spends tokens only on judgment calls (which docs deserve a TOC entry, what the setup narrative should say) — not on enumerating files or splicing markers.

## Files

- `scripts/scan.sh` — repo facts report (marker state, manifests, CI, docs). Deterministic, no LLM tokens.
- `scripts/splice.sh` — replaces the body between `<!-- AI:START -->` and `<!-- AI:END -->` with a file's contents.
- `templates/README.template.md` — bootstrap when no README exists.

## Workflow

1. **Scan.** From the repo root:
   ```bash
   bash .claude/skills/update-readme/scripts/scan.sh > /tmp/readme-scan.txt
   cat /tmp/readme-scan.txt
   ```
   The `[readme]` section's `status=` line is the branching signal:
   - `status=ok` → markers present, go to step 3.
   - `status=missing` → no README → step 2a.
   - `status=legacy` → README exists, no markers → step 2b.
   - `status=partial` → mixed marker state → stop and surface to the user. Don't try to auto-repair.

2a. **Bootstrap (no README).** Ask the user for the project title and a one-paragraph description. Write `README.md` from `templates/README.template.md`, substituting `{{PROJECT_NAME}}` and `{{PROJECT_DESCRIPTION}}`. Then continue at step 3.

2b. **Wrap legacy README (diff-and-confirm).** Show the user a concrete plan:
   - Existing content will be wrapped verbatim as the USER section (title + description preserved).
   - An AI-disclaimer line and empty AI block will be appended below.

   Confirm explicitly before writing. After confirmation, rewrite `README.md` to:
   ```
   <!-- USER:START -->
   <existing content unchanged>
   <!-- USER:END -->

   > **Disclaimer:** Everything below this line was generated or modified by AI via the [/update-readme](https://github.com/Harrison-Blair/template-repo/tree/main/.claude/skills/update-readme) skill.

   <!-- AI:START -->
   <!-- AI:END -->
   ```
   Then continue at step 3.

3. **Curate the AI section.** Two subsections in this fixed order:

   1. **Documentation** — links to other markdown in the repo. Pull candidates from the scan's `[docs]` block. Use judgment: skip internal-only files (drafts, scratchpads, `INTERNAL.md`-style names). Write a one-line blurb per link based on the file's first heading or its opening paragraph — use `Read` only when the heading alone is not informative.
   2. **Setup** — install + run instructions. Combine:
      - Manifest hints from the scan's `[manifests]` block (e.g. `package.json` → `npm install` / `npm run <script>`).
      - A targeted Read of the actual manifest for real script names (e.g. `package.json#scripts`, `pyproject.toml#[project.scripts]`).
      - Any `Makefile`, `justfile`, or `scripts/` entries that look like real entry points — read sparingly.
      - CI workflow files only if they reveal a non-obvious build step worth documenting.

   Tone: concise, copy-pasteable commands. Don't pad with prose. If the repo has nothing setup-worthy (e.g. a config/templates repo), say so in one line rather than inventing steps.

4. **Splice.** Write the curated section to a tempfile, then:
   ```bash
   bash .claude/skills/update-readme/scripts/splice.sh README.md /tmp/readme-ai.md
   ```

5. **Show the diff** (`git diff README.md`) and stop. Don't commit — the user owns that step.

## Guardrails

- Never edit content between `<!-- USER:START -->` and `<!-- USER:END -->` unless the user explicitly asks.
- Never delete or move the marker comments themselves.
- Never run the splice in `status=partial` state — markers are corrupted; stop and ask how to proceed.
- The scan reports file *paths and first headings only*. For setup curation, Read manifest/script files directly as needed — don't dump whole files into context.
- The skill only writes `README.md`. If you find yourself wanting to edit other files, stop — that's out of scope.

## Cross-platform notes

Scripts use POSIX bash + `awk`/`grep`/`find`/`sed` — no `jq`, no Python. Runs on Ubuntu and on Git Bash for Windows.

## Drag-and-drop into another repo

Copy `.claude/skills/update-readme/` into the target repo's `.claude/skills/`. No other setup required. The first run will detect a missing/legacy README and walk the user through bootstrapping.
