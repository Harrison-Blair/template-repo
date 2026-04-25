#!/usr/bin/env bash
# PostToolUse nudge: when Claude edits a file whose change usually
# requires updating documentation, print a reminder. Informational
# only — Claude is free to skip if the doc is already current.

set -euo pipefail

input=$(cat)
file_path=$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get("tool_input", {}).get("file_path", ""))
except Exception:
    print("")
' 2>/dev/null || true)

[ -z "$file_path" ] && exit 0

case "$file_path" in
  */package.json|*/package-lock.json|*/pyproject.toml|*/requirements*.txt|*/.python-version)
    msg="Dependency manifest changed -> update docs/SETUP.md (and the relevant section)." ;;
  */.gitignore|*.env*|*/secrets*|*/credentials*)
    msg="Secrets / ignore pattern touched -> review docs/SECURITY.md for accuracy." ;;
  */eslint.config.*|*/tsconfig.json|*/.prettier*|*/.editorconfig)
    msg="Code-quality tooling changed -> update docs/CODE_QUALITY.md." ;;
  */next.config.*|*/postcss.config.*|*/tailwind.config.*)
    msg="Build/framework config changed -> update docs/SETUP.md and docs/CODE_QUALITY.md if rules shifted." ;;
  */.github/workflows/*|*/Dockerfile*|*/vercel.json|*/netlify.toml|*/fly.toml)
    msg="CI/deploy config changed -> update docs/CI_CD.md." ;;
  *)
    exit 0 ;;
esac

printf 'Doc reminder: %s\n' "$msg" >&2
exit 2
