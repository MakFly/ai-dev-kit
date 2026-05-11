# AGENTS.md — ai-dev-kit v5

> Cross-runtime doctrine. Read by Codex CLI (hierarchical AGENTS.md discovery) and referenced by Claude Code via `@AGENTS.md`.

## Role

This repository is a **Spec-Kit-Native Agentic OS**: a kit of agents, skills, rules, and hooks that lets either Claude Code or Codex CLI drive the same spec-driven workflow (`/constitution → /specify → /clarify → /plan → /tasks → /implement → /review`).

Use **French** in chat, **English** in code, identifiers, commits, and frontmatter.

## Operating contract

1. **Inspect before editing.** Identify stack, existing skills/agents, hooks, and verification commands.
2. **Spec-before-code.** Every change under `src/**` traces back to a `specs/<slug>/spec.md`. Hook `pre-edit-gate` blocks code edits without spec.
3. **Surgical changes.** Touch only what the user request requires.
4. **Truthful claims only.** Cite `file:line` or doc URL. If unsure, say "not verified" and propose how to verify.
5. **Never auto-push.** Never run destructive git or infra commands without explicit user confirmation.
6. **No secret read or print.** `.env`, credentials, cookies, production data are off-limits.

## Verification commands

- `./scripts/sniff-docs.sh` — refresh upstream doc digest (`supports/digests/<date>.md`).
- `bun test` — when tests exist for the active spec.
- `bun run index.ts` — smoke check.

When a command is unavailable, report it as skipped with the reason. Never claim a check passed unless it actually ran.

## File bus

See `CLAUDE.md` for full mapping. Key invariants:

- `memory/constitution.md` is the supreme contract. Conflict with any other artefact → constitution wins.
- `specs/<slug>/spec.md` is the WHAT. `plan.md` is the HOW. `tasks.md` is the atomic TODO. `reviews/codex-*.md` is the challenge log.
- `supports/digests/<date>.md` < 7 days old or refresh required before claims about CC/Codex APIs.

## Definition of done

- Spec exists. Plan exists. Tasks exist. Codex review exists. Tests pass or are explicitly skipped with reason. No claim without evidence.
