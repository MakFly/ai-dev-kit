# ai-dev-kit — Spec-Driven Agentic OS for Claude Code + OpenAI Codex CLI

> **Self-hosted toolkit that enforces spec-before-code discipline across Claude Code and OpenAI Codex CLI.** Native skills, subagents, hooks, and an adversarial codex review loop — inspired by [github/spec-kit](https://github.com/github/spec-kit), built directly on Claude Code primitives. No daemon, no custom binary, no vendor lock-in.

![Status](https://img.shields.io/badge/status-alpha-orange)
![License](https://img.shields.io/badge/license-MIT-green)
![Bun](https://img.shields.io/badge/runtime-bun%20%E2%89%A5%201.3-black)
![Claude Code](https://img.shields.io/badge/Claude%20Code-%E2%89%A5%202.1-9cf)
![Codex CLI](https://img.shields.io/badge/Codex%20CLI-%E2%89%A5%200.13-blue)

**Keywords:** Claude Code skills · Claude Code subagents · Claude Code hooks · Claude Code plugin · OpenAI Codex CLI · spec-driven development · SDD · AI coding agent · agentic OS · github spec-kit alternative · Anthropic developer tools · Bun TypeScript

---

## Table of Contents

1. [What is ai-dev-kit?](#what-is-ai-dev-kit)
2. [Why spec-driven development for AI coding agents?](#why-spec-driven-development-for-ai-coding-agents)
3. [Key features](#key-features)
4. [Architecture](#architecture)
5. [Requirements](#requirements)
6. [Installation](#installation)
7. [Quickstart: your first feature in five minutes](#quickstart-your-first-feature-in-five-minutes)
8. [The pipeline in detail](#the-pipeline-in-detail)
9. [Components reference](#components-reference)
10. [Comparison with github/spec-kit and other AI agent frameworks](#comparison-with-githubspec-kit-and-other-ai-agent-frameworks)
11. [Frequently asked questions](#frequently-asked-questions)
12. [Roadmap](#roadmap)
13. [Contributing](#contributing)
14. [License](#license)

---

## What is ai-dev-kit?

**ai-dev-kit** is an open-source workflow that turns [Claude Code](https://code.claude.com) (Anthropic's terminal coding agent) and [OpenAI Codex CLI](https://developers.openai.com/codex) into a **spec-driven development environment**. Instead of letting AI agents jump straight from a user request to source code, ai-dev-kit enforces a chain of versioned artefacts — `spec.md → plan.md → tasks.md → src/**` — each challenged by an adversarial Codex review before the next phase locks.

It is **not** a hosted SaaS, **not** a wrapper around Claude or Codex, and **not** a fork. It is a directory of native Claude Code skills, subagents, rules, hooks, and shell scripts that you drop into any project alongside your `package.json`.

If you have used [github/spec-kit](https://github.com/github/spec-kit), think of ai-dev-kit as **"spec-kit's discipline + Claude Code's primitives + Codex's adversarial review, in one repo"**.

---

## Why spec-driven development for AI coding agents?

Large-language-model coding tools (Claude Code, OpenAI Codex, Cursor, Aider, Cline, Continue.dev) share a common failure mode: they happily produce plausible-looking code that drifts from intent, invents APIs, or passes shallow tests while quietly breaking the contract the user had in mind.

**Spec-driven development (SDD)** — popularised by [github/spec-kit](https://github.com/github/spec-kit) in 2025 — counters this by making the specification the **single source of truth**. The code becomes its projection, not the other way around.

ai-dev-kit pushes the idea further with four mechanical guarantees:

1. **Hook-enforced spec-before-code.** `.claude/hooks/pre-edit-gate.sh` blocks any `Write` / `Edit` / `MultiEdit` on `src/**` or `tests/**` whose path is not listed in an owning `specs/<slug>/plan.md` or `tasks.md`. Hard block, not advice.
2. **Adversarial dual review.** Every `spec.md`, `plan.md`, and `tasks.md` is challenged by both a Claude-native `verifier` subagent and a separate `codex exec --sandbox read-only` session, before being locked.
3. **Always-fresh upstream docs.** A weekly sniff loop (`./scripts/sniff-docs.sh`) calls `claude -p` and `codex exec` in parallel against Anthropic and OpenAI documentation. The `session-start` hook warns if your digest is older than seven days.
4. **One task, one commit.** The `implementer` subagent commits per atomic task. The `subagent-stop` hook flags any leftover uncommitted change in `src/**` / `tests/**`.

---

## Key features

- 🧩 **Five specialised subagents** — specifier, planner, decomposer, implementer, verifier — each with a distinct color, system prompt, tool allow-list, and verdict schema.
- 🪄 **Seven slash-command skills** — `/constitution`, `/specify`, `/clarify`, `/plan`, `/tasks`, `/implement`, `/review`. Each declares `context: fork` and an `agent:` target, so invoking the skill spawns the matching subagent in its own forked context.
- 🛡️ **Four production hooks** — `PreToolUse`, `PostToolUse`, `SessionStart`, `SubagentStop` — registered in `.claude/settings.json` and tested offline with deterministic JSON outputs.
- 📜 **Three doctrinal rules** — spec-before-code, evidence-required, digest-freshness — encoded as markdown so every agent can read and quote them.
- 🔄 **Documentation sniff loop** — `scripts/sniff-docs.sh` keeps a dated digest of Claude Code + Codex CLI upstream docs and the top agentic GitHub repositories.
- 🧪 **Lint + smoke + full-cycle scripts** — CI-ready checks for frontmatter conformance, single-step pipeline liveness, and end-to-end `/specify → /review` execution.
- 📐 **Git worktree-friendly** — the implementer doctrine is one-task-one-commit; clean history per feature is the default.

---

## Architecture

```
╔══════════════════════════════ ai-dev-kit ═══════════════════════════════════╗
║                                                                              ║
║  ┌─ supports/ ─────────────┐    ┌─ scripts/ ──────────────┐                 ║
║  │  prompt.md              │───▶│  sniff-docs.sh          │                 ║
║  │  (master research       │    │  claude -p ║ codex exec │                 ║
║  │   prompt, Anthropic     │    │  (parallel, read-only)  │                 ║
║  │   skill format)         │    └─────────────────────────┘                 ║
║  │  digests/<date>.md  ◀───┐                                                 ║
║  └─────────────────────────┘                                                 ║
║                                                                              ║
║  ┌─ .claude/ ──────────────────────────────────────────────────────────┐   ║
║  │ skills/  ▶ /constitution /specify /clarify /plan /tasks /implement  │   ║
║  │           /review                                                    │   ║
║  │ agents/  ▶ specifier(cyan) planner(blue) decomposer(green)           │   ║
║  │           implementer(yellow) verifier(red)                          │   ║
║  │ rules/   ▶ spec-before-code · evidence-required · digest-freshness   │   ║
║  │ hooks/   ▶ pre-edit-gate · session-start · post-write-format ·       │   ║
║  │           subagent-stop                                              │   ║
║  │ settings.json (permissions + hook registration)                      │   ║
║  └────────────────────────────────────────────────────────────────────┘    ║
║                                          │                                   ║
║                                          ▼ produce                           ║
║  ┌─ memory/ ──────────────┐    ┌─ specs/<feature>/ ──────────────────┐    ║
║  │  constitution.md       │    │  spec.md   ◀── /specify             │    ║
║  │  decisions/<date>.md   │    │  plan.md   ◀── /plan                │    ║
║  └────────────────────────┘    │  tasks.md  ◀── /tasks               │    ║
║                                 │  reviews/  ◀── /review              │    ║
║                                 │    verifier-<artefact>-<ISO>.md     │    ║
║                                 │    codex-<artefact>-<ISO>.md        │    ║
║                                 └──────────────────────────────────────┘    ║
║                                                                              ║
║  ┌─ src/  tests/ ──────────────────────────────────────────────────────┐   ║
║  │  Only created by /implement, gated by pre-edit-gate.sh hook.         │   ║
║  └─────────────────────────────────────────────────────────────────────┘    ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

---

## Requirements

| Tool | Minimum version | Purpose |
|---|---|---|
| [Bun](https://bun.com) | 1.3 | TypeScript runtime, test runner, package manager |
| [Claude Code CLI](https://code.claude.com) | 2.1 | Hosts skills, subagents, hooks |
| [OpenAI Codex CLI](https://developers.openai.com/codex) | 0.13 | Adversarial reviewer in `/review` + sniff loop |
| `jq` | 1.7 | Hook JSON output |
| `git` | 2.30 | One-task-one-commit doctrine |
| Optional: [`ig`](https://github.com/) (instant-grep) | — | Faster code search across the repo |

---

## Installation

```bash
git clone https://github.com/<your-org>/ai-dev-kit my-project
cd my-project
bun install

# Verify the kit is healthy
./scripts/lint-frontmatter.sh    # 5/5 agents OK, 7/7 skills OK
./scripts/smoke-test.sh          # end-to-end /specify liveness (~30 s)

# Refresh the upstream doc digest (one-time, then weekly)
./scripts/sniff-docs.sh
```

---

## Quickstart: your first feature in five minutes

Open a Claude Code session in the repo:

```bash
claude
```

Then run the spec-driven pipeline, one slash-command at a time:

```
/constitution                    # author memory/constitution.md (once per project)
/specify hello-name              # specifier writes specs/hello-name/spec.md
/clarify hello-name              # resolve open questions interactively
/plan hello-name                 # planner writes specs/hello-name/plan.md
/review hello-name plan          # codex challenges the plan
/tasks hello-name                # decomposer writes specs/hello-name/tasks.md
/implement hello-name            # implementer writes src/** + tests/**, commits per task
/review hello-name               # final dual review (verifier + codex)
```

Each slash command forks into a dedicated subagent (specifier, planner, decomposer, implementer, verifier) so the main conversation stays clean.

**Real benchmark** from this repo's `scripts/full-cycle-test.sh` on a trivial CLI feature:

| Phase | Duration | Output |
|---|---|---|
| `/specify` | 51 s | spec.md 59 lines, Status: locked |
| `/plan` | 49 s | plan.md 95 lines |
| `/tasks` | 32 s | tasks.md 44 lines, 3 atomic tasks |
| `/implement` | 86 s | 3 commits, src + tests written |
| `bun test` | <1 s | 3 pass / 0 fail / 9 expect() |

Total: **~3.5 minutes of agent time** to produce a fully-specified, planned, decomposed, implemented, and tested feature — fully unattended.

---

## The pipeline in detail

### `/constitution` — the supreme contract

Edits `memory/constitution.md`, which sets immutable principles (Article I), the canonical workflow (Article II), authoring conventions (Article III), out-of-scope items (Article IV), and required verifications (Article V). In case of conflict between any other artefact and the constitution, the constitution wins.

### `/specify <slug>` — WHAT and WHY only

Forks into the **specifier** subagent (color: cyan). Produces `specs/<slug>/spec.md` with eight strict sections: Problem, Outcome, Users & scenarios, Acceptance criteria, Non-goals, Open questions, Constraints linked to constitution, References. The specifier refuses to write any HOW — no library names, no architecture.

### `/clarify <slug>` — resolve open questions one by one

Reads §6 Open questions from `spec.md`, presents each to the user with concrete options, integrates the answers, bumps the spec to `Status: clarified`. Decisions and rationales are recorded in an Appendix A.

### `/plan <slug>` — HOW only

Forks into the **planner** subagent (color: blue). Produces `specs/<slug>/plan.md` with an ASCII architecture diagram, a Components table, a Data flow, a Risks & mitigations matrix, rejected alternatives, a test strategy, dependencies, and an Acceptance mapping cross-check against the spec. Refuses to plan if the spec is still `Status: draft`.

### `/tasks <slug>` — atomic decomposition

Forks into the **decomposer** subagent (color: green). Produces `specs/<slug>/tasks.md` as a flat ordered list of tasks. Each task has a single owner, an estimate ≤ 1 hour, explicit dependencies, explicit `Files touched`, and one testable acceptance command.

### `/implement <slug>` — write the code

Forks into the **implementer** subagent (color: yellow). Walks `tasks.md` one task at a time: reads it, implements only the listed files, runs the acceptance command, marks the task done, and commits with message `feat(<slug>): T<N> <title>`. The `pre-edit-gate` hook deterministically blocks any drift from the listed `Files touched`.

### `/review <slug> [artefact]` — adversarial dual review

Forks into the **verifier** subagent (color: red) which:
1. Re-runs every check claimed by the implementer (pasting actual `stdout` / `stderr`).
2. Spawns `codex exec --sandbox read-only` to challenge the same artefact from a different model and runtime.
3. Compares verdicts, writes two reports — `verifier-<artefact>-<ISO>.md` and `codex-<artefact>-<ISO>.md` — and prints a synthesis to chat.

Lock the artefact only if **both** reviewers return `PASS`.

---

## Components reference

### Subagents (`.claude/agents/`)

| Name | Color | Used by | Tools |
|---|---|---|---|
| `specifier` | cyan | `/specify` | Read, Write, Edit, Bash, WebFetch |
| `planner` | blue | `/plan` | Read, Write, Edit, Bash, WebFetch, Glob, Grep |
| `decomposer` | green | `/tasks` | Read, Write, Edit, Bash, Glob, Grep |
| `implementer` | yellow | `/implement` | Read, Write, Edit, Bash, Grep, Glob |
| `verifier` | red | `/review` | Read, Bash, Write, Glob, Grep |

### Slash-command skills (`.claude/skills/<name>/SKILL.md`)

| Skill | Frontmatter | Body purpose |
|---|---|---|
| `/constitution` | `name`, `description`, `argument-hint`, `allowed-tools`, `when_to_use` | Edit `memory/constitution.md` |
| `/specify` | `+ context: fork`, `agent: specifier` | Delegate to specifier |
| `/clarify` | `allowed-tools` (in-session) | Interactive Q&A |
| `/plan` | `+ context: fork`, `agent: planner` | Delegate to planner |
| `/tasks` | `+ context: fork`, `agent: decomposer` | Delegate to decomposer |
| `/implement` | `+ context: fork`, `agent: implementer` | Delegate to implementer |
| `/review` | `+ context: fork`, `agent: verifier` | Verifier + codex challenge |

### Hooks (`.claude/hooks/`)

| Hook | Claude Code event | Effect |
|---|---|---|
| `pre-edit-gate.sh` | `PreToolUse(Edit\|Write\|MultiEdit\|NotebookEdit)` | Blocks writes to `src/**` / `tests/**` without owning spec |
| `post-write-format.sh` | `PostToolUse(Edit\|Write\|MultiEdit)` | Trailing-newline normalization on artefact files |
| `session-start.sh` | `SessionStart` | Warns if newest digest > 7 days or absent |
| `subagent-stop.sh` | `SubagentStop` | Warns if implementer left uncommitted changes |

### Rules (`.claude/rules/`)

| Rule | Enforcement |
|---|---|
| `spec-before-code.md` | Deterministic (hook) |
| `evidence-required.md` | Doctrinal (verifier + codex) |
| `digest-freshness.md` | Soft (session-start hook) |

### Scripts (`scripts/`)

| Script | Purpose | Typical time |
|---|---|---|
| `sniff-docs.sh` | Parallel `claude -p` + `codex exec` doc digest | 2-5 min |
| `lint-frontmatter.sh` | Verify agent/skill frontmatter conventions | <1 s |
| `smoke-test.sh` | End-to-end `/specify` liveness check | 30-60 s |
| `full-cycle-test.sh` | Chain `/specify → /review` with verification | 5-15 min |

---

## Comparison with github/spec-kit and other AI agent frameworks

| Feature | ai-dev-kit | [github/spec-kit](https://github.com/github/spec-kit) | [LangGraph](https://github.com/langchain-ai/langgraph) | [AutoGen](https://github.com/microsoft/autogen) | [OpenHands](https://github.com/OpenHands/OpenHands) | [Aider](https://github.com/Aider-AI/aider) |
|---|---|---|---|---|---|---|
| Spec-driven workflow | ✅ native | ✅ flagship | ⚠ DIY | ⚠ DIY | ⚠ partial | ❌ |
| Adversarial dual review | ✅ `verifier` + `codex` | ❌ | ❌ | ❌ | ❌ | ❌ |
| Hook-enforced spec-before-code | ✅ `pre-edit-gate` | ❌ | ❌ | ❌ | ❌ | ❌ |
| Built on Claude Code natively | ✅ | ⚠ agent-agnostic | ❌ | ❌ | ❌ | ❌ |
| Built on Codex CLI natively | ✅ | ⚠ agent-agnostic | ❌ | ❌ | ❌ | ❌ |
| Cross-runtime (CC + Codex) | ✅ | ⚠ | ❌ | ❌ | ❌ | ❌ |
| Daemon required | ❌ none | ❌ none | ❌ | ❌ runtime | ✅ Docker | ❌ |
| Distribution | git clone | `uvx specify` | pip | pip | Docker | pip |
| Language | Bun TS + bash | Python | Python | Python | Python | Python |

**TL;DR**: ai-dev-kit is the most discipline-focused option, the only one with built-in adversarial review, and the only one that natively targets Claude Code + Codex CLI together.

---

## Frequently asked questions

### Is ai-dev-kit a Claude Code plugin?

Not yet, but it is plugin-shaped. The `.claude/` directory follows the marketplace plugin layout (skills, agents, hooks, settings.json). Packaging as an installable plugin via `claude /plugin install` is on the roadmap.

### Does it work without Codex CLI?

The full pipeline degrades gracefully: `/review` still runs the Claude-native verifier even if `codex` is missing. The sniff loop has `--claude-only` and `--codex-only` flags. But you lose the adversarial review value if you skip Codex — the whole point is two independent models challenging each other.

### Can I use it with other LLM CLIs (Cursor, Aider, Cline)?

The skills and hooks are Claude Code-specific. The artefact format (`spec.md`, `plan.md`, `tasks.md`) and the rules are tool-agnostic, so other agents can read them. Full integration would require porting the skills.

### Why Bun and not Node.js?

Bun ships a built-in test runner (`bun test`), a TypeScript loader (no `tsc` step), `Bun.spawn` for clean subprocess capture, and `Bun.serve` for any local web tooling — keeping the dependency surface minimal. Node + tsx + Jest would also work; we just have not bothered.

### What is `context: fork` in a skill frontmatter?

A Claude Code feature (≥ 2.1.x) that runs a slash-command skill inside a forked subagent context instead of the main conversation. Combined with `agent: <name>`, it lets you delegate `/specify` to the `specifier` subagent (its own system prompt, tools, model) without manually invoking the `Task` tool. Source: [Claude Code sub-agents documentation](https://code.claude.com/docs/en/sub-agents).

### How is "spec-before-code" actually enforced?

A `PreToolUse(Edit|Write|MultiEdit)` hook (`pre-edit-gate.sh`) intercepts every file-write attempt. If the target is under `src/**` or `tests/**`, it greps `specs/*/tasks.md` and `specs/*/plan.md` for an owning spec. No owner found → block with exit code 2 and a `decision: block` JSON output. Allowlist exists for trivial paths (`package.json`, `README.md`, etc.).

### Is the codex review sandbox safe?

Yes — `codex exec --sandbox read-only` cannot write to disk, modify state, run network calls (beyond what the model orchestrates), or escape its workspace. The shell redirect `> specs/<slug>/reviews/codex-<artefact>-<ISO>.md` is done from outside the sandbox by the verifier.

### What happens if my digest is stale?

The `session-start.sh` hook emits a `systemMessage` warning at every Claude Code session start, reminding you to run `./scripts/sniff-docs.sh`. Work is not blocked — claims about Claude Code or Codex APIs should just be qualified with `(based on cached digest from <date>, may be stale)`.

### Can I add more agents?

Article IV of the bundled constitution caps the kit at five agents (`no more than 5 agents in any single release`). Adding one requires removing one. This is intentional: Claude Code's automatic delegation is driven by the `description` field, and more agents dilute the routing signal.

### Is this production-ready?

**No.** Status is alpha. The pipeline has been smoke-tested and full-cycle-tested on trivial features. It has not been used to ship anything customer-facing. Honest known gaps are listed in the [Roadmap](#roadmap).

---

## Roadmap

- [ ] **v5.0** — Stabilise the pipeline. Full-cycle test green end-to-end including codex verdict extraction.
- [ ] **v5.1** — Filter `codex exec` verbose tool traces; keep only the final markdown verdict.
- [ ] **v5.2** — Package as installable Claude Code plugin (`claude /plugin install ai-dev-kit`).
- [ ] **v5.3** — Optional `--isolation worktree` for `/implement` so parallel tasks run in independent git worktrees.
- [ ] **v5.4** — `/digest-apply` skill that reads the latest digest and proposes patches to CLAUDE.md, agents, and hooks.
- [ ] **v6.0** — MCP server kernel option for cross-team collaboration. Reuse the file bus.

---

## Contributing

Pull requests welcome. Please:

1. Open a `/specify` issue describing WHAT and WHY before any PR with code.
2. Follow the `/specify → /plan → /tasks → /implement → /review` loop on your branch.
3. Run `./scripts/lint-frontmatter.sh` and `./scripts/smoke-test.sh` before pushing.
4. Cite sources for any factual claim in your PR description (`file:line` or doc URL).

The kit is licensed MIT — see [LICENSE](#license).

---

## License

MIT. See [LICENSE](./LICENSE) (to be added).

---

## See also

- [Claude Code documentation](https://code.claude.com/docs/en/) — official Anthropic docs.
- [OpenAI Codex CLI documentation](https://developers.openai.com/codex) — official OpenAI docs.
- [github/spec-kit](https://github.com/github/spec-kit) — original spec-driven development toolkit.
- [Model Context Protocol (MCP)](https://www.anthropic.com/news/model-context-protocol) — the protocol both Claude Code and Codex consume.

---

*ai-dev-kit — bringing Karpathy-grade discipline to AI-assisted coding.*
