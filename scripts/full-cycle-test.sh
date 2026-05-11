#!/usr/bin/env bash
# End-to-end full-cycle test of the v5 pipeline.
# Chains: /specify → /plan → /tasks → /implement → /review.
# Skips /clarify (we craft a trivial feature with no admissible open questions).
#
# Each phase is a SEPARATE `claude -p` call so failures are localized and the
# previous artefacts are visible to the next call via the filesystem bus.
#
# Usage:
#   ./scripts/full-cycle-test.sh                # cleanup at end (default)
#   ./scripts/full-cycle-test.sh --keep         # keep specs/cycle-*/ + src + tests
#   ./scripts/full-cycle-test.sh --timeout 240  # per-step timeout (default 180)

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

TIMEOUT_PER_STEP=180         # default per-step (override via --timeout)
TIMEOUT_REVIEW=360           # /review needs more time: codex challenge is slow
KEEP=0
SLUG="cycle-$(date +%s)"
SPEC_DIR="$PROJECT_DIR/specs/$SLUG"
SRC_FILE="$PROJECT_DIR/src/$SLUG.ts"
TEST_FILE="$PROJECT_DIR/tests/$SLUG.test.ts"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep) KEEP=1; shift ;;
    --timeout) TIMEOUT_PER_STEP="$2"; shift 2 ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
done

command -v claude >/dev/null || { echo "ERROR: 'claude' not in PATH" >&2; exit 1; }

cleanup() {
  if [[ $KEEP -eq 0 ]]; then
    echo
    echo "→ cleanup: rm -rf $SPEC_DIR $SRC_FILE $TEST_FILE"
    rm -rf "$SPEC_DIR" "$SRC_FILE" "$TEST_FILE"
    # Also: revert any commits made by /implement during this run? No — keep
    # the commit log as evidence. User can `git reset` if they want.
  else
    echo
    echo "→ --keep: artefacts retained at $SPEC_DIR (and src/${SLUG}.ts, tests/${SLUG}.test.ts if any)"
  fi
}
trap cleanup EXIT

echo "═══════════════════════════════════════════════════════════════════"
echo "  full-cycle-test"
echo "  slug=$SLUG"
echo "  timeout per step=${TIMEOUT_PER_STEP}s"
echo "═══════════════════════════════════════════════════════════════════"

run_step() {
  local label="$1" prompt="$2" timeout_override="${3:-}"
  local step_timeout="${timeout_override:-$TIMEOUT_PER_STEP}"
  echo
  echo "▶ Step: $label  (timeout=${step_timeout}s)"
  local start end exit_code
  start=$(date +%s)
  set +e
  local RESULT
  RESULT=$(timeout "$step_timeout" claude -p --output-format text "$prompt" 2>&1)
  exit_code=$?
  set -e
  end=$(date +%s)
  echo "  exit=$exit_code  duration=$((end - start))s"
  if [[ $exit_code -ne 0 ]]; then
    echo "  -- claude output (last 30 lines) --"
    printf '%s\n' "$RESULT" | tail -30
    echo "  -- (end) --"
    echo "✗ step '$label' failed"
    return 1
  fi
  # Print summary line if the agent emitted one
  printf '%s\n' "$RESULT" | tail -5
  return 0
}

verify_file() {
  local path="$1" min_lines="$2" label="$3"
  if [[ ! -f "$path" ]]; then
    echo "  ✗ $label missing: $path"
    return 1
  fi
  local lines
  lines=$(wc -l < "$path")
  if (( lines < min_lines )); then
    echo "  ✗ $label too short ($lines lines, expected ≥ $min_lines): $path"
    head -10 "$path"
    return 1
  fi
  echo "  ✓ $label: $path ($lines lines)"
  return 0
}

# ───── Step 1: /specify ───────────────────────────────────────────────
SPEC_PROMPT=$(cat <<EOF
Invoke the /specify skill (which will fork into the specifier subagent) with slug='$SLUG' for this trivial feature:

  Feature: a Bun TypeScript CLI \`src/$SLUG.ts\` that, when run as \`bun run src/$SLUG.ts <name>\`,
  prints exactly one line "Hello <name>!\\n" to stdout and exits 0.
  - Exactly one positional argument: name (any non-empty string).
  - If no argument or empty, print "Usage: bun run src/$SLUG.ts <name>\\n" to stderr and exit 1.
  - No flags, no i18n, no config file, no dependency.

Because the feature is fully constrained, the spec MUST have Status: locked (no admissible open questions). If the specifier finds open questions anyway, mark them as Deferred with a one-line rationale and still set Status: locked. Write specs/$SLUG/spec.md and stop.
EOF
)
run_step "/specify $SLUG" "$SPEC_PROMPT" || exit 1
verify_file "$SPEC_DIR/spec.md" 15 "spec.md" || exit 1

# ───── Step 2: /plan ───────────────────────────────────────────────────
PLAN_PROMPT=$(cat <<EOF
Invoke the /plan skill (which forks into the planner subagent) with slug='$SLUG'. Read the existing spec at specs/$SLUG/spec.md (Status: locked).

Constraints for plan.md §2 Components — exactly two files:
  src/$SLUG.ts      (the entry)
  tests/$SLUG.test.ts (Bun spawn test)

Set plan.md Status: locked since the spec is trivial. Write specs/$SLUG/plan.md and stop.
EOF
)
run_step "/plan $SLUG" "$PLAN_PROMPT" || exit 1
verify_file "$SPEC_DIR/plan.md" 20 "plan.md" || exit 1

# ───── Step 3: /tasks ──────────────────────────────────────────────────
TASKS_PROMPT=$(cat <<EOF
Invoke the /tasks skill (which forks into the decomposer subagent) with slug='$SLUG'. Read specs/$SLUG/plan.md.

Decompose into ≤ 3 atomic tasks. Each task must:
- Own: implementer
- List explicit Files touched (src/$SLUG.ts or tests/$SLUG.test.ts)
- Have a runnable acceptance command (bun test … or bun run …)

Write specs/$SLUG/tasks.md and stop.
EOF
)
run_step "/tasks $SLUG" "$TASKS_PROMPT" || exit 1
verify_file "$SPEC_DIR/tasks.md" 15 "tasks.md" || exit 1

# ───── Step 4: /implement ──────────────────────────────────────────────
IMPL_PROMPT=$(cat <<EOF
Invoke the /implement skill (which forks into the implementer subagent) with slug='$SLUG'. Read specs/$SLUG/tasks.md and execute tasks in order.

For each task:
  1. Write only the files listed in 'Files touched'.
  2. Run the acceptance command and paste real output.
  3. Commit per task with message "feat($SLUG): T<N> <title>".

When all tasks are done, run \`bun test tests/$SLUG.test.ts\` once and stop.
EOF
)
run_step "/implement $SLUG" "$IMPL_PROMPT" || exit 1
verify_file "$SRC_FILE" 1 "src/$SLUG.ts" || exit 1
verify_file "$TEST_FILE" 5 "tests/$SLUG.test.ts" || exit 1

echo
echo "▶ Step: bun test on $SLUG"
if bun test "tests/$SLUG.test.ts" 2>&1 | tail -10; then
  echo "  ✓ bun test green"
else
  echo "  ✗ bun test failed"
  exit 1
fi

# ───── Step 5: /review ─────────────────────────────────────────────────
REV_PROMPT=$(cat <<EOF
Invoke the /review skill (which forks into the verifier subagent) with slug='$SLUG' and artefact='all'. Run:
  1. The verifier's own re-check of spec ↔ plan ↔ tasks ↔ code coherence.
  2. The codex challenge via \`codex exec --sandbox read-only ... > specs/$SLUG/reviews/codex-<artefact>-<ISO>.md\` per the SKILL.md procedure.

Write at least specs/$SLUG/reviews/verifier-*.md and ideally specs/$SLUG/reviews/codex-*.md. Stop.
EOF
)
# /review uses the longer TIMEOUT_REVIEW: codex challenge alone takes 3-5 min.
# We do NOT exit on timeout (124) — codex often writes its file before the
# wrapper finishes. We verify the artefact instead.
set +e
run_step "/review $SLUG" "$REV_PROMPT" "$TIMEOUT_REVIEW"
REVIEW_EXIT=$?
set -e

echo
echo "▶ Step: verify reviews/ (review exit was $REVIEW_EXIT)"
if [[ -d "$SPEC_DIR/reviews" ]]; then
  ls -la "$SPEC_DIR/reviews/"
  REVIEW_COUNT=0
  for r in "$SPEC_DIR"/reviews/*.md; do
    [[ -f "$r" ]] || continue
    if [[ -s "$r" ]]; then
      echo "  ✓ $(basename "$r") ($(wc -l < "$r") lines, $(stat -c %s "$r") bytes)"
      REVIEW_COUNT=$((REVIEW_COUNT + 1))
    fi
  done
  if (( REVIEW_COUNT == 0 )); then
    echo "  ✗ no non-empty review artefact written"
    exit 1
  fi
  # If the wrapper timed out but reviews exist, consider it a soft pass.
  if [[ $REVIEW_EXIT -ne 0 && $REVIEW_EXIT -ne 124 ]]; then
    echo "  ✗ /review failed with non-timeout exit $REVIEW_EXIT"
    exit 1
  fi
  if [[ $REVIEW_EXIT -eq 124 ]]; then
    echo "  ⚠ /review hit timeout but produced $REVIEW_COUNT review file(s) — soft pass"
  fi
else
  echo "  ✗ no reviews/ directory created"
  exit 1
fi

echo
echo "═══════════════════════════════════════════════════════════════════"
echo "  ✅ FULL-CYCLE TEST PASSED"
echo "  slug=$SLUG"
echo "  artefacts:"
echo "    $SPEC_DIR/{spec,plan,tasks}.md"
echo "    $SRC_FILE"
echo "    $TEST_FILE"
echo "    $SPEC_DIR/reviews/"
echo "═══════════════════════════════════════════════════════════════════"
exit 0
