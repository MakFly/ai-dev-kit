---
name: doc-sniff
description: Master research prompt to keep Claude Code + Codex CLI docs and top agentic GitHub repos always up-to-date. Used non-interactively by scripts/sniff-docs.sh — both claude -p and codex exec consume this file as their initial prompt.
version: 1.0.0
---

# Context

You are running **non-interactively** (`claude -p` or `codex exec`) to refresh the upstream documentation digest of the ai-dev-kit project (Spec-Kit-Native Agentic OS for Claude Code + Codex CLI). Your output is written to `supports/digests/<runtime>-<iso>.md` and consumed by the project's agents and skills as fresh ground truth.

You operate in a workspace-read-only sandbox. Use **WebFetch** and **WebSearch** for everything. Do not attempt to edit files.

# Goal

Produce a concise, dated digest covering exactly:

1. **Claude Code changes** (≤ 30 days) — sub-agents, skills, hooks, plugins, MCP, CLI flags.
2. **Codex CLI changes** (≤ 30 days) — config, AGENTS.md, MCP, sandbox modes, exec flags.
3. **Top agentic-orchestration GitHub repos** — 5 most relevant, with stars / last-commit / one-line concept.
4. **RFCs / open issues** affecting a spec-driven workflow (spec-kit, claude-code, codex).

# Sources to fetch (priority order, mandatory)

## Claude Code official docs

1. https://code.claude.com/docs/en/sub-agents — auto-delegation, frontmatter fields, scopes, `color:` field
2. https://code.claude.com/docs/en/skills — skill frontmatter, `allowed-tools`, `when_to_use`, `disable-model-invocation`
3. https://code.claude.com/docs/en/hooks — hook events, output schemas (`systemMessage`, `hookSpecificOutput`)
4. https://code.claude.com/docs/en/plugins — plugin marketplace, install/update
5. https://code.claude.com/docs/en/mcp — MCP integration in CC
6. https://code.claude.com/docs/en/cli-reference — flags (`-p`, `--bare`, `--agents`, `--allowed-tools`, `--output-format`)
7. https://code.claude.com/docs/en/settings — settings.json schema

## Codex CLI official docs

1. https://developers.openai.com/codex/cli/features — feature matrix
2. https://developers.openai.com/codex/guides/agents-md — AGENTS.md hierarchy
3. https://developers.openai.com/codex/mcp — MCP in Codex
4. https://developers.openai.com/codex/config-reference — config.toml schema (was /cli/config, dead since v0.13x)
5. https://developers.openai.com/codex/concepts/sandboxing — sandbox modes (was /cli/sandbox, dead since v0.13x)
6. https://developers.openai.com/codex/changelog — release notes (≤ 30 days)
7. https://developers.openai.com/codex/hooks — Codex hooks (parity with CC hooks?)
8. https://developers.openai.com/codex/subagents — Codex subagents

## GitHub repos (use WebSearch + WebFetch)

- `github.com/github/spec-kit` — Spec-Driven Development reference (slash commands, artefact schema)
- `github.com/openai/codex` — Codex CLI source (release notes since ≤ 30 d.)
- `github.com/anthropics/claude-code-action` — official GitHub Action
- WebSearch query : `"agentic OS" OR "agent orchestration" stars:>500 pushed:>2026-04-11`

# Output format (strict)

```markdown
# Doc Sniff Digest — <ISO-8601 UTC date>

**Source runtime:** <claude-code | codex>
**Generated at:** <ISO-8601>

## 1. Claude Code — changes ≤ 30 days
- [<short title>](<URL>) — <one-line summary>
- ...

## 2. Codex CLI — changes ≤ 30 days
- [<title>](<URL>) — <summary>
- ...

## 3. Top agentic repos

| Repo | Stars | Last commit | Concept |
| --- | --- | --- | --- |
| [name](URL) | n | YYYY-MM-DD | one line |

## 4. RFCs / open issues affecting ai-dev-kit
- [<title>](<URL>) — <why it matters in 1 line>

## Sources consulted
- <URL fetched 1>
- <URL fetched 2>
```

# Constraints (truthfulness, non-negotiable)

- **Cite every claim.** Every bullet ends with a URL that was actually fetched in this session. Bullets without URL are forbidden.
- **No invention.** If a doc page returns 404 or is unreachable, write `(not fetched: <reason>)` — never paraphrase from training memory.
- **No undated guesses.** If a page lacks a visible "last updated" date, mark `(undated)`. Do not estimate.
- **Quantity > 0 only.** If fewer than 5 agentic repos match the filter, list what you found and add `"fewer than 5 matched the filter"`. Padding with weak repos is forbidden.
- **Length cap.** Under 400 lines total. Trim quotes, prefer summaries.
- **No code blocks** other than the output schema itself. The digest is for downstream agents to read, not to execute.
- **English output.** Even though the project speaks French, the digest mirrors upstream docs which are English. Consistency > localization.

# Examples

The output schema above is the single example. Follow it literally.
