#!/usr/bin/env bash
# Lint .claude/agents/*.md and .claude/skills/*/SKILL.md frontmatters against
# the conventions in CLAUDE.md:
#   - Agents MUST have `color:` field.
#   - Skills MUST NOT have `color:` field.
#   - Both MUST have a description starting with or containing "Use PROACTIVELY".
#
# Exits non-zero on any violation. Use as CI check or pre-commit.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXIT=0
AGENT_OK=0; AGENT_BAD=0
SKILL_OK=0; SKILL_BAD=0

# Extract YAML frontmatter between the first pair of `---` lines
extract_frontmatter() {
  awk 'BEGIN{c=0} /^---$/{c++; if(c==2) exit; next} c==1{print}' "$1"
}

# ---- Agents ----
echo "═══ Agents (color: required, 'Use PROACTIVELY' required) ═══"
for f in "$PROJECT_DIR"/.claude/agents/*.md; do
  [[ -f "$f" ]] || continue
  rel="${f#$PROJECT_DIR/}"
  fm=$(extract_frontmatter "$f")

  local_bad=0

  if ! printf '%s\n' "$fm" | grep -qE '^color:[[:space:]]'; then
    echo "  ✗ $rel — missing 'color:' field"
    local_bad=1
  fi

  if ! printf '%s\n' "$fm" | grep -qiE 'use[[:space:]]+proactively'; then
    echo "  ✗ $rel — description missing 'Use PROACTIVELY'"
    local_bad=1
  fi

  if [[ $local_bad -eq 0 ]]; then
    color=$(printf '%s\n' "$fm" | grep -E '^color:' | head -1 | sed 's/^color:[[:space:]]*//')
    echo "  ✓ $rel — color: $color"
    AGENT_OK=$((AGENT_OK + 1))
  else
    AGENT_BAD=$((AGENT_BAD + 1))
    EXIT=1
  fi
done

# ---- Skills ----
echo
echo "═══ Skills (color: forbidden, 'Use PROACTIVELY' required) ═══"
for f in "$PROJECT_DIR"/.claude/skills/*/SKILL.md; do
  [[ -f "$f" ]] || continue
  rel="${f#$PROJECT_DIR/}"
  fm=$(extract_frontmatter "$f")

  local_bad=0

  if printf '%s\n' "$fm" | grep -qE '^color:[[:space:]]'; then
    echo "  ✗ $rel — has FORBIDDEN 'color:' field (skills schema does not allow it)"
    local_bad=1
  fi

  if ! printf '%s\n' "$fm" | grep -qiE 'use[[:space:]]+proactively'; then
    echo "  ✗ $rel — description missing 'Use PROACTIVELY'"
    local_bad=1
  fi

  if [[ $local_bad -eq 0 ]]; then
    name=$(printf '%s\n' "$fm" | grep -E '^name:' | head -1 | sed 's/^name:[[:space:]]*//')
    echo "  ✓ $rel — name: $name"
    SKILL_OK=$((SKILL_OK + 1))
  else
    SKILL_BAD=$((SKILL_BAD + 1))
    EXIT=1
  fi
done

# ---- Summary ----
echo
echo "═══ Summary ═══"
echo "  Agents: $AGENT_OK ok, $AGENT_BAD bad"
echo "  Skills: $SKILL_OK ok, $SKILL_BAD bad"

if [[ $EXIT -eq 0 ]]; then
  echo "  → all frontmatters compliant ✓"
else
  echo "  → frontmatter violations — fix per CLAUDE.md Authoring conventions"
fi

exit $EXIT
