# Triage record — the whole `site/` vitest suite on a clean install

**Task:** task-002 (RESEARCH) · **Delivery:** delivery-001 · **Work:** work-001-skill-explorer
**Measured:** 2026-07-26, in the `work-001` worktree at
`C:\Projects\Personal\AID\.claude\worktrees\work-001`, after `rm`-free clean `npm ci`.

This task changes no file. It measures, classifies and routes; task-003 remediates what is
routed "absorb", task-004 wires CI.

---

## 1. Install and environment

| Fact | Value |
|---|---|
| `cd site && npm ci` | exit **0**, 26 s |
| Node | v22.14.0 (`site/.nvmrc`) |
| Vitest | v4.1.8 |
| git | Windows git 2.54.0 via Git Bash (`C:\Program Files\Git\bin\bash.exe`), per KI-017 |

**Both categories of noise feature-001 § Part C predicted are GONE, and neither was a defect:**

- **`[TSCONFIG_ERROR] Tsconfig not found` on the five TypeScript suites — did not occur.** All
  five loaded and executed. Cause was `node_modules/astro` being absent, so
  `site/tsconfig.json`'s `"extends": "astro/tsconfigs/strict"` could not resolve; `npm ci`
  installs it. **Confirmed environmental, now cleared.** This is the first time these five
  suites have ever executed anywhere — 141 of the 228 tests in this suite live in them.
- **The two `git diff`-based idempotency tests — did not fail.** Cause was the worktree's
  `.git` file holding a WSL path Windows git could not resolve; the worktree has since been
  recreated with Windows git (KI-017). **Confirmed environmental, now cleared.** Both
  `gen-reference.test.mjs` and `sync-docs.test.mjs` idempotency tests pass.

---

## 2. All eight test files — load status and verdict

Measured with `npx vitest run --reporter=json`. No file is "unknown" and none failed to load.

| # | Test file | Loaded | Tests | Pass | Fail | Verdict |
|---|-----------|--------|-------|------|------|---------|
| 1 | `scripts/__tests__/fetch-release-data.test.mjs` | yes | 9 | 9 | 0 | **PASS** |
| 2 | `scripts/__tests__/gen-reference.test.mjs` | yes | 36 | 36 | 0 | **PASS** (as corrected by task-001) |
| 3 | `scripts/__tests__/sync-docs.test.mjs` | yes | 42 | 42 | 0 | **PASS** |
| 4 | `src/data/__tests__/ac13-version-injection.test.ts` | yes | 45 | 44 | **1** | **FAIL** — see F-1 |
| 5 | `src/data/__tests__/version.test.ts` | yes | 18 | 18 | 0 | **PASS** |
| 6 | `src/lib/__tests__/feature-009-releases-banner.test.ts` | yes | 38 | 38 | 0 | **PASS** |
| 7 | `src/lib/__tests__/feature-010-feedback.test.ts` | yes | 24 | 24 | 0 | **PASS** |
| 8 | `src/lib/__tests__/release-data.test.ts` | yes | 16 | 16 | 0 | **PASS** |
| | **Total** | **8/8** | **228** | **227** | **1** | `npm test` exits **1** |

---

## 3. Findings, classified and routed

Classification alphabet (task-002 Scope): **(a)** stale assertion of KI-005's class ·
**(b)** environmental · **(c)** real defect.

### F-1 — `ac13-version-injection.test.ts:193` asserts a pipeline diagram that no longer exists

- **Class:** **(a) stale assertion of KI-005's class.**
- **Route:** **ABSORB into task-003.** It is a literal-for-derived assertion correction inside
  `site/src/data/__tests__/*.ts`, which is exactly task-003's declared bound, and it is well
  under one agent session.
- **Runner's message, verbatim:**
  ```
  FAIL  src/data/__tests__/ac13-version-injection.test.ts > AC5 — Home pipeline diagram >
        index.mdx pipeline shows the TRIAGE branch and the lite path
  AssertionError: expected '---\ntitle: AID — AI Integrated Deve…' to contain 'TRIAGE'
   ❯ src/data/__tests__/ac13-version-injection.test.ts:193:17
  ```
- **The assertion** (`:190-197`), guarded by a comment reading *"Regression guard (this has been
  wrong three times): the pipeline diagram must include the TRIAGE node AND the lite-path branch
  that routes straight to Execute, skipping Specify/Plan/Detail — matching README.md's canonical
  diagram"*:
  ```js
  expect(src).toContain('TRIAGE');
  expect(src).toContain('lite path');
  expect(src).toMatch(/Triage\s*--\s*"lite path[\s\S]*?-->\s*Exe/);
  ```
- **Cited cause.** Commit `ca4aad21` *("refactor(work-018): reframe phase/group model")* rewrote
  the diagram in `site/src/content/docs/index.mdx` (22 lines changed) and touched this test file
  in only 4 lines — **none of them this guard**. The model the guard pins was deliberately
  superseded in that commit. In the current model `/aid-triage` is *suggest-only* and cannot
  route anywhere itself; the lite path is the **shortcut engine**:
  - `index.mdx`:38 declares the node as `TR["/aid-triage<br/>not sure? suggest-only"]` — the
    identifier is `TR`, not `TRIAGE`.
  - `index.mdx`:63-66 are `TR -. suggests .-> SC`, `TR -. suggests .-> Desc`, and
    `SC --> Eng --> Exe`. There is no `Triage --"lite path"--> Exe` edge and there should not be.
  - **The guard's own stated oracle now disagrees with it too.** `README.md`'s canonical diagram
    has `TR -. suggests .-> SC` (:9) and `SC --> ENG` (:16) and contains no `lite path` edge
    label anywhere — the string "lite path" survives in README only as prose at `README.md`:201.
- **Therefore the product is correct and the test is stale** — the same shape as KI-005, where
  `toHaveLength(94)` pinned a superseded corpus. This is *not* a regression in `index.mdx`.
- **Instruction to task-003, so it does not swap one literal for another.** task-003's first
  acceptance criterion requires re-deriving from source where a source exists, and here one
  does: the guard names `README.md`'s diagram as the oracle. Re-derive the assertion from
  `README.md`'s mermaid block — assert that `index.mdx` declares the same triage node and the
  same suggest-only edges README does, and that the shortcut entry reaches Execute — rather than
  hard-coding the new node names `TR`/`SC`/`Eng`. That keeps the guard's intent (the entry-point
  topology must not silently change) while removing its dependence on a frozen spelling, and it
  makes the guard fail the next time the two diagrams diverge, which is what it was for.

### F-2 — `index.mdx`'s prose skill counts are stale (92 / 14 / 76 against a measured 111 / 21 / 64)

- **Class:** **(c) real defect** — in published product content, not in a test.
- **Route:** **ESCALATE to the owner as a gate escalation.** Out of task-003's bound, which is
  explicitly limited to `site/src/**/__tests__/`; `index.mdx` is a content page. Recorded in
  `deliveries/delivery-001/STATE.md`.
- **Evidence.** `index.mdx`:76-77 and :91-92 both read *"92 skills — 14 classic pipeline/on-demand
  skills, the `/aid-triage` router, `/aid-ask` … and 76 verb-first shortcut skills"*. Measured on
  the same tree: **111** directories under `canonical/skills/`, **21** curated by the generator's
  `SKILL_GROUPS`, **64** emitting catalog rows. The site's own generated page states the correct
  figures one click away — `reference/skills.md`:9 reads *"111 skill directories … 19 classic
  pipeline skills … 64 engine-driven direct-entry shortcut skills generated from a 94-row catalog
  … 30 of the rows are `repurpose: true`"*.
- **Why it is being surfaced and not fixed.** No test asserts these numbers, so it neither blocks
  `npm test` nor is caught by anything this delivery adds. It is the same stale-inventory class as
  KI-003/KI-005/KI-009 and it is directly adjacent to this work's subject matter — a reader
  arriving at `/skills/` after delivery-002 will see 111 cards under a home page promising 92
  skills. Fixing published prose is a content change delivery-001 has no mandate for.
- **Also note the two surfaces disagree with each other on the classic count** — `index.mdx` says
  14, `reference/skills.md` says 19, and the generator actually curates 21 sections. That third
  divergence is inside frozen `gen-reference.mjs` territory (KI-010) and is not opened here.

### F-3 — `site/` still has no `vitest.config.*`

- **Class:** **(b) environmental / pre-existing**, and **not a delivery-001 problem**.
- **Route:** **No action here; already owned.** This is **KI-016**, whose routing decision is due
  before task-017 and task-018 land in delivery-002. It cannot bite in delivery-001: the only
  generator-re-running suites today are `gen-reference.test.mjs` and `sync-docs.test.mjs`, which
  write to disjoint output sets (`reference/*.md` vs the synced docs tree), so the parallel
  workers do not collide. Recorded here only so the gate can see it was considered rather than
  missed.

### F-4 — nothing else

No further failure, no skipped test, no `todo`, no unhandled rejection and no stderr output
appeared across the 228 tests. In particular, the five never-before-run TypeScript suites
contributed **140 passing tests and exactly one failure** — the residual risk feature-001 § Part C
stated ("their assertions are unverified and may carry staleness of the same kind") **materialised
once**, as F-1, and is bounded.

---

## 4. Frozen-artifact verification on the same clean install

| Check | Result |
|---|---|
| `npm run prebuild` (`sync:docs && gen:reference && fetch:release`) | exit **0** |
| `gen-reference.mjs` byte-unmodified (`git diff --stat`) | **empty** — unmodified |
| Its throw-on-drift guard | **passes** — `node scripts/gen-reference.mjs` exits 0 |
| `reference/skills.md`, `agents.md`, `kb.md`, `settings.md` after full prebuild | **byte-unchanged** |
| `scripts/.reference-manifest.json` after full prebuild | **byte-unchanged** |
| `git status --porcelain` after prebuild | only this task's own artifacts under `.aid/works/` (its `STATE.md`, this `TRIAGE.md`, and the delivery `STATE.md` carrying Q1 and E-1). **Zero paths under `site/` or `.github/`** — no generated-file drift, and task-002's "changes no file" bound holds. |

---

## 5. Does `npm test` exit 0 as-is?

**No — it exits 1, and exactly one thing stands between here and exit 0:** the single stale
assertion F-1, at `src/data/__tests__/ac13-version-injection.test.ts:193`. 227 of 228 tests pass.
No other change to any test file, production file, config or dependency is required.

Once task-003 corrects F-1, `npm test` exits 0 for the **whole** suite — all eight files including
the five that have never executed in CI — which is delivery-001's third gate criterion and the
precondition Part C sets on task-004's CI wiring.

---

## 6. Recommendation

1. **task-003 proceeds — it is NOT canceled.** Exactly one finding is routed "absorb" (F-1).
   task-003's own acceptance criterion for the canceled path ("if task-002 routed nothing to
   absorb") therefore does not apply.
2. **task-003's whole scope is F-1**, corrected by re-deriving from `README.md`'s canonical
   diagram per the instruction in F-1 above. Nothing else is absorbed.
3. **task-004 proceeds after task-003 lands and `npm test` is confirmed green**, wiring the
   `npm test` step per Part B. The precondition Part C sets — "confirmed green on a complete
   install before Part B lands" — is satisfiable, and the risk that Part B "turns an invisible
   problem into a permanently red pipeline" is now measured and closed rather than assumed.
4. **F-2 is the owner's call** at delivery-001's gate: correct `index.mdx`'s counts as a
   ride-along, file it as a ticket, or accept it. Delivery-001 does not touch it either way.
