# Tasks — hello-world

**Slug:** hello-world
**Date:** 2026-05-11
**Plan:** [plan.md](./plan.md)

## Convention

- Each task is `T<N>`.
- Each task has: title, owner, estimate (≤ 1h), dependencies, acceptance.
- Tasks ordered; a task only depends on earlier-numbered tasks.

## Tasks

### T1 — Write the greeter entry
- **Owner:** implementer
- **Est:** 5 min
- **Depends on:** —
- **Files touched:** `src/hello.ts`
- **Acceptance:** `bun run src/hello.ts` prints `Hello, agentic OS` followed by a newline, exit 0.

### T2 — Write the integration test
- **Owner:** implementer
- **Est:** 10 min
- **Depends on:** T1
- **Files touched:** `tests/hello.test.ts`
- **Acceptance:** `bun test tests/hello.test.ts` reports `1 pass, 0 fail`.

## Acceptance mapping (cross-check)

| Spec §4 criterion | Plan element | Task(s) |
| --- | --- | --- |
| AC1 stdout = "Hello, agentic OS\n" | `src/hello.ts` console.log | T1 |
| AC2 exit code 0 | `src/hello.ts` clean exit | T1 |
| AC3 bun test passes | `tests/hello.test.ts` | T2 |
| AC4 only 2 files touched | implementer scope discipline + pre-edit-gate | T1, T2 (commit diff verify) |

## Execution status

| Task | Status | Commit | Acceptance result |
| --- | --- | --- | --- |
| T1 | ✅ done | `164c058` | `bun run src/hello.ts` → `Hello, agentic OS`, exit 0 |
| T2 | ✅ done | `6b19b7e` | `bun test` → 1 pass, 0 fail, 2 expect() calls |
