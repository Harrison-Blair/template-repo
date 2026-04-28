#!/usr/bin/env bash
# scan.sh <target-dir>
# Enumerate markdown files for the summarize-directory skill.
#
# Output sections (machine-friendly, line-oriented):
#   [target] absolute target path
#   [existing] which of INDEX.md/SUMMARY.md/README.md already live at target
#   [top] one line per top-level *.md file (excluding skip list)
#   [sub] one line per *.md file exactly one level deep (path relative to target)
#   [subdirs] one line per immediate subdirectory that contained any *.md
#   [skipped-dirs] subdirectories that were ignored by the skip list
#
# Skip list rationale: hidden dot-dirs, dependency caches, and build outputs
# generate noise that adds no value to a directory summary. README/INDEX/SUMMARY
# at the *target* level are excluded from the file lists because the skill
# treats them specially (read them, but don't summarize them as TOC entries).

set -euo pipefail

target="${1:-}"
if [[ -z "$target" ]]; then
  echo "usage: scan.sh <target-dir>" >&2
  exit 2
fi
if [[ ! -d "$target" ]]; then
  echo "not a directory: $target" >&2
  exit 2
fi

# Normalize: strip trailing slash, resolve to absolute.
target="${target%/}"
abs_target="$(cd "$target" && pwd)"

# Directories to skip when descending one level.
skip_dir_re='^(\.|node_modules$|\.git$|\.venv$|venv$|__pycache__$|dist$|build$|target$|\.next$|\.cache$|coverage$)'

# Files to skip at top level (treated specially by the skill).
is_special_file() {
  case "$(basename "$1")" in
    INDEX.md|SUMMARY.md|README.md) return 0 ;;
    *) return 1 ;;
  esac
}

echo "[target] $abs_target"

# --- existing special files at target ---
echo "[existing]"
for f in INDEX.md SUMMARY.md README.md; do
  if [[ -f "$target/$f" ]]; then
    echo "$f"
  fi
done

# --- top-level markdown ---
echo "[top]"
# shellcheck disable=SC2012
for f in "$target"/*.md; do
  [[ -e "$f" ]] || continue
  if is_special_file "$f"; then
    continue
  fi
  # Hidden files (start with .) — globs above don't match them, but be explicit.
  base="$(basename "$f")"
  [[ "$base" == .* ]] && continue
  echo "$base"
done

# --- one-level-deep markdown + subdir bookkeeping ---
sub_tmp="$(mktemp)"
subdirs_tmp="$(mktemp)"
skipped_tmp="$(mktemp)"
trap 'rm -f "$sub_tmp" "$subdirs_tmp" "$skipped_tmp"' EXIT

for d in "$target"/*/; do
  [[ -e "$d" ]] || continue
  dname="$(basename "$d")"
  if [[ "$dname" =~ $skip_dir_re ]]; then
    echo "$dname" >> "$skipped_tmp"
    continue
  fi
  found_any=0
  for f in "$d"*.md; do
    [[ -e "$f" ]] || continue
    base="$(basename "$f")"
    [[ "$base" == .* ]] && continue
    # Don't skip INDEX/SUMMARY/README in subdirs — they're informational
    # signals about whether that subdir has been summarized already.
    echo "$dname/$base" >> "$sub_tmp"
    found_any=1
  done
  if [[ "$found_any" -eq 1 ]]; then
    echo "$dname" >> "$subdirs_tmp"
  fi
done

echo "[sub]"
if [[ -s "$sub_tmp" ]]; then sort "$sub_tmp"; fi

echo "[subdirs]"
if [[ -s "$subdirs_tmp" ]]; then sort "$subdirs_tmp"; fi

echo "[skipped-dirs]"
if [[ -s "$skipped_tmp" ]]; then sort "$skipped_tmp"; fi
