# Spec — hello-world

**Slug:** hello-world
**Date:** 2026-05-11
**Status:** locked

## 1. Problem (WHY)

The v5 pivot of ai-dev-kit needs an end-to-end validation of the full pipeline (`/constitution → /specify → /clarify → /plan → /tasks → /implement → /review`) before any real feature is written. Without this dry run, we cannot prove the hooks, agents, and skills cooperate as designed.

## 2. Outcome (WHAT)

A trivial executable that, when run, prints `Hello, agentic OS` to stdout and exits 0. A unit test verifies the output.

## 3. Users & scenarios

- **Project maintainer** — runs `bun run src/hello.ts` and observes the expected string.
- **CI / verifier subagent** — runs `bun test tests/hello.test.ts` and observes a pass.

## 4. Acceptance criteria

- [x] AC1: `bun run src/hello.ts` outputs exactly `Hello, agentic OS\n` to stdout.
- [x] AC2: `bun run src/hello.ts` exits with code 0.
- [x] AC3: `bun test tests/hello.test.ts` reports 1 pass, 0 fail.
- [x] AC4: No file other than `src/hello.ts`, `tests/hello.test.ts`, and this spec/plan/tasks chain is touched.

## 5. Non-goals

- No CLI argument parsing.
- No i18n.
- No configuration file.
- No reusable library API.

## 6. Open questions

(none — locked for boot validation)

## 7. Constraints linked to constitution

- Article I.1 (spec-before-code) — this spec exists before any `src/**` file is written.
- Article I.4 (surgical changes) — scope strictly limited to 2 files.
- Article III (authoring conventions) — N/A here (no agents/skills authored).

## 8. References

- `memory/constitution.md` v1.0.0
- `README.md` — Quickstart section
