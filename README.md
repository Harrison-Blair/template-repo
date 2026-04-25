<!-- USER:START -->
# template-repo

This repository holds a bunch of different workflows, configuration files, scripts, and other useful things I find myself using on a frequent enough basis to genericize and put in the cloud.
<!-- USER:END -->

> [!WARNING]
> **Disclaimer:** Everything below this line was generated or modified by AI via the [/update-readme](https://github.com/Harrison-Blair/template-repo/tree/main/.claude/skills/update-readme) skill.

<!-- AI:START -->
## What's in here

This is a grab-bag of reusable bits — drop-in GitHub Actions workflows, Claude Code skills, and Windows scripting — meant to be cherry-picked into other repos rather than run as a project.

### GitHub workflows (`.github/workflows/`)

- **issue-triage.yml** — auto-triages new issues.
- **pr-checklist.yml** — enforces a PR checklist.
- **pr-title-and-tag.yml** — validates PR titles and applies tags.
- **python-format-lint-typecheck.yml** — Python formatting, lint, and type-check gate.
- **typescript-lint-typecheck.yml** — TypeScript lint and type-check gate.

### Claude Code skills (`.claude/skills/`)

- **summarize-pr** — refresh a PR description to match the current state of the branch.
- **update-readme** — keep `README.md` in sync with the repo without touching the title or description (this skill produced the section you're reading).

### Scripts (`WindowsPowerShell/`)

- **web-dev.ps1** — launches a 3-monitor web-dev workspace on Windows 11 (Firefox, Windows Terminal panes, VS Code, Docker Desktop) snapped into a fixed layout.

## Setup

No build or install — this is a templates/config repo. To use a piece elsewhere, copy the relevant file or directory into the target repo:

```bash
# Example: drop a workflow into another repo
cp .github/workflows/pr-checklist.yml /path/to/target/.github/workflows/

# Example: drop a Claude skill into another repo
cp -r .claude/skills/update-readme /path/to/target/.claude/skills/
```

The `web-dev.ps1` launcher is meant to be pinned as a Windows shortcut:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\WindowsPowerShell\web-dev.ps1
```
<!-- AI:END -->
