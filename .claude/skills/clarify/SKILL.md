---
name: clarify
description: Use PROACTIVELY when the user invokes /clarify <slug> or when a spec has Open questions and the user wants to resolve them. Reads specs/<slug>/spec.md §6, asks targeted questions, integrates answers, bumps Status to `clarified`.
argument-hint: <slug>
allowed-tools: Read, Write, Edit, Bash
when_to_use: |
  Use whenever a spec.md exists with Status: draft and §6 Open questions are non-empty. Also
  when the user explicitly invokes /clarify to revisit assumptions.
---

# /clarify

Resolve `specs/<slug>/spec.md` §6 Open questions one by one with the user, then bump `Status: clarified`.

## Procedure

1. **Read spec.** `cat specs/<slug>/spec.md`. If file missing → tell user, suggest `/specify <slug>` first.
2. **Find Open questions.** Section `## 6. Open questions`. If empty, ask user what to clarify — do not invent.
3. **Ask one by one.** For each question, present it to the user with 2-4 concrete options + a "Other" / free-form fallback. Use `AskUserQuestion` tool if available, else plain chat.
4. **Integrate.** For each answer, edit the spec:
   - Move the question from §6 to the relevant §1-§7 with the resolved decision.
   - Add the decision as a bullet under "Decisions resolved during /clarify" appendix (create if missing).
5. **Bump Status.** When §6 is empty, set `Status: clarified` and update the `Date:` field.
6. **Commit.** `git commit -m "spec(<slug>): clarify open questions"`.

## Doctrine

- **One question at a time.** Do not batch — the user must consciously decide each.
- **Concrete options.** "What database?" → "(1) Postgres, (2) SQLite, (3) Bun.sql, (Other)". Never open-ended without scaffolding.
- **Record reasoning.** Each resolved question keeps a one-line rationale in the appendix.
- **No silent choices.** If the user defers, the question stays open with `Deferred: <reason>` annotation.

## Output appendix (added to spec.md)

```markdown
## Appendix A — Decisions resolved during /clarify

- **Q (was §6):** <question>
  - **A:** <decision>
  - **Rationale:** <one line>
  - **Date:** <ISO>
```

## On completion

Print to chat: count of questions resolved, count deferred, new Status. Suggest `/plan <slug>` if Status is now `clarified`.
