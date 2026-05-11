# Constitution — ai-dev-kit

**Version:** v1.0.0
**Last amended:** 2026-05-11

> Supreme contract of this repository. In case of conflict with any other artefact, this file wins. Edit only via the `/constitution` skill.

## Article I — Principles

1. **Spec-before-code.** No file under `src/**` or `tests/**` exists without a corresponding `specs/<slug>/spec.md` and `plan.md`. Enforced by `.claude/hooks/pre-edit-gate.sh`.
2. **Evidence-required.** Every factual claim cites a verifiable source (`file:line`, doc URL, or fresh digest). "I haven't verified" beats plausible-sounding content.
3. **Codex-as-adversary.** Every artefact (spec, plan, tasks) is challenged by `codex exec` before the next phase. Disagreement is information.
4. **Surgical changes.** Touch only what the user request requires. No "while I'm here" cleanup.
5. **No invention.** If a path, API, or version is unknown, run `--help`, fetch the doc, or ask. Never write from memory.

## Article II — Workflow

The canonical loop is :

```
/constitution → /specify → /clarify → /plan → /tasks → /implement → /review
```

Skipping a step requires a written ADR in `memory/decisions/<ISO>-<slug>.md` explaining what was skipped and why.

## Article III — Authoring conventions

- **Agents** (`.claude/agents/*.md`) MUST include `color:` in frontmatter.
- **Skills** (`.claude/skills/<slug>/SKILL.md`) MUST NOT include `color:` (not part of schema).
- **`description:`** for any auto-delegated subagent or skill MUST start with `Use PROACTIVELY when …`.
- **Commits** are imperative, lowercase, scoped. One task = one commit during `/implement`.
- **French** in chat. **English** in code, identifiers, frontmatter, commits.

## Article IV — Out of scope

- No daemon outside what Claude Code or Codex already runs.
- No reimplementation of features already shipped by the underlying runtimes (scheduler, hooks, MCP, plugin manager).
- No more than 5 agents in any single release. Add one = remove one.
- No telemetry, no analytics, no phone-home.

## Article V — Verification

Required commands and their meaning:

| Command | Meaning |
| --- | --- |
| `./scripts/sniff-docs.sh` | Refresh `supports/digests/`. Required if newest digest > 7 days. |
| `bun test` | Run test suite when tests exist. |
| `bun run index.ts` | Smoke check the entry point. |
| `/review <slug>` | Dual review (verifier subagent + codex exec) on a slug's latest artefact. Blocks locking on FAIL. |

Codex review is non-optional for `spec.md`, `plan.md`, `tasks.md` before each transitions from `draft` to `reviewed`/`locked`.

## Amendments

- 2026-05-11 v0.0.0 → v1.0.0 — Initial constitution. Replaces the bootstrap placeholder. Bootstrap during Phase 6 boot of v5 pivot.
