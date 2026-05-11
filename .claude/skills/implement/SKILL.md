---
name: implement
description: Use PROACTIVELY when the user invokes /implement <slug> or asks "now build it / run the tasks / execute the plan". Runs the `implementer` subagent in a forked context which walks specs/<slug>/tasks.md and writes src/** + tests/** one task at a time, one commit per task.
argument-hint: <slug> [--from T<N>] [--only T<N>,T<M>]
context: fork
agent: implementer
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
when_to_use: |
  Use after tasks.md exists and every task is unchecked (or to resume from a partial run with --from).
  The user invokes /implement or asks to execute the plan.
---

# /implement

Execute `specs/<slug>/tasks.md` task-by-task via the `implementer` subagent.

## Procedure

1. **Read tasks.** Parse tasks.md. Identify the next un-`[x]` task respecting dependencies.
2. **Pre-flight.**
   - Verify spec.md `Status: locked` (or `clarified` at minimum).
   - Verify plan.md `Status: reviewed` or `locked`.
   - Verify clean working tree: `git status -s` must be empty.
3. **Delegate per task.** Invoke `implementer` for ONE task. Wait for it to mark `[x]` and commit. Then next.
4. **Stream progress.** After each task, print to chat: task ID, files changed, test command result.
5. **Stop conditions.**
   - All tasks `[x]`: print "✓ all tasks complete", suggest `/review <slug>`.
   - Implementer fails: print failure detail, do NOT auto-skip — ask user.
   - User interrupts: clean state, leave tasks.md in current state.

## Flags

- `--from T<N>` : resume from task N, skip already-`[x]` tasks before.
- `--only T<N>,T<M>` : run only listed tasks (and verify their dependencies are `[x]`).

## Doctrine

- **One task, one commit, one verify.** No batching.
- **Hook will block edits without spec.** That's by design (cf rules/spec-before-code.md).
- **No "while I'm here".** Drift from the task scope is forbidden — the rule kicks in.

## Pipeline position

```
... → /tasks → /implement [YOU] → /review
```
