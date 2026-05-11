# CLAUDE.md — ai-dev-kit v5

> Spec-Kit-Native Agentic OS for Claude Code + Codex CLI.
> Inspired by [github/spec-kit](https://github.com/github/spec-kit) — concepts transposed, not embedded.

@AGENTS.md

## Operating contract

- French in conversation. English in code, identifiers, commits, frontmatter.
- **Spec-before-code.** No file under `src/**` is created without a matching `specs/<slug>/spec.md`. Enforced by hook `pre-edit-gate`.
- **Evidence-required.** Every factual claim cites `specs/<slug>/spec.md:line` or a URL from a fresh `supports/digests/<date>.md` (≤ 7 days old).
- **Truthfulness.** If unsure, say so. Never invent paths, APIs, or results. "I haven't verified" beats plausible-sounding content.
- **No destructive action without explicit user confirmation.** `rm -rf`, `git reset --hard`, force-push, dropping branches — confirm first.
- **Hooks are deterministic guardrails.** Do not bypass them. If a hook blocks, fix the root cause, don't override.

## Pipeline (spec-driven)

```
/constitution  →  memory/constitution.md           (principes immuables)
/specify       →  specs/<slug>/spec.md             (WHAT + WHY)
/clarify       →  specs/<slug>/spec.md (revisé)    (lève ambiguïtés)
/plan          →  specs/<slug>/plan.md             (HOW : archi + risques)
/tasks         →  specs/<slug>/tasks.md            (atomic tasks)
/implement     →  src/** + tests/**                (exécute les tasks)
/review        →  specs/<slug>/reviews/codex-*.md  (codex challenge)
```

## Authoring conventions

- Claude Code **agents** (`.claude/agents/*.md`) MUST include `color:` in frontmatter (validated against all existing agents under `~/.claude/agents/` and bundled plugins).
- Claude Code **skills** (`.claude/skills/<slug>/SKILL.md`) MUST NOT include `color:` (not part of skill schema). Valid fields: `name`, `description`, `allowed-tools` / `tools`, `argument-hint`, `version`, `disable-model-invocation`, `when_to_use`.
- `description:` MUST start with `Use PROACTIVELY when …` for any subagent intended for automatic delegation. Source: https://code.claude.com/docs/en/sub-agents.md#understand-automatic-delegation
- Subagents that should rely on `ig` (instant-grep) MUST set `tools: Bash, Write` and `disallowedTools: Read, Grep, Glob` in frontmatter, plus a body line: *"Use `ig "pattern" [path]` via Bash for all code search."*

## File bus

| Path | Purpose | Tracked ? |
|---|---|---|
| `memory/constitution.md` | Project-immutable principles | ✅ |
| `memory/decisions/<date>.md` | ADRs | ✅ |
| `specs/<slug>/spec.md` | WHAT + WHY | ✅ |
| `specs/<slug>/plan.md` | HOW | ✅ |
| `specs/<slug>/tasks.md` | atomic TODO list | ✅ |
| `specs/<slug>/reviews/codex-*.md` | codex review reports | ✅ |
| `supports/prompt.md` | sniff master prompt | ✅ |
| `supports/digests/<date>.md` | sniff output | ❌ (gitignored) |
| `.ai/reports/<role>-<slug>-<date>.md` | ephemeral worker outputs | ❌ (gitignored) |

## Verification

- `./scripts/sniff-docs.sh` — refresh `supports/digests/` against latest CC + Codex docs + agentic repos.
- `bun test` — when the spec adds tests.
- Codex review on every spec/plan/tasks before `/implement` starts.

## Definition of done

- Spec → plan → tasks → implementation → codex review, all artefacts committed.
- No `src/**` file without spec ancestor.
- No claim without `file:line` or URL evidence.
- Hooks pass without override.

---

## Annex A — Bun stack conventions (kept from `bun init`)

Default to using **Bun** instead of Node.js.

- `bun <file>` instead of `node <file>` or `ts-node <file>`
- `bun test` instead of `jest` or `vitest`
- `bun build <file>` instead of `webpack` or `esbuild`
- `bun install` instead of `npm/yarn/pnpm install`
- `bun run <script>` instead of `npm run`
- `bunx <package>` instead of `npx`
- Bun auto-loads `.env`; do not import `dotenv`.

### Bun APIs to prefer
- `Bun.serve()` (WebSockets, HTTPS, routes) — not `express`.
- `bun:sqlite` — not `better-sqlite3`.
- `Bun.redis`, `Bun.sql` — not `ioredis`, `pg`.
- `WebSocket` built-in — not `ws`.
- `Bun.file` — over `node:fs` readFile/writeFile.
- `` Bun.$`...` `` — over `execa`.

### Testing
```ts
import { test, expect } from "bun:test";
test("hello world", () => { expect(1).toBe(1); });
```

For more, read `node_modules/bun-types/docs/**.mdx`.
