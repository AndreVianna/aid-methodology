# delivery-003 re-scope: the count guard was retired upstream

**Owner decision, 2026-08-14 (delivery-003 STATE.md § Cross-phase Q&A, Q1, option (a)).**
This document is the single authoritative record of the re-scope. Where any delivery-003
`DETAIL.md`, this delivery's `BLUEPRINT.md`, or a feature SPEC still cites
`tests/canonical/check-skill-counts.mjs` or its internals, **this document supersedes that
citation**.

## What changed upstream

`tests/canonical/check-skill-counts.mjs` — the repo-wide count guard — was **deleted** (a
~462-line full delete) by work-004, merged to `master`. delivery-003 was planned against it
and named it in 12 of its 25 task DETAILs, in its own BLUEPRINT, and in four feature SPECs.

Every construct task-069 was written to modify is gone with it: the `CLAIMS` array, the
`SUPERSEDED` map, the `MARKER_CAP` ratchet, the `CLAIM_FLOOR` ratchet, the `EXT` extension
filter, the `*` lookbehind, the `HISTORY_SHAPES` rule, `EXCLUDE_FILES`, and the stage-2
replay. None of them can be extended, raised, or replayed.

## The replacement regime, in two halves

| Surface class | Governed by | Kind |
|---|---|---|
| **Public-facing docs** — `README.md`, `docs/`, and the five `profiles/*/README.md` | `tests/canonical/test-doc-counts.sh` | a guard that **runs** in CI |
| Count-bearing prose inside **`canonical/`** and **`.aid/knowledge/`** | criterion **`G-01`** in `authoring-conventions.md` | a criterion a **reviewer applies**, severity `MINOR` |

**The single most important consequence: there are no ratchets any more.**
`test-doc-counts.sh` *derives* every count from the canonical tree (`SKILLS`, `AGENTS`,
`PROFILES`, `ROWS`, `CANON`, `ALIAS`, `REPURPOSE`, `SHORTCUTS`) and then asserts that each
listed surface states the current derived number. Its own header says it: *"you regenerate
the docs, not this test."* So the obligation is no longer "extend the claim set and raise two
ratchets near the live figure" — it is simply **"make the documents state the true number."**
`CLAIM_FLOOR`, `MARKER_CAP`, `SUPERSEDED` and the replay have no successor and are dropped,
not migrated.

`G-01` reads: *"No cosmetic count unless it is load-bearing and measured from disk at
authoring time."* So for `canonical/` and `.aid/knowledge/`, the rule is now to **remove a
cosmetic count or measure it at authoring time**, and a violation is a `MINOR` review finding
rather than a red build. This is the accepted trade of option (a).

## The concrete work list that replaces the ratchet obligations

Run today on this branch, `bash tests/canonical/test-doc-counts.sh` reports **17 passed / 14
failed** — all `DC02` count drift, over exactly **10 files**. Driving these to zero is the
whole of the guarded half:

| Surface | Assertion(s) that must hold |
|---|---|
| `README.md` | `111 skills` |
| `docs/repository-structure.md` | `111 skill definitions`; `94-row catalog` |
| `docs/aid-methodology.md` | `111 skill directories`; `94-row catalog` |
| `docs/glossary.md` | `111 skills total`; `94-row catalog` |
| `docs/diagram-content-reference.md` | `111 skills` |
| `docs/install.md` | ``111 `aid-`-prefixed skill`` |
| `profiles/claude-code/README.md` | `111 skills` |
| `profiles/codex/README.md` | `111 skills` |
| `profiles/cursor/README.md` | `111 skills` |
| `profiles/copilot-cli/README.md` | `111 skills` |
| `profiles/antigravity/README.md` | `111 skills` |

Two notes on that list. The derived figures are `111` skills and `94` catalog rows because
**this work's 36 skills and 36 rows have landed** and **`aid-graph` was removed upstream**
(which is why the skill figure is 111 rather than the 112 this document first recorded) — they
are not hard-coded and will move again if the tree does, so **re-derive at execution time**
rather than trusting the numbers written here. And the five `profiles/*/README.md` are **renders**: fix their `canonical/`
source and re-render rather than editing them in place (`G-06` excludes a render from content
review for the same reason).

## How each stale citation resolves

| Citation class | Where | Resolution |
|---|---|---|
| Ran the guard as an **acceptance oracle** | task-065, task-068, task-069, task-070, task-072 | Replace with `bash tests/canonical/test-doc-counts.sh` exiting **0** for a public-facing surface; for a `canonical/`/KB surface, a recorded `G-01` reviewer verdict |
| Asserted the guard **would not be edited** / was out of scope | task-050, task-062, task-063, task-065, task-066, task-067, task-068, task-071 | Vacuous — the file does not exist. Read as "no count guard is edited by this task", which remains true and is now trivially satisfied |
| Described the guard's **internals** as fact (`EXT`, the `*` lookbehind, `HISTORY_SHAPES`, `EXCLUDE_FILES`, `CLAIMS`, line refs) | task-059, task-062, task-065, task-066, task-067, task-068, task-071, task-072, BLUEPRINT | Those facts are retired. The live scope statement is the table above: public docs guarded, `canonical/` + KB reviewer-governed under `G-01` |
| Defined the **constants to raise** | `feature-006` SPEC §3 (a)(b)(c) and its §10 count rows | Superseded. No constant survives to raise; §3's surfaces-state-their-own-value half survives and is discharged by the work list above |

## What is unchanged by this re-scope

- **task-071's `kb.html` regeneration** still stands, and is still the only route for that
  file. The old reasoning was that `EXT` admitted no `.html` so no claim could reach it; the
  new reasoning is simply that `test-doc-counts.sh` does not scan it and `G-01` reaches only
  markdown. Either way the remedy is regeneration, not a claim entry.
- **The `34 emitting shortcuts` negative half** still holds and still has three independent
  witnesses: `test-doc-counts.sh` derives `SHORTCUTS` and asserts it in the public docs;
  `tests/coverage-baseline.tsv` (task-063) is the second; the regenerated `kb.html`
  (task-071) is the third.
- **`.claude/skills/release-aid/SKILL.md`** remains editable without breaking byte-identity —
  it is in that suite's documented allowlist and has no `canonical/` source.
- Every task's non-count subject matter is untouched by this document.
