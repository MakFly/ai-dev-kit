# Rule — evidence-required

> **Every factual claim cites a source. No claim from memory.**

## Categories and required evidence

| Claim type | Required evidence |
| --- | --- |
| Code behavior (function, type, path) | `file:line` read during this session |
| External API / library / CLI flag | Code read, `--help` executed, or doc URL fetched via WebFetch |
| Benchmark / perf number | Raw output of the command run in this session + exact command + env |
| Test / lint / type-check passing | Pasted output of the command in the current turn |
| Version / date | Read from `package.json`, `bun.lock`, `CHANGELOG`, or doc URL |

## Banned phrases without an attached source

`generally`, `likely`, `around`, `the docs say`, `it's faster`, `it's standard`, `well-known`, `industry practice`. If you use one of these, the source must appear in the same paragraph.

## When source is missing

Say `I haven't verified` and propose the command or file that would verify it. Never fill the gap with plausible-sounding content.

## Enforcement

- **Verifier subagent:** re-runs every claimed check on any non-trivial result. If it cannot reproduce → hallucination, fix before reporting done.
- **Codex review (`/review` skill):** challenges optimistic claims, surfaces missing evidence.
- **`pre-edit-gate.sh`** does NOT enforce this — it's a doctrinal rule for prose, not code. Reviewers enforce.

## Rationale

LLMs hallucinate. The cost of fabricated facts in a spec/plan/code pipeline is silent drift between artefacts. Forcing evidence makes drift visible.
