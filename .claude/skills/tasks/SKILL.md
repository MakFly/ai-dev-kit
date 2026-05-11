---
name: tasks
description: Use PROACTIVELY when the user invokes /tasks <slug> or asks "break this plan into tasks". Runs the `decomposer` subagent in a forked context which writes specs/<slug>/tasks.md. Refuses if plan.md is still `draft`.
argument-hint: <slug>
context: fork
agent: decomposer
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
when_to_use: |
  Use after plan.md has Status: reviewed or locked. The user invokes /tasks or asks to decompose
  the plan into an executable TODO list.
---

# /tasks

Author `specs/<slug>/tasks.md` via the `decomposer` subagent.

## Procedure

1. **Read plan.** `cat specs/<slug>/plan.md`. Refuse if missing or `Status: draft` (plan must be reviewed first).
2. **Cross-check acceptance mapping.** Plan §8 must already map spec criteria to plan elements. If missing, send back to /plan.
3. **Delegate.** Invoke `decomposer` with the slug.
4. **Print summary.** Count of tasks, total estimated time, list of T-IDs with one-line title.
5. **Validate coverage.** Every spec §4 criterion appears in tasks.md acceptance-mapping table — refuse if not.
6. **Commit.** `git commit -m "tasks(<slug>): decompose plan into T1..TN"`.

## Doctrine

- **Atomic > comprehensive.** A task that takes > 1 hour is too big — split.
- **Owner is named.** No "team", no "claude". One agent or `user` per task.
- **Acceptance is testable.** Each task's acceptance line must be a runnable command or a grep-able assertion.
- **Coverage is enforced.** No spec §4 criterion may be unmapped.

## On completion

Suggest: `/implement <slug>` to begin execution.
