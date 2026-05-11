#!/usr/bin/env bash
# Hook: PostToolUse(Write|Edit|MultiEdit)
# Light markdown post-format for spec.md / plan.md / tasks.md:
#   - Ensure trailing newline
#   - Normalize "**Date:**" lines to current ISO UTC if absent or templated

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INPUT="$(cat)"

TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // ""')"
FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')"

case "$TOOL_NAME" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

[[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]] && exit 0

REL_PATH="${FILE_PATH#$PROJECT_DIR/}"

case "$REL_PATH" in
  specs/*/spec.md|specs/*/plan.md|specs/*/tasks.md|memory/constitution.md|memory/decisions/*.md) ;;
  *) exit 0 ;;
esac

# Ensure trailing newline
if [[ -n "$(tail -c 1 "$FILE_PATH")" ]]; then
  printf '\n' >> "$FILE_PATH"
fi

exit 0
