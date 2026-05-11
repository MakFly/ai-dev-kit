# ADR — v5 bootstrap

**Date:** 2026-05-11
**Status:** accepted
**Constitution version at decision time:** v1.0.0

## Context

ai-dev-kit v3 was a Claude Code plugin + scaffolding CLI ("plugin-first lean kit", 4 skills + 2 agents). Over the May 10-11 sessions the project was wiped and rebooted (auto mode, user-confirmed wipe of repo content including `.git`) as a **Spec-Kit-Native Agentic OS** for Claude Code + Codex CLI.

Local backup of v3 state preserved at `~/ai-dev-v3-backup-1778522179.tgz` (91 KB, sans `node_modules`).

## Decision

Reimplement the project as a thin, spec-driven kit that transposes (not embeds) the concepts of [github/spec-kit](https://github.com/github/spec-kit) into Claude Code's native primitives:

- **5 agents** (`specifier`, `planner`, `decomposer`, `implementer`, `verifier`) — each with mandatory `color:` frontmatter.
- **7 skills** (`/constitution`, `/specify`, `/clarify`, `/plan`, `/tasks`, `/implement`, `/review`).
- **3 rules** (`spec-before-code`, `evidence-required`, `digest-freshness`).
- **3 hooks** (`pre-edit-gate`, `session-start`, `post-write-format`) enforced via `.claude/settings.json`.
- **Sniff loop** (`supports/prompt.md` + `scripts/sniff-docs.sh`) that calls `claude -p` and `codex exec` in parallel against the upstream docs, producing `supports/digests/digest-<ISO>.md`.

## Alternatives considered

- **Embarquer spec-kit directement** — rejected: dependency on their roadmap, less control over hooks and agent shape.
- **Daemon CLI dedicated kernel** — rejected (earlier session): double layer vs Claude Code / Codex internal schedulers, 2-4 person-month cost, no clear ROI for solo dev.
- **MCP-server-as-kernel** — rejected for v5: still adds an extra layer Claude Code and Codex don't really need; native primitives (agents + skills + hooks + filesystem bus) cover the use cases.

## Validation (Phase 6 boot)

- `bun run src/hello.ts` → `Hello, agentic OS\n`, exit 0 ✓
- `bun test` → 1 pass, 0 fail ✓
- Hook `pre-edit-gate.sh` blocks `src/orphan.ts` (no spec), allows `src/hello.ts` (in tasks.md) ✓
- Hook `session-start.sh` warns when no digest ✓
- `./scripts/sniff-docs.sh` produced `claude-*.md` (4.4 KB) and `codex-*.md` (14.6 KB) parallel outputs (merge pending at commit time).

## Consequences

- All future features go through `/constitution → /specify → /clarify → /plan → /tasks → /implement → /review`.
- No code under `src/**` without a matching spec — enforced.
- Sniff digest stale > 7 d. forces refresh — soft-enforced via session-start warning.
- Codex review is non-optional for spec/plan/tasks transitions to `locked`.

## References

- `memory/constitution.md` v1.0.0
- Commits: `f664ad3` (Phase 0+1), `27b3b95` (Phase 2-5), `164c058` (T1), `6b19b7e` (T2)
- Backup: `~/ai-dev-v3-backup-1778522179.tgz`
