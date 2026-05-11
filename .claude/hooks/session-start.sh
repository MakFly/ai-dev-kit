#!/usr/bin/env bash
# Hook: SessionStart
# Warns if the latest digest is > 7 days old, or absent.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIGEST_DIR="$PROJECT_DIR/supports/digests"

LATEST=""
if [[ -d "$DIGEST_DIR" ]]; then
  LATEST="$(find "$DIGEST_DIR" -maxdepth 1 -type f -name 'digest-*.md' -printf '%T@ %p\n' 2>/dev/null \
    | sort -n | tail -1 | awk '{print $2}')"
fi

if [[ -z "$LATEST" ]]; then
  jq -n '{
    systemMessage: "⚠ digest-freshness: no supports/digests/digest-*.md found. Run ./scripts/sniff-docs.sh before claims about Claude Code / Codex APIs."
  }'
  exit 0
fi

MTIME=$(stat -c %Y "$LATEST" 2>/dev/null || stat -f %m "$LATEST" 2>/dev/null || echo 0)
NOW=$(date +%s)
AGE_DAYS=$(( (NOW - MTIME) / 86400 ))

if (( AGE_DAYS > 7 )); then
  jq -n \
    --arg path "${LATEST#$PROJECT_DIR/}" \
    --arg days "$AGE_DAYS" \
    '{
      systemMessage: ("⚠ digest-freshness: " + $path + " is " + $days + " days old (> 7). Run ./scripts/sniff-docs.sh to refresh before making claims about CC/Codex APIs.")
    }'
else
  jq -n \
    --arg path "${LATEST#$PROJECT_DIR/}" \
    --arg days "$AGE_DAYS" \
    '{
      systemMessage: ("✓ digest: " + $path + " (age " + $days + "d, OK).")
    }'
fi

exit 0
