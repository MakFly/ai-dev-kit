#!/usr/bin/env bash
# Hook: SubagentStop
# When the `implementer` subagent finishes, verify the doctrine
# "one task = one commit" by checking for uncommitted src/** or tests/** changes.
# Warns via systemMessage; never blocks.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INPUT="$(cat)"

# Extract subagent name — schemas vary by CC version, try several keys
AGENT_NAME="$(printf '%s' "$INPUT" | jq -r '
  .subagent_name //
  .subagent_type //
  .agent_name //
  .agent //
  .name //
  ""
' 2>/dev/null || echo "")"

# Only act on the implementer
[[ "$AGENT_NAME" == "implementer" ]] || exit 0

# Check uncommitted src/** and tests/** changes
DIRTY=$(cd "$PROJECT_DIR" && git status -s -- src/ tests/ 2>/dev/null || true)

if [[ -n "$DIRTY" ]]; then
  # Warn, do not block — implementer may legitimately leave a partial run
  jq -n --arg dirty "$DIRTY" '{
    systemMessage: ("⚠ implementer stopped with uncommitted src/ or tests/ changes (doctrine: one task = one commit). Uncommitted:\n" + $dirty)
  }'
else
  jq -n '{
    systemMessage: "✓ implementer stopped; working tree clean (one-task-one-commit doctrine respected)."
  }'
fi

exit 0
