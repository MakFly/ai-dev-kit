# Plan — hello-world

**Slug:** hello-world
**Date:** 2026-05-11
**Spec:** [spec.md](./spec.md)
**Status:** locked

## 1. Architecture

```
┌───────────────────┐         ┌──────────────────────┐
│  src/hello.ts     │ stdout  │  test runner         │
│  console.log(...) │────────▶│  bun test            │
└───────────────────┘         │  tests/hello.test.ts │
                              └──────────────────────┘
```

## 2. Components

| Component | Responsibility | Touched files |
| --- | --- | --- |
| entry | print the greeting | `src/hello.ts` |
| test | assert stdout matches | `tests/hello.test.ts` |

## 3. Data flow

1. User invokes `bun run src/hello.ts`.
2. Bun loads `src/hello.ts`, executes top-level `console.log`.
3. Process exits 0.

For the test:

1. `bun test` discovers `tests/hello.test.ts`.
2. Test spawns `bun run src/hello.ts` as a subprocess (Bun.$ or `Bun.spawn`).
3. Test asserts stdout equals `"Hello, agentic OS\n"` and exit code is 0.

## 4. Risks & mitigations

| Risk | Impact | Mitigation | Test |
| --- | --- | --- | --- |
| Bun output buffering adds trailing characters | low | Use `String.prototype.trim()` on captured stdout before exact compare, OR assert with `.toBe()` against the literal | AC3 |
| Pre-edit-gate hook blocks writes despite spec | low | This plan explicitly lists `src/hello.ts` and `tests/hello.test.ts` in §2 Components and Files touched, satisfying `pre-edit-gate.sh` ownership scan | (hook test) |
| Test process fails to capture stdout cross-platform | med | Use `Bun.spawn` with `stdout: "pipe"` and `await proc.exited` | AC3 |

## 5. Alternatives considered (and rejected)

- **Inline test via `expect(true).toBe(true)`** — rejected: doesn't actually verify `src/hello.ts` behavior.
- **Shell-based test (`bun run src/hello.ts | grep`)** — rejected: not portable, not reproducible from `bun test`.

## 6. Test strategy

- **Unit:** N/A (no library API).
- **Integration:** `tests/hello.test.ts` spawns the entry and asserts stdout+exit code. Covers AC1, AC2, AC3.
- **Manual:** `bun run src/hello.ts` and visually check the output. Covers AC1.
- **Out of scope:** load testing, fuzzing, multi-platform CI matrix.

## 7. Dependencies

- Runtime: `bun >= 1.3`
- Test framework: `bun:test` (built-in)
- No npm dependencies added.

## 8. Acceptance mapping

| Spec §4 criterion | Plan element | Test |
| --- | --- | --- |
| AC1: stdout = "Hello, agentic OS\n" | `src/hello.ts` console.log | `tests/hello.test.ts::matches greeting` |
| AC2: exit code 0 | `src/hello.ts` no throw / no process.exit | `tests/hello.test.ts::exits 0` |
| AC3: bun test passes | `tests/hello.test.ts` | itself |
| AC4: only 2 files touched | `pre-edit-gate.sh` + plan §2 enumeration | manual verify in commit diff |
