# Rule — digest-freshness

> **No claim about Claude Code, Codex CLI, or external agentic tooling without a `supports/digests/digest-*.md` newer than 7 days.**

## Enforcement

- **`session-start.sh` hook:** at every session start, compute age of the newest `supports/digests/digest-*.md`. If > 7 days, print a `systemMessage` warning the agent to run `./scripts/sniff-docs.sh` before making claims about CC/Codex.
- **Skills `/plan`, `/specify`, `/review`:** all explicitly check digest age in their procedure and warn the user.
- **No hard block.** Stale digest does not prevent work — it only forces the agent to qualify claims with `(based on cached digest from <date>, may be stale)`.

## Refresh

```bash
./scripts/sniff-docs.sh           # full run, both runtimes
./scripts/sniff-docs.sh --dry-run # preview commands
```

Output: `supports/digests/digest-<ISO>.md` (merged from claude + codex outputs).

## What goes into a digest

(cf `supports/prompt.md` Output Format) — Claude Code changes ≤ 30 d., Codex CLI changes ≤ 30 d., top agentic repos, RFCs/open issues. Sources cited per claim.

## Rationale

CC and Codex ship CLI flag changes, hook schema changes, and agent system updates monthly. A spec written against a 3-month-old understanding will fail review. The digest is the single source of truth for "what works today".
