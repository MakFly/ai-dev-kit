# Rule — spec-before-code

> **No file under `src/**` or `tests/**` is created or edited without a corresponding `specs/<slug>/spec.md` (Status ≥ `clarified`) and `specs/<slug>/plan.md` (Status ≥ `reviewed`).**

## Enforcement

- **Deterministic gate:** `.claude/hooks/pre-edit-gate.sh` runs on `PreToolUse(Edit|Write)`. It inspects the target path; if under `src/**` or `tests/**`, it greps `specs/**/spec.md` for the file's slug ownership. If no match, the hook blocks with exit code 2.
- **Doctrinal gate:** the `implementer` agent refuses to start without a locked tasks.md.

## Slug ownership

A file `src/<area>/<name>.ts` is owned by spec `<slug>` if either:

1. `specs/<slug>/plan.md` §2 Components table lists a matching glob, OR
2. `specs/<slug>/tasks.md` lists the file under any task's `Files touched`.

If neither match, the file is **orphan** and forbidden.

## Bypass (rare, audited)

Trivial cases that may legitimately bypass (still require user GO via `--no-spec` flag or explicit override in chat):

- Pure dependency bumps in `package.json`.
- `.gitignore`, `README.md`, `LICENSE` edits.
- `tsconfig.json` tweaks.

These bypass paths are listed in `.claude/hooks/pre-edit-gate.sh` ALLOWLIST.

## Rationale

Code without spec drifts. Code with stale spec lies. The spec-before-code rule keeps the artefact chain (`spec → plan → tasks → code → review`) coherent.
