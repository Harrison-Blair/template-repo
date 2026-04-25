#!/usr/bin/env bash
# scan.sh — emit a structured facts report for the update-readme skill.
#
# Output is ini-ish: [section] headers with key=value or path<TAB>title rows.
# Designed to be cheap (file presence + first headings only — never reads bodies)
# and parseable by the main-session model without jq/Python.
#
# Usage: scan.sh [repo_root]
#   repo_root defaults to `git rev-parse --show-toplevel` or $PWD.

set -eu

REPO_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$REPO_ROOT"

README="README.md"

# ---- [meta] ---------------------------------------------------------------
printf '[meta]\n'
printf 'repo_root=%s\n' "$REPO_ROOT"
printf 'scanned_at=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '\n'

# ---- [readme] -------------------------------------------------------------
printf '[readme]\n'
if [ ! -f "$README" ]; then
  printf 'status=missing\n\n'
else
  us=$(grep -cF '<!-- USER:START -->' "$README" 2>/dev/null || true); us=${us:-0}
  ue=$(grep -cF '<!-- USER:END -->'   "$README" 2>/dev/null || true); ue=${ue:-0}
  as=$(grep -cF '<!-- AI:START -->'   "$README" 2>/dev/null || true); as=${as:-0}
  ae=$(grep -cF '<!-- AI:END -->'     "$README" 2>/dev/null || true); ae=${ae:-0}
  printf 'user_start=%s\n' "$us"
  printf 'user_end=%s\n'   "$ue"
  printf 'ai_start=%s\n'   "$as"
  printf 'ai_end=%s\n'     "$ae"
  if [ "$us" -ge 1 ] && [ "$ue" -ge 1 ] && [ "$as" -ge 1 ] && [ "$ae" -ge 1 ]; then
    printf 'status=ok\n'
  elif [ "$us" = 0 ] && [ "$ue" = 0 ] && [ "$as" = 0 ] && [ "$ae" = 0 ]; then
    printf 'status=legacy\n'
  else
    printf 'status=partial\n'
  fi
  printf '\n'
fi

# ---- [manifests] ----------------------------------------------------------
printf '[manifests]\n'
[ -f package.json ]                                    && printf 'node=package.json\n'                || true
[ -f pnpm-lock.yaml ]                                  && printf 'node=pnpm-lock.yaml\n'              || true
[ -f yarn.lock ]                                       && printf 'node=yarn.lock\n'                   || true
[ -f pyproject.toml ]                                  && printf 'python=pyproject.toml\n'            || true
[ -f requirements.txt ]                                && printf 'python=requirements.txt\n'          || true
[ -f Pipfile ]                                         && printf 'python=Pipfile\n'                   || true
[ -f poetry.lock ]                                     && printf 'python=poetry.lock\n'               || true
[ -f Cargo.toml ]                                      && printf 'rust=Cargo.toml\n'                  || true
[ -f go.mod ]                                          && printf 'go=go.mod\n'                        || true
[ -f pom.xml ]                                         && printf 'java=pom.xml\n'                     || true
{ [ -f build.gradle ] || [ -f build.gradle.kts ]; }    && printf 'java=gradle\n'                      || true
[ -f Gemfile ]                                         && printf 'ruby=Gemfile\n'                     || true
[ -f composer.json ]                                   && printf 'php=composer.json\n'                || true
[ -f mix.exs ]                                         && printf 'elixir=mix.exs\n'                   || true
[ -f Dockerfile ]                                      && printf 'container=Dockerfile\n'             || true
{ [ -f docker-compose.yml ] || [ -f docker-compose.yaml ]; } && printf 'container=docker-compose\n'   || true
[ -f Makefile ]                                        && printf 'make=Makefile\n'                    || true
[ -f justfile ]                                        && printf 'just=justfile\n'                    || true
printf '\n'

# ---- [ci] -----------------------------------------------------------------
printf '[ci]\n'
if [ -d .github/workflows ]; then
  find .github/workflows -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) 2>/dev/null \
    | sort | sed 's|^|github=|' || true
fi
[ -f .gitlab-ci.yml ]       && printf 'gitlab=.gitlab-ci.yml\n'       || true
[ -f .circleci/config.yml ] && printf 'circleci=.circleci/config.yml\n' || true
printf '\n'

# ---- [scripts] ------------------------------------------------------------
printf '[scripts]\n'
list_scripts() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  find "$dir" -maxdepth 3 -type f \
    \( -name '*.sh' -o -name '*.ps1' -o -name '*.py' -o -name '*.js' -o -name '*.mjs' -o -name '*.ts' \) \
    2>/dev/null | sort | head -50 | sed 's|^|file=|' || true
}
list_scripts scripts
list_scripts bin
list_scripts WindowsPowerShell
list_scripts WindowsCommandPrompt
printf '\n'

# ---- [docs] ---------------------------------------------------------------
# Format per row:  <relative_path>\t<first_h1_title_or_empty>
# Top-level *.md (excluding README) + everything under docs/.
printf '[docs]\n'
emit_doc_row() {
  local f="$1"
  [ -f "$f" ] || return 0
  local title
  title=$(grep -m1 '^# ' "$f" 2>/dev/null | sed 's/^# *//' || true)
  printf '%s\t%s\n' "$f" "$title"
}

for f in *.md; do
  [ -f "$f" ] || continue
  [ "$f" = "README.md" ] && continue
  emit_doc_row "$f"
done

if [ -d docs ]; then
  find docs -type f -name '*.md' 2>/dev/null | sort | while IFS= read -r f; do
    emit_doc_row "$f"
  done
fi
printf '\n'

# ---- [summary] ------------------------------------------------------------
printf '[summary]\n'
total_md=$(find . -type f -name '*.md' \
  -not -path './node_modules/*' \
  -not -path './.git/*' \
  -not -path './vendor/*' \
  2>/dev/null | wc -l | tr -d ' ')
printf 'markdown_files=%s\n' "$total_md"

exit 0
