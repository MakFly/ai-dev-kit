---
name: specify
description: Use PROACTIVELY when the user invokes /specify <slug> or asks to "write the spec", "define the feature", "what should we build". Runs the `specifier` subagent in a forked context which writes specs/<slug>/spec.md. Refuses to write code or plan.
argument-hint: <slug> [free-form intent]
context: fork
agent: specifier
allowed-tools: Read, Write, Edit, Bash
when_to_use: |
  Use whenever a new feature must be specified BEFORE any code or planning. The user mentions
  /specify, or describes a feature in WHAT/WHY terms without HOW. Never use to write code or
  decompose tasks.
---

# /specify

Author `specs/<slug>/spec.md` via the `specifier` subagent.

## Procedure

1. **Parse the argument.** `<slug>` is the first arg (kebab-case). The rest is free-form user intent.
2. **Reject if conflict.** If `specs/<slug>/spec.md` already exists with `Status: locked`, refuse and propose `/clarify <slug>` instead.
3. **Read constitution.** `cat memory/constitution.md` — surface any obvious tension with the user's intent before delegating.
4. **Check digest freshness.** If newest `supports/digests/digest-*.md` is > 7 days old, warn the user. Do not block.
5. **Delegate.** Invoke the `specifier` subagent with the user intent and slug. The subagent writes the file.
6. **Surface Open questions.** When specifier returns, list the spec's §6 Open questions to the user. Suggest `/clarify <slug>` if any.
7. **Commit.** `git add specs/<slug>/spec.md && git commit -m "spec(<slug>): initial draft"`. Ask user before committing if they prefer to review first.

## Doctrine

- **WHAT only.** No HOW. If the user's intent already contains HOW ("use redis", "with a worker"), redirect those to `/plan`.
- **One spec, one slug.** Refuse to mix multiple features in one spec.
- **Surface ambiguity, don't smooth it.** Better to write a spec with 5 Open questions than a "clear" spec that silently chose for the user.

## Pipeline position

```
/constitution → /specify [YOU] → /clarify → /plan → /tasks → /implement → /review
```
