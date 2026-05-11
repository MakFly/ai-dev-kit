---
name: review
description: Use PROACTIVELY after /plan, /tasks, or /implement completes — and any time the user invokes /review <slug> [artefact]. Runs both the `verifier` subagent (forked context, Claude-native) and codex (via `codex exec`) on the named artefact. Writes specs/<slug>/reviews/{verifier,codex}-<artefact>-<date>.md. Never edits the implementation.
argument-hint: <slug> [spec|plan|tasks|all]
context: fork
agent: verifier
allowed-tools: Read, Bash, Write
when_to_use: |
  Use after any artefact is freshly written or modified. Default: review the latest artefact for
  <slug>. Explicitly invoked with /review.
---

# /review

Dual review: native `verifier` subagent + adversarial `codex exec` challenge.

## Procedure (runs inside the forked `verifier` subagent)

1. **Resolve artefact.** First arg = slug. Second arg = artefact name (`spec`, `plan`, `tasks`, `all`). Default = the most recently-modified of the three.
2. **Native verifier work.** As the `verifier` agent in fork mode, perform your normal job — re-run claimed checks, cross-check spec/plan/tasks/code. Write `specs/<slug>/reviews/verifier-<artefact>-<ISO>.md`.
3. **Codex challenge (Bash).** Run codex via stdin (avoids YAML/option parsing issues) and redirect output to file (codex `--sandbox read-only` cannot write to disk itself):
   ```bash
   ISO=$(date -u +%Y%m%dT%H%M%SZ)
   PROMPT_TEXT=$(cat <<EOF
   You are Codex acting as an adversarial reviewer for ai-dev-kit v5.
   Target artefact: specs/<slug>/<artefact>.md
   Constitution: memory/constitution.md
   Latest digest: supports/digests/digest-*.md (newest)
   
   Surface, with file:line citations:
   1. Contradictions between artefact and constitution.
   2. Missing or non-testable acceptance criteria.
   3. Optimistic claims without evidence.
   4. Risks omitted from plan.md §4.
   5. Coverage gaps in tasks.md vs spec §4.
   
   Output ONLY strict markdown matching this schema, no preamble, no chat:
   
   # Codex review — <slug>/<artefact>
   **Date:** <ISO>
   **Verdict:** PASS | FAIL | NEEDS_REWORK
   ## Findings
   - <file:line> — <finding>
   ## Required fixes (if not PASS)
   - <one-liner>
   EOF
   )
   codex exec --sandbox read-only "$PROMPT_TEXT" \
     > "specs/<slug>/reviews/codex-<artefact>-$ISO.md"
   ```
4. **Compare verdicts.** Read both reports. Print to chat: verifier verdict, codex verdict, points of agreement, divergences.
5. **Lock if both PASS.** Update artefact frontmatter `Status: locked`. Else recommend next step (`/clarify`, `/plan` rerun, or `/implement` on affected tasks).

## Output convention

- `specs/<slug>/reviews/verifier-<artefact>-<ISO>.md` — Claude-native challenger
- `specs/<slug>/reviews/codex-<artefact>-<ISO>.md` — adversarial second pair of eyes

## Doctrine

- **Two eyes, not one.** Codex must run even if verifier passes. Disagreement is information, not error.
- **Block locking on FAIL.** Either reviewer FAIL ⇒ no Status: locked. User must address.
- **No edits.** Reviews produce verdicts. Fixes happen via `/implement` re-runs on affected tasks.
- **Digest freshness check.** If `supports/digests/latest` > 7 days, run `./scripts/sniff-docs.sh` first.

## Pipeline position

```
/plan → /review [YOU] → /tasks
/tasks → /review [YOU] → /implement
/implement → /review [YOU] → done
```
