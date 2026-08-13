# Superseded Guard Retirement

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-12 | Feature identified from REQUIREMENTS.md §4 stream 3 + deferred front-face bucket | /aid-define |
| 2026-08-13 | Second cross-reference pass: "CI invokes `kb-citation-lint.sh`" retracted as false; the merged 2,181 floor split to a **379** guard floor with 1,802 reported separately; `check-skill-counts.mjs` established as a **partial** retirement (non-markdown corpus + three trees with no registry row); the `examples/` "zero inbound references" claim retracted; the import log given a path and an owner | /aid-define |
| 2026-08-13 | Technical Specification authored — 8 sections (removal-set derivation, `check-skill-counts.mjs` partial retirement, front face, single render both chains, exit arithmetic, C-7 audit, AC-2 proof, ordering/out-of-scope). Application-software sections N/A | /aid-specify |
| 2026-08-13 | Grade gate: aid-reviewer, 2 passes. Pass 1 → 2 HIGH (§2 AC-3 disposition unfulfilled; §4.2 flow.json mislabelled feeder) + 1 MED (`.py` missing from filter). Pass 2 confirmed fixes + 1 HIGH (`.py` divergence vs REQUIREMENTS L1167, fixed at root). All Fixed, 0 Pending → **Grade A**. §2 carries a flagged owner judgment call (full-delete vs narrow of `check-skill-counts.mjs`). Ledger `review-archive/specify-feature-003.md` | /aid-specify |

## Source

- REQUIREMENTS.md §2 (what stands in its place), §4 (stream 3; the deferred front-face bucket), §5 FR-8
- REQUIREMENTS.md §6 NFR-1, NFR-2, NFR-4; §7 C-1, C-2, C-3, C-6; §8 C-7; §9 **AC-2**, AC-3, AC-4, AC-6

*AC-2 is **shared** across all three features — each carries its own planted-defect proof criterion —
so each declares it. An earlier draft carried the criterion without declaring the AC.*

*FR-8 was added during the cross-reference correction pass: the front-face bucket was gated here
with no requirement behind it, so the same work was simultaneously unscoped and blocking.*

## Description

The declarations now exist and are read. This feature removes what was standing in for them, and
closes the work by aligning the surfaces a user reads.

**It derives its own removal set before removing anything.** REQUIREMENTS.md deliberately asserts no
inventory: an earlier draft listed six scripts totalling 2,816 lines, four of which do not exist on
this branch at all. Asserting an underived number is the defect this work exists to remove, so the
first task here is to enumerate — from disk — every script whose job is to check a fact stated in
prose, and for each one name the declaration that now covers it.

The verified archetype is `tests/canonical/check-skill-counts.mjs`: **379 lines** whose entire
purpose is to find count claims written in prose and compare them against the corpus. That is a
`review-criteria:` entry wearing a script costume — it encodes one fact-check in code and can be wrong
about the fact.

**But it cannot be retired wholesale, and the scoping happens before the removal.** Its corpus, read
from `INCLUDE_FILES` / `INCLUDE_TREES` / `REPO_LOCAL_SKILLS`, is the root `README.md`, `docs/`,
`.aid/knowledge/`, `canonical/`, `site/src/content/docs/`, and
`.claude/skills/{generate-profile,release-aid}`; its extension filter is
`.md|.mdx|.sh|.mjs|.js|.ts|.yml|.yaml`. Two parts of that have nowhere to go:

1. **The non-markdown files.** A markdown-frontmatter criterion cannot live in a `.sh` or `.mjs`, so
   the cascade **structurally** cannot cover them.
2. **Three trees with no registry row.** `site/src/content/docs/` is out of scope; `docs/` and the root
   `README.md` are this feature's own deferred front face; and the two repo-local skill trees are absent
   from `canonical/`, so no document type reaches them.

So the removal is **partial by construction**, and for each part dropped this feature states either the
criterion that replaces it or that the coverage is being given up and why.

Two named non-candidates, so the sweep does not over-reach:

- **`canonical/aid/scripts/kb/kb-citation-lint.sh`** (70 lines) checks citation *form*, not a prose
  fact. No declaration replaces it, so it stays. *An earlier draft added "and CI invokes it" — that is
  **false**: `grep -rn "citation-lint" .github/workflows` returns nothing. It is orchestrator-gated at
  GENERATE (`authoring-conventions.md § Enforcement`); CI runs only its unit test. The form-versus-fact
  distinction is the whole reason it survives, and it does not need a second one.*
- **`tests/canonical/test-dogfood-byte-identity.sh`** sha256s the two tracked dogfood trees against
  the render manifest. That answers *"was the generator re-run"* — a build question, not a review
  question. It stays, and REQUIREMENTS.md §4 puts it explicitly out of scope.

The feature then closes the work:

- **The front face**, deferred by owner decision to the very end because it describes trees that
  were still moving: `docs/*.md` (7 files), the repo-root `README.md` (257 lines), and
  `examples/**/README.md` (4 files, 1,237 lines). *All four are referenced — an earlier draft called
  `brownfield-full-path` and `greenfield` "zero inbound references", which is wrong: `examples/README.md`
  links both as directory links (`→ [examples/greenfield/](greenfield/)`) and `docs/repository-structure.md`
  lists them. The audit behind that claim searched only for `](README.md)`.*
- **The single render**, per C-2 and NFR-4: `canonical/` → `profiles/` → the two tracked dogfood
  trees, run once, here, after the source has stopped moving.
- **The exit arithmetic**: **removed guard lines** minus **added mechanism lines**, stated as a number.
  The guard-line floor is **379** (`check-skill-counts.mjs`), and that is the figure AC-4 tests. The
  **1,802** documentation lines from the deleted READMEs are reported **separately** and carry no weight
  in the test. *An earlier draft stated a merged floor of 2,181, which NFR-2 forbids — merged, deleted
  prose pays for added machinery.*
- **The C-7 audit**: `.aid/works/work-004-frontmatter-review-criteria/imports-from-work-003.md` is
  reviewed, confirming nothing crossed from `work-003` except through its six gates. *The file does not
  exist on this branch today; feature-001's first task creates it, so this audit has something to read.*

## User Stories

- As an AID user, I want a fact stated once where it lives rather than re-encoded in a script that
  can be wrong about it, so that there is one thing to keep true instead of two.
- As an AID user, I want to be told which check was removed and what replaced it, so that "we
  deleted the tests" is a claim I can audit rather than trust.
- As an AID user, I want the README and docs to describe what the project actually is now, so that
  the first thing I read is not the most out-of-date thing in the repo.
- As an AID user, I want the work to end with less enforcement machinery than it started, so that
  the fix for over-engineering is not itself over-engineering.

## Priority

Must

## Acceptance Criteria

- [ ] Given stream 3 begins, when the removal set is decided, then it was **derived from this
      branch's disk** and no file is removed on the strength of an inherited inventory (AC-3).
- [ ] Given each removed check, when it is removed, then the declaration now covering it is named —
      a removal with no named replacement is not permitted.
- [ ] Given `kb-citation-lint.sh` and `test-dogfood-byte-identity.sh`, when the sweep runs, then both
      survive it, for the reasons recorded above.
- [ ] Given the removals and additions across all three features, when the work closes, then removed
      **guard** lines exceed added **mechanism** lines — tested against the **379** guard-line floor,
      with the **1,802** documentation-line removals reported **separately** and never summed into it,
      and with authored `review-criteria:` blocks excluded from "added mechanism" per NFR-2 (AC-4).
- [ ] Given each check removed, when it is removed, then any part of its corpus the cascade cannot
      reach — non-markdown files, and trees with no registry row — is named, with either the criterion
      that replaces it or an explicit statement that the coverage is dropped and why (AC-3).
- [ ] Given C-2 and NFR-4, when the work closes, then **both** derived chains have been refreshed
      once — `canonical/` → `profiles/` → the two dogfood trees, **and** the site chain
      (`site/src/content/docs`, `site/src/data/skill-flows/*.flow.json`), the latter **regenerated**
      rather than hand-edited.
- [ ] Given the deferred front-face bucket, when this feature completes, then `docs/`, the root
      `README.md` and `examples/**/README.md` describe the trees as they now are.
- [ ] Given C-2 and NFR-4, when the work closes, then the render chain has been refreshed **exactly
      once**, here — and `tests/canonical/test-dogfood-byte-identity.sh` passes against it.
- [ ] Given `.aid/works/work-004-frontmatter-review-criteria/imports-from-work-003.md` — created by
      feature-001, since it does not exist on this branch today — when the work closes, then every entry
      passes all six C-7 gates, and no commit, cherry-pick or file copy from `work-003` appears anywhere
      in the branch (AC-6).
- [ ] **Proof (AC-2, method per NFR-1):** given a check removed in this feature, when a defect of the
      class it used to catch is planted in a disposable worktree, then a real review reports it via
      the declaration that replaced it. A removal whose replacement cannot catch the defect is a
      regression, not a retirement.

---

## Technical Specification

*Section set.* A retirement + documentation + build change — no database, service, API, or UI, so the
application-software sections are N/A. Content-bearing sections: **removal-set derivation**, **the
`check-skill-counts.mjs` partial retirement**, **the front face**, **the single render (both chains)**,
**the exit arithmetic**, **the C-7 audit**, and the **AC-2 proof**. This feature runs **last** — it
depends on feature-001 (the declarations exist and are read) and feature-002 (they are populated), or a
removed guard loses a check nothing yet replaces.

### 1. Removal-set derivation (AC-3 — derive, never assert)

REQUIREMENTS deliberately asserts **no** inventory: an earlier draft named six scripts totalling 2,816
lines, four of which do not exist on this branch. So the first task is to enumerate from disk every
script whose job is to check a fact stated in prose, and for each name the declaration that now covers
it. A removal with no named replacement is not permitted.

**Two named non-candidates, so the sweep does not over-reach:**

| script | why it stays |
|--------|--------------|
| `canonical/aid/scripts/kb/kb-citation-lint.sh` (70 lines) | checks citation **form**, not a prose fact — no declaration replaces it. (It is orchestrator-gated at GENERATE; CI runs only its unit test. NOT "CI invokes it" — `grep -rn "citation-lint" .github/workflows` is empty.) |
| `tests/canonical/test-dogfood-byte-identity.sh` | sha256s the two dogfood trees against the render manifest — a **build** question ("was the generator re-run"), not a review question. REQUIREMENTS §4 puts it explicitly out of scope. |

### 2. The `check-skill-counts.mjs` partial retirement

The verified archetype: `tests/canonical/check-skill-counts.mjs`, **379 lines** (`wc -l`) whose whole
job is to find count claims in prose and compare them to the corpus — a `review-criteria:` entry wearing
a script costume. Its corpus (`INCLUDE_FILES`/`INCLUDE_TREES`/`REPO_LOCAL_SKILLS`) is root `README.md`,
`docs/`, `.aid/knowledge/`, `canonical/`, `site/src/content/docs/`, and
`.claude/skills/{generate-profile,release-aid}`; its extension filter is the regex
`/\.(md|mdx|sh|mjs|js|ts|py|yml|yaml)$/` (**including `.py`** — `render.py`, `run_generator.py` and 6
siblings are in reach). The declared-criteria cascade replaces its job **only for markdown files that
resolve to a registry type**, so a straight delete would drop coverage elsewhere. AC-3 requires a stated
disposition for **every** part — the table below is that disposition, not a to-do:

| corpus part | disposition | why |
|-------------|-------------|-----|
| `.aid/knowledge/*.md` + `canonical/**/*.md` (typed markdown) | **replaced** by the global criterion *counts must be load-bearing and current* (`G-01`-class), applied by the reviewer | this is the overlap the cascade exists to absorb |
| non-markdown (`.py`/`.sh`/`.mjs`/`.js`/`.ts`/`.yml`/`.yaml`) anywhere in the corpus | **dropped** | code/config is out of scope for declared criteria — build, lint and test are its oracle (REQUIREMENTS §4 Out of Scope); a count in a code comment is not a review concern |
| `docs/*.md` + root `README.md` (front face) | **reduced** to the once-per-work front-face review (FR-8); no ongoing automated count gate | these carry the "N skills / N shortcuts" phrasings; the residual risk — drift between works — is real but small, and is flagged, not hidden (see note) |
| `site/src/content/docs/` | **already out of scope** — separate validation, decided elsewhere (REQUIREMENTS §4) | not this work's corpus |
| `.claude/skills/{generate-profile,release-aid}` | **dropped** | repo-local maintainer skills, absent from `canonical/`; not part of the shipped methodology corpus |

Because every non-cascade part has a stated disposition (mostly *dropped, with reason*), a **full delete
of the 379 lines is justified** — the retirement leaves no stub, but its *coverage* is narrower than the
script's, and that narrowing is declared above rather than silent. Silent truncation is the failure
NFR-2/AC-4 exist to prevent; this is the opposite. The final delete-vs-narrow call is made at execution
against disk (AC-3), with full delete the stated default.

> **Flagged for the owner (residual risk):** dropping the ongoing count gate on `docs/` and root
> `README.md` means a stale "N skills" line there is caught at the next front-face review rather than on
> every commit. If that is too loose, the alternative is to **narrow** `check-skill-counts.mjs` to just
> those two front-face targets rather than delete it — which lowers the guard-line reduction below 379.
> This is the one disposition that is a judgment call rather than a derivation.

### 3. The front face (deferred to here by owner decision)

Brought into line with the changed trees only now, because until stream 3 closes they describe trees
still moving:

| files | count | lines |
|-------|-------|-------|
| `docs/*.md` | 7 | — |
| repo-root `README.md` | 1 | 257 |
| `examples/**/README.md` | 4 | 1,237 |

(`ls docs/*.md | wc -l` = 7; `wc -l README.md` = 257; `find examples -name README.md | wc -l` = 4.) All
four `examples/` READMEs are referenced — `brownfield-full-path` and `greenfield` via directory links in
`examples/README.md` and in `docs/repository-structure.md` — so none is a delete candidate.

### 4. The single render — both chains, exactly once (C-2, NFR-4)

Run once, here, after the source has stopped moving:

1. `canonical/` → `profiles/` → the two tracked dogfood trees, via
   `.claude/skills/generate-profile/scripts/run_generator.py` (full run, never a partial render), then
   resync the dogfood trees. `tests/canonical/test-dogfood-byte-identity.sh` must pass against the
   result.
2. The **site chain** — `site/src/content/docs` and `site/src/data/skill-flows/*.flow.json` (76 files),
   both **outputs** that are regenerated, never hand-edited. Their feeders are the sources this work
   edited: `docs/*.md` (this feature) feeds `site/src/content/docs`, and
   `canonical/skills/aid-execute/references/state-execute.md` (feature-002's aid-clerk pointer fix) feeds
   `aid-execute.flow.json` — whose `excerpt` field embeds that file's prose verbatim (`grep -o
   "aid-clerk[^\"]*" site/src/data/skill-flows/aid-execute.flow.json` returns the `state-execute.md`
   text). An earlier draft wrongly called the flow.json a *feeder*; it is one of the 76 regenerated
   outputs.

Mid-work staleness of either chain before this point is correct, not a defect.

### 5. Exit arithmetic (AC-4 / NFR-2)

**Removed guard lines minus added mechanism lines**, as a number. The guard-line floor is **379**
(`check-skill-counts.mjs`) — the figure AC-4 is tested against, and it holds **on §2's default of a full
delete**; if the owner chooses §2's narrow alternative instead, this figure drops and is re-derived at
execution. The **1,802** documentation lines from feature-002's 20 deleted READMEs are reported
**separately** and carry **no** weight in the test:
merged, deleted prose would pay for added machinery, which NFR-2 forbids (an earlier draft stated a
merged 2,181 floor). An authored `review-criteria:` block is **not** mechanism and does not count on the
added side.

### 6. The C-7 audit (AC-6)

`.aid/works/work-004-frontmatter-review-criteria/imports-from-work-003.md` — **created by feature-001**,
since it does not exist on this branch — is reviewed: every entry passes all six C-7 gates (fact not
file; named need; independently re-derived on this branch; no mechanism rides along; smallest form;
logged). Confirm no commit, cherry-pick, or file copy from `work-003` appears anywhere in the branch
(`git log`, `git diff` against `master`).

### 7. AC-2 proof (verification)

Per NFR-1, in a disposable worktree: plant a defect of the class a **removed** check used to catch; a
real review must report it via the declaration that replaced it. A removal whose replacement cannot
catch the defect is a regression, not a retirement — which is the guard against §2 dropping coverage it
only claimed to replace.

### 8. Ordering and out of scope

Runs after feature-001 (mechanism) and feature-002 (population); nothing here is safe until the
declarations exist and are populated. Not in scope: authoring criteria (feature-001), populating files
or deleting the READMEs (feature-002). The render performed here is the **only** render in the whole
work.
