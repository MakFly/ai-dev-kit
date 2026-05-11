---
name: plan
description: Use PROACTIVELY when the user invokes /plan <slug> or asks "how should we build this". Runs the `planner` subagent in a forked context which writes specs/<slug>/plan.md from a clarified spec. Refuses to plan if spec.md is still `draft`.
argument-hint: <slug>
context: fork
agent: planner
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
when_to_use: |
  Use after spec.md exists with Status: clarified or locked. The user invokes /plan or asks
  for architecture/risks/strategy. Never invent the WHAT — only the HOW.
---

# /plan

Author `specs/<slug>/plan.md` via the `planner` subagent.

## Procedure

1. **Read spec.** `cat specs/<slug>/spec.md`. Refuse if missing or `Status: draft`.
2. **Read constitution.** Cross-check against principles before delegating.
3. **Read digest.** Check current versions of libs/tools in `supports/digests/digest-*.md` (≤ 7 days). Warn if stale.
4. **Delegate.** Invoke `planner` subagent with the spec slug.
5. **Surface risks.** When planner returns, print the §4 Risks table to chat. Highlight any `Impact: high`.
6. **Commit.** `git commit -m "plan(<slug>): initial draft"`. Suggest `/review <slug> plan` for codex challenge before locking.

## Doctrine

- **No code.** Architecture, data flow, risks, alternatives, test strategy. Not function bodies.
- **Spec is law.** Plan cannot widen scope vs spec §4 acceptance criteria. If you find yourself adding scope, stop and propose a spec amendment instead.
- **Risks are required.** A plan with zero risks is incomplete.
- **Codex review before locking.** Plan stays `draft` until codex review passes.

## Pipeline position

```
/constitution → /specify → /clarify → /plan [YOU] → /tasks → /implement → /review
```
