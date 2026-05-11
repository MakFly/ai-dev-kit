#!/usr/bin/env bash
# Hook: PreToolUse(Edit|Write|MultiEdit)
# Blocks any edit/write under src/** or tests/** unless a spec owns it.
#
# Schema: reads JSON from stdin (tool_input.file_path), exits 2 to block.
# Outputs JSON with systemMessage to explain the block.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INPUT="$(cat)"

TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // ""')"
FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')"

# Only inspect file-write tools
case "$TOOL_NAME" in
  Edit|Write|MultiEdit|NotebookEdit) ;;
  *) exit 0 ;;
esac

# No file path → allow
[[ -z "$FILE_PATH" ]] && exit 0

# Normalize to repo-relative
REL_PATH="${FILE_PATH#$PROJECT_DIR/}"

# Allowlist: trivial paths that bypass spec ownership
case "$REL_PATH" in
  package.json|bun.lock|tsconfig.json|.gitignore|README.md|LICENSE|index.ts)
    exit 0 ;;
  CLAUDE.md|AGENTS.md)
    exit 0 ;;
  supports/*|scripts/*|memory/*|specs/*|.claude/*|.ai/*|.git/*)
    exit 0 ;;
esac

# Gate: only src/** and tests/** are governed
case "$REL_PATH" in
  src/*|tests/*) ;;
  *) exit 0 ;;
esac

# Search for owning spec.
# Match strategies (in order, first hit wins):
#   1. Exact path literal in tasks.md or plan.md.
#   2. Glob pattern in tasks.md or plan.md that matches REL_PATH (e.g. `src/auth/*`).
OWNER=""
if [[ -d "$PROJECT_DIR/specs" ]]; then
  while IFS= read -r spec_dir; do
    slug="$(basename "$spec_dir")"
    for artefact in tasks.md plan.md; do
      f="$spec_dir/$artefact"
      [[ -r "$f" ]] || continue

      # 1. Exact literal match
      if grep -qF "$REL_PATH" "$f" 2>/dev/null; then
        OWNER="$slug"; break 2
      fi

      # 2. Glob match — extract candidate path-like tokens under src/ or tests/ and test each
      while IFS= read -r pattern; do
        # shellcheck disable=SC2053
        if [[ "$REL_PATH" == $pattern ]]; then
          OWNER="$slug"; break 3
        fi
      done < <(grep -oE '(src|tests)/[A-Za-z0-9_./*+-]+' "$f" 2>/dev/null | sort -u)
    done
  done < <(find "$PROJECT_DIR/specs" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
fi

if [[ -n "$OWNER" ]]; then
  # Allow — print informational systemMessage
  jq -n --arg slug "$OWNER" --arg path "$REL_PATH" '{
    systemMessage: ("spec-before-code: " + $path + " owned by specs/" + $slug + " ✓")
  }'
  exit 0
fi

# Block
jq -n --arg path "$REL_PATH" '{
  decision: "block",
  reason: ("spec-before-code rule: " + $path + " has no owning spec. Run /specify <slug> first, ensure plan.md §2 or tasks.md Files touched lists this path, then retry.")
}'
exit 2
