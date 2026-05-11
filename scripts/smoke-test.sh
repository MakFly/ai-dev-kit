#!/usr/bin/env bash
# End-to-end smoke test of the v5 pipeline.
#
# Goal: prove that a fresh `claude -p` invocation, given a user prompt that
# asks for /specify, actually discovers the skill, forks into the `specifier`
# subagent, and writes specs/<slug>/spec.md.
#
# This is the "is the pipeline alive?" test. Run after any change to skills,
# agents, hooks, or settings.json.
#
# Usage:
#   ./scripts/smoke-test.sh                 # full run (timeout 120s)
#   ./scripts/smoke-test.sh --timeout 240   # longer timeout
#   ./scripts/smoke-test.sh --keep          # don't cleanup specs/smoke-*/
#   ./scripts/smoke-test.sh --dry-run       # print plan, don't run claude

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

TIMEOUT_SEC=120
KEEP=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --timeout) TIMEOUT_SEC="$2"; shift 2 ;;
    --keep) KEEP=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "Unknown flag: $1" >&2; exit 2 ;;
  esac
done

command -v claude >/dev/null || { echo "ERROR: 'claude' not in PATH" >&2; exit 1; }

SLUG="smoke-$(date +%s)"
SPEC_DIR="$PROJECT_DIR/specs/$SLUG"

cleanup() {
  if [[ $KEEP -eq 0 && -d "$SPEC_DIR" ]]; then
    echo "→ cleanup: rm -rf $SPEC_DIR"
    rm -rf "$SPEC_DIR"
  fi
}
trap cleanup EXIT

echo "═══ smoke-test ═══"
echo "  slug=$SLUG"
echo "  timeout=${TIMEOUT_SEC}s"
echo "  spec target=$SPEC_DIR/spec.md"
echo

USER_PROMPT="Use the /specify skill with slug '$SLUG' to write a minimal spec for: a tiny CLI that prints the current ISO-8601 UTC date when called via 'bun run src/date.ts'. Acceptance: stdout is a valid ISO date, exit 0. Keep the spec under 30 lines. After /specify completes, stop — do not run /plan or /tasks."

if [[ $DRY_RUN -eq 1 ]]; then
  echo "[dry-run] would run:"
  echo "  claude -p --output-format text \\"
  echo "    \"\$USER_PROMPT\""
  echo
  echo "  then check $SPEC_DIR/spec.md exists"
  exit 0
fi

echo "→ launching claude -p (timeout ${TIMEOUT_SEC}s)…"
START=$(date +%s)
set +e
RESULT=$(timeout "$TIMEOUT_SEC" claude -p \
  --output-format text \
  "$USER_PROMPT" 2>&1)
CLAUDE_EXIT=$?
set -e
END=$(date +%s)
ELAPSED=$((END - START))

echo "→ claude exited $CLAUDE_EXIT in ${ELAPSED}s"
echo
echo "--- claude response (head 30 lines) ---"
echo "$RESULT" | head -30
echo "--- (truncated) ---"
echo

# Verification
if [[ -f "$SPEC_DIR/spec.md" ]]; then
  LINES=$(wc -l < "$SPEC_DIR/spec.md")
  echo "✓ $SPEC_DIR/spec.md exists ($LINES lines)"
  echo
  echo "--- spec.md head ---"
  head -25 "$SPEC_DIR/spec.md"
  echo "--- (truncated) ---"
  echo
  echo "✅ SMOKE TEST PASSED"
  exit 0
else
  echo "✗ $SPEC_DIR/spec.md NOT written"
  echo "✗ files in $SPEC_DIR (if any):"
  ls -la "$SPEC_DIR" 2>/dev/null || echo "  (directory does not exist)"
  echo
  echo "❌ SMOKE TEST FAILED"
  exit 1
fi
