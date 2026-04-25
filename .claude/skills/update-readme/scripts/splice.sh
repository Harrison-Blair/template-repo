#!/usr/bin/env bash
# splice.sh — replace the body between <!-- AI:START --> and <!-- AI:END -->
# in a README with the contents of an AI-content file.
#
# Usage: splice.sh <readme_path> <ai_content_file>
#
# Refuses to touch the README unless all four markers (USER:START, USER:END,
# AI:START, AI:END) are present, so a corrupted/legacy README cannot be
# silently overwritten.

set -eu

if [ "$#" -ne 2 ]; then
  printf 'Usage: %s <readme_path> <ai_content_file>\n' "$0" >&2
  exit 2
fi

README="$1"
AI_FILE="$2"

if [ ! -f "$README" ]; then
  printf 'error: README not found: %s\n' "$README" >&2
  exit 1
fi
if [ ! -f "$AI_FILE" ]; then
  printf 'error: AI content file not found: %s\n' "$AI_FILE" >&2
  exit 1
fi

for marker in '<!-- USER:START -->' '<!-- USER:END -->' '<!-- AI:START -->' '<!-- AI:END -->'; do
  if ! grep -qF "$marker" "$README"; then
    printf 'error: marker not found in %s: %s\n' "$README" "$marker" >&2
    printf '       run scan.sh — if status is "legacy" or "partial", fix that first.\n' >&2
    exit 1
  fi
done

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

# Replace everything strictly between AI:START and AI:END with the file's contents.
# Markers themselves are preserved. A trailing newline is appended after the
# injected content if the AI file does not already end with one, so the
# closing marker always lands on its own line.
awk -v aifile="$AI_FILE" '
  BEGIN {
    ai = ""
    while ((getline line < aifile) > 0) {
      ai = ai line "\n"
    }
    close(aifile)
  }
  /<!-- AI:START -->/ {
    print
    if (length(ai) > 0) printf "%s", ai
    in_ai = 1
    next
  }
  /<!-- AI:END -->/ {
    in_ai = 0
    print
    next
  }
  !in_ai { print }
' "$README" > "$TMP"

mv "$TMP" "$README"
trap - EXIT

printf 'ok: spliced AI section into %s\n' "$README"
