---
name: constitution
description: Use PROACTIVELY when the user wants to author, amend, or revise memory/constitution.md (the supreme project contract). Triggers on /constitution and on phrases like "set the project principles", "redéfinis les principes", "what are our invariants". Never use during a feature flow (specify/plan/...) — pause the flow and explain.
argument-hint: [amendment-note]
allowed-tools: Read, Write, Edit, Bash
when_to_use: |
  Use ONLY for editing memory/constitution.md. Do NOT use to write feature specs (that's /specify),
  plans (/plan), or task lists (/tasks). Constitution edits are rare and explicit by design.
---

# /constitution

You edit `memory/constitution.md` — the supreme contract of this repository.

## Pipeline position

```
/constitution [YOU] → /specify → /clarify → /plan → /tasks → /implement → /review
```

The constitution is **rarely edited**. Most sessions never touch it. Treat each edit as a deliberate amendment, not a normal feature flow step.

## Procedure

1. **Read current state.** `cat memory/constitution.md`.
2. **If placeholder:** draft the initial constitution from scratch using the structure below. Confirm with user before writing.
3. **If real content:** treat the user's amendment as a proposed diff. Show the diff, explain consequences, ask for explicit GO before writing.
4. **Write.** Commit message: `chore(constitution): <one line>`.
5. **Stamp version.** Each amendment bumps the constitution version (semver: amendment = patch, structural change = minor, full rewrite = major).

## Required structure of `memory/constitution.md`

```markdown
# Constitution — ai-dev-kit

**Version:** v<major>.<minor>.<patch>
**Last amended:** <ISO-8601>

## Article I — Principles
1. <principle 1> — <one-line rationale>
2. ...

## Article II — Workflow
- The canonical loop is /constitution → /specify → /clarify → /plan → /tasks → /implement → /review.
- Skipping a step requires an ADR in memory/decisions/.

## Article III — Authoring conventions
- <agent frontmatter rules>
- <skill frontmatter rules>
- <commit conventions>

## Article IV — Out of scope
- <bounded list of what this project will NOT do>

## Article V — Verification
- Required commands and their meaning.
- Codex review is non-optional for spec, plan, tasks.

## Amendments
- <date> v<old> → v<new> — <summary>
```

## Doctrine

- **Reuse > rewrite.** Amendments are small and surgical. Full rewrites need user signoff.
- **Conflict resolution.** If a future spec/plan/code conflicts with the constitution, the constitution wins. Always.
- **Bounded scope.** Articles I-V are the schema. Do not invent Article VI without user direction.
- **Pause feature flows.** If invoked during an active /specify or /plan, refuse and explain — finish or abort the feature flow first.

## After write

Print to chat:
- New constitution version.
- One-paragraph summary of the amendment.
- Any spec/plan/code in the repo that may now be in violation (`grep -l` cross-check).
