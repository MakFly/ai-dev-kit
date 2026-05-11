#!/usr/bin/env bash
# Refresh supports/digests/ by running `claude -p` and `codex exec` in parallel
# against supports/prompt.md. Idempotent. Exits non-zero on any failure.
#
# Usage:
#   ./scripts/sniff-docs.sh                  # full run (both runtimes)
#   ./scripts/sniff-docs.sh --claude-only    # skip codex
#   ./scripts/sniff-docs.sh --codex-only     # skip claude
#   ./scripts/sniff-docs.sh --dry-run        # print commands, don't execute

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROMPT="$PROJECT_DIR/supports/prompt.md"
DIGEST_DIR="$PROJECT_DIR/supports/digests"
DATE="$(date -u +%Y%m%dT%H%M%SZ)"

RUN_CLAUDE=1
RUN_CODEX=1
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --claude-only) RUN_CODEX=0 ;;
    --codex-only)  RUN_CLAUDE=0 ;;
    --dry-run)     DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,9p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown flag: $arg" >&2
      exit 2
      ;;
  esac
done

# --- Preconditions ---

[[ -r "$PROMPT" ]] || {
  echo "ERROR: prompt not found or unreadable: $PROMPT" >&2
  exit 1
}

if [[ $RUN_CLAUDE -eq 1 ]]; then
  command -v claude >/dev/null 2>&1 || {
    echo "ERROR: 'claude' CLI not in PATH" >&2
    exit 1
  }
fi

if [[ $RUN_CODEX -eq 1 ]]; then
  command -v codex >/dev/null 2>&1 || {
    echo "ERROR: 'codex' CLI not in PATH" >&2
    exit 1
  }
fi

mkdir -p "$DIGEST_DIR"

CLAUDE_OUT="$DIGEST_DIR/claude-$DATE.md"
CODEX_OUT="$DIGEST_DIR/codex-$DATE.md"
DIGEST="$DIGEST_DIR/digest-$DATE.md"

# --- Dry run ---

if [[ $DRY_RUN -eq 1 ]]; then
  echo "[dry-run] DIGEST_DIR=$DIGEST_DIR"
  echo "[dry-run] DATE=$DATE"
  [[ $RUN_CLAUDE -eq 1 ]] && echo "[dry-run] claude -p --system-prompt \"\$(cat $PROMPT)\" --allowed-tools 'WebFetch WebSearch' --output-format text 'Execute ...' > $CLAUDE_OUT  (prompt-as-system, short user trigger; --bare dropped to keep keychain auth)"
  [[ $RUN_CODEX -eq 1 ]] && echo "[dry-run] codex exec --sandbox read-only - < $PROMPT > $CODEX_OUT"
  exit 0
fi

# --- Parallel run ---

CLAUDE_PID=""
CODEX_PID=""
CLAUDE_STATUS=0
CODEX_STATUS=0

if [[ $RUN_CLAUDE -eq 1 ]]; then
  echo "→ claude -p (background)..."
  # NOTE: passing prompt.md as --system-prompt (not as user message) so claude
  # treats it as a directive task, not conversational context. The brief user
  # message acts as the "execute" trigger. Empirically: passing as user msg
  # or via stdin makes claude ask "what should I do?" instead of executing.
  # --bare is NOT used: it strips keychain auth and requires ANTHROPIC_API_KEY.
  (
    claude -p \
      --system-prompt "$(cat "$PROMPT")" \
      --allowed-tools "WebFetch WebSearch" \
      --output-format text \
      "Execute the doc-sniff task per system instructions. Output ONLY the final markdown digest, no preamble, no questions, no commentary." \
      > "$CLAUDE_OUT" 2>&1
  ) &
  CLAUDE_PID=$!
fi

if [[ $RUN_CODEX -eq 1 ]]; then
  echo "→ codex exec (background)..."
  (
    codex exec \
      --sandbox read-only \
      - < "$PROMPT" \
      > "$CODEX_OUT" 2>&1
  ) &
  CODEX_PID=$!
fi

[[ -n "$CLAUDE_PID" ]] && {
  echo "→ waiting on claude ($CLAUDE_PID)..."
  wait "$CLAUDE_PID" || CLAUDE_STATUS=$?
}
[[ -n "$CODEX_PID" ]] && {
  echo "→ waiting on codex ($CODEX_PID)..."
  wait "$CODEX_PID" || CODEX_STATUS=$?
}

# --- Merge ---

{
  echo "# Doc Sniff Digest — $DATE"
  echo
  echo "**Generated:** $DATE"
  echo "**claude -p:** status $CLAUDE_STATUS$([[ $RUN_CLAUDE -eq 0 ]] && echo ' (skipped)')"
  echo "**codex exec:** status $CODEX_STATUS$([[ $RUN_CODEX -eq 0 ]] && echo ' (skipped)')"
  echo
  echo "---"
  if [[ $RUN_CLAUDE -eq 1 ]]; then
    echo
    echo "## A. From Claude Code (\`claude -p\`)"
    echo
    cat "$CLAUDE_OUT"
    echo
  fi
  if [[ $RUN_CODEX -eq 1 ]]; then
    echo "---"
    echo
    echo "## B. From Codex CLI (\`codex exec\`)"
    echo
    cat "$CODEX_OUT"
    echo
  fi
} > "$DIGEST"

# --- Report ---

if [[ $CLAUDE_STATUS -ne 0 || $CODEX_STATUS -ne 0 ]]; then
  echo "✗ Sniff finished with failures (claude=$CLAUDE_STATUS, codex=$CODEX_STATUS)." >&2
  echo "  Partial digest at: $DIGEST" >&2
  exit 1
fi

echo "✓ Digest written: $DIGEST"
